local this_file = debug.getinfo(1, "S").source:sub(2)
local nvim_root = vim.fn.fnamemodify(this_file, ":h:h")
vim.opt.runtimepath:prepend(nvim_root)
package.path = nvim_root .. "/lua/?.lua;" .. nvim_root .. "/lua/?/init.lua;" .. package.path

local scroll = require("config.scrollbar_scroll")
scroll.setup()

local buf = vim.api.nvim_create_buf(false, true)
local lines = {}
for i = 1, 300 do
  lines[#lines + 1] = "Line " .. i
end
vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
local win = vim.api.nvim_get_current_win()
vim.api.nvim_win_set_buf(win, buf)

-- 1. Test scroll down
vim.api.nvim_win_set_cursor(win, { 1, 0 })
local w0_before = vim.fn.line("w0")
vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<ScrollWheelDown>", true, false, true), "tx", false)
local w0_after = vim.fn.line("w0")
assert(w0_after > w0_before, "ScrollWheelDown must advance the visible top line")

-- 2. Test scroll up stops at line 1 without buffer switch
for _ = 1, 10 do
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<ScrollWheelUp>", true, false, true), "tx", false)
end
assert(vim.fn.line("w0") == 1, "ScrollWheelUp past the top must stop cleanly at line 1")
assert(vim.api.nvim_get_current_buf() == buf, "ScrollWheelUp must never cycle or switch buffers")

print("scrollbar_scroll_spec: OK")
