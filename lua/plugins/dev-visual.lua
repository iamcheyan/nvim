return {
  {
    "j-hui/fidget.nvim",
    event = "LspAttach",
    opts = {
      notification = {
        window = {
          border = "single",
        },
      },
    },
  },

  {
    "kevinhwang91/nvim-hlslens",
    event = "VeryLazy",
    opts = {},
    -- n/N are owned by config/keymaps-defaults.lua so fold-open (`zv`) and
    -- hlslens stay on one mapping. * / # / g* / g# still start the lens here.
    keys = {
      {
        "*",
        function()
          pcall(vim.cmd, "normal! *")
          require("hlslens").start()
        end,
        desc = "Search Word Forward",
      },
      {
        "#",
        function()
          pcall(vim.cmd, "normal! #")
          require("hlslens").start()
        end,
        desc = "Search Word Backward",
      },
      {
        "g*",
        function()
          pcall(vim.cmd, "normal! g*")
          require("hlslens").start()
        end,
        desc = "Search Partial Word Forward",
      },
      {
        "g#",
        function()
          pcall(vim.cmd, "normal! g#")
          require("hlslens").start()
        end,
        desc = "Search Partial Word Backward",
      },
    },
  },
}
