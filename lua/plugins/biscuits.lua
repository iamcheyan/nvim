-- Show the closing text of the current scope as virtual text.
return {
  {
    "code-biscuits/nvim-biscuits",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    event = "VeryLazy",
    opts = {
      cursor_line_only = true,
      default_separator = "  ",
      max_biscuit_length = 40,
      on_events = { "CursorHold", "CursorHoldI" },
    },
    keys = {
      {
        "<leader>uB",
        function()
          require("nvim-biscuits").toggle_biscuits()
        end,
        desc = "Toggle biscuits",
      },
    },
  },
}
