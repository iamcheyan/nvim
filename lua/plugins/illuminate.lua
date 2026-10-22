-- Highlight every other use of the word under the cursor.
return {
  {
    "RRethy/vim-illuminate",
    event = "LspAttach",
    opts = {
      delay = 200,
      under_cursor = true,
      large_file_cutoff = 4000,
      filetypes_denylist = { "dashboard", "neo-tree", "Trouble", "qf", "lazy", "lazyterm" },
    },
    keys = {
      {
        "]r",
        function()
          require("illuminate").next_reference({ wrap = true })
        end,
        desc = "Next reference",
      },
      {
        "[r",
        function()
          require("illuminate").prev_reference({ wrap = true })
        end,
        desc = "Previous reference",
      },
    },
  },
}
