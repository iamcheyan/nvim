local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h:h")
vim.opt.runtimepath:prepend(root)
vim.o.lines = 30
vim.o.columns = 100
vim.o.mousemoveevent = false
local buf = vim.api.nvim_get_current_buf()
local original = function() end
vim.keymap.set("n", "j", original, { buffer = buf, desc = "Original cursor mapping" })
local redraws = 0
package.loaded["config.bar_feedback"] = { on_redraw = function() redraws = redraws + 1 end }
local menu = require("config.statusline.menu")
menu.open("lifecycle", { { label = "Action", action = function() end } })
local close = assert(_G._statusline_menu_close)
assert(vim.o.mousemoveevent, "opening a menu must enable hover")
close()
close()
menu.close()
assert(redraws == 1, "WinClosed reentry/repeated close must clean up only once")
assert(_G._statusline_menu_win == nil and _G._statusline_menu_source_maps == nil)
assert(not vim.o.mousemoveevent, "closing must restore mousemoveevent")
local mapping = vim.fn.maparg("j", "n", false, true)
assert(mapping.callback == original and mapping.desc == "Original cursor mapping", "closing must restore the exact buffer mapping")
print("statusline_menu_lifecycle_spec: OK")
