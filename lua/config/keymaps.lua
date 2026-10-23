-- Personal keymaps. Loaded after keymaps-defaults.lua so these mappings win
-- when they intentionally reuse the same lhs.

local map = require("config.reload").mapper("personal")

-- Terminal keybindings
map("n", "<leader>tr", function()
  vim.cmd("vsplit | terminal")
end, { desc = "Terminal Right" })

map("n", "<leader>tb", function()
  vim.cmd("split | terminal")
end, { desc = "Terminal Bottom" })

-- Path yanks live under <leader>y so <leader>c stays code actions.
-- <leader>cd is line diagnostics (keymaps-defaults.lua).
map("n", "<leader>yp", function()
  vim.fn.setreg("+", vim.fn.expand("%"))
end, { desc = "Copy file (relative path)" })

map("n", "<leader>yP", function()
  vim.fn.setreg("+", vim.fn.expand("%:p"))
end, { desc = "Copy file (absolute path)" })

map("n", "<leader>yd", function()
  vim.fn.setreg("+", vim.fn.expand("%:p:h"))
end, { desc = "Copy directory" })

-- Search the config's own repository, wherever it is checked out. stdpath
-- follows the ~/.config/nvim symlink, so this works on any machine without
-- assuming a particular home directory or clone location.
map("n", "<leader>fC", function()
  local config_root = vim.uv.fs_realpath(vim.fn.stdpath("config")) or vim.fn.stdpath("config")
  local dirs = { config_root }
  require("snacks").picker.files({
    title = "Common Configuration Files",
    dirs = dirs,
  })
end, { desc = "Browse Neovim Configuration Files" })

map("n", "<leader>fo", function()
  vim.lsp.buf.format({ async = true })
end, { desc = "Format Current File" })

map("n", "<leader>fu", function()
  local file = vim.fn.expand("%:p")
  if file == "" then
    vim.notify("dos2unix: buffer has no file", vim.log.levels.WARN)
    return
  end
  if vim.fn.executable("dos2unix") ~= 1 then
    vim.notify("dos2unix: not installed", vim.log.levels.WARN)
    return
  end
  -- vim.fn.system() throws when the executable is missing, and its exit status
  -- must be checked explicitly: a conversion failure would otherwise still be
  -- reported as success.
  local result = vim.system({ "dos2unix", file }, { text = true }):wait()
  if result.code ~= 0 then
    vim.notify("dos2unix failed: " .. vim.trim(result.stderr or ""), vim.log.levels.ERROR)
    return
  end
  vim.cmd("checktime")
  vim.notify("dos2unix: " .. vim.fn.fnamemodify(file, ":t"))
end, { desc = "Convert Current File to Unix Line Endings" })

-- <leader>a is only "increment" (below). A second key on that prefix made it wait.
map("n", "<leader>bC", function()
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { "" })
  vim.api.nvim_win_set_cursor(0, { 1, 0 })
end, { desc = "Clear buffer contents" })

-- grug-far:
-- <leader>sr => project search/replace, filtered to the current extension
-- <leader>sR => current file search/replace
-- visual mode uses selected text as Search
local function current_extension_filter()
  if vim.bo.buftype ~= "" then return nil end
  local ext = vim.fn.expand("%:e")
  if ext == "" then return nil end
  return "*." .. ext
end

map("n", "<leader>sr", function()
  require("grug-far").open({
    transient = true,
    prefills = { filesFilter = current_extension_filter() },
  })
end, { desc = "Search/Replace (project)" })

map("x", "<leader>sr", function()
  require("grug-far").with_visual_selection({
    transient = true,
    prefills = { filesFilter = current_extension_filter() },
  })
end, { desc = "Search/Replace selection (project)" })

map("n", "<leader>sR", function()
  require("grug-far").open({ prefills = { paths = vim.fn.expand("%") } })
end, { desc = "Search/Replace (current file)" })

