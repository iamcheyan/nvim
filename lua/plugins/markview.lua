return {
  {
    "OXY2DEV/markview.nvim",
    -- Load with the first Markdown buffer. lazy=false made the ft field a no-op.
    ft = { "markdown", "markdown.mdx", "quarto", "rmd" },
    opts = {
      preview = {
        enable = true,
        icon_provider = "internal",
        filetypes = { "markdown", "markdown.mdx", "quarto", "rmd" },
      },
    },
    keys = {
      {
        "<leader>um",
        "<cmd>Markview<cr>",
        ft = { "markdown", "markdown.mdx", "quarto", "rmd" },
        desc = "Toggle Markdown preview",
      },
    },
  },
}
