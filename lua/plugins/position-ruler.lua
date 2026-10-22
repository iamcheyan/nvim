-- position-ruler.nvim: character ruler for fixed-width text and data files.
--
-- The plugin activates for text-like data files. `.txt` is already `text`
-- and `.csv` is already `csv`; map the remaining fixed-width extensions once
-- so the ruler turns on for them too.
vim.filetype.add({
  pattern = {
    ['.*%.[tT][xX][tT]'] = 'text',
    ['.*%.[cC][sS][vV]'] = 'csv',
    ['.*%.[tT][sS][vV]'] = 'tsv',
    ['.*%.[dD][aA][tT]'] = 'text',
    ['.*%.[lL][sS][tT]'] = 'text',
    ['.*%.[cC][tT][lL]'] = 'text',
  },
  extension = {
    dat = "text",
    lst = "text",
    ctl = "text",
  },
})

return {
  {
    "iamcheyan/position-ruler.nvim",
    ft = { "text", "txt", "csv", "tsv" },
    cmd = {
      "PositionJump",
      "PositionRange",
      "PositionRulerToggle",
      "PositionRulerEnable",
      "PositionRulerDisable",
    },
    opts = {
      enabled = true,
      filetypes = { "text", "txt", "csv", "tsv" },
      ruler = true,
      show_position = true,
      -- Crosshair: show the cursor column so it lines up with the ruler.
      cursorcolumn = true,
      -- Keep a topbar for data files regardless of size.
      max_file_size = math.huge,
      copy_to_clipboard = false,
    },
    config = function(_, opts)
      require("position-ruler").setup(opts)
    end,
  },
}
