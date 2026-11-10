-- Code bookmarks that live in the source: `BOOKMARK: name` comments (and
-- `BOOKMARK-BEGIN: name` / `BOOKMARK-END` blocks). Nothing is stored in
-- shada/sessions, so Git is the persistence layer.
local M = {}

local api = vim.api
local uv = vim.uv or vim.loop

M.ns = api.nvim_create_namespace("aws_bookmarks_current")

local MARKER = "BOOKMARK"
local BLOCK_MARKERS = { "BOOKMARK-BEGIN", "BOOKMARK-END" }

---@type table<string, string>
M.highlights = {
  BookmarkSign = "FreshStatusLineAccent",
  BookmarkLine = "CursorLine",
  BookmarkName = "DiagnosticHint",
  BookmarkFile = "Comment",
}

local function set_highlights()
  local hint = api.nvim_get_hl(0, { name = "DiagnosticHint", link = false })
  local normal = api.nvim_get_hl(0, { name = "Normal", link = false })
  local fg = hint.fg or 0x56b6c2
  local bg = normal.bg or 0x1e2127

  api.nvim_set_hl(0, "BookmarkSign", { fg = fg, bold = true })
  api.nvim_set_hl(0, "BookmarkName", { fg = fg, bold = true })
  api.nvim_set_hl(0, "BookmarkFile", { fg = api.nvim_get_hl(0, { name = "Comment", link = false }).fg })
  api.nvim_set_hl(0, "BookmarkLine", { bg = blend(bg, fg, 0.12) })
  api.nvim_set_hl(0, "BookmarkRange", { bg = blend(bg, fg, 0.07) })
end

---Mix two 24-bit colors: weight is how much of `accent` ends up in the result.
---@param base integer
---@param accent integer
---@param weight number
---@return integer
function blend(base, accent, weight)
  local function channel(shift)
    local b = math.floor(base / 2 ^ shift) % 256
    local a = math.floor(accent / 2 ^ shift) % 256
    return math.floor(b + (a - b) * weight + 0.5)
  end
  return channel(16) * 65536 + channel(8) * 256 + channel(0)
end

---@param dir string|nil
---@return string
function M.project_root(dir)
  local start = dir or api.nvim_buf_get_name(0)
  if start == "" then
    start = uv.cwd() or "."
  end
  local root = vim.fs.root(start, { ".git" })
  return root or (uv.cwd() or ".")
end

