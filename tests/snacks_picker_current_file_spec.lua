-- Regression spec: In file pickers (<leader><space> / Snacks.picker.files),
-- all open buffers are placed at the top, with the currently active file ([current])
-- and other open buffers ([open]) distinguished with high-contrast badges.
-- Run: nvim --headless -u init.lua -c "lua dofile('tests/snacks_picker_current_file_spec.lua')"

local this_file = debug.getinfo(1, "S").source:sub(2)
local nvim_root = vim.fn.fnamemodify(this_file, ":h:h")
vim.opt.runtimepath:prepend(nvim_root)
package.path = nvim_root .. "/lua/?.lua;" .. nvim_root .. "/lua/?/init.lua;" .. package.path
vim.cmd("filetype plugin indent on")

-- Open two buffers: options.lua (background open) and lsp.lua (current active)
local path_options = vim.fs.normalize(nvim_root .. "/lua/config/options.lua")
local path_lsp = vim.fs.normalize(nvim_root .. "/lua/plugins/lsp.lua")

vim.cmd("edit " .. path_options)
vim.cmd("edit " .. path_lsp)
-- Active buffer is lsp.lua

Snacks.picker.pick("files")

vim.defer_fn(function()
  local pickers = Snacks.picker.get({ source = "files" })
  assert(#pickers > 0, "Snacks files picker must be opened")
  local p = pickers[1]

  local first = p.list:get(1)
  assert(first ~= nil, "First item must exist")
  assert(first.file == "lua/plugins/lsp.lua", "Currently active file must be at the very top (index 1), got: " .. tostring(first.file))
  assert(first.is_current == true, "First item must have is_current flag set")
  assert(first.filename_hl == "SnacksPickerCurrentFile", "First item must have filename_hl set")

  local first_text = p.list:format(first)
  assert(first_text:find("%[current%]"), "First item must contain [current] badge, got: " .. first_text)

  local second = p.list:get(2)
  assert(second ~= nil, "Second item must exist")
  assert(second.file == "lua/config/options.lua", "Second item must be the other open buffer, got: " .. tostring(second.file))
  assert(second.is_open == true, "Second item must have is_open flag set")

  local second_text = p.list:format(second)
  assert(second_text:find("%[open%]"), "Second item must contain [open] badge, got: " .. second_text)

  -- Check highlight definitions
  local current_badge_hl = vim.api.nvim_get_hl(0, { name = "SnacksPickerCurrentBadge", link = false })
  assert(current_badge_hl.bg ~= nil, "SnacksPickerCurrentBadge must have a background color")
  assert(current_badge_hl.fg ~= nil, "SnacksPickerCurrentBadge must have a foreground color")

  local open_badge_hl = vim.api.nvim_get_hl(0, { name = "SnacksPickerOpenBadge", link = false })
  assert(open_badge_hl.bg ~= nil, "SnacksPickerOpenBadge must have a background color")
  assert(open_badge_hl.fg ~= nil, "SnacksPickerOpenBadge must have a foreground color")

  print("snacks_picker_current_file_spec: OK")
  vim.cmd("qa!")
end, 300)
