-- Hover framework: one preview window for LSP, diagnostics, man and dictionary.
--
-- Pinned to the last revision that supports Neovim 0.10; newer commits require
-- Neovim 0.11 and changed the provider and window API.
local hover_commit = "81e7197b59a57edfc4cffcb3174b284c989a6a7f"

return {
  {
    "lewis6991/hover.nvim",
    commit = hover_commit,
    event = "LspAttach",
    opts = {
      init = function()
        require("hover.providers.lsp")
        require("hover.providers.diagnostic")
        require("hover.providers.man")
        require("hover.providers.dictionary")
      end,
      preview_window = false,
      preview_opts = { border = "single" },
    },
    keys = {
      {
        "<leader>cH",
        function()
          require("hover").select()
        end,
        desc = "Hover: choose source",
      },
    },
  },
}
