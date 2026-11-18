local M = {}
local path = vim.fn.stdpath('state') .. '/editor-mode'
local valid = { daily = true, full = true }
local labels = { daily = 'Daily', full = 'Enhanced' }

local function saved()
  local ok, lines = pcall(vim.fn.readfile, path)
  local mode = ok and lines[1] or nil
  return valid[mode] and mode or 'full'
end

M.current = valid[vim.env.NVIM_MODE] and vim.env.NVIM_MODE or saved()

function M.toggle()
  local choice = saved() == 'daily' and 'full' or 'daily'
  vim.fn.mkdir(vim.fn.fnamemodify(path, ':h'), 'p')
  local ok, err = pcall(vim.fn.writefile, { choice }, path)
  if not ok or err ~= 0 then
    vim.notify('Could not save editor mode: ' .. tostring(err), vim.log.levels.ERROR)
    return
  end
  local message = 'Next mode: ' .. labels[choice] .. '. Restart Neovim to apply. Current mode: ' .. labels[M.current]
  if valid[vim.env.NVIM_MODE] then
    message = message .. '. NVIM_MODE overrides the saved selection; unset it to use the saved mode.'
  end
  vim.notify(message, vim.log.levels.INFO, { title = 'Editor Mode', timeout = 8000 })
end

function M.setup()
  vim.api.nvim_create_user_command('NvimMode', M.toggle, { force = true })
  vim.api.nvim_create_autocmd('VimEnter', {
    once = true,
    callback = function()
      vim.schedule(function()
        vim.notify('Current mode: ' .. labels[M.current], vim.log.levels.INFO, { title = 'Editor Mode', timeout = 5000 })
      end)
    end,
  })
end

return M
