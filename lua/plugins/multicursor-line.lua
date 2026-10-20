return {
  {
    "iamcheyan/multicursor-line.nvim",
    dependencies = { "mg979/vim-visual-multi" },
    cmd = {
      "McLineHead",
      "McLineBol",
      "McLineTail",
      "McLineAlt",
      "McLineAltBol",
      "McLineClear",
    },
    keys = {
      -- Visual Mode 快速两键触发
      {
        "<leader>h",
        function()
          require("multicursor-line").apply("head")
        end,
        mode = "x",
        desc = "多光标: 每行首个字符前加光标(智能跳过缩进)",
      },
      {
        "<leader>H",
        function()
          require("multicursor-line").apply("bol")
        end,
        mode = "x",
        desc = "多光标: 绝对行首(第0列)加光标",
      },
      {
        "<leader>0",
        function()
          require("multicursor-line").apply("bol")
        end,
        mode = "x",
        desc = "多光标: 绝对行首(第0列)加光标",
      },
      {
        "<leader>t",
        function()
          require("multicursor-line").apply("tail")
        end,
        mode = "x",
        desc = "多光标: 选区行尾/右边缘加光标",
      },
      {
        "<leader>a",
        function()
          require("multicursor-line").apply("alternate")
        end,
        mode = "x",
        desc = "多光标: 智能首尾交替(首字符前 <-> 行尾)",
      },
      {
        "<leader>A",
        function()
          require("multicursor-line").apply("alternate_bol")
        end,
        mode = "x",
        desc = "多光标: 绝对首尾交替(第0列 <-> 行尾)",
      },
      -- Visual Mode 与 Normal Mode <leader>m 助记分组
      {
        "<leader>mh",
        function()
          require("multicursor-line").apply("head")
        end,
        mode = { "n", "x" },
        desc = "多光标: 每行首字符前加光标",
      },
      {
        "<leader>mH",
        function()
          require("multicursor-line").apply("bol")
        end,
        mode = { "n", "x" },
        desc = "多光标: 绝对行首(第0列)加光标",
      },
      {
        "<leader>m0",
        function()
          require("multicursor-line").apply("bol")
        end,
        mode = { "n", "x" },
        desc = "多光标: 绝对行首(第0列)加光标",
      },
      {
        "<leader>mt",
        function()
          require("multicursor-line").apply("tail")
        end,
        mode = { "n", "x" },
        desc = "多光标: 行尾加光标",
      },
      {
        "<leader>ma",
        function()
          require("multicursor-line").apply("alternate")
        end,
        mode = { "n", "x" },
        desc = "多光标: 智能首尾交替加光标",
      },
      {
        "<leader>mA",
        function()
          require("multicursor-line").apply("alternate_bol")
        end,
        mode = { "n", "x" },
        desc = "多光标: 绝对首尾交替加光标",
      },
    },
    opts = {
      backend = "vm",
      alternate_start = "tail",
    },
    config = function(_, opts)
      require("multicursor-line").setup(opts)
    end,
  },
}
