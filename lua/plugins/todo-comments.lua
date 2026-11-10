-- todo-comments.nvim: TODO / HACK / WARN / PERF / NOTE / TEST, plus the
-- insert / delete / list keymaps and the Todo sidebar source.
return {
  {
    "folke/todo-comments.nvim",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = { "nvim-lua/plenary.nvim" },
    cmd = { "TodoTelescope", "TodoQuickFix", "TodoLocList", "TodoTrouble" },
    keys = {
      { "<leader>tt", function() require("config.todo").add("TODO") end, desc = "Todo: insert TODO" },
      { "<leader>th", function() require("config.todo").add("HACK") end, desc = "Todo: insert HACK" },
      { "<leader>tw", function() require("config.todo").add("WARN") end, desc = "Todo: insert WARN" },
      { "<leader>tp", function() require("config.todo").add("PERF") end, desc = "Todo: insert PERF" },
      { "<leader>tn", function() require("config.todo").add("NOTE") end, desc = "Todo: insert NOTE" },
      { "<leader>ts", function() require("config.todo").add("TEST") end, desc = "Todo: insert TEST" },
      { "<leader>ta", function() require("config.todo").list_project() end, desc = "Todo: list project" },
      { "<leader>tf", function() require("config.todo").list_buffer() end, desc = "Todo: list buffer" },
      { "<leader>td", function() require("config.todo").delete() end, desc = "Todo: delete line" },
      { "<leader>to", function() require("config.todo").panel() end, desc = "Todo: sidebar" },
      { "]t", function() require("config.todo").jump("next") end, desc = "Todo: next" },
      { "[t", function() require("config.todo").jump("prev") end, desc = "Todo: previous" },
    },
    opts = {
      signs = true,
      sign_priority = 12,
      -- exactly the keywords todo-comments ships with; FIX/FIXME is not used
      merge_keywords = false,
      keywords = {
        TODO = { icon = "󰄱 ", color = "info" },
        HACK = { icon = "󰈸 ", color = "warning" },
        WARN = { icon = "󰀪 ", color = "warning", alt = { "WARNING" } },
        PERF = { icon = "󰒡 ", color = "default", alt = { "OPTIM", "PERFORMANCE", "OPTIMIZE" } },
        NOTE = { icon = "󰋼 ", color = "hint", alt = { "INFO" } },
        TEST = { icon = "󰙨 ", color = "test", alt = { "TESTING", "PASSED", "FAILED" } },
      },
    },
    config = function(_, opts)
      require("todo-comments").setup(opts)
      require("config.todo").setup()
    end,
  },
}
