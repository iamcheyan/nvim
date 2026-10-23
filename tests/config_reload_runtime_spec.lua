-- Run with: nvim --headless -u ./init.lua -l tests/config_reload_runtime_spec.lua
local reload = require('config.reload')
local original_notify = vim.notify
vim.notify = function() end
assert(reload.reload('statusline'))
local heirline = require('heirline')
local original = heirline.statusline
local original_feedback = require('config.bar_feedback').on_redraw
local original_opts = require('plugins.heirline')[1]
local original_maps = vim.api.nvim_get_autocmds({group='HeirlineReloadOnColorscheme'})
package.preload['plugins.heirline'] = function()
  return {{ opts = original_opts.opts, config = function(_, opts)
    original_opts.config(nil, opts)
    error('intentional failure after actual heirline setup')
  end }}
end
assert(not reload.reload('statusline'))
assert(heirline.statusline == original)
assert(require('config.bar_feedback').on_redraw == original_feedback)
local maps = vim.api.nvim_get_autocmds({group='HeirlineReloadOnColorscheme'})
assert(#maps == #original_maps and maps[1].callback == original_maps[1].callback)
local ok, text = pcall(heirline.eval_statusline)
assert(ok, text)
assert(type(text) == 'string' and #text > 0)
package.preload['plugins.heirline'] = nil
-- Use the real defaults module (including v-mode Alt-j/k) and fail only
-- when the subsequent personal keymap file would be loaded.
local old_visual = vim.fn.maparg('<A-j>', 'x', false, true)
local old_select = vim.fn.maparg('<A-j>', 's', false, true)
local old_new = vim.fn.maparg('<leader>N', 'n', false, true).callback
package.preload['config.keymaps'] = function() error('intentional failure after actual defaults reload') end
local handled, success = pcall(reload.reload, 'keymaps')
assert(handled and not success)
assert(vim.api.nvim_replace_termcodes(vim.fn.maparg('<A-j>', 'x', false, true).rhs,true,true,true) == vim.api.nvim_replace_termcodes(old_visual.rhs,true,true,true))
assert(vim.api.nvim_replace_termcodes(vim.fn.maparg('<A-j>', 's', false, true).rhs,true,true,true) == vim.api.nvim_replace_termcodes(old_select.rhs,true,true,true))
assert(vim.fn.maparg('<leader>N', 'n', false, true).callback == old_new)
package.preload['config.keymaps'] = nil
vim.notify = original_notify
print('config_reload_runtime_spec: OK')
vim.cmd('qa!')
