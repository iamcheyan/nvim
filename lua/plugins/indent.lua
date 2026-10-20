return {
  {
    "snacks.nvim",
    opts = {
      indent = {
        enabled = true,
        char = "│",
        only_scope = false,
        only_current = false,
      },
      scope = {
        enabled = true,
        char = "│",
        underline = false,
      },
      animate = {
        enabled = false, -- 关闭动画，确保打字与移动零延迟
      },
    },
    keys = {
      {
        "<leader>ug",
        function()
          Snacks.toggle.indent():toggle()
        end,
        desc = "Toggle Indent Guides",
      },
    },
  },
}
