return {
  "jake-stewart/multicursor.nvim",
  branch = "1.0",
  keys = {
    { "<up>", mode = { "n", "x" }, desc = "Multicursor: Add cursor above" },
    { "<down>", mode = { "n", "x" }, desc = "Multicursor: Add cursor below" },
    { "<leader><up>", mode = { "n", "x" }, desc = "Multicursor: Skip line above" },
    { "<leader><down>", mode = { "n", "x" }, desc = "Multicursor: Skip line below" },
    { "<leader>n", mode = { "n", "x" }, desc = "Multicursor: Add next match" },
    { "<leader>N", mode = { "n", "x" }, desc = "Multicursor: Add previous match" },
    { "<leader>s", mode = { "n", "x" }, desc = "Multicursor: Skip next match" },
    { "<leader>S", mode = { "n", "x" }, desc = "Multicursor: Skip previous match" },
    { "<c-leftmouse>", mode = "n", desc = "Multicursor: Add or remove cursor" },
    { "<c-leftdrag>", mode = "n", desc = "Multicursor: Drag cursor" },
    { "<c-leftrelease>", mode = "n", desc = "Multicursor: Release cursor" },
    { "<C-q>", mode = { "n", "x" }, desc = "Multicursor: Toggle cursors" },
    { "<leader>A", mode = { "n", "x" }, desc = "Multicursor: Add all matches" },
    -- VS Code style shortcuts.
    { "<C-n>", mode = { "n", "x" }, desc = "Multicursor: Add next match (VS Code)" },
    { "<C-S-n>", mode = { "n", "x" }, desc = "Multicursor: Select all matches (VS Code)" },
    { "<C-d>", mode = { "n", "x" }, desc = "Multicursor: Skip current match (VS Code)" },
    -- Advanced actions kept from the plugin's recommendations.
    { "ga", mode = { "n", "x" }, desc = "Multicursor: Add cursor operator (gaip)" },
    { "<leader>a", mode = "n", desc = "Multicursor: Align cursors" },
    { "<leader>gv", mode = "n", desc = "Multicursor: Restore cursors" },
  },
  config = function()
    local mc = require("multicursor-nvim")
    mc.setup()

    local set = vim.keymap.set
    set({ "n", "x" }, "<up>", function() mc.lineAddCursor(-1) end)
    set({ "n", "x" }, "<down>", function() mc.lineAddCursor(1) end)
    set({ "n", "x" }, "<leader><up>", function() mc.lineSkipCursor(-1) end)
    set({ "n", "x" }, "<leader><down>", function() mc.lineSkipCursor(1) end)

    set({ "n", "x" }, "<leader>n", function() mc.matchAddCursor(1) end)
    set({ "n", "x" }, "<leader>s", function() mc.matchSkipCursor(1) end)
    set({ "n", "x" }, "<leader>N", function() mc.matchAddCursor(-1) end)
    set({ "n", "x" }, "<leader>S", function() mc.matchSkipCursor(-1) end)
    set({ "n", "x" }, "<leader>A", mc.matchAllAddCursors)

    -- VS Code style: Ctrl+n adds the next match, Ctrl+Shift+n selects every
    -- match of the word/selection, Ctrl+d skips the current match. Only
    -- normal and visual mode are mapped, so Ctrl+n keeps working as keyword
    -- completion in insert mode.
    set({ "n", "x" }, "<C-n>", function() mc.matchAddCursor(1) end)
    set({ "n", "x" }, "<C-S-n>", mc.matchAllAddCursors)
    set({ "n", "x" }, "<C-d>", function() mc.matchSkipCursor(1) end)

    -- Advanced actions. `ga` is an operator, so `gaip` adds a cursor to every
    -- line of the paragraph. <leader>a and <leader>gv are normal mode only,
    -- which keeps them clear of the visual-mode mappings of
    -- multicursor-line.nvim and of the diffview mappings.
    set({ "n", "x" }, "ga", mc.addCursorOperator)
    set("n", "<leader>a", mc.alignCursors)
    set("n", "<leader>gv", mc.restoreCursors)

    set("n", "<c-leftmouse>", mc.handleMouse)
    set("n", "<c-leftdrag>", mc.handleMouseDrag)
    set("n", "<c-leftrelease>", mc.handleMouseRelease)
    set({ "n", "x" }, "<C-q>", mc.toggleCursor)

    mc.addKeymapLayer(function(layer_set)
      layer_set({ "n", "x" }, "<left>", mc.prevCursor)
      layer_set({ "n", "x" }, "<right>", mc.nextCursor)
      layer_set({ "n", "x" }, "<leader>x", mc.deleteCursor)
      -- This layer is only active while cursors exist, so Escape clears them.
      -- With no cursors the layer is inactive and the global <esc> mapping runs
      -- (clear search highlight, dismiss popups). When cursors are merely
      -- disabled by <C-q>, Escape re-enables them.
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
