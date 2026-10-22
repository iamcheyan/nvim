-- Official dropbar with native menus and public source/symbol adapters.
return {
  {
    "Bekaboo/dropbar.nvim",
    event = { "BufReadPost", "BufNewFile", "FileType" },
    cmd = { "DropbarContextMenu" },
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      local source = require("config.dropbar")
      local dropbar = require("dropbar")
      source.setup()
      local native_file_icon = require("dropbar.configs").opts.icons.kinds.file_icon
      local native_on_click = require("dropbar.configs").opts.symbol.on_click
      dropbar.setup({
        symbol = { on_click = function(symbol, ...)
          local _, _, button = ...
          if button == 'l' or button == 'left' then
            require('config.dropbar_mouse').open(symbol)
          else
            native_on_click(symbol, ...)
            source.path_menu(symbol.menu)
          end
        end },
        sources = { path = { preview = false } },
        menu = {
          scrollbar = { enable = false },
          preview = false,
          entry = { padding = { left = 1, right = 1 } },
          win_configs = {
            border = "single",
            win = function(menu) return menu.prev_menu and menu.prev_menu.win or menu.prev_win end,
            col = source.menu_col,
            row = source.menu_row,
          },
        },
        icons = {
          kinds = {
            dir_icon = function() return " ", "DropBarContextIcon" end,
            file_icon = function(path)
              local icon = native_file_icon(path)
              return icon .. " ", "DropBarContextIcon"
            end,
          },
          ui = { menu = { separator = " ", indicator = "" }, bar = { separator = "  " } },
        },
        bar = {
          -- Own cursor refreshes so queued cursor updates cannot destroy menus.
          -- Keep buffer events for the upstream LSP document-symbol cache.
          update_debounce = 0,
          update_events = { win = {}, buf = { "TextChanged", "TextChangedI", "BufWritePost" }, global = {} },
          padding = { left = 1, right = 1 },
          enable = source.should_attach,
          sources = source.sources,
        },
      })
      source.highlights()
    end,
  },
}
