-- Keep the enclosing function/class header visible at the top of the window.
return {
  {
    "nvim-treesitter/nvim-treesitter-context",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    event = "VeryLazy",
    opts = {
      enable = true,
      max_lines = 3,
      min_window_height = 12,
      line_numbers = true,
      multiline_threshold = 4,
      trim_scope = "outer",
      mode = "cursor",
      separator = "─",
      zindex = 20,
    },
  },
}
