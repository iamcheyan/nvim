-- Inline counts of references, definitions and implementations.
return {
  {
    "Wansmer/symbol-usage.nvim",
    event = "LspAttach",
    opts = {
      vt_position = "end_of_line",
      disable = { filetypes = { "markdown", "yaml", "sh", "Trouble", "qf" } },
      request_pending_text = "…",
    },
  },
}