map("x", "<leader>sR", function()
  require("grug-far").with_visual_selection({ prefills = { paths = vim.fn.expand("%") } })
end, { desc = "Search/Replace selection (current file)" })

map("n", "<2-LeftMouse>", function()
  local m = vim.fn.getmousepos()
  if m.winid and m.winid ~= 0 then
    vim.api.nvim_set_current_win(m.winid)
  end
  if not (m.line and m.line > 0) then
    return
  end

  local col = math.max((m.column or 1) - 1, 0)
  vim.api.nvim_win_set_cursor(0, { m.line, col })

  local line = vim.api.nvim_get_current_line()
  local cursor_col = vim.api.nvim_win_get_cursor(0)[2] + 1
  local color_found = false

  for s in line:gmatch("()#%x%x%x%x%x%x") do
    local e = s + 6
    if cursor_col >= s and cursor_col <= e then
      color_found = true
      break
    end
  end

  if not color_found then
    for s in line:gmatch("()#%x%x%x") do
      local e = s + 3
      if cursor_col >= s and cursor_col <= e then
        color_found = true
        break
      end
    end
  end

  if color_found then
    vim.cmd("CccPick")
  end
end, { desc = "Open Color Picker on Double-Click" })

-- Add tab-page switching to the <leader><tab> menu.
-- <leader><tab><tab> lists tab pages and switches to the selected one.
map("n", "<leader><tab><tab>", function()
  local tabs = vim.api.nvim_list_tabpages()
  local current_tab = vim.api.nvim_get_current_tabpage()
  local items = {}

  for i, tab in ipairs(tabs) do
    local windows = vim.api.nvim_tabpage_list_wins(tab)
    local buf_names = {}
    for _, win in ipairs(windows) do
      local buf = vim.api.nvim_win_get_buf(win)
      local name = vim.api.nvim_buf_get_name(buf)
      if name ~= "" then
        table.insert(buf_names, vim.fn.fnamemodify(name, ":t"))
      end
    end
    local label = #buf_names > 0 and table.concat(buf_names, ", ") or "[empty]"
    local marker = tab == current_tab and "● " or "  "
    table.insert(items, string.format("%s%d: %s", marker, i, label))
  end

  vim.ui.select(items, {
    prompt = "Select Tab Page:",
  }, function(_, idx)
    if idx then
      vim.cmd("tabnext " .. idx)
    end
  end)
end, { desc = "List and switch Tab Pages" })

-- <leader><tab><tab> 用于 tab 列表；新建 Tab 改用 n
map("n", "<leader><tab>n", "<cmd>tabnew<cr>", { desc = "New Tab" })

-- =======================================================================
-- Modern editing workflow (AI collaboration and web-friendly interaction).
-- =======================================================================

-- 1. Ctrl + A selects the file in normal and visual mode.
-- Insert <C-a> stays "insert previously inserted text".
map({ "n", "x" }, "<C-a>", "ggVG", { desc = "Select all lines" })
-- noremap so this is the builtin increment, not the select-all map above.
map("n", "<leader>a", "<C-a>", { desc = "Increment number" })
-- <C-v> is paste. <C-q> is the terminal-friendly visual-block key.
map({ "n", "x" }, "<C-q>", "<C-v>", { desc = "Visual block" })

-- Ctrl+C copies the selection to the system clipboard in Visual mode only.
map("x", "<C-c>", '"+y', { desc = "Copy selection to system clipboard" })

-- Ctrl+X cuts the selection to the system clipboard in Visual mode only.
map("x", "<C-x>", '"+d', { desc = "Cut selection to system clipboard" })

-- Ctrl+V uses smart paste to replace the Visual selection.
map("x", "<C-v>", function() require("smart-paste").paste_clipboard_visual() end, { desc = "Smart paste clipboard over selection" })

-- Ctrl+V smart-pastes multiline code with indentation in Insert mode.
map("i", "<C-v>", "<Plug>(smart-paste-clipboard-insert)", { remap = true, desc = "Smart paste from system clipboard" })
