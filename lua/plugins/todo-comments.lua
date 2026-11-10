-- BOOKMARK is the code-bookmark keyword; TODO/FIXME/HACK stay as todo markers.
return {
  {
    "folke/todo-comments.nvim",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = { "nvim-lua/plenary.nvim" },
    cmd = { "TodoTelescope", "TodoQuickFix", "TodoLocList", "TodoTrouble" },
    keys = {
      {
        "<leader>bt",
        function()
          pcall(function()
            vim.cmd("TodoTelescope keywords=BOOKMARK,BOOKMARK-BEGIN,BOOKMARK-END")
          end)
        end,
        desc = "Bookmarks: only BOOKMARK (Telescope)",
      },
    },
    opts = {
      signs = true,
      sign_priority = 12,
      keywords = {
        BOOKMARK = {
          icon = " ",
          color = "hint",
        },
        ["BOOKMARK-BEGIN"] = {
          icon = " ",
          color = "hint",
        },
        ["BOOKMARK-END"] = {
          icon = " ",
          color = "hint",
        },
      },
      highlight = {
        multiline = true,
        multiline_pattern = "^.",
        multiline_context = 10,
        before = "",
        keyword = "wide",
        after = "fg",
        -- capture the whole keyword, including the -BEGIN/-END suffix
        pattern = {
          [[.*<(BOOKMARK-BEGIN|BOOKMARK-END|BOOKMARK)\s*:?]],
          [[.*region\s+BOOKMARK\s*:?]],
        },
        comments_only = true,
        max_line_len = 500,
        exclude = {},
      },
      colors = {
        hint = { "DiagnosticHint", "#56B6C2" },
      },
      search = {
        command = "rg",
        args = { "--color=never", "--no-heading", "--with-filename", "--line-number", "--column" },
        pattern = [[\bBOOKMARK]],
      },
    },
    config = function(_, opts)
      require("todo-comments").setup(opts)
      require("config.bookmarks").setup()
    end,
  },
}
