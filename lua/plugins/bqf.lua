-- Quickfix window with syntax highlighting, filtering and a preview pane.
return {
  {
    "kevinhwang91/nvim-bqf",
    ft = "qf",
    opts = {
      auto_enable = true,
      magic_window = true,
      auto_resize_height = true,
      preview = {
        auto_preview = true,
        show_title = true,
        show_scroll_bar = true,
        win_height = 20,
        win_vheight = 20,
        delay_syntax = 80,
        border = { "┏", "━", "┓", "┃", "┛", "━", "┗", "┃" },
      },
    },
  },
}
