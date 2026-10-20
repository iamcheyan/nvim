return {
  {
    "nvim-tree/nvim-web-devicons",
    opts = function(_, opts)
      opts.color_icons = true
      opts.default = true
      opts.variant = "dark"
      opts.override_by_extension = vim.tbl_extend("force", opts.override_by_extension or {}, {
        ["cob"] = { icon = "󰒋", color = "#00a4e4", name = "Cobol" },
        ["COB"] = { icon = "󰒋", color = "#00a4e4", name = "Cobol" },
        ["cbl"] = { icon = "󰒋", color = "#00a4e4", name = "Cobol" },
        ["CBL"] = { icon = "󰒋", color = "#00a4e4", name = "Cobol" },
        ["cobol"] = { icon = "󰒋", color = "#00a4e4", name = "Cobol" },
        ["COBOL"] = { icon = "󰒋", color = "#00a4e4", name = "Cobol" },
        ["cpy"] = { icon = "󰒋", color = "#00a4e4", name = "Cobol" },
        ["CPY"] = { icon = "󰒋", color = "#00a4e4", name = "Cobol" },
        ["cnf"] = { icon = "", color = "#6D8086", name = "Conf" },
        ["CNF"] = { icon = "", color = "#6D8086", name = "Conf" },
        ["cmd"] = { icon = "", color = "#C1F12E", name = "Bat" },
        ["CMD"] = { icon = "", color = "#C1F12E", name = "Bat" },
      })
      opts.override = vim.tbl_extend("force", opts.override or {}, {
        cobol = { icon = "󰒋", color = "#00a4e4", name = "Cobol" },
        md = { icon = "", color = "#ffffff", name = "Markdown" },
        sh = { icon = "", color = "#428850", name = "Shell" },
        zsh = { icon = "", color = "#428850", name = "Zsh" },
        toml = { icon = "", color = "#9c4221", name = "TOML" },
      })
    end,
    config = function(_, opts)
      local devicons = require("nvim-web-devicons")
      devicons.setup(opts)
      devicons.set_icon_by_filetype({
        cobol = "cobol",
        cbl = "cobol",
        cob = "cobol",
        cpy = "cobol",
      })
    end,
  },
}
