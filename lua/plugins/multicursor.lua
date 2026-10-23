return {
  "jake-stewart/multicursor.nvim",
  branch = "1.0",
  -- Load at startup instead of on first keypress. lazy.nvim replays a lazy
  -- `keys` entry by feeding the raw lhs back into the typeahead; for a
  -- modified key like <C-S-n> that replay is unreliable, which made the first
  -- Ctrl+Shift+n do nothing. Loading eagerly means the mappings defined in
  -- config() already exist when the key is pressed.
  lazy = false,
  config = function()
    local mc = require("multicursor-nvim")
    mc.setup()

    require("config.multicursor_keymaps").apply(mc)

    mc.addKeymapLayer(function(layer_set)
      layer_set({ "n", "x" }, "<left>", mc.prevCursor)
      layer_set({ "n", "x" }, "<right>", mc.nextCursor)
      layer_set({ "n", "x" }, "<leader>x", mc.deleteCursor, { desc = "Delete current cursor" })
      -- This layer is only active while cursors exist, so Escape clears them.
      -- With no cursors the layer is inactive and the global <esc> mapping runs
      -- (clear search highlight, dismiss popups). When cursors are merely
      -- disabled by <leader>mq, Escape re-enables them.
      layer_set("n", "<esc>", function()
        if not mc.cursorsEnabled() then
          mc.enableCursors()
        else
          mc.clearCursors()
        end
      end)
    end)

    local hl = vim.api.nvim_set_hl
    hl(0, "MultiCursorCursor", { reverse = true })
    hl(0, "MultiCursorVisual", { link = "Visual" })
    hl(0, "MultiCursorSign", { link = "SignColumn" })
    hl(0, "MultiCursorMatchPreview", { link = "Search" })
    hl(0, "MultiCursorDisabledCursor", { reverse = true })
    hl(0, "MultiCursorDisabledVisual", { link = "Visual" })
    hl(0, "MultiCursorDisabledSign", { link = "SignColumn" })
  end,
}
