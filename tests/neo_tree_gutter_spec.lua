-- Run: nvim --headless -u NONE -l tests/neo_tree_gutter_spec.lua
local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h:h")
vim.opt.rtp:prepend(root)
for _, name in ipairs({ "neo-tree.nvim", "plenary.nvim", "nui.nvim", "nvim-web-devicons" }) do
  vim.opt.rtp:prepend(vim.fn.stdpath("data") .. "/lazy/" .. name)
end
vim.cmd("colorscheme blue")
require("config.ui_highlights").apply()
require("neo-tree").setup(dofile(root .. "/lua/plugins/neo-tree.lua")[1].opts)
require("neo-tree.command").execute({ action = "show", source = "filesystem", reveal = false })
vim.wait(500)
local tree = require("neo-tree.sources.manager").get_state("filesystem")
assert(tree and tree.winid and vim.api.nvim_win_is_valid(tree.winid), "Neo-tree did not open")
vim.api.nvim_set_current_win(tree.winid)
vim.wait(1000)
assert(vim.fn.getwininfo(tree.winid)[1].textoff == 0, "Neo-tree rows must start at the sidebar edge without a gutter")

local win = vim.api.nvim_get_current_win()
assert(vim.bo.filetype == "neo-tree", "Neo-tree did not open")
assert(vim.wo[win].signcolumn == "no", "Neo-tree must not reserve a sign column")
assert(vim.wo[win].foldcolumn == "0", "Neo-tree must not reserve a fold column")

vim.cmd("qa!")
print("neo_tree_gutter_spec: OK")
