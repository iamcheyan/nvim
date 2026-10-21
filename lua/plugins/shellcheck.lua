return {
  {
    "mfussenegger/nvim-lint",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      local lint = require("lint")
      lint.linters_by_ft = {
        sh = { "shellcheck" },
        bash = { "shellcheck" },
        python = { "ruff" },
      }

      local group = vim.api.nvim_create_augroup("NvimLintOnWrite", { clear = true })
      vim.api.nvim_create_autocmd("BufWritePost", {
        group = group,
        callback = function(args)
          local ft = vim.bo[args.buf].filetype
          if lint.linters_by_ft[ft] then
            lint.try_lint()
          end
        end,
      })
    end,
  },
}
