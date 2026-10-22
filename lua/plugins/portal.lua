-- Search the jumplist instead of stepping through it blindly.
return {
  {
    "cbochs/portal.nvim",
    cmd = "Portal",
    keys = {
      { "<leader>jo", "<cmd>Portal jumplist backward<cr>", desc = "Portal: jump back" },
      { "<leader>jO", "<cmd>Portal jumplist forward<cr>", desc = "Portal: jump forward" },
      { "<leader>jc", "<cmd>Portal changelist backward<cr>", desc = "Portal: change list" },
      { "<leader>jg", "<cmd>Portal grapple<cr>", desc = "Portal: grapple tags" },
    },
    opts = {
      escape = { ["<esc>"] = true, ["<C-c>"] = true, q = true },
      window_options = { border = "rounded" },
    },
  },
}
