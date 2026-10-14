local file = vim.fn.stdpath("config") .. "/init.lua"
dofile(file)
vim.wait(3000, function()
  return vim.g.colors_name == "blue"
end, 50)
assert(vim.g.colors_name == "blue", "must retain active Blue theme")
local markdown = vim.api.nvim_create_buf(true, false)
vim.api.nvim_buf_set_name(markdown, "/tmp/runtime-doc.md")
vim.api.nvim_buf_set_lines(markdown, 0, -1, false, {
  "# COBOL",
  "",
  "本文段落",
  "",
  "> 引用",
  "",
  "`MOVE`",
  "",
  "- 项目",
  "",
  "```cobol",
  "DISPLAY 'dark code block'",
  "```",
})
vim.api.nvim_win_set_buf(0, markdown)
vim.api.nvim_exec_autocmds("BufReadPost", { buffer = markdown, modeline = false })
vim.bo[markdown].filetype = "markdown"
vim.api.nvim_exec_autocmds("FileType", { buffer = markdown, modeline = false })
vim.wait(300, function()
  return vim.wo.winhighlight:find("MdTypographyNormal", 1, true) ~= nil
end, 10)
local ns = vim.api.nvim_get_hl_ns({ winid = 0 })
local normal = vim.api.nvim_get_hl(ns, { name = "MdTypographyNormal", link = false })
assert(normal.bg == 0xfaf9f5, string.format("expected #faf9f5, got #%06x", normal.bg or 0))
assert(normal.fg == 0x303030)
assert(vim.wo.winhighlight:find("Normal:MdTypographyNormal", 1, true))
assert(vim.api.nvim_get_hl(0, { name = "Normal", link = false }).bg == 0x000087)
local code = vim.api.nvim_get_hl(ns, { name = "MarkviewCode", link = false })
assert(code.bg == 0x202536)
print(string.format("PASS: colorscheme=%s, filetype=%s, Markdown bg=#%06x, foreground=#%06x, code block=#%06x", vim.g.colors_name, vim.bo[markdown].filetype, normal.bg, normal.fg, code.bg))
vim.cmd("qa!")