local root = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':h:h')
vim.opt.rtp:prepend(root)
vim.opt.rtp:prepend(vim.fn.stdpath('data') .. '/lazy/dropbar.nvim')
vim.opt.rtp:prepend(vim.fn.stdpath('data') .. '/site')
require('dropbar').setup({bar={enable=false}})
local context = {get_info=function()
  local buf, win = vim.api.nvim_get_current_buf(), vim.api.nvim_get_current_win()
  local symbols = require('config.dropbar').treesitter_symbols(buf, win, vim.api.nvim_win_get_cursor(win))
  return {segments=vim.tbl_map(function(symbol)
    return {text=symbol.data and symbol.data.text or symbol.name, icon=vim.trim(symbol.icon), label=symbol.data and symbol.data.label}
  end, symbols)}
end}

vim.cmd("enew")
vim.bo.filetype = "typescript"
vim.api.nvim_buf_set_lines(0, 0, -1, false, {
  "interface JobResult {",
  "  jobId: string;",
  "  status: string;",
  "}",
  "",
  "class NightJob {",
  "  validateInput(path: string): JobResult {",
  "    return { jobId: '1', status: 'OK' };",
  "  }",
  "}",
})

local ok = pcall(vim.treesitter.start, 0, "typescript")
if not ok then
  print("typescript_spec: SKIP (typescript parser is not installed)")
  return
end

-- Test 1: Interface and Property
vim.api.nvim_win_set_cursor(0, { 2, 4 }) -- cursor on `jobId: string;`
local info_prop = context.get_info({ bufnr = 0, winid = 0 })
assert(info_prop, "Dropbar should detect TS interface & property")
assert(#info_prop.segments == 2, "Expected 2 segments: Interface and Property, got " .. #info_prop.segments)
assert(info_prop.segments[1].text == "JobResult")
assert(info_prop.segments[1].icon == "󰠱", "Expected Interface icon 󰠱")
assert(info_prop.segments[2].text == "jobId")
assert(info_prop.segments[2].icon == "󰅪", "Expected Property icon 󰅪")

-- Test 2: Class and Method
vim.api.nvim_win_set_cursor(0, { 7, 6 }) -- cursor inside `validateInput`
local info_method = context.get_info({ bufnr = 0, winid = 0 })
assert(info_method, "Dropbar should detect TS class & method")
assert(#info_method.segments == 2, "Expected 2 segments: Class and Method")
assert(info_method.segments[1].text == "NightJob")
assert(info_method.segments[1].icon == "󰌗", "Expected Class icon 󰌗")
assert(info_method.segments[2].text == "validateInput")
assert(info_method.segments[2].icon == "󰆧", "Expected Method icon 󰆧")

print("typescript_spec: OK")
