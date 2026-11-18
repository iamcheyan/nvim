-- Run: nvim --headless -u NONE -l tests/theme_bar_accent_spec.lua
local root = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':h:h')
vim.opt.rtp:prepend(root)
vim.cmd.colorscheme('blue')
local ui = require('config.ui_highlights')
local function check()
  ui.apply()
  ui.apply()
  local function bg(group) return vim.api.nvim_get_hl(0, { name = group, link = false }).bg end
  local accent = bg('ScrollbarHandle')
  assert(accent and bg('BufferLineBufferSelected') == accent, 'selected tab must match scrollbar')
  assert(bg('StatusLine') == accent and bg('StatusLineNC') == accent, 'status bars must match scrollbar')
end
check()
vim.cmd.colorscheme('high-contrast-plus')
check()
vim.cmd.colorscheme('blue')
check()
print('theme_bar_accent_spec: OK')
