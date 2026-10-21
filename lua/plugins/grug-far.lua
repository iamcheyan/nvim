return {
  -- search/replace in multiple files
  {
    "MagicDuck/grug-far.nvim",
    -- Keymaps live in config/keymaps.lua so the extension filter and the
    -- visual-selection entry stay one mapping, loaded after plugin specs.
    opts = { headerMaxWidth = 80 },
    cmd = { "GrugFar", "GrugFarWithin" },
  },
}
