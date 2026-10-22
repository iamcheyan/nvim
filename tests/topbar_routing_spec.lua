-- Run with the real configuration through pcall(dofile, ...).
require('auto-session.config').enabled = false
local win = vim.api.nvim_get_current_win()
local temp = vim.fn.tempname()
vim.fn.mkdir(temp, 'p')
for _, name in ipairs({'Makefile', 'unknown.xyzabc', 'sample.txt', 'sample.TXT',
  'sample.csv', 'sample.CSV', 'sample.tsv', 'sample.TSV', 'sample.DAT', 'sample.LST', 'sample.CTL', 'main.lua', 'Makefile'}) do
  vim.cmd.edit(vim.fn.fnameescape(temp .. '/' .. name))
  vim.cmd('filetype detect')
  vim.api.nvim_exec_autocmds('BufEnter', {buffer=0})
  vim.wait(100)
  local ext = name:match('%.([^.]*)$')
  local data = ext and vim.tbl_contains({'txt','csv','tsv','dat','lst','ctl'}, ext:lower())
  local bar = vim.wo[win].winbar
  assert(bar:find(data and 'position-ruler' or 'dropbar', 1, true), name .. ': wrong topbar: ' .. bar)
  local rendered = vim.api.nvim_eval_statusline(bar, {winid=win,use_winbar=true}).str
  assert(rendered:find('%S'), name .. ': empty topbar')
  if not data then assert(rendered:find(name, 1, true), name .. ': missing filename: ' .. rendered) end
end
vim.fn.delete(temp, 'rf')
print('topbar_routing_spec: OK')
