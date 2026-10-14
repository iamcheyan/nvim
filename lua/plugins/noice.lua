-- Keep Ex command entry at the bottom, but render Neovim's blocking confirm
-- prompts (for example :q with unsaved changes) in Noice's centered popup.
return {
  {
    "folke/noice.nvim",
    event = "VeryLazy",
    dependencies = { "MunifTanjim/nui.nvim" },
    opts = {
      cmdline = {
        enabled = true,
        view = "cmdline",
        format = {
          -- Keep the native ':' prompt instead of Noice's default '>' icon.
          cmdline = { icon = false, conceal = false },
          -- Keep vim.ui.input prompts at the bottom too.
          input = { view = "cmdline", icon = false },
        },
      },
      messages = {
        enabled = true,
        -- Keep ordinary messages at the bottom; Noice's built-in confirm
        -- route still sends confirm dialogs to the dedicated floating view.
        view = "cmdline",
        view_error = "cmdline",
        view_warn = "cmdline",
        view_search = "cmdline",
        view_history = "messages",
      },
      -- Keep yank confirmations in their own bottom view. They can stack while
      -- copying, then the whole message group hides after the last yank.
      routes = {
        {
          filter = { event = "msg_show", find = "yanked into" },
          view = "yank",
          opts = { stop = true },
        },
      },
      views = {
        yank = {
          backend = "popup",
          relative = "editor",
          position = { row = "100%", col = 0 },
          size = { height = "auto", width = "100%" },
          border = { style = "none" },
          timeout = 2200,
          win_options = {
            winhighlight = {
              Normal = "NoiceCmdline",
              IncSearch = "",
              CurSearch = "",
              Search = "",
            },
          },
        },
        confirm = {
          position = { row = "50%", col = "50%" },
          size = { width = "auto", height = "auto", max_width = 64 },
          format = { "{dialog}" },
          align = "left",
          scrollbar = false,
          border = { style = "rounded", padding = { 1, 2 }, text = { top = " Confirm " } },
          win_options = {
            wrap = true,
            winhighlight = {
              Normal = "ConfirmDialogNormal",
              FloatBorder = "ConfirmDialogBorder",
            },
          },
        },
      },
      popupmenu = { enabled = false },
      -- Preserve the existing Snacks notification UI and LSP UI behavior.
      notify = { enabled = false },
      lsp = {
        progress = { enabled = false },
        message = { enabled = false },
        hover = { enabled = false },
        signature = { enabled = false },
      },
    },
    config = function(_, opts)
      require("config.confirm_dialog").setup()
      require("noice").setup(opts)
    end,
  },
}
