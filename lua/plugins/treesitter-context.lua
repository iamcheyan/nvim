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
      -- No border/separator: a solid, slightly darker surface is enough to
      -- show that the header is pinned.  The global float wrapper only leaves
      -- borderless non-focusable windows alone, so this also avoids a
      -- one-cell frame around the line number and context text.
      separator = nil,
      zindex = 20,
    },
  },
}
