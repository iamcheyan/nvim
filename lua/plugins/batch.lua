return {
  {
    "iamcheyan/batch.nvim",
    name = "batch.nvim",
    dependencies = { "iamcheyan/contextline.nvim" },
    ft = { "dosbatch" },
    opts = {
      enable_diagnostics = true,
      enable_folding = true,
      enable_statusline = true,
      map_keys = false,
    },
    config = function(_, opts)
      require("batch").setup(opts)
    end,
  },
}
