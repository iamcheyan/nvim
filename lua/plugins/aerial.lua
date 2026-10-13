return {
  {
    "stevearc/aerial.nvim",
    cmd = { "AerialToggle", "AerialOpen", "AerialInfo" },
    keys = {
      { "<leader>cs", function() require("config.sidebar_tabs").toggle_symbols() end, desc = "Aerial (Symbols)" },
    },
    opts = {
      layout = {
        default_direction = "left",
        placement = "window",
        width = 32,
        min_width = 32,
        max_width = 32,
        resize_to_content = false,
        -- Apply the inset on every Aerial window creation, including session
        -- restoration. A literal status column keeps fold arrows out of it.
        win_opts = {
          foldcolumn = "1",
          statuscolumn = " ",
        },
      },
      keymaps = {
        ["<"] = function() require("config.sidebar_tabs").cycle(-1) end,
        [">"] = function() require("config.sidebar_tabs").cycle(1) end,
      },
      show_guides = true,
      manage_folds = true,
      link_tree_to_folds = true,
      link_tree_to_window = true,
      backends = {
        ["_"] = { "treesitter", "lsp", "markdown", "asciidoc", "man" },
        cobol = { "cobol" },
        cbl = { "cobol" },
        cob = { "cobol" },
        dosbatch = { "batch" },
        batch = { "batch" },
        sh = { "treesitter", "lsp" },
      },
    },
    config = function(_, opts)
      -- `sh`/`zsh` are registered as `bash` by the treesitter configuration so
      -- they work without aerial being loaded first.
      require("aerial").setup(opts)
    end,
  },
}