---@param text string
---@param keyword string
---@return string|nil
local function name_after(text, keyword)
  local start = text:find(keyword, 1, true)
  if not start then
    return nil
  end
  local rest = text:sub(start + #keyword)
  rest = rest:gsub("^%s*[:%-]+%s*", "")
  rest = rest:gsub("%s*[%*%)]*%s*$", "")
  if rest == "" then
    return nil
  end
  return rest
end

---@param file string
---@param lnum integer
---@param text string
---@return table|nil
local function classify(file, lnum, text)
  local begin_name = name_after(text, "BOOKMARK-BEGIN")
  if begin_name or text:find("BOOKMARK%-BEGIN") then
    return { kind = "begin", name = begin_name or "block", file = file, lnum = lnum }
  end
  if text:find("BOOKMARK%-END") or text:find("endregion", 1, true) then
    return { kind = "end", file = file, lnum = lnum }
  end
  if text:find("region%s+BOOKMARK") then
    return { kind = "begin", name = name_after(text, "BOOKMARK") or "block", file = file, lnum = lnum }
  end
  local name = name_after(text, MARKER)
  return { kind = "line", name = name or MARKER, file = file, lnum = lnum }
end

---Run ripgrep over `root` and return every BOOKMARK match, block ranges folded in.
---@param root string
---@param callback fun(items: table[])
function M.scan(root, callback)
  local args = {
    "--json",
    "--no-messages",
    "--hidden",
    "--glob",
    "!**/.git/**",
    "--glob",
    "!**/node_modules/**",
    "-e",
    MARKER,
    "-e",
    "endregion",
    ".",
  }
  vim.system(vim.list_extend({ "rg" }, args), { cwd = root, text = true }, function(obj)
    local items = {}
    local files = {}
    for line in (obj.stdout or ""):gmatch("[^\r\n]+") do
      local ok, msg = pcall(vim.json.decode, line)
      if ok and type(msg) == "table" and msg.type == "match" then
        local path = msg.data.path.text
        local abs = path:sub(1, 1) == "/" and path or (root .. "/" .. path:gsub("^%./", ""))
        items[#items + 1] = { file = abs, lnum = msg.data.line_number, text = (msg.data.lines.text or ""):gsub("\n$", "") }
        files[abs] = true
      end
    end
    local folded = M.fold(items)
    vim.schedule(function()
      callback(folded)
    end)
  end)
end

---Turn raw matches into bookmark entries, pairing BEGIN/END markers.
---@param matches table[]
---@return table[]
function M.fold(matches)
  table.sort(matches, function(a, b)
    if a.file == b.file then
      return a.lnum < b.lnum
    end
    return a.file < b.file
  end)

  local items = {}
  local open = {}
  for _, match in ipairs(matches) do
    local entry = classify(match.file, match.lnum, match.text)
    if entry then
      if entry.kind == "begin" then
        open[#open + 1] = entry
      elseif entry.kind == "end" then
        local start = table.remove(open)
        if start then
          start.kind = "block"
          start.end_lnum = match.lnum
          items[#items + 1] = start
        end
      else
        items[#items + 1] = entry
      end
    end
  end
  for _, start in ipairs(open) do
    start.kind = "block"
    start.unclosed = true
    items[#items + 1] = start
  end

  table.sort(items, function(a, b)
    if a.file == b.file then
      return a.lnum < b.lnum
    end
    return a.file < b.file
  end)

  for _, item in ipairs(items) do
    item.root = nil
    item.rel = vim.fn.fnamemodify(item.file, ":.")
  end
  return items
end

---Relative path used in lists: project-relative when possible.
---@param file string
---@param root string
---@return string
function M.relative(file, root)
  if file:sub(1, #root) == root then
    return file:sub(#root + 2)
  end
  return vim.fn.fnamemodify(file, ":~:.")
end

---@param item table
---@return string
function M.label(item)
  if item.kind == "block" then
    local range = item.end_lnum and string.format("%d-%d", item.lnum, item.end_lnum) or "open"
    return string.format("%s  [%s]", item.name, range)
  end
  return item.name
end

---Jump to a bookmark from any list.
---@param item table
---@param opts table|nil
function M.open(item, opts)
  opts = opts or {}
  local win = api.nvim_get_current_win()
  if vim.bo[api.nvim_win_get_buf(win)].filetype == "neo-tree" then
    win = vim.fn.win_getid(vim.fn.winnr("#"))
  end
  api.nvim_win_call(win, function()
    vim.cmd.edit({ args = { vim.fn.fnameescape(item.file) }, mods = { silent = true } })
  end)
  api.nvim_win_set_cursor(win, { item.lnum, 0 })
  vim.cmd("normal! zv")
  if item.kind == "block" and item.end_lnum and opts.select ~= false then
    api.nvim_win_call(win, function()
      vim.cmd(string.format("normal! %dGV%dG", item.lnum, item.end_lnum))
    end)
  end
end

---Highlight the bookmark under the cursor in the active window.
function M.refresh_current()
  local buf = api.nvim_get_current_buf()
  if not api.nvim_buf_is_loaded(buf) or vim.bo[buf].filetype == "neo-tree" then
    return
  end
  api.nvim_buf_clear_namespace(buf, M.ns, 0, -1)
  local row = math.max(0, api.nvim_win_get_cursor(0)[1] - 1)
  local line = api.nvim_buf_get_lines(buf, row, row + 1, false)[1] or ""
  if line:find(MARKER, 1, true) then
    api.nvim_buf_set_extmark(buf, M.ns, row, 0, {
      line_hl_group = "BookmarkLine",
      hl_eol = true,
    })
  end
end

---Bookmarked lines for quickfix / statusline style navigation.
---@param items table[]
---@return table[]
function M.to_qf(items)
  local list = {}
  for _, item in ipairs(items) do
    list[#list + 1] = {
      filename = item.file,
      lnum = item.lnum,
      col = 1,
      text = string.format("[%s] %s", item.kind == "block" and "BLOCK" or "MARK", item.name),
      valid = 1,
    }
  end
  return list
end

---@param after boolean
function M.jump(direction)
  local buf = api.nvim_get_current_buf()
  local line = math.max(1, api.nvim_win_get_cursor(0)[1])
  local lines = api.nvim_buf_get_lines(buf, 0, -1, false)
  local step = direction == "next" and 1 or -1
  local index = line + step
  while index >= 1 and index <= #lines do
    if lines[index]:find(MARKER, 1, true) then
      api.nvim_win_set_cursor(0, { index, 0 })
      vim.cmd("normal! zv")
      return true
    end
    index = index + step
  end
  -- wrap around once
  index = (step == 1) and 1 or #lines
  while (step == 1 and index < line) or (step == -1 and index > line) do
    if lines[index]:find(MARKER, 1, true) then
      api.nvim_win_set_cursor(0, { index, 0 })
      vim.cmd("normal! zv")
      return true
    end
    index = index + step
  end
  return false
end

---Comment string for the current buffer, e.g. "#" or "--".
---@param bufnr integer
---@return string
function M.comment_prefix(bufnr)
  local cs = vim.bo[bufnr].commentstring
  local left = cs:match("^(.-)%%s") or "#"
  return vim.trim(left)
end

---Insert a bookmark line for the cursor line (or wrap the visual range).
---@param name string|nil
---@param opts table|nil
function M.add(name, opts)
  opts = opts or {}
  local bufnr = api.nvim_get_current_buf()
  local prefix = M.comment_prefix(bufnr)
  local start_line = math.max(1, api.nvim_win_get_cursor(0)[1])
  local range = opts.range
  if not range then
    local mode = api.nvim_get_mode().mode
    if mode == "v" or mode == "V" or mode == "\22" then
      local s = api.nvim_buf_get_mark(bufnr, "<")[1]
      local e = api.nvim_buf_get_mark(bufnr, ">")[1]
      if s > 0 and e > 0 then
        range = { math.min(s, e), math.max(s, e) }
        api.nvim_feedkeys(api.nvim_replace_termcodes("<Esc>", true, false, true), "nx", false)
      end
    end
  end
  if range then
    start_line = range[1]
  end

  local function write(value)
    value = vim.trim(value or "")
    if value == "" then
      value = "bookmark"
    end
    local indent = api.nvim_buf_get_lines(bufnr, start_line - 1, start_line, false)[1]:match("^%s*") or ""
    local line = api.nvim_buf_get_lines(bufnr, start_line - 1, start_line, false)[1] or ""
    -- keep the marker next to the comment leader when the line already has one
    local leader = prefix
    if line:match("^%s*" .. vim.pesc(prefix)) then
      leader = ""
    end
    if range then
      local end_indent = api.nvim_buf_get_lines(bufnr, range[2] - 1, range[2], false)[1]:match("^%s*") or indent
      api.nvim_buf_set_lines(bufnr, range[2], range[2], false, {
        end_indent .. prefix .. " BOOKMARK-END",
      })
      api.nvim_buf_set_lines(bufnr, range[1] - 1, range[1] - 1, false, {
        indent .. leader .. (leader == "" and "" or " ") .. "BOOKMARK-BEGIN: " .. value,
      })
      vim.notify(string.format("Bookmark block: %s (%d-%d)", value, range[1], range[2] + 1))
    else
      -- place the marker above the line it describes
      local insert_at = start_line - 1
      api.nvim_buf_set_lines(bufnr, insert_at, insert_at, false, {
        indent .. leader .. (leader == "" and "" or " ") .. "BOOKMARK: " .. value,
      })
      vim.notify("Bookmark added: " .. value)
    end
    M.refresh_current()
    vim.cmd("write")
  end

  if name and name ~= "" then
    write(name)
  else
    vim.ui.input({ prompt = "Bookmark name: " }, function(value)
      if value then
        write(value)
      end
    end)
  end
end

---Wrap the last visual selection in BOOKMARK-BEGIN/END.
---@param name string|nil
function M.add_range(name)
  local bufnr = api.nvim_get_current_buf()
  local first = api.nvim_buf_get_mark(bufnr, "<")[1]
  local last = api.nvim_buf_get_mark(bufnr, ">")[1]
  if first <= 0 or last <= 0 then
    return M.add(name)
  end
  api.nvim_feedkeys(api.nvim_replace_termcodes("<Esc>", true, false, true), "nx", false)
  M.add(name, { range = { math.min(first, last), math.max(first, last) } })
end

---@param items table[]
---@param root string
function M.quickfix(items, root)
  local list = M.to_qf(items)
  if #list == 0 then
    vim.notify("No bookmarks in " .. root, vim.log.levels.WARN)
    return
  end
  vim.fn.setqflist({}, " ", { title = "BOOKMARK · " .. vim.fn.fnamemodify(root, ":t"), items = list })
  vim.cmd("copen")
end

-- Telescope picker -----------------------------------------------------------

local function previewer_for()
  local previewers = require("telescope.previewers")
  return previewers.new_buffer_previewer({
    title = "Bookmark",
    define_preview = function(self, entry)
      local item = entry.value
      local bufnr = self.state.bufnr
      local last = item.end_lnum or (item.lnum + 20)
      local ok, lines = pcall(vim.fn.readfile, item.file, "", last)
      if not ok then
        lines = {}
      end
      local out = {}
      if item.kind == "block" then
        out[#out + 1] = string.format("-- %s  [%d-%d]", item.name, item.lnum, item.end_lnum or last)
      end
      for index = item.lnum, math.min(#lines, last) do
        out[#out + 1] = string.format("%4d %s", index, lines[index])
      end
      vim.bo[bufnr].modifiable = true
      api.nvim_buf_set_lines(bufnr, 0, -1, false, out)
      local ft = vim.filetype.match({ filename = item.file })
      if ft then
        vim.bo[bufnr].filetype = ft
      end
      vim.bo[bufnr].modifiable = false
    end,
  })
end

---Open the bookmark picker for the current project.
---@param opts table|nil
function M.pick(opts)
  opts = opts or {}
  local root = opts.root or M.project_root()
  M.scan(root, function(items)
    if #items == 0 then
      vim.notify("No bookmarks in " .. root, vim.log.levels.WARN)
      return
    end
    vim.schedule(function()
      local pickers = require("telescope.pickers")
      local finders = require("telescope.finders")
      local sorters = require("telescope.sorters")
      local actions = require("telescope.actions")
      local action_state = require("telescope.actions.state")
      local conf = require("telescope.config").values

      local function entry_maker(item)
        local rel = M.relative(item.file, root)
        local display = string.format("%s  %s:%d", M.label(item), rel, item.lnum)
        return {
          value = item,
          display = display,
          ordinal = item.name .. " " .. rel .. " " .. item.lnum,
          path = item.file,
          filename = item.file,
          lnum = item.lnum,
          col = 1,
        }
      end

      pickers
        .new({}, {
          prompt_title = string.format("BOOKMARK · %s (%d)", vim.fn.fnamemodify(root, ":t"), #items),
          finder = finders.new_table({ results = items, entry_maker = entry_maker }),
          sorter = sorters.get_generic_fuzzy_sorter(),
          previewer = previewer_for(),
          results_title = "Bookmarks",
          layout_strategy = "horizontal",
          layout_config = {
            width = 0.9,
            height = 0.8,
            horizontal = { preview_width = 0.55, preview_cutoff = 60 },
          },
          attach_mappings = function(prompt_bufnr)
            actions.select_default:replace(function()
              local selection = action_state.get_selected_entry()
              actions.close(prompt_bufnr)
              if selection then
                M.open(selection.value)
              end
            end)
            return true
          end,
        })
        :find()
    end)
  end)
end

---@param root string|nil
function M.panel(root)
  require("neo-tree.command").execute({ source = "bookmarks", dir = root or M.project_root(), toggle = true })
end

function M.setup()
  set_highlights()
  local group = api.nvim_create_augroup("CodeBookmarks", { clear = true })
  api.nvim_create_autocmd({ "CursorMoved", "BufEnter", "WinEnter" }, {
    group = group,
    callback = function()
      M.refresh_current()
    end,
  })
  api.nvim_create_autocmd("ColorScheme", {
    group = group,
    callback = set_highlights,
  })
  api.nvim_create_autocmd("User", {
    group = group,
    pattern = "NeotreeBookmarksRefresh",
    callback = function(args)
      pcall(function()
        require("neo-tree.sources.manager").refresh("bookmarks")
      end)
    end,
  })
  vim.api.nvim_create_user_command("BookmarkList", function()
    M.pick()
  end, { desc = "List bookmarks in the current project" })
  vim.api.nvim_create_user_command("BookmarkAdd", function(args)
    M.add(args.args ~= "" and args.args or nil)
  end, { nargs = "*", desc = "Add a BOOKMARK comment" })
  vim.api.nvim_create_user_command("BookmarkNext", function()
    M.jump("next")
  end, { desc = "Jump to the next bookmark" })
  vim.api.nvim_create_user_command("BookmarkPrev", function()
    M.jump("prev")
  end, { desc = "Jump to the previous bookmark" })
  vim.api.nvim_create_user_command("BookmarkQF", function()
    local root = M.project_root()
    M.scan(root, function(items)
      M.quickfix(items, root)
    end)
  end, { desc = "Send project bookmarks to the quickfix list" })
  vim.api.nvim_create_user_command("BookmarkPanel", function()
    M.panel()
  end, { desc = "Open the bookmark sidebar" })
end

return M
