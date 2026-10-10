package.path = './lua/?.lua;' .. package.path
local actions = require('config.file_actions')
local removed = {}
package.loaded.snacks = { bufdelete = function(opts)
  removed[#removed + 1] = opts.buf
  vim.api.nvim_buf_delete(opts.buf, { force = true })
end }
local choice = 3
vim.fn.confirm = function() return choice end
local function buffer()
  local buf = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { 'unsaved content' })
  return buf
end

local first, second = buffer(), buffer()
actions.close_many({ first, second })
assert(#removed == 0 and vim.bo[first].modified, 'Cancel must preserve edits and stop batch close')

choice = 1
vim.ui.input = function(_, callback) callback(nil) end
actions.close(first)
assert(#removed == 0, 'Cancelling Save As must keep the buffer')

local readonly = buffer()
vim.api.nvim_buf_set_name(readonly, vim.fn.tempname())
vim.bo[readonly].readonly = true
local notify = vim.notify
vim.notify = function() end
actions.close(readonly)
vim.notify = notify
assert(#removed == 0 and vim.bo[readonly].modified, 'A failed save must never discard edits')
vim.api.nvim_buf_delete(readonly, { force = true })

local path = vim.fn.tempname() .. '/nested/new.txt'
vim.ui.input = function(_, callback) callback(path) end
actions.close(first)
assert(removed[1] == first, 'Close only after successful save')
assert(vim.fn.readfile(path)[1] == 'unsaved content', 'Save As must preserve buffer contents')
vim.fn.delete(vim.fn.fnamemodify(path, ':h:h'), 'rf')

choice = 2
actions.close(second)
assert(removed[2] == second, 'Discard must close the selected buffer')
print('file_actions_spec: OK')
