return {
  {
    "mfussenegger/nvim-lint",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      local lint = require("lint")
      lint.linters_by_ft = {
        sh = { "shellcheck" },
        bash = { "shellcheck" },
      }

      local group = vim.api.nvim_create_augroup("ShellCheckLint", { clear = true })
      vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
        group = group,
        callback = function(args)
          if vim.tbl_contains({ "sh", "bash" }, vim.bo[args.buf].filetype) then
            lint.try_lint("shellcheck")
          end
        end,
      })
    end,
  },
}
