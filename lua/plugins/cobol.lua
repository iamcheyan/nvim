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

  -- Indent guides come from snacks.nvim (see lua/plugins/indent.lua); the old
  -- indent-blankline exclusion was removed because that plugin is not installed.

  -- COBOL guides and development tools.
  {
    "iamcheyan/cobol.nvim",
    build = "bash scripts/build_parser.sh",
    dependencies = { "Bekaboo/dropbar.nvim" },
    ft = { "cobol", "cbl", "cob" },
    init = function()
      -- Neovim's runtime COBOL ftplugin stores non-silent `unmap <buffer> [[`
      -- commands in b:undo_ftplugin. A second FileType pass (lazy loads the
      -- plugin on the same event) then raises E31 even though the mapping is
      -- gone. cobol.nvim supplies the COBOL-specific maps we use instead.
      vim.g.no_cobol_maps = 1
    end,
    cmd = {
      "CobolGuideToggle",
      "CobolGuideEnable",
      "CobolGuideDisable",
      "CobolToggleComment",
      "CobolHex",
      "CobolRenum",
      "CobolUnnum",
      "CobolCapsToggle",
      "CobolCalcRecord",
    },
    keys = {
      { "<leader>cg", "<cmd>CobolGuideToggle<cr>", desc = "Toggle COBOL Guide" },
      { "<leader>cL", "<cmd>CobolCalcRecord<cr>", desc = "Calculate Record Layout" },
      { "<leader>cK", function()
        local ok, diag = pcall(require, "cobol.diagnostics")
        if ok and diag.lint then diag.lint(0, { interactive = true }) end
      end, desc = "COBOL syntax check" },
      { "<leader>ch", "<cmd>CobolHex<cr>", desc = "Inspect Hex / EBCDIC / COMP-3" },
      { "<leader>cc", "<cmd>CobolCapsToggle<cr>", desc = "Toggle Smart CAPS" },
    },
    opts = {
      enabled = true,
      columns = { 7, 8, 12, 73 },
      show_lines = true,         -- 启用细标尺线 (│)
      char = "│",
      -- dropbar owns the bracketed chain and waiting closures.
      show_winbar = false,
      show_colorcolumn = false,  -- 关闭背景粗色块
      highlight_overflow = true,
      overflow_col = 72,
      disable_indent_guide = true,-- 屏蔽通用缩进线干扰
      smart_tab = true,
      smart_comments = true,
      keymaps = true,
      -- nvim-ufo owns foldmethod. The plugin's expr folds replace it per window.
      folding = { enable = false, foldtext = "auto" },
    },
    config = function(_, opts)
      require("cobol").setup(opts)
    end,
  },
}
