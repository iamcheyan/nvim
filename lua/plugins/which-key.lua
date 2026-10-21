return {
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts_extend = { "spec" },
    opts = {
      preset = "helix",
      show_keys = false,
      win = {
        border = "single",
        title = true,
        title_pos = "center",
      },
      icons = {
        breadcrumb = "»",
        group = "",
        keys = {
          Space = "SPC ",
        },
      },
      defaults = {},
      spec = {
        {
          mode = { "n", "x" },
          { "<leader>", group = "Leader" },
          { "<leader><tab>", group = "tabs" },
          { "<leader>c", group = "code" },
          { "<leader>d", group = "profiler" },
          { "<leader>y", group = "yank path" },
          { "<leader>h", group = "help" },
          { "<leader>f", group = "file/find" },
          { "<leader>g", group = "git" },
          { "<leader>gh", group = "hunks" },
          { "<leader>q", group = "quit/session" },
          { "<leader>m", group = "bookmarks" },
          { "<leader>s", group = "search" },
          { "<leader>u", group = "ui" },
          { "<leader>x", group = "diagnostics/quickfix" },
          -- { "[", group = "prev" },
          -- { "]", group = "next" },
          { "g", group = "goto" },
          { "gs", group = "surround" },
          { "z", group = "fold" },
          {
            "<leader>b",
            group = "buffer",
            expand = function()
              return require("which-key.extras").expand.buf()
            end,
          },
          {
            "<leader>w",
            group = "windows",
            proxy = "<c-w>",
            expand = function()
              return require("which-key.extras").expand.win()
            end,
          },
          { "<c-w>", group = "windows" },
          { "gx", desc = "Open with system app" },
        },
      },
    },
    keys = {
      {
        "<leader>hk",
        function()
          require("which-key").show({ global = false })
        end,
        desc = "Buffer Keymaps (which-key)",
      },
      {
        "<c-w><space>",
        function()
          require("which-key").show({ keys = "<c-w>", loop = true })
        end,
        desc = "Window Hydra Mode (which-key)",
      },
    },
    config = function(_, opts)
      local function apply_which_key_highlights()
        require("config.ui_highlights").apply_menu_highlights()
      end
      apply_which_key_highlights()
      vim.api.nvim_create_autocmd("ColorScheme", {
        group = vim.api.nvim_create_augroup("WhichKeyThemeHighlights", { clear = true }),
        callback = function() vim.schedule(apply_which_key_highlights) end,
      })
      local wk = require("which-key")
      wk.setup(opts)
      if not vim.tbl_isempty(opts.defaults) then
        wk.register(opts.defaults)
      end
    end,
  },
}
