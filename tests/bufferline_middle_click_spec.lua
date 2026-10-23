local this_file = debug.getinfo(1, "S").source:sub(2)
local nvim_root = vim.fn.fnamemodify(this_file, ":h:h")
vim.opt.runtimepath:prepend(nvim_root)
package.path = nvim_root .. "/lua/?.lua;" .. nvim_root .. "/lua/?/init.lua;" .. package.path

local spec = dofile(nvim_root .. "/lua/plugins/bufferline.lua")[1]
local options = spec.opts().options
assert(options.middle_mouse_command == options.close_command,
  "middle-clicking a buffer tab should close that buffer using BufferLine's configured close command")
assert(options.mode == "buffers" and options.show_tab_indicators,
  "the global file strip must expose separate native tab-page indicators")
local previous = package.loaded["config.file_actions"]
local closed = {}
package.loaded["config.file_actions"] = { close = function(buf) closed[#closed + 1] = buf end }
options.close_command(41)
options.middle_mouse_command(42)
assert(closed[1] == 41 and closed[2] == 42,
  "existing file tabs must resolve the newly reloaded file actions for both close buttons")
package.loaded["config.file_actions"] = previous
print("bufferline_middle_click_spec: OK")
