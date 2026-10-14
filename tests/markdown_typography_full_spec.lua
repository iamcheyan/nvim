local root = vim.fn.getcwd()
package.path = root .. "/lua/?.lua;" .. root .. "/lua/?/init.lua;" .. package.path
local plugin_root = vim.fn.stdpath("data") .. "/lazy/markview.nvim"
if vim.fn.isdirectory(plugin_root) == 1 then
  vim.opt.rtp:append(plugin_root)
end
local spec = dofile(root .. "/lua/plugins/markview.lua")[1]
require("markview").setup(spec.opts)

local config = vim.fn.stdpath("config")
dofile(config .. "/init.lua")
vim.wait(5000, function()
  return vim.g.colors_name ~= nil and #vim.api.nvim_get_autocmds({ group = "MarkdownTypographyBlue" }) > 0
end, 50)
assert(vim.g.colors_name == "blue", "the current config is expected to use Blue")
local blue_normal = vim.api.nvim_get_hl(0, { name = "Normal", link = false })
local markdown = vim.api.nvim_create_buf(true, false)
vim.api.nvim_buf_set_name(markdown, "/tmp/typography-markview-smoke.md")
vim.api.nvim_buf_set_lines(markdown, 0, -1, false, {
  "# COBOL",
  "",
  "## REDEFINES",
  "",
  "> 同じメモリを別の形式で参照します",
  "",
  "`MOVE`",
  "",
  "- item1",
  "- [x] item2",
  "",
  "| A | B |",
  "|---|---|",
  "| one | two |",
})
vim.api.nvim_win_set_buf(0, markdown)
vim.cmd("setfiletype markdown")
vim.wait(2000, function()
  return package.loaded["markview"] ~= nil
end, 50)
assert(package.loaded["markview"] ~= nil, "existing Markview should load for Markdown")
local ns = vim.api.nvim_get_hl_ns({ winid = 0 })
assert(ns ~= -1, "Markdown opens with its local namespace")
local md_normal = vim.api.nvim_get_hl(ns, { name = "MdTypographyNormal", link = false })
assert(md_normal.bg == 0xffffff and md_normal.fg == 0x000000)
assert(vim.wo.winhighlight:find("MdTypographyNormal", 1, true))
local parser_ok = pcall(vim.treesitter.get_parser, markdown, "markdown")
assert(parser_ok, "Markdown Treesitter parser is available")
assert(vim.api.nvim_get_hl(0, { name = "@markup.heading.1", link = false }).fg == 0xcd00cd)
print("markdown_typography_full_config: OK (Blue, Markview, Treesitter, local warm-paper window)")
vim.cmd("qa!")