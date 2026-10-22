-- Winbar context after the dropbar port.
-- Run: nvim --headless -u NONE -l tests/context_bar_spec.lua
local this_file = debug.getinfo(1, "S").source:sub(2)
local nvim_root = vim.fn.fnamemodify(this_file, ":h:h")
local lazy = vim.fn.stdpath("data") .. "/lazy"
local lab = nvim_root .. "/tests/fixtures/context"

vim.opt.runtimepath:prepend(nvim_root)
for _, plugin in ipairs({
  "nvim-treesitter",
  "dropbar.nvim",
  "cobol.nvim",
  "batch.nvim",
  "nvim-web-devicons",
}) do
  vim.opt.runtimepath:prepend((vim.env.NVIM_PLUGIN_DEV_ROOT and ({["cobol.nvim"]=true,["batch.nvim"]=true})[plugin])
    and (vim.env.NVIM_PLUGIN_DEV_ROOT .. "/" .. plugin) or (lazy .. "/" .. plugin))
end
vim.opt.runtimepath:prepend(vim.fn.stdpath("data") .. "/site")
package.path = nvim_root .. "/lua/?.lua;" .. nvim_root .. "/lua/?/init.lua;" .. package.path
vim.cmd("filetype plugin indent on")

dofile(nvim_root .. "/lua/plugins/dropbar.lua")[1].config()
require("cobol").setup({
  show_winbar = false,
  diagnostics = { enable = false },
  folding = { enable = false },
})
require("batch").setup({
  enable_diagnostics = false,
  enable_folding = false,
  enable_statusline = false,
  map_keys = false,
})

local function find_line(pattern)
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  for i, line in ipairs(lines) do
    if line:find(pattern) then
      return i
    end
  end
  error("pattern not found: " .. pattern)
end

local function open(path, ft)
  vim.cmd("edit " .. vim.fn.fnameescape(path))
  vim.bo.filetype = ft
  return vim.api.nvim_get_current_buf(), vim.api.nvim_get_current_win()
end

local function place(pattern, col)
  vim.api.nvim_win_set_cursor(0, { find_line(pattern), col or 0 })
end

local function dropbar_text()
  local buf = vim.api.nvim_get_current_buf()
  local win = vim.api.nvim_get_current_win()
  require("config.dropbar").sync(buf, win)
  assert(vim.wo[win].winbar:find("dropbar", 1, true), "winbar was not armed: " .. vim.wo[win].winbar)
  local rendered = _G.dropbar.bars[buf][win]
  rendered:_update()
  return rendered:cat(true), rendered:cat(false), rendered
end

local function menu_open()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].filetype == "dropbar_menu" then
      return true
    end
  end
  return false
end

