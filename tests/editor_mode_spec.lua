-- Run with an empty XDG_STATE_HOME: nvim --headless -u NONE -l tests/editor_mode_spec.lua
local root = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':h:h')
vim.opt.rtp:prepend(root)
vim.env.NVIM_MODE = nil
local mode = require('config.mode')
assert(mode.current == 'full', 'fresh installations default to enhanced mode')
local notices = {}
vim.notify = function(message) notices[#notices + 1] = message end
mode.toggle()
assert(notices[1]:find('Daily', 1, true) and notices[1]:find('Restart', 1, true), 'selection must explain restart')
package.loaded['config.mode'] = nil
assert(require('config.mode').current == 'daily', 'selection persists across launches')
vim.env.NVIM_MODE = 'full'
package.loaded['config.mode'] = nil
assert(require('config.mode').current == 'full', 'environment override takes precedence')
vim.env.NVIM_MODE = nil
package.loaded['config.mode'] = nil
assert(require('config.mode').current == 'daily', 'override does not change saved mode')
print('editor mode: ok')

require('config.mode').toggle()
package.loaded['config.mode'] = nil
assert(require('config.mode').current == 'full', 'second toggle returns to enhanced mode')

local startup_autocmds = #vim.api.nvim_get_autocmds({ event = 'VimEnter' })
require('config.mode').setup()
assert(#vim.api.nvim_get_autocmds({ event = 'VimEnter' }) == startup_autocmds, 'setup must not announce the mode on startup')
assert(vim.fn.exists(':NvimMode') == 2, ':NvimMode must stay available after startup')
