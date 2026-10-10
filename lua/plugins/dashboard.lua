return {
  {
    "nvimdev/dashboard-nvim",
    -- dashboard-nvim installs its startup hook on UIEnter. Load it before
    -- that event so a no-argument launch never leaves the initial [No Name]
    -- buffer on screen.
    lazy = false,
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      theme = "hyper",
      change_to_vcs_root = false,
      config = {
        header = {
          "███╗   ██╗██╗   ██╗██╗███╗   ███╗",
          "████╗  ██║██║   ██║██║████╗ ████║",
          "██╔██╗ ██║██║   ██║██║██╔████╔██║",
          "██║╚██╗██║╚██╗ ██╔╝██║██║╚██╔╝██║",
          "██║ ╚████║ ╚████╔╝ ██║██║ ╚═╝ ██║",
          "╚═╝  ╚═══╝  ╚═══╝  ╚═╝╚═╝     ╚═╝",
        },
        project = { enable = false },
        mru = {
          enable = true,
          limit = 10,
          label = " Recent files",
          cwd_only = false,
        },
        shortcut = {
          {
            desc = " New file",
            group = "Label",
            key = "n",
            action = function()
              require("config.file_actions").new_file()
            end,
          },
          {
            desc = " Open folder",
            group = "Label",
            key = "o",
            action = function() require("config.file_actions").open_folder() end,
          },
          { desc = " Find file", group = "Label", key = "f", action = "lua Snacks.picker.files()" },
          { desc = " Search text", group = "Label", key = "s", action = "lua Snacks.picker.grep()" },
          { desc = " Lazy", group = "Label", key = "l", action = "Lazy" },
        },
      },
    },
  },
  {
    "folke/snacks.nvim",
    opts = {
      dashboard = { enabled = false },
    },
  },
}
