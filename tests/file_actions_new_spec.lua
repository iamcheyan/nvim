local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h:h")
vim.opt.runtimepath:prepend(root)
local actions = require("config.file_actions")
local cwd = vim.fn.getcwd()
local dir = vim.fn.tempname() .. " file actions"
vim.fn.mkdir(dir, "p")
vim.cmd.cd({ args = { dir } })
local function path(name) return dir .. "/" .. name end
local function current_name() return vim.api.nvim_buf_get_name(0) end
local function tabs() return #vim.api.nvim_list_tabpages() end

vim.fn.writefile({ "existing disk file" }, path("new-file.txt"))
local initial_tabs = tabs()
actions.new_file(true)
assert(tabs() == initial_tabs + 1 and #vim.api.nvim_tabpage_list_wins(0) == 1,
  "default creation must open one new tab page, not split the editor")
assert(current_name() == path("new-file-2.txt"), "default filename must not reuse a disk file")
assert(vim.fn.filereadable(current_name()) == 0, "new file stays an unsaved named buffer until written")
local second_buf = vim.api.nvim_get_current_buf()
local second_tab = vim.api.nvim_get_current_tabpage()
actions.new_file(true)
assert(current_name() == path("new-file-3.txt"), "default filename must not reuse an unsaved named buffer")

local pending, suggested
vim.ui.input = function(opts, callback)
  suggested, pending = opts.default, callback
end
local before_cancel = tabs()
actions.new_file()
assert(suggested == "new-file-4.txt", "prompt should offer the next available default filename")
pending(nil)
assert(tabs() == before_cancel, "cancelling the prompt must not create a tab")
actions.new_file()
pending("  ")
assert(current_name() == path("new-file-4.txt"), "empty input should accept an available English filename")

actions.new_file()
vim.fn.writefile({ "claimed during prompt" }, path(suggested))
pending(suggested)
assert(current_name() == path("new-file-6.txt"), "accepting a stale default must recheck collisions")

actions.new_file()
pending("nested/space name.txt")
assert(current_name() == path("nested/space name.txt"), "explicit paths with spaces must survive command parsing")
assert(vim.fn.isdirectory(path("nested")) == 1, "new explicit path should create its parent directory")

-- The global file strip must return to an already-open layout instead of
-- replacing the file in the current tab with another copy.
local before_focus = tabs()
assert(actions.open_buffer(second_buf), "an existing buffer can be selected")
assert(vim.api.nvim_get_current_tabpage() == second_tab and vim.api.nvim_get_current_buf() == second_buf,
  "selecting an already-visible buffer should focus its existing tab/window")
assert(tabs() == before_focus, "buffer selection must not create additional tab pages")
vim.cmd.vsplit()
local same_tab_win = vim.api.nvim_get_current_win()
actions.open_buffer(second_buf)
assert(vim.api.nvim_get_current_win() == same_tab_win,
  "clicking the current file should preserve its focused window")
local hidden = vim.api.nvim_create_buf(true, false)
local routed
package.loaded["config.sidebar_tabs"] = { open_buffer = function(buf) routed = buf end }
assert(actions.open_buffer(hidden) and routed == hidden, "hidden buffers should use the existing sidebar-aware router")

vim.cmd("tabonly!")
local before_new, before_windows = tabs(), #vim.api.nvim_tabpage_list_wins(0)
vim.cmd.new()
assert(tabs() == before_new and #vim.api.nvim_tabpage_list_wins(0) == before_windows + 1,
  "native :new should keep its standard split behavior")
vim.cmd.cd({ args = { cwd } })
vim.fn.delete(dir, "rf")
print("file_actions_new_spec: OK")
