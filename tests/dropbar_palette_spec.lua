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
  local padding=require('dropbar.configs').opts.bar.padding
  assert(padding.left==1 and padding.right==1,'winbar needs one space on both sides')
  assert(require('dropbar.configs').opts.menu.entry.padding.right==1,'menu needs space between icon and text')
  assert(require('dropbar.configs').opts.icons.ui.menu.indicator=='','menu arrow must not contain trailing spacing')
end
check()
vim.cmd.colorscheme('blue')
vim.wait(250)
check()
print('dropbar_palette_spec: OK')
vim.cmd.qa()
