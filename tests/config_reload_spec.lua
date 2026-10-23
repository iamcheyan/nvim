local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h:h")
package.path = root .. "/lua/?.lua;" .. package.path
vim.g.mapleader = " "
local reload = require("config.reload")
local notifications = {}
vim.notify = function(message) notifications[#notifications + 1] = message end
reload.setup()
reload.setup()
assert(vim.fn.exists(":ConfigReload") == 2, "Reload command setup must be repeatable")

local phase = 1
local called
local external = function() called = "external" end
package.preload["config.keymaps-defaults"] = function()
  local map = reload.mapper("defaults")
  map("v", "<F9>", function() called = "visual" end)
  if phase == 1 then
    map("n", "<leader>zz", function() called = "old" end)
    map("n", "<leader>zx", function() called = "owned" end)
    map("n", "<leader>zt", '"same"', { expr = false })
  else
    map("n", "<leader>zy", function() called = "new" end)
  end
end
package.preload["config.keymaps"] = function()
  if phase == 3 then error("intentional invalid keymap setup") end
end
assert(reload.reload("keymaps"))
vim.fn.maparg("<leader>zz", "n", false, true).callback()
assert(called == "old")
vim.keymap.set("n", "<leader>zx", external)
vim.keymap.set("n", "<leader>zt", '"same"', { expr = true })
phase = 2
assert(reload.reload("keymaps"))
assert(vim.tbl_isempty(vim.fn.maparg("<leader>zz", "n", false, true)), "Removed configuration key must not remain live")
assert(vim.fn.maparg("<leader>zx", "n", false, true).callback == external, "Cleanup must preserve a later plugin override")
assert(vim.fn.maparg("<leader>zt", "n", false, true).expr == 1, "Same RHS with different mapping semantics must remain plugin-owned")
-- A buffer-local mapping must not hide the owned global map from cleanup.
local local_callback = function() end
vim.keymap.set("n", "<leader>zy", local_callback, { buffer = 0 })
assert(reload.reload("keymaps"))
assert(vim.fn.maparg("<leader>zy", "n", false, true).callback == local_callback)
vim.keymap.del("n", "<leader>zy", { buffer = 0 })
local previous = vim.fn.maparg("<leader>zy", "n", false, true).callback
local previous_visual = vim.fn.maparg("<F9>", "x", false, true).callback
local previous_select = vim.fn.maparg("<F9>", "s", false, true).callback
phase = 3
assert(not reload.reload("keymaps"), "Runtime errors must be reported")
assert(vim.fn.maparg("<leader>zy", "n", false, true).callback == previous, "Failed reload must restore the previous keymap callback")
assert(vim.fn.maparg("<F9>", "x", false, true).callback == previous_visual, "Visual mapping must survive failure rollback")
assert(vim.fn.maparg("<F9>", "s", false, true).callback == previous_select, "Select mapping must survive failure rollback")
assert(not reload.reload("plugins"), "Arbitrary plugin reload is intentionally unsupported")

-- A failure unrelated to keymaps must leave external overrides untouched.
package.preload["config.file_actions"] = function() error("intentional file action setup error") end
assert(not reload.reload("files"))
assert(vim.fn.maparg("<leader>zx", "n", false, true).callback == external)
package.preload["config.file_actions"] = nil

-- Partial statusline setup must restore the actual running object and callbacks.
local old_statusline = { old = true }
local old_redraw = function() end
local old_autocmd = function() end
local old_option = vim.o.statusline
package.loaded.heirline = { statusline = old_statusline }
package.loaded["config.bar_feedback"] = { on_redraw = old_redraw }
vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("HeirlineReloadTest", { clear = true }),
  callback = old_autocmd,
})
package.preload["plugins.heirline"] = function()
  return {{ opts = function() return {} end, config = function()
    package.loaded.heirline.statusline = { changed = true }
    package.loaded["config.bar_feedback"].on_redraw = function() end
    vim.o.statusline = "BROKEN"
    vim.api.nvim_create_augroup("HeirlineReloadTest", { clear = true })
    error("intentional partial statusline setup error")
  end }}
end
assert(not reload.reload("statusline"))
assert(package.loaded.heirline.statusline == old_statusline)
assert(package.loaded["config.bar_feedback"].on_redraw == old_redraw)
assert(vim.o.statusline == old_option)
assert(vim.api.nvim_get_autocmds({group="HeirlineReloadTest"})[1].callback == old_autocmd)

local prompt
vim.ui.select = function(items, opts, callback)
  prompt = opts.prompt
  assert(#items == 4 and items[1].target == "all")
  callback(nil)
end
vim.cmd("ConfigReload")
assert(prompt:find("restart", 1, true), "Menu must explain the reload scope")

local function noop() end
local mc = setmetatable({}, { __index = function() return noop end })
vim.keymap.set({ "n", "x" }, "<leader>N", noop, { desc = "Add cursor to previous match" })
require("config.multicursor_keymaps").apply(mc)
assert(vim.tbl_isempty(vim.fn.maparg("<leader>N", "x", false, true)), "Old visual-mode N must no longer retain the conflicting action")
assert(vim.fn.maparg("<leader>mn", "n", false, true).desc == "Add cursor to next match")
assert(vim.fn.maparg("<leader>mN", "x", false, true).desc == "Add cursor to previous match")
print("config_reload_spec: OK")
