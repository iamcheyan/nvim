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

    set("n", "<c-leftmouse>", mc.handleMouse)
    set("n", "<c-leftdrag>", mc.handleMouseDrag)
    set("n", "<c-leftrelease>", mc.handleMouseRelease)
    set({ "n", "x" }, "<C-q>", mc.toggleCursor)

    mc.addKeymapLayer(function(layer_set)
      layer_set({ "n", "x" }, "<left>", mc.prevCursor)
      layer_set({ "n", "x" }, "<right>", mc.nextCursor)
      layer_set({ "n", "x" }, "<leader>x", mc.deleteCursor)
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