local function jump_from_menu()
  local menu = require('config.dropbar_mouse').get_current() or require('dropbar.utils.menu').get_current()
  assert(menu and #menu.entries > 0, 'native menu must contain an outline')
  local target = menu.entries[#menu.entries].components[2]
  local range, win = target.range, target.win
  target:on_click()
  assert(vim.api.nvim_get_current_win() == win, 'menu jump must restore source window')
  local cursor = vim.api.nvim_win_get_cursor(win)
  assert(cursor[1] == range.start.line+1 and cursor[2] == range.start.character, 'menu must jump to AST/label range')
end

local function click_code(bar, pattern)
  for _, symbol in ipairs(bar.components) do
    if (symbol.data and symbol.data.kind and symbol.name:find(pattern,1,true))
      or (symbol.name:find(pattern,1,true)) or (pattern=='[' and symbol:cat(true):find('[',1,true)) then
      symbol:on_click(nil,1,'l')
      return
    end
  end
  error('code component missing: '..pattern)
end

local function close_menu()
  pcall(function()
    require("dropbar.utils.menu").exec("close")
  end)
end

-- Python at file scope still has a breadcrumb, and a method shows the
-- contextline names rather than the raw Treesitter statement text.
open(lab .. "/examples/python/night_report.py", "python")
require("config.dropbar").sync(0, 0)
place("^\"\"\"", 0)
local root_plain, root_hl = dropbar_text()
assert(root_plain:find("(root)", 1, true), "file scope must stay visible: " .. root_plain)
assert(root_hl:find("DropBarContextText", 1, true), "breadcrumb must use the winbar palette")
assert(root_hl:find("v:lua.dropbar.callbacks", 1, true), "breadcrumb must be clickable")
assert(not root_hl:find("%%#Type#", 1, false) and not root_hl:find("%%#Title#", 1, false), "semantic colors must stay off the bar")

place("def read_input", 4)
local method_plain, method_hl, method_bar = dropbar_text()
assert(method_plain:find("NightReport", 1, true), method_plain)
assert(method_plain:find("read_input", 1, true), method_plain)
assert(not method_plain:find("def read_input", 1, true), "must not show the raw statement: " .. method_plain)
click_code(method_bar,"NightReport")
assert(vim.wait(300, menu_open), "clicking a Python segment must open the hierarchy menu")
jump_from_menu()
close_menu()

-- JavaScript uses the same source.
open(lab .. "/examples/javascript/csv2xls.js", "javascript")
require("config.dropbar").sync(0, 0)
place("^", 0)
local js_plain = dropbar_text()
assert(js_plain ~= "", "javascript must show a breadcrumb: " .. tostring(js_plain))

-- Shell scripts are filetype sh. The breadcrumb has to use the bash grammar.
open(lab .. "/scripts/linux/nightly-main.sh", "sh")
require("config.dropbar").sync(0, 0)
place("validate%-input", 0)
local shell_plain = dropbar_text()
assert(shell_plain:find("validate", 1, true), "shell must show a breadcrumb: " .. shell_plain)

-- Batch labels come from the language provider.
open(lab .. "/windows-batch/nightly-main.bat", "dosbatch")
require("config.dropbar").sync(0, 0)
place("^:error_input", 0)
local batch_plain, batch_hl, batch_bar = dropbar_text()
assert(batch_plain:find("error_input", 1, true), batch_plain)
assert(batch_hl:find("v:lua.dropbar.callbacks", 1, true), "batch breadcrumb must be clickable")
click_code(batch_bar,"error_input")
assert(vim.wait(300, menu_open), "clicking a batch segment must open the hierarchy menu")
jump_from_menu()
close_menu()

-- COBOL keeps the bracketed chain and can open the same menu.
open(lab .. "/src/cobol/NIGHTSETTLE.COB", "cobol")
require("config.dropbar").sync(0, 0)
assert(vim.wo.winbar == "%{%v:lua.dropbar()%}", "COBOL must use dropbar")
place("FILE%-CONTROL", 10)
local cobol_option = select(2, dropbar_text())
local cobol_text = vim.api.nvim_eval_statusline(cobol_option, { winid = 0, use_winbar = true }).str
assert(cobol_option:find("v:lua.dropbar.callbacks", 1, true), "COBOL chain must be clickable: " .. cobol_option)
assert(cobol_option:find("CobolBreadcrumb", 1, true), cobol_option)
assert(cobol_text:find("ENVIRONMENT DIVISION", 1, true), cobol_text)
assert(not cobol_text:find("FIXED", 1, true), "COBOL must not use the icon chips: " .. cobol_text)
assert(not cobol_text:find("AREA A", 1, true), cobol_text)
local _, _, cobol_bar = dropbar_text()
click_code(cobol_bar,"[")
assert(vim.wait(300, menu_open), "clicking the COBOL chain must open the hierarchy menu")
jump_from_menu()
close_menu()

place("IF WS%-STATUS", 12)
local proc_option = select(2, dropbar_text())
local proc_text = vim.api.nvim_eval_statusline(proc_option, { winid = 0, use_winbar = true }).str
assert(proc_text:find("[", 1, true) and proc_text:find("]", 1, true), proc_text)
assert(proc_text:find("IF WS-STATUS", 1, true), proc_text)
-- A long file path may elide outer scopes; keep the active IF visible.
assert(not proc_text:find("FIXED", 1, true), proc_text)

-- A short chain keeps the division and the waiting closure on one row.
local short_buf = vim.api.nvim_create_buf(true, false)
vim.api.nvim_buf_set_lines(short_buf, 0, -1, false, {
  "       IDENTIFICATION DIVISION.",
  "       PROGRAM-ID. SHORT.",
  "       PROCEDURE DIVISION.",
  "       SHORT-PARA.",
  "           IF A > 1",
  '           DISPLAY "X"',
  "           END-IF.",
  "           STOP RUN.",
})
vim.bo[short_buf].filetype = "cobol"
vim.api.nvim_set_current_buf(short_buf)
require("cobol").attach(short_buf)
vim.api.nvim_win_set_cursor(0, { 6, 20 })
require("config.dropbar").sync(short_buf, 0)
local short_option = select(2, dropbar_text())
local short_text = vim.api.nvim_eval_statusline(short_option, { winid = 0, use_winbar = true }).str
assert(short_text:find("PROCEDURE DIVISION", 1, true), short_text)
assert(short_text:find("SHORT-PARA", 1, true), short_text)
assert(short_text:find("END-IF", 1, true), "waiting closure must stay on the COBOL bar: " .. short_text)
assert(short_option:find("CobolWaitingClosure", 1, true), short_option)

-- Diagnostics stay on the breadcrumb and open the quickfix list.
open(lab .. "/examples/python/night_report.py", "python")
require("config.dropbar").sync(0, 0)
place("def read_input", 4)
vim.diagnostic.set(vim.api.nvim_create_namespace("context_bar_spec"), 0, {
  { lnum = 1, col = 0, message = "broken", severity = vim.diagnostic.severity.ERROR },
}, {})
local _, diag_hl, diag_bar = dropbar_text()
assert(diag_hl:find("DropBarContextErrorBadge", 1, true), diag_hl)
diag_bar.components[#diag_bar.components]:on_click(nil, 1, "l", "")
local qf = vim.fn.getqflist({ title = 0, items = 0 })
assert(qf.title == "Errors in current buffer", "diagnostic click must fill the quickfix list")
assert(#qf.items == 1, "diagnostic click must list the buffer error")

-- Plain text does not keep an empty context row.
open(lab .. "/README.md", "text")
vim.wo.winbar = "%{%v:lua.dropbar()%}"
require("config.dropbar").sync(0, 0)
assert(vim.wo.winbar == "", "text buffers must not keep a context winbar, ft=" .. vim.bo.filetype .. " bar=" .. vim.wo.winbar)

assert(require("dropbar.configs").opts.bar.render == nil, "must use official symbol API")
assert(package.loaded["dropbar.context"] == nil, "must not use fork modules")
assert(package.loaded["contextline"] == nil, "contextline must never load")

-- The native right-click handler creates its menu read-only before invoking
-- path_menu. Refreshing directory colours must temporarily unlock that buffer.
local path_menu = require("dropbar.menu").dropbar_menu_t:new({entries={}})
path_menu.buf = vim.api.nvim_create_buf(false, true)
path_menu.win_configs = {win=function() return vim.api.nvim_get_current_win() end}
path_menu._win_configs = {width=24}
path_menu.entries = {require("dropbar.menu").dropbar_menu_entry_t:new({components={
  require("dropbar.bar").dropbar_symbol_t:new({name=" ",icon="",data={path=lab}}),
  require("dropbar.bar").dropbar_symbol_t:new({name="context",data={path=lab}}),
}})}
require("dropbar.menu").dropbar_menu_t.fill_buf(path_menu)
vim.bo[path_menu.buf].modifiable = false
require("config.dropbar").path_menu(path_menu)
assert(vim.bo[path_menu.buf].modifiable == false, "path menu refresh must restore the original modifiable state")
assert(vim.api.nvim_buf_get_lines(path_menu.buf,0,1,false)[1]:find("context",1,true), "path menu refresh must redraw its labels")

print("context_bar_spec: OK")
