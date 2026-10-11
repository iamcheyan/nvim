vim.filetype.add({
  pattern = {
    [".*%.[cC][oO][bB]"] = "cobol",
    [".*%.[cC][bB][lL]"] = "cobol",
    [".*%.[cC][oO][bB][oO][lL]"] = "cobol",
    [".*%.[cC][pP][yY]"] = "cobol",
  },
})

return {
  -- Install Aerial for the COBOL outline view. The backend itself lives in
  -- cobol.nvim, and is loaded as a public dependency.
  {
    "stevearc/aerial.nvim",
    cmd = { "AerialToggle", "AerialOpen", "AerialClose", "AerialNavToggle" },
    keys = {
      { "<leader>cs", function() require("config.sidebar_tabs").toggle_symbols() end, desc = "Toggle Aerial Outline" },
      { "<leader>cO", "<cmd>CobolFormatCase<cr>", desc = "Format COBOL reserved words" },
    },
    opts = function(_, opts)
      opts.backends = vim.tbl_deep_extend("force", opts.backends or {}, {
        cobol = { "cobol" },
      })
      opts.cobol = vim.tbl_deep_extend("force", opts.cobol or {}, {
        update_delay = 300,
      })
    end,
  },

  -- 在 COBOL 文件中排除 indent-blankline，隐藏通用的缩进线与 scope 范围线
  {
    "lukas-reineke/indent-blankline.nvim",
    optional = true,
    opts = function(_, opts)
      opts.exclude = opts.exclude or {}
      opts.exclude.filetypes = opts.exclude.filetypes or {}
      vim.list_extend(opts.exclude.filetypes, { "cobol", "cbl", "cob" })
    end,
  },

  -- COBOL guides and development tools.
  {
    "iamcheyan/cobol.nvim",
    name = "cobol.nvim",
    dependencies = { "iamcheyan/contextline.nvim" },
    ft = { "cobol", "cbl", "cob" },
    cmd = {
      "CobolGuideToggle",
      "CobolGuideEnable",
      "CobolGuideDisable",
      "CobolToggleComment",
    },
    keys = {
      { "<leader>uc", "<cmd>CobolGuideToggle<cr>", desc = "Toggle COBOL Guide" },
    },
    opts = {
      enabled = true,
      columns = { 7, 8, 12, 73 },
      show_lines = true,         -- 启用细标尺线 (│)
      char = "│",
      show_winbar = true,
      show_colorcolumn = false,  -- 关闭背景粗色块
      highlight_overflow = true,
      overflow_col = 72,
      disable_indent_guide = true,-- 屏蔽通用缩进线干扰
      smart_tab = true,
      smart_comments = true,
      keymaps = true,
    },
    config = function(_, opts)
      require("cobol").setup(opts)
    end,
  },
}
