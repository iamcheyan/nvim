-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- Keep LazyVim default startup behavior:
-- restore session when available; otherwise show dashboard.

-- Closing the last named file leaves Neovim on its unnamed replacement buffer.
-- :enew / <leader>fn does not delete a named buffer, so a scratch buffer stays.
local dashboard_after_file_delete = false
local dashboard_group = vim.api.nvim_create_augroup("DashboardOnLastFile", { clear = true })
vim.api.nvim_create_autocmd("BufDelete", {
  group = dashboard_group,
  callback = function(args)
    local buf = args.buf
    if vim.bo[buf].buftype == "" and vim.api.nvim_buf_get_name(buf) ~= "" then
      dashboard_after_file_delete = true
    end
  end,
})
vim.api.nvim_create_autocmd("BufEnter", {
  group = dashboard_group,
  callback = function(args)
    vim.schedule(function()
      if not dashboard_after_file_delete then return end
      dashboard_after_file_delete = false
      if not vim.api.nvim_buf_is_valid(args.buf) or vim.api.nvim_get_current_buf() ~= args.buf then
        return
      end
      if vim.bo[args.buf].buftype ~= "" or vim.bo[args.buf].filetype == "dashboard" then
        return
      end
      if vim.bo[args.buf].modified or vim.api.nvim_buf_get_name(args.buf) ~= "" then
        return
      end
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if buf ~= args.buf and vim.api.nvim_buf_is_loaded(buf)
          and vim.bo[buf].buftype == "" and vim.api.nvim_buf_get_name(buf) ~= "" then
          return
        end
      end
      pcall(vim.cmd, "Dashboard")
    end)
  end,
})

local function set_cmdline_highlights()
  local normal = vim.api.nvim_get_hl(0, { name = "Normal", link = false })
  local bg, fg = normal.bg, normal.fg

  vim.api.nvim_set_hl(0, "MsgArea", { bg = bg, fg = fg })
  vim.api.nvim_set_hl(0, "Cmdline", { bg = bg, fg = fg })
  vim.api.nvim_set_hl(0, "CmdLine", { bg = bg, fg = fg })
  vim.api.nvim_set_hl(0, "CmdLinePrompt", { bg = bg, fg = fg })
  -- WinSeparator and VertSplit stay theme-owned.  Overriding either field
  -- here would erase the active theme's UI surface semantics.
end

vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("CmdlineHighlights", { clear = true }),
  callback = set_cmdline_highlights,
})

set_cmdline_highlights()

-- swapfile is off for new buffers. An old swap whose process is gone can be
-- edited. A live process still gets Neovim's prompt.
vim.api.nvim_create_autocmd("SwapExists", {
  group = vim.api.nvim_create_augroup("HandleSwapExists", { clear = true }),
  callback = function()
    local info = vim.fn.swapinfo(vim.v.swapname)
    local pid = info and info.pid or 0
    if type(pid) == "number" and pid > 0 then
      vim.fn.system({ "ps", "-p", tostring(pid) })
      if vim.v.shell_error == 0 then
        return
      end
    end
    vim.v.swapchoice = "e"
  end,
})
