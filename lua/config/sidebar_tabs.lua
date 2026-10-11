local M = {}
local sources = { "filesystem", "buffers", "git_status", "symbols" }
local labels = { "File", "Bufs", "Git", "Syms" }
local icons = { "󰉓", "󰈚", "󰊢", "󰘦" }

local function sidebar_windows()
  local windows = {}
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local ft = vim.bo[vim.api.nvim_win_get_buf(win)].filetype
    if ft == "neo-tree" or ft == "aerial" then windows[#windows + 1] = win end
  end
  return windows
end

local function editor_window()
  if M.editor and vim.api.nvim_win_is_valid(M.editor)
    and vim.api.nvim_win_get_tabpage(M.editor) == vim.api.nvim_get_current_tabpage() then
    local buf = vim.api.nvim_win_get_buf(M.editor)
    if vim.bo[buf].buftype == "" and vim.bo[buf].filetype ~= "aerial" then return M.editor end
  end
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].buftype == "" and vim.bo[buf].filetype ~= "aerial" then return win end
  end
end

function M.open_buffer(buf)
  if not vim.api.nvim_buf_is_valid(buf) then return end
  local win = editor_window()
  if not win then return end
  vim.api.nvim_set_current_win(win)
  vim.api.nvim_win_set_buf(win, buf)
  vim.cmd.redrawtabline()
end

function M.on_tree_open(args)
  local request = M.pending_tree
  if not request or request.source ~= args.source then return end
  vim.schedule(function()
    if M.pending_tree ~= request or not vim.api.nvim_win_is_valid(args.winid) then return end
    M.pending_tree = nil
    vim.api.nvim_win_set_width(args.winid, request.width)
    if request.focus then vim.api.nvim_set_current_win(args.winid) end
  end)
end

function M.select(source, opts)
  local focus = not opts or opts.focus ~= false
  local editor = editor_window()
  if not editor then return end
  local sidebar = sidebar_windows()[1]
  local width = sidebar and vim.api.nvim_win_get_width(sidebar) or 32
  M.pending_tree = nil
  vim.api.nvim_set_current_win(editor)
  if source == "symbols" then
    if sidebar then
      -- Neo-tree redirects foreign buffers on BufEnter. During this deliberate
      -- handoff, seed the alternate buffer with the source file instead.
      local aerial = require("aerial")
      local ignored = vim.o.eventignore
      vim.opt.eventignore:append({ "BufEnter", "BufWinEnter" })
      local ok, err = pcall(function()
        vim.api.nvim_win_set_buf(sidebar, vim.api.nvim_win_get_buf(editor))
        aerial.open_in_win(sidebar, editor)
      end)
      vim.o.eventignore = ignored
      if not ok then error(err) end
      vim.api.nvim_set_current_win(sidebar)
      -- Replay the event after the handoff: Aerial uses it to render cached
      -- symbols into a newly created outline buffer.
      vim.api.nvim_exec_autocmds("BufWinEnter", { buffer = vim.api.nvim_win_get_buf(sidebar) })
    else
      require("aerial").open({ focus = focus, direction = "left" })
    end
    if vim.bo.filetype == "aerial" then
      vim.wo.foldcolumn = "0"
      vim.wo.statuscolumn = ""
    end
  else
    -- Neo-tree's left location survives while Aerial borrows its window.
    if sidebar and vim.bo[vim.api.nvim_win_get_buf(sidebar)].filetype == "aerial" then
      vim.w[sidebar].is_aerial_win = nil
      vim.w[sidebar].source_win = nil
      vim.w[editor].aerial_win = nil
      require("neo-tree.ui.windows").get_location("left").winid = sidebar
    end
    M.pending_tree = { source = source, width = width, focus = focus }
    require("neo-tree.command").execute({ source = source, action = focus and "focus" or "show", position = "left" })
    if focus and sidebar and vim.api.nvim_win_is_valid(sidebar)
      and vim.bo[vim.api.nvim_win_get_buf(sidebar)].filetype == "neo-tree" then
      vim.api.nvim_set_current_win(sidebar)
    end
  end
  if vim.bo.filetype == "aerial" or vim.bo.filetype == "neo-tree" then
    vim.wo.winfixwidth = true
    vim.api.nvim_win_set_width(0, width)
  end
  if not focus then vim.api.nvim_set_current_win(editor) end
  vim.cmd.redrawtabline()
end

function M.toggle_symbols()
  for _, win in ipairs(sidebar_windows()) do
    if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "aerial" then
      vim.api.nvim_win_close(win, true)
      return
    end
  end
  M.select("symbols", { focus = false })
end

function M.cycle(step)
  local current = vim.bo.filetype == "aerial" and "symbols" or vim.b.neo_tree_source
  for index, source in ipairs(sources) do
    if source == current then M.select(sources[(index - 1 + step) % #sources + 1]); return end
  end
end

function M.render(win, width)
  local buf = vim.api.nvim_win_get_buf(win)
  local current = vim.bo[buf].filetype == "aerial" and "symbols" or vim.b[buf].neo_tree_source
  local parts = {}
  for index, source in ipairs(sources) do
    local size = math.floor(width * index / #sources) - math.floor(width * (index - 1) / #sources)
    local label = icons[index] .. " " .. labels[index]
    while vim.fn.strdisplaywidth(label) > size do
      label = vim.fn.strcharpart(label, 0, vim.fn.strchars(label) - 1)
    end
    local label_width = vim.fn.strdisplaywidth(label)
    local left = math.floor((size - label_width) / 2)
    local group = source == current and "NeoTreeTabActive" or "NeoTreeTabInactive"
    parts[#parts + 1] = string.format("%%#%s#%%%d@v:lua.__sidebar_source_click@%s%s%s%%X",
      group, index, string.rep(" ", left), label, string.rep(" ", size - label_width - left))
  end
  return table.concat(parts)
end

function M.setup()
  local offset = require("bufferline.offset")
  if M.installed then return end
  M.installed = true
  _G.__sidebar_source_click = function(index, _, button)
    if button == "l" and sources[index] then M.select(sources[index], { focus = false }) end
  end
  local group = vim.api.nvim_create_augroup("SidebarSourceTabs", { clear = true })
  vim.api.nvim_create_autocmd("BufEnter", {
    group = group,
    callback = function()
      if vim.bo.buftype == "" and vim.bo.filetype ~= "aerial" then M.editor = vim.api.nvim_get_current_win() end
    end,
  })
  local original = offset.get
  offset.get = function()
    local result = original()
    if result.left_size == 0 then return result end
    local layout = vim.fn.winlayout()
    while layout[1] ~= "leaf" do layout = layout[2][1] end
    local win = layout[2]
    local ft = vim.bo[vim.api.nvim_win_get_buf(win)].filetype
    if ft == "neo-tree" or ft == "aerial" then result.left = M.render(win, result.left_size) end
    return result
  end
end

return M
