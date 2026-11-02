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
    -- Window-local search owns / and ? highlighting. hlslens's incremental
    -- search handler toggles global hlsearch back on when the command line exits,
    -- which makes every split highlight every window's search pattern.
    opts = { enable_incsearch = false },
    -- n/N are owned by config/keymaps-defaults.lua so fold-open (`zv`) and
    -- hlslens stay on one mapping. * / # / g* / g# still start the lens here.
    keys = {
      {
        "*",
        function()
          pcall(vim.cmd, "normal! *")
          pcall(function()
            require("config.win_search").set(vim.api.nvim_get_current_win(), vim.fn.getreg("/"))
          end)
          pcall(function()
            require("hlslens").start()
          end)
        end,
        desc = "Search Word Forward",
      },
      {
        "#",
        function()
          pcall(vim.cmd, "normal! #")
          pcall(function()
            require("config.win_search").set(vim.api.nvim_get_current_win(), vim.fn.getreg("/"))
          end)
          pcall(function()
            require("hlslens").start()
          end)
        end,
        desc = "Search Word Backward",
      },
      {
        "g*",
        function()
          pcall(vim.cmd, "normal! g*")
          pcall(function()
            require("config.win_search").set(vim.api.nvim_get_current_win(), vim.fn.getreg("/"))
          end)
          pcall(function()
            require("hlslens").start()
          end)
        end,
        desc = "Search Partial Word Forward",
      },
      {
        "g#",
        function()
          pcall(vim.cmd, "normal! g#")
          pcall(function()
            require("config.win_search").set(vim.api.nvim_get_current_win(), vim.fn.getreg("/"))
          end)
          pcall(function()
            require("hlslens").start()
          end)
        end,
        desc = "Search Partial Word Backward",
      },
    },
  },
}
