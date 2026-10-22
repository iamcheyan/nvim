-- Extensible increment/decrement for numbers, dates, words and more.
return {
  {
    "monaqa/dial.nvim",
    keys = {
      { "<leader>ni", "<Plug>(dial-increment)", desc = "Dial: increment" },
      { "<leader>nd", "<Plug>(dial-decrement)", desc = "Dial: decrement" },
      { "<leader>ni", "<Plug>(dial-increment)", mode = "x", desc = "Dial: increment" },
      { "<leader>nd", "<Plug>(dial-decrement)", mode = "x", desc = "Dial: decrement" },
    },
    config = function()
      local augend = require("dial.augend")
      require("dial.config").augends:register_group({
        default = {
          augend.integer.alias.decimal,
          augend.integer.alias.hex,
          augend.date.alias["%Y/%m/%d"],
          augend.constant.alias.bool,
          augend.semver.alias.semver,
        },
      })
    end,
  },
}
