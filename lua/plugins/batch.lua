return {
  {
    "iamcheyan/batch.nvim",
    name = "batch.nvim",
    dependencies = { "iamcheyan/contextline.nvim" },
    event = { "BufReadPost", "BufNewFile" },
    cmd = {
      "BatchCheck",
      "BatchJumpToLabel",
      "BatchReferences",
      "BatchOutline",
      "BatchPeek",
    },
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
