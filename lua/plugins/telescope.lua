return {
  {
    "nvim-telescope/telescope.nvim",
    cmd = "Telescope",
    keys = {
      { "<leader>bl", "<cmd>Telescope find_files<cr>", desc = "Files (Telescope)" },
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
      {
        "folke/todo-comments.nvim",
        optional = true,
      },
    },
    opts = {
      defaults = {
        sorting_strategy = "ascending",
        layout_config = {
          prompt_position = "top",
          width = 0.9,
          height = 0.82,
          horizontal = { preview_width = 0.5, preview_cutoff = 60 },
        },
        mappings = {
          i = {
            ["<C-q>"] = function(prompt_bufnr)
              local actions = require("telescope.actions")
              actions.send_selected_to_qflist(prompt_bufnr)
              actions.open_qflist(prompt_bufnr)
            end,
          },
        },
      },
    },
    config = function(_, opts)
      local telescope = require("telescope")
      telescope.setup(opts)
      pcall(telescope.load_extension, "todo-comments")
    end,
  },
}
