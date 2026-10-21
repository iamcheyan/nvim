-- vim-visual-multi
--
-- Keeps the plugin's own defaults. Only one mapping is added on top:
--   Ctrl+n        -> Find Under          (default: select next occurrence)
--   Ctrl+Shift+n  -> Select All          (added below: select all occurrences)
--
-- The addition goes through the supported `g:VM_maps` dictionary instead of
-- hand-written keymaps. vim-visual-multi reads that dict while building its
-- mappings and only replaces the named entries, so every other VM mapping
-- (including the default <C-n> used by Find Under) is left untouched.
return {
  {
    "mg979/vim-visual-multi",
    branch = "master",
    init = function()
      -- Merge into an existing g:VM_maps if something else already set one,
      -- rather than replacing the whole dictionary and dropping other keys.
      local maps = vim.g.VM_maps or {}
      maps["Select All"] = "<C-S-n>"
      vim.g.VM_maps = maps
    end,
  },
}
