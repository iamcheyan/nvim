local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h:h")
vim.opt.runtimepath:prepend(root)

local source = vim.api.nvim_get_current_win()
vim.bo.tabstop = 4
vim.api.nvim_buf_set_lines(0, 0, -1, false, { "a\t中x", "second line" })
vim.api.nvim_win_set_cursor(source, { 1, 2 })
local menu = require("config.statusline.menu")
local opened
local original_open = menu.open
menu.open = function(id, items, click_name)
  opened = { id = id, items = items, click_name = click_name }
end
local position = require("config.statusline.position").new({ text = 0xffffff })
assert(position.provider() == "L1C6P3", "display columns and byte positions must differ for tabs/CJK")
position.on_click.callback({}, 0, 1, "r")
assert(opened == nil, "right click must leave the position menu closed")
position.on_click.callback({}, 0, 1, "l")
assert(opened.id == "position" and opened.click_name == "heirline_position_menu")
local function action(label)
  for _, item in ipairs(opened.items) do
    if item.label == label then return assert(item.action) end
  end
  error("missing position action: " .. label)
end
local original_input = vim.ui.input
vim.ui.input = function(_, done) done("2") end
action("Go to line…")()
assert(vim.api.nvim_win_get_cursor(source)[1] == 2, "line navigation must use the editor window")
vim.api.nvim_win_set_cursor(source, { 1, 0 })
vim.ui.input = function(_, done) done("5") end
action("Go to column…")()
assert(vim.api.nvim_win_get_cursor(source)[2] == 2, "column navigation must account for tabs and double-width text")
vim.ui.input = function(_, done) done(nil) end
local before = vim.api.nvim_win_get_cursor(source)
action("Go to column…")()
assert(vim.deep_equal(before, vim.api.nvim_win_get_cursor(source)), "cancel must preserve the cursor")
vim.ui.input = original_input
menu.open = original_open
print("statusline_position_spec: OK")
