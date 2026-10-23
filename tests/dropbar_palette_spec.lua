-- Run through pcall(dofile, ...) with the real config; cquit on failure.
local root=vim.fn.fnamemodify(debug.getinfo(1,'S').source:sub(2),':h:h')
require('auto-session.config').enabled=false
vim.cmd('silent! only')
vim.cmd.edit(root..'/tests/fixtures/context/examples/python/night_report.py')
vim.wait(200)
local function check()
  for name, target in pairs({DropBarMenuNormalFloat='FreshMenu', DropBarMenuFloatBorder='FreshMenuBorder',
    DropBarMenuCurrentContext='FreshMenuSelected', DropBarMenuHoverEntry='FreshMenuSelected'}) do
    assert(vim.deep_equal(vim.api.nvim_get_hl(0,{name=name,link=false}),
      vim.api.nvim_get_hl(0,{name=target,link=false})), name .. ' must match unified UI')
  end
  for _,name in ipairs({'DropBarIconUISeparatorMenu','dropbarIconUIIndicator'}) do
    assert(vim.api.nvim_get_hl(0,{name=name,link=false}).bg==nil,
      name .. ' must stay transparent so selected menu rows have no dark notch')
  end
  local padding=require('dropbar.configs').opts.bar.padding
  assert(padding.left==1 and padding.right==1,'winbar needs one space on both sides')
  assert(require('dropbar.configs').opts.menu.entry.padding.right==1,'menu needs space between icon and text')
  assert(require('dropbar.configs').opts.icons.ui.menu.indicator=='','menu arrow must not contain trailing spacing')
  local winbar=vim.api.nvim_get_hl(0,{name='WinBar',link=false})
  local bar_fg=winbar.fg or vim.api.nvim_get_hl(0,{name='Normal',link=false}).fg
  for _,name in ipairs({'DropBarContextText','DropBarContextIcon','DropBarKindDir','DropBarKindFile',
    'DropBarIconUISeparator','DropBarIconUIIndicator'}) do
    assert(vim.api.nvim_get_hl(0,{name=name,link=false}).fg==bar_fg,
      name .. ' must follow the WinBar foreground')
  end
end
check()
vim.cmd.colorscheme('blue')
vim.wait(250)
check()

-- A dark WinBar must recolor the path breadcrumb instead of leaving the old
-- hard-coded black foreground.
vim.api.nvim_set_hl(0,'WinBar',{fg=0xf0f0f0,bg=0x101010})
vim.api.nvim_set_hl(0,'WinBarNC',{fg=0xd0d0d0,bg=0x101010})
require('config.dropbar').highlights()
for _,name in ipairs({'DropBarContextText','DropBarContextIcon','DropBarKindDir','DropBarKindFile',
  'DropBarIconUISeparator','DropBarIconUIIndicator'}) do
  assert(vim.api.nvim_get_hl(0,{name=name,link=false}).fg==0xf0f0f0,
    name .. ' must use the dark WinBar foreground')
end
for _,name in ipairs({'DropBarKindDirNC','DropBarKindFileNC','DropBarIconUISeparatorNC'}) do
  assert(vim.api.nvim_get_hl(0,{name=name,link=false}).fg==0xd0d0d0,
    name .. ' must use the dark WinBarNC foreground')
end
print('dropbar_palette_spec: OK')
vim.cmd.qa()
