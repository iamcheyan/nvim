return {
  "jake-stewart/multicursor.nvim",
  branch = "1.0",
  keys = {
    { "<leader>mn", mode = { "n", "x" }, desc = "Multicursor: Add next match" },
    { "<leader>mN", mode = { "n", "x" }, desc = "Multicursor: Add previous match" },
    { "<leader>ms", mode = { "n", "x" }, desc = "Multicursor: Skip next match" },
    { "<leader>mS", mode = { "n", "x" }, desc = "Multicursor: Skip previous match" },
    { "<C-q>", mode = { "n", "x" }, desc = "Multicursor: Toggle cursors" },
  },
  config = function()
    local mc = require("multicursor-nvim")
    mc.setup()

    local set = vim.keymap.set
    set({ "n", "x" }, "<leader>mn", function() mc.matchAddCursor(1) end, { desc = "Multicursor: Add next match" })
    set({ "n", "x" }, "<leader>mN", function() mc.matchAddCursor(-1) end, { desc = "Multicursor: Add previous match" })
    set({ "n", "x" }, "<leader>ms", function() mc.matchSkipCursor(1) end, { desc = "Multicursor: Skip next match" })
    set({ "n", "x" }, "<leader>mS", function() mc.matchSkipCursor(-1) end, { desc = "Multicursor: Skip previous match" })
    set({ "n", "x" }, "<C-q>", mc.toggleCursor, { desc = "Multicursor: Toggle cursors" })

    mc.addKeymapLayer(function(layer_set)
      layer_set({ "n", "x" }, "<left>", mc.prevCursor)
      layer_set({ "n", "x" }, "<right>", mc.nextCursor)
      layer_set("n", "<esc>", function()
        if not mc.cursorsEnabled() then
          mc.enableCursors()
        else
          mc.clearCursors()
        end
      end)
    end)
  end,
}
