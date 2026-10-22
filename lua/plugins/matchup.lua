-- Better % matching: navigate and select matching constructs.
return {
  {
    "andymass/vim-matchup",
    event = "VeryLazy",
    init = function()
      -- Keep the built-in matchparen disabled: matchup replaces it.
      vim.g.matchup_matchparen_enabled = 1
      vim.g.matchup_matchparen_offscreen = { method = "popup" }
      vim.g.matchup_surround_enabled = 1
      vim.g.matchup_transmute_enabled = 1
    end,
    keys = {
      { "<leader>uM", "<cmd>DoMatchParen<cr>", desc = "Matchup: enable matchparen" },
      { "<leader>uN", "<cmd>NoMatchParen<cr>", desc = "Matchup: disable matchparen" },
    },
  },
}
