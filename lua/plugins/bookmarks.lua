-- Code bookmarks (<leader>b): comment-based, one namespace for reading code.
return {
  {
    "folke/todo-comments.nvim",
    optional = true,
    keys = {
      {
        "<leader>bb",
        function()
          require("config.bookmarks").add()
        end,
        desc = "Bookmarks: add for the current line",
      },
      {
        "<leader>bb",
        function()
          require("config.bookmarks").add_range()
        end,
        mode = "x",
        desc = "Bookmarks: wrap the selection in a block",
      },
      {
        "<leader>bl",
        function()
          require("config.bookmarks").pick()
        end,
        desc = "Bookmarks: list",
      },
      {
        "<leader>bn",
        function()
          require("config.bookmarks").jump("next")
        end,
        desc = "Bookmarks: next",
      },
      {
        "<leader>bp",
        function()
          require("config.bookmarks").jump("prev")
        end,
        desc = "Bookmarks: previous",
      },
      {
        "<leader>bq",
        function()
          vim.cmd("BookmarkQF")
        end,
        desc = "Bookmarks: quickfix list",
      },
      {
        "<leader>bs",
        function()
          require("config.bookmarks").panel()
        end,
        desc = "Bookmarks: sidebar",
      },
    },
    cmd = { "BookmarkList", "BookmarkAdd", "BookmarkNext", "BookmarkPrev", "BookmarkQF", "BookmarkPanel" },
  },
}
