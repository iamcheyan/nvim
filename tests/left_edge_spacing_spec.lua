local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h:h")
local lazy = vim.fn.stdpath("data") .. "/lazy/"
for _, plugin in ipairs({ "noice.nvim", "nui.nvim", "heirline.nvim" }) do
  vim.opt.runtimepath:prepend(lazy .. plugin)
end
local opts = dofile(root .. "/lua/plugins/noice.lua")[1].opts
require("noice.config").setup(opts)
local cmdline = require("noice.ui.cmdline")
cmdline.on_show("cmdline_show", { { 0, "BufferLineCloseLeft" } }, 18, ":", "", 0, 1)
local message = require("noice.message")("cmdline", nil)
cmdline.active:format(message, true)
assert(message:content():sub(1, 1) == ":", "command prompt must start in the first column without icon spacing")
local statusline = dofile(root .. "/lua/plugins/heirline.lua")[1].opts().statusline
vim.api.nvim_set_hl(0, "StatusLine", { bg = "#00aaaa", fg = "#000000" })
vim.api.nvim_set_hl(0, "FreshStatusLineGit", { bg = "#ffff55", fg = "#000000" })
require("heirline").setup({ statusline = statusline })
local rendered = vim.api.nvim_eval_statusline(require("heirline").eval_statusline(), { highlights = true })
local git_hl = vim.api.nvim_get_hl(0, { name = rendered.highlights[1].group, link = false })
assert(git_hl.bg == 0xffff55,
  "Git's yellow background must start at the first column, including its padding")
print("left_edge_spacing_spec: OK")
