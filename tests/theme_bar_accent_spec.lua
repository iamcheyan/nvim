-- Run: nvim --headless -u NONE -l tests/theme_bar_accent_spec.lua
local root = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':h:h')
vim.opt.rtp:prepend(root)
vim.cmd.colorscheme('blue')
local ui = require('config.ui_highlights')
local function hl(group)
  return vim.api.nvim_get_hl(0, { name = group, link = false })
end

local function check_document_chrome(theme)
  vim.cmd.colorscheme(theme)
  ui.apply()
  ui.apply()
  local normal = hl('Normal')
  local document_bg = normal.bg
  if theme == 'oceanblack256' then
    assert(normal.bg == 0, 'oceanblack256 document background should be pure black')
    if normal.ctermbg == 0 then document_bg = 0 end
  end

  for _, group in ipairs({
    'BufferLineBufferSelected', 'StatusLine', 'StatusLineNC',
    'TabLineSel', 'WinBar', 'WinBarNC', 'TitleBar',
  }) do
    local style = hl(group)
    assert(style.bg == document_bg, theme .. ' ' .. group .. ' should blend into the document background')
    assert(style.fg == normal.fg, theme .. ' ' .. group .. ' should use document text color')
  end

  local inactive_bg
  for _, group in ipairs({ 'BufferLineBuffer', 'BufferLineBufferVisible', 'TabLine', 'TabLineFill', 'TitleBarNC' }) do
    local style = hl(group)
    assert(style.bg ~= document_bg, theme .. ' ' .. group .. ' should distinguish inactive tabs')
    assert(style.fg ~= normal.fg, theme .. ' ' .. group .. ' should soften inactive text')
    inactive_bg = inactive_bg or style.bg
    assert(style.bg == inactive_bg, theme .. ' inactive tabs should share one background')
  end

  assert(hl('SatelliteBackground').bg == inactive_bg, theme .. ' scrollbar track should share the inactive surface')
  assert(hl('WinSeparator').fg == document_bg, theme .. ' split divider should disappear into the document')
end

for _, theme in ipairs({ 'high-contrast-plus', 'oceanblack', 'oceanblack256' }) do
  check_document_chrome(theme)
end

vim.cmd.colorscheme('blue')
ui.apply()
local blue_normal = hl('Normal')
assert(hl('BufferLineBufferSelected').bg == blue_normal.bg, 'Blue active tab should blend into the document')
assert(hl('StatusLine').bg == blue_normal.bg and hl('StatusLineNC').bg == blue_normal.bg, 'Blue status bars should blend into the document')
assert(hl('WinSeparator').fg == blue_normal.bg, 'Blue split divider should disappear into the document')
print('theme_bar_accent_spec: OK')
