-- Personal keymaps. Loaded after keymaps-defaults.lua so these mappings win
-- when they intentionally reuse the same lhs.

-- Terminal keybindings
vim.keymap.set("n", "<leader>tr", function()
  vim.cmd("vsplit | terminal")
end, { desc = "Terminal Right" })

vim.keymap.set("n", "<leader>tb", function()
  vim.cmd("split | terminal")
end, { desc = "Terminal Bottom" })

-- Path yanks live under <leader>y so <leader>c stays code actions.
-- <leader>cd is line diagnostics (keymaps-defaults.lua).
vim.keymap.set("n", "<leader>yp", function()
  vim.fn.setreg("+", vim.fn.expand("%"))
end, { desc = "Copy file (relative path)" })

vim.keymap.set("n", "<leader>yP", function()
  vim.fn.setreg("+", vim.fn.expand("%:p"))
end, { desc = "Copy file (absolute path)" })

vim.keymap.set("n", "<leader>yd", function()
  vim.fn.setreg("+", vim.fn.expand("%:p:h"))
end, { desc = "Copy directory" })

-- Search the config's own repository, wherever it is checked out. stdpath
-- follows the ~/.config/nvim symlink, so this works on any machine without
-- assuming a particular home directory or clone location.
vim.keymap.set("n", "<leader>fC", function()
  local config_root = vim.uv.fs_realpath(vim.fn.stdpath("config")) or vim.fn.stdpath("config")
  local dirs = { config_root }
  require("snacks").picker.files({
    title = "常用配置文件",
    dirs = dirs,
  })
end, { desc = "打开常用收藏" })

vim.keymap.set("n", "<leader>fo", function()
  vim.lsp.buf.format({ async = true })
end, { desc = "format this file" })

vim.keymap.set("n", "<leader>fu", function()
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
end, { desc = "dos2unix current file" })

-- <leader>a is only "increment" (below). A second key on that prefix made it wait.
vim.keymap.set("n", "<leader>bC", function()
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

vim.keymap.set("n", "<leader>sr", function()
  require("grug-far").open({
    transient = true,
    prefills = { filesFilter = current_extension_filter() },
  })
end, { desc = "Search/Replace (project)" })

vim.keymap.set("x", "<leader>sr", function()
  require("grug-far").with_visual_selection({
    transient = true,
    prefills = { filesFilter = current_extension_filter() },
  })
end, { desc = "Search/Replace selection (project)" })

vim.keymap.set("n", "<leader>sR", function()
  require("grug-far").open({ prefills = { paths = vim.fn.expand("%") } })
end, { desc = "Search/Replace (current file)" })

vim.keymap.set("x", "<leader>sR", function()
  require("grug-far").with_visual_selection({ prefills = { paths = vim.fn.expand("%") } })
end, { desc = "Search/Replace selection (current file)" })

vim.keymap.set("n", "<2-LeftMouse>", function()
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
end, { desc = "双击颜色弹出 ccc 取色器" })

-- 添加到 <leader><tab> 菜单中
-- <leader><tab><tab> - 列出所有 Tab Pages 并选择切换（类似 buffer 切换）
vim.keymap.set("n", "<leader><tab><tab>", function()
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
vim.keymap.set("n", "<leader><tab>n", "<cmd>tabnew<cr>", { desc = "New Tab" })

-- =======================================================================
-- 现代编辑器操作流 (AI 协作 / 网页交互友好，兼顾 Vim 模态特性)
-- =======================================================================

-- 1. Ctrl + A selects the file in normal and visual mode.
-- Insert <C-a> stays "insert previously inserted text".
vim.keymap.set({ "n", "x" }, "<C-a>", "ggVG", { desc = "Select all lines" })
-- noremap so this is the builtin increment, not the select-all map above.
vim.keymap.set("n", "<leader>a", "<C-a>", { desc = "Increment number" })
-- <C-v> is paste. <C-q> is the terminal-friendly visual-block key.
vim.keymap.set({ "n", "x" }, "<C-q>", "<C-v>", { desc = "Visual block" })

-- 2. Ctrl + C: 仅在可视模式下生效，复制选区到系统剪贴板 (普通模式保留原生中断/取消)
vim.keymap.set("x", "<C-c>", '"+y', { desc = "Copy selection to system clipboard" })

-- 3. Ctrl + X: 仅在可视模式下生效，剪切选区到系统剪贴板 (普通模式保留数字减 1，插入模式保留补全前缀)
vim.keymap.set("x", "<C-x>", '"+d', { desc = "Cut selection to system clipboard" })

-- 4. smart-paste.nvim 接管 p/P：行式粘贴按目标上下文调整缩进，并保留原剪贴板。
vim.keymap.set("x", "<C-v>", function() require("smart-paste").paste_clipboard_visual() end, { desc = "Smart paste clipboard over selection" })

-- 5. 插入模式 Ctrl + V：多行代码按当前位置缩进重排；单行文本保持原样插入。
vim.keymap.set("i", "<C-v>", "<Plug>(smart-paste-clipboard-insert)", { remap = true, desc = "Smart paste from system clipboard" })
