-- Open definitions and references in floating preview windows.
return {
  {
    "rmagatti/goto-preview",
    event = "LspAttach",
    opts = {
      width = 80,
      height = 20,
      default_mappings = false,
      preview_window_title = { enable = true },
    },
    keys = {
      { "gpd", "<cmd>lua require('goto-preview').goto_preview_definition()<cr>", desc = "Preview definition" },
      { "gpi", "<cmd>lua require('goto-preview').goto_preview_implementation()<cr>", desc = "Preview implementation" },
      { "gpr", "<cmd>lua require('goto-preview').goto_preview_references()<cr>", desc = "Preview references" },
      { "gP", "<cmd>lua require('goto-preview').close_all_win()<cr>", desc = "Close previews" },
    },
  },
}
