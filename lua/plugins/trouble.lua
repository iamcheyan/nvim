-- Diagnostics, symbols and reference lists in one dockable panel.
return {
  {
    "folke/trouble.nvim",
    cmd = "Trouble",
    keys = {
      { "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", desc = "Trouble: diagnostics" },
      {
        "<leader>xX",
        "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
        desc = "Trouble: buffer diagnostics",
      },
      { "<leader>xs", "<cmd>Trouble symbols toggle<cr>", desc = "Trouble: symbols" },
      { "<leader>xr", "<cmd>Trouble lsp toggle<cr>", desc = "Trouble: LSP references" },
      { "<leader>xL", "<cmd>Trouble loclist toggle<cr>", desc = "Trouble: location list" },
      { "<leader>xt", "<cmd>Trouble todo toggle<cr>", desc = "Trouble: TODOs" },
    },
    opts = {
      focus = true,
      auto_preview = true,
      auto_close = false,
      win = { position = "bottom", size = 12 },
      render = { indent = { enable = true } },
    },
  },
}
