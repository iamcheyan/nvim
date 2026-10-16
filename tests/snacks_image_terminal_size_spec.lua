-- Regression spec: Ensure Snacks image terminal size never returns 0 or NaN inside tmux/pty.
-- Run: nvim --headless -u NONE -l tests/snacks_image_terminal_size_spec.lua
local this_file = debug.getinfo(1, "S").source:sub(2)
local nvim_root = vim.fn.fnamemodify(this_file, ":h:h")
vim.opt.runtimepath:prepend(nvim_root)
package.path = nvim_root .. "/lua/?.lua;" .. nvim_root .. "/lua/?/init.lua;" .. package.path

local plugin_def = dofile(nvim_root .. "/lua/plugins/snacks.lua")[1]
assert(type(plugin_def.config) == "function", "snacks.lua should define a config function")

-- Run config with a dummy setup to test monkey patching
local fake_snacks = {
  setup = function() end,
}
package.loaded["snacks"] = fake_snacks
package.loaded["snacks.picker.source.proc"] = { proc = function() end }

local fake_term = {
  size = function()
    -- Simulate tmux pty where ioctl returns xpixel=0, ypixel=0
    return {
      width = 0,
      height = 0,
      columns = 80,
      rows = 24,
      cell_width = 0,
      cell_height = 0,
      scale = 1,
    }
  end,
}
package.loaded["snacks.image.terminal"] = fake_term

plugin_def.config(nil, {})

local patched_size = fake_term.size()
assert(patched_size.cell_width > 0, "cell_width must be greater than 0")
assert(patched_size.cell_height > 0, "cell_height must be greater than 0")
assert(patched_size.width > 0, "width must be greater than 0")
assert(patched_size.height > 0, "height must be greater than 0")
assert(patched_size.columns == vim.o.columns, "columns should match vim.o.columns")
assert(patched_size.rows == vim.o.lines, "rows should match vim.o.lines")

print("snacks_image_terminal_size_spec: OK")
