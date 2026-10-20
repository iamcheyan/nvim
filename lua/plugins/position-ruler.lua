-- position-ruler.nvim: character ruler for fixed-width text and data files.
--
-- The plugin activates for text-like data files. `.txt` is already `text`
-- and `.csv` is already `csv`; map the remaining fixed-width extensions once
-- so the ruler turns on for them too.
vim.filetype.add({
  extension = {
    dat = "text",
    lst = "text",
    ctl = "text",
  },
})

return {
  {
    "iamcheyan/position-ruler.nvim",
    ft = { "text", "csv" },
    cmd = {
      "PositionJump",
      "PositionRange",
      "PositionRulerToggle",
      "PositionRulerEnable",
      "PositionRulerDisable",
    },
    opts = {
      enabled = true,
      ruler = true,
      show_position = true,
      -- Crosshair: show the cursor column so it lines up with the ruler.
      cursorcolumn = true,
      -- Skip the ruler for files above 100 MB to avoid frequent redraws.
      max_file_size = 100 * 1024 * 1024,
      copy_to_clipboard = false,
    },
    config = function(_, opts)
      require("position-ruler").setup(opts)
    end,
  },
}
