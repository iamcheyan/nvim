-- Visual undo tree: browse every branch of the buffer history.
return {
  {
    "mbbill/undotree",
    cmd = "UndotreeToggle",
    keys = {
      { "<leader>uu", "<cmd>UndotreeToggle<cr>", desc = "Undo tree" },
    },
    config = function()
      vim.g.undotree_WindowLayout = 2
      vim.g.undotree_SetFocusWhenToggle = 1
      vim.g.undotree_ShortIndicators = 1
      vim.g.undotree_SplitWidth = 30
      vim.g.undotree_DiffpanelHeight = 12
      vim.g.undotree_TreeNodeShape = "*"
      vim.g.undotree_HelpLine = 1
      -- Persist undo history across sessions.
      vim.opt.undofile = true
      vim.opt.undolevels = 10000
    end,
  },
}
