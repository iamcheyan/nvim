return {
  {
    "iamcheyan/contextline.nvim",
    name = "contextline.nvim",
    event = { "BufReadPost", "BufNewFile" },
    cmd = { "ContextlineMenu" },
    keys = {
      { "<leader>cb", "<cmd>ContextlineMenu<cr>", desc = "Code Breadcrumbs (Dropdown)" },
    },
    opts = {
      separator = "  ",
      show_path = false,
      show_file = false,
      show_icons = true,
      use_lsp = true,
      use_navic = true,
      use_treesitter = true,
    },
    config = function(_, opts)
      require("contextline").setup(opts)
    end,
  },
}
