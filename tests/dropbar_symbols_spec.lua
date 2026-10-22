-- nvim --headless -u NONE -l tests/dropbar_symbols_spec.lua
local root = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':h:h')
vim.opt.rtp:prepend(root)
vim.opt.rtp:prepend(vim.fn.stdpath('data') .. '/lazy/dropbar.nvim')
vim.opt.rtp:prepend(vim.fn.stdpath('data') .. '/site')
local source = require('config.dropbar')
require('dropbar').setup({bar={enable=source.should_attach, sources=source.sources, update_debounce=0}})
source.setup()
vim.api.nvim_buf_set_lines(0, 0, -1, false, {
  'class Report:', '    def first(self):', '        return 1',
  '    def second(self):', '        return 2',
})
vim.bo.filetype = 'python'
local buf, win = vim.api.nvim_get_current_buf(), vim.api.nvim_get_current_win()
for _ = 1, 3 do
  for _, row in ipairs({2, 4}) do
    vim.api.nvim_win_set_cursor(win, {row, 8})
    vim.api.nvim_exec_autocmds('CursorMoved', {buffer=buf})
    source.sync(buf, win)
    local bar = require('dropbar.utils.bar').get({buf=buf, win=win})
    assert(bar:cat(true):find('Report', 1, true), 'class must render after cursor refresh')
    assert(bar:cat(true):find(row == 2 and 'first' or 'second', 1, true), 'method must follow cursor')
  end
end
local symbols = source.treesitter_symbols(buf, win, {2, 8})
assert(type(symbols[1].cat) == 'function', 'source must return native dropbar symbols')
local children = symbols[1].children
assert(#children == 2 and children[1].name == 'first' and children[2].name == 'second')
assert(type(children[1].cat) == 'function' and type(children[1].on_click) == 'function')
local siblings = children[1].siblings
assert(#siblings == 2 and siblings[2].sibling_idx == 2)
assert(#symbols[2].siblings == 2 and symbols[2].siblings[2].name == 'second',
  'breadcrumb method menu must contain its peer methods')
assert(children[1]:merge({name='copy'}):cat(true):find('copy', 1, true))
children[1]:del()
vim.api.nvim_win_set_width(win, 12)
source.sync(buf, win)
print('dropbar_symbols_spec: OK')
