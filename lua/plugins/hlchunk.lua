-- Highlight the code block the cursor sits in.
return {
  {
    "shellRaining/hlchunk.nvim",
    event = "UIEnter",
    -- indent-blankline already draws indent guides, so only the block
    -- highlight is enabled to avoid two competing visuals.
    opts = {
      chunk = {
        enable = true,
        chars = {
          horizontal_line = "─",
          vertical_line = "│",
          left_top = "╭",
          left_bottom = "╰",
          right_arrow = "─",
        },
        style = "#808080",
        textobject = "",
      },
      indent = { enable = false },
      line_num = { enable = false },
      blank = { enable = false },
    },
    keys = {
      { "<leader>uH", "<cmd>DisableHLChunk<cr>", desc = "Disable chunk highlight" },
      { "<leader>uG", "<cmd>EnableHLChunk<cr>", desc = "Enable chunk highlight" },
    },
  },
}
