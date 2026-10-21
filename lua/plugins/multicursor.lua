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

    local set = vim.keymap.set
    -- Plain arrows stay as cursor movement. Adjacent-line cursors use the
    -- leader form so they do not fight the window-motion maps.
    set({ "n", "x" }, "<leader><up>", function() mc.lineSkipCursor(-1) end)
    set({ "n", "x" }, "<leader><down>", function() mc.lineSkipCursor(1) end)

    -- <leader>s is the search prefix. Skip lives on Alt-d so <C-d> can scroll.
    set({ "n", "x" }, "<leader>n", function() mc.matchAddCursor(1) end)
    set({ "n", "x" }, "<leader>N", function() mc.matchAddCursor(-1) end)
    set({ "n", "x" }, "<M-d>", function() mc.matchSkipCursor(1) end)
    set({ "n", "x" }, "<M-D>", function() mc.matchSkipCursor(-1) end)

    -- Ctrl+n adds the next match. Ctrl+Shift+n selects every match.
    -- Insert mode is left alone so keyword completion keeps Ctrl+n.
    set({ "n", "x" }, "<C-n>", function() mc.matchAddCursor(1) end)
    set({ "n", "x" }, "<C-S-n>", mc.matchAllAddCursors)

    -- <leader>A aligns columns. <leader>a stays "increment number".
    -- <C-q> is visual-block in keymaps.lua. Toggle cursors with <leader>mq.
    set({ "n", "x" }, "ga", mc.addCursorOperator)
    set("n", "<leader>A", mc.alignCursors)
    set("n", "<leader>gv", mc.restoreCursors)
    set({ "n", "x" }, "<leader>mq", mc.toggleCursor)

    set("n", "<c-leftmouse>", mc.handleMouse)
    set("n", "<c-leftdrag>", mc.handleMouseDrag)
    set("n", "<c-leftrelease>", mc.handleMouseRelease)

    mc.addKeymapLayer(function(layer_set)
      layer_set({ "n", "x" }, "<left>", mc.prevCursor)
      layer_set({ "n", "x" }, "<right>", mc.nextCursor)
      layer_set({ "n", "x" }, "<leader>x", mc.deleteCursor)
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
