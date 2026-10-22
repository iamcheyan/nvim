-- Run with the real configuration using pcall(dofile, ...) and cquit on failure.
local root = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':h:h')
local fixtures = root .. '/tests/fixtures/context/'
require('auto-session.config').enabled=false
vim.cmd('silent! only')
local failures = {}
local function check(ok, message)
  if not ok then failures[#failures+1]=message; print('FAIL: '..message) end
end
local function rendered()
  vim.cmd.redraw()
  vim.wait(100)
  return vim.api.nvim_eval_statusline(vim.wo.winbar,{winid=0,use_winbar=true}).str
end
vim.cmd.edit(fixtures .. 'README.md')
vim.bo.filetype='text'
local win = vim.api.nvim_get_current_win()
local picker = {main=win}
local opts = require('snacks').config.picker
opts.on_show(picker)
require('config.dropbar').sync(0,0)
check(vim.wo[win].winbar=='', 'picker suspension must prevent reattaching the topbar')
vim.cmd.edit(fixtures .. 'examples/python/night_report.py')
vim.api.nvim_win_set_cursor(win,{4,10})
opts.on_close(picker)
check(rendered():find('NightReport',1,true), 'picker restored a stale empty winbar over Python')

-- Parser installation/registration may finish after FileType. A cursor event
-- must be sufficient to recover a supported buffer without leaving it.
vim.cmd.enew()
vim.api.nvim_buf_set_lines(0,0,-1,false,{'class Delayed:', '    def run(self):', '        return 1'})
local buf = vim.api.nvim_get_current_buf()
local original = vim.treesitter.get_parser
vim.treesitter.get_parser = function(b,...)
  if b == buf or b == 0 or b == nil then return nil end
  return original(b,...)
end
vim.bo.filetype='python'
check(rendered():find('%S'), 'Python vanished while its parser was unavailable')
vim.treesitter.get_parser = original
vim.api.nvim_win_set_cursor(win,{2,8})
vim.api.nvim_exec_autocmds('CursorMoved',{buffer=buf})
check(rendered():find('Delayed',1,true), 'Python did not reattach when its parser became available')
vim.bo.modified=false

vim.cmd.enew()
vim.api.nvim_buf_set_lines(0,0,-1,false,{'      * Comment before the first division.',
  '       IDENTIFICATION DIVISION.', '       PROGRAM-ID. ROOT-TEST.',
  '       PROCEDURE DIVISION.', '           STOP RUN.', ''})
vim.bo.filetype='cobol'
vim.api.nvim_win_set_cursor(0,{1,0})
local text = rendered()
check(text:find('%S'), 'COBOL disappears before its first division')
vim.api.nvim_win_set_cursor(0,{5,12})
vim.api.nvim_exec_autocmds('CursorMoved',{buffer=0})
text=rendered()
check(text:match('^ %S'), 'COBOL needs one cell of padding, not the line-number gutter')
check(text:find('󰌗',1,true) or text:find('󰏗',1,true), 'COBOL has no structure icon')
vim.bo.modified=false
assert(#failures==0,table.concat(failures,'\n'))
print('dropbar_lifecycle_spec: OK')
vim.cmd.qa()
