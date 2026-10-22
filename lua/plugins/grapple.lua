-- Tag files you keep coming back to, per git branch.
return {
  {
    "cbochs/grapple.nvim",
    cmd = "Grapple",
    opts = {
      scope = "git_branch",
      icon = " ",
      popup_options = { border = "rounded" },
    },
    keys = {
      { "<leader>ja", function() require("grapple").toggle() end, desc = "Grapple: tag file" },
      { "<leader>jt", function() require("grapple").toggle_tags() end, desc = "Grapple: tag list" },
      { "<leader>jn", function() require("grapple").cycle_tags("next") end, desc = "Grapple: next tag" },
      { "<leader>jp", function() require("grapple").cycle_tags("prev") end, desc = "Grapple: previous tag" },
      { "<leader>js", function() require("grapple").toggle_scopes() end, desc = "Grapple: scopes" },
    },
  },
}
