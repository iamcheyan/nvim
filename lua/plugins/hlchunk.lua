-- Highlight the code block the cursor sits in.
return {
  {
    "shellRaining/hlchunk.nvim",
    event = "UIEnter",
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
        duration = 0,
      },
      indent = { enable = false },
      line_num = { enable = false },
      blank = { enable = false },
    },
  },
}
