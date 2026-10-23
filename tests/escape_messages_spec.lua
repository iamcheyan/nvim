local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h:h")
dofile(root .. "/lua/config/keymaps-defaults.lua")
local escape = vim.fn.maparg("<Esc>", "n", false, true).callback
local dismissed = 0
package.loaded.noice = { cmd = function(command)
  assert(command == "dismiss")
  dismissed = dismissed + 1
end }
vim.o.hlsearch = true
vim.v.hlsearch = 1
assert(escape() == "<esc>", "Escape must retain its native mode exit")
vim.wait(100, function() return dismissed > 0 end)
assert(dismissed == 1, "Escape must dismiss the bottom Noice message covering the statusline")
assert(vim.v.hlsearch == 0, "Escape must still clear search highlighting")
package.loaded.noice = nil
assert(escape() == "<esc>", "Escape must work before Noice is loaded")
vim.wait(20)
print("escape_messages_spec: OK")
local search_next = vim.fn.maparg("n", "n", false, true).callback
local search_previous = vim.fn.maparg("N", "n", false, true).callback
vim.api.nvim_buf_set_lines(0, 0, -1, false, { "alpha", "beta" })
vim.fn.setreg("/", "missing-pattern")
for _, ahead in ipairs({ 0, 1 }) do
  vim.v.searchforward = ahead
  local ok, err = pcall(search_next)
  assert(ok, "n mapping should ignore absent search results: " .. tostring(err))
  ok, err = pcall(search_previous)
  assert(ok, "N mapping should ignore absent search results: " .. tostring(err))
end
print("search mappings tolerate absent matches: OK")
