return {
  {
    "iamcheyan/bookmark.nvim",
    name = "bookmark.nvim",
    event = { "BufReadPost", "BufNewFile" },
    cmd = {
      "BookmarkToggle",
      "BookmarkList",
      "BookmarkNext",
      "BookmarkPrev",
      "BookmarkClear",
    },
    keys = {
      { "<leader>mm", "<cmd>BookmarkList<cr>",   desc = "Bookmarks: List" },
      { "<leader>mt", "<cmd>BookmarkToggle<cr>", desc = "Bookmarks: Toggle Line" },
      { "]b",         "<cmd>BookmarkNext<cr>",   desc = "Bookmarks: Next" },
      { "[b",         "<cmd>BookmarkPrev<cr>",   desc = "Bookmarks: Prev" },
      { "<leader>mc", "<cmd>BookmarkClear!<cr>", desc = "Bookmarks: Clear Buffer" },
      { "<leader>mC", "<cmd>BookmarkClear<cr>",  desc = "Bookmarks: Clear Project" },
    },
    opts = {
      sign = "󰃁 ",
      sign_color = "#e0af68",
      mouse = true,
    },
    config = function(_, opts)
      require("bookmark").setup(opts)
    end,
  },
}
