return {
  {
    "akinsho/bufferline.nvim",
    lazy = false,
    enabled = vim.env.WDIFF_NVIM ~= "1",
    opts = function()
      local function middle_truncate_name(info)
        local name = info.name or ""
        local limit = 21
        if vim.fn.strdisplaywidth(name) <= limit then return name end

        local left, right = "", ""
        local left_index, right_index = 0, vim.fn.strchars(name) - 1
        local left_width, right_width = 0, 0
        local left_turn = true
        while left_index <= right_index do
          if left_turn then
            local char = vim.fn.strcharpart(name, left_index, 1)
            local width = vim.fn.strdisplaywidth(char)
            if left_width + right_width + width > limit - 3 then break end
            left, left_width, left_index = left .. char, left_width + width, left_index + 1
          else
            local char = vim.fn.strcharpart(name, right_index, 1)
            local width = vim.fn.strdisplaywidth(char)
            if left_width + right_width + width > limit - 3 then break end
            right, right_width, right_index = char .. right, right_width + width, right_index - 1
          end
          left_turn = not left_turn
        end
        return left .. "..." .. right
      end
      -- Neovim's tabline click protocol only resolves global functions.
      _G.__bufferline_new_buffer = function(_, _, button)
        if button == "l" then
          require("config.bar_feedback").press("__bufferline_new_buffer", 0)
          vim.schedule(function() require("config.file_actions").new_file() end)
        end
      end
      _G.__bufferline_open_buffer_list = function(_, _, button)
        if button == "l" then
          require("config.bar_feedback").press("__bufferline_open_buffer_list", 0)
          require("snacks").picker.buffers()
        end
      end
      local function close_buffer(buf)
        return require("config.file_actions").close(buf)
      end

      -- The native PopUp menu is installed by config.context_menu.
      return {
        highlights = require("config.ui_highlights").bufferline_highlights(),
        options = {
          style_preset = nil, -- resolved in config (no_italic preset)
          mode = "buffers",
          diagnostics = false,
          themable = true,
          -- Let each label use its own text width, with the current longest
          -- tab name as the cap for truncating longer buffer names.
          truncate_names = true,
          -- Zero disables Bufferline's minimum/equal tab sizing, so each tab
          -- can shrink to its content. max_name_length leaves room for the
          -- icon, suffix, and padding within the intended overall cap.
          tab_size = 0,
          -- This is the filename budget; the remaining fixed label parts
          -- (icon, close/modified marker, and padding) bring the full tab to
          -- roughly 24 display cells at most while short names stay compact.
          max_name_length = 21,
          name_formatter = middle_truncate_name,
          enforce_regular_tabs = false,
          -- Icons inherit the active/inactive tab text color. Keeping the
          -- filetype glyph while disabling per-filetype icon colors prevents
          -- selected icons from turning white or retaining stale colors.
          color_icons = false,
          -- File tabs are global buffers. Native numbered indicators separately
          -- expose the tab pages (window layouts) created by :tabnew.
          show_tab_indicators = true,
          offsets = {
            {
              filetype = "neo-tree",
              text = "",
              highlight = "NeoTreeTabInactive",
              text_align = "left",
              -- Window width excludes the split separator; reserve that cell
              -- so the first tab starts above the editor's winbar.
              padding = 1,
            },
            {
              filetype = "aerial",
              text = "",
              highlight = "NeoTreeTabInactive",
              padding = 1,
            },
            {
              filetype = "snacks_layout_box",
            },
          },
          -- Remove separator character between tabs for a seamless, compact layout
          separator_style = { "", "" },
          indicator = {
            style = "none",
          },
          show_buffer_close_icons = true,
          show_close_icon = false,
          buffer_padding = 1,
          hover = {
            enabled = true,
            reveal = { "close" },
          },
          enforce_regular_tabs = false,
          buffer_close_icon = "",
          modified_icon = "●",
          close_command = close_buffer,
          middle_mouse_command = close_buffer,
          right_mouse_command = function(buffer_id)
            require("config.context_menu").open_buffer(buffer_id)
          end,
          left_mouse_command = function(buf)
            require("config.file_actions").open_buffer(buf)
          end,
          custom_areas = {
            left = function()
              return {
                {
                  text = "%@v:lua.__bufferline_open_buffer_list@ 󰍜 %T",
                  link = "BufferLineNewBuffer",
                },
              }
            end,
            right = function()
              return {
                {
                  -- Keep the click marker inside the highlighted plus area.
                  text = "%@v:lua.__bufferline_new_buffer@ + %T",
                  link = "BufferLineNewBuffer",
                },
              }
            end,
          },
        },
      }
    end,
    config = function(_, opts)
      local bufferline = require("bufferline")
      if not (opts.options and opts.options.style_preset) then
        opts.options = opts.options or {}
        opts.options.style_preset = bufferline.style_preset.no_italic
      end
      bufferline.setup(opts)
      require("config.sidebar_tabs").setup()
      require("config.bufferline_scroll").setup()
      require("config.bufferline_drag").setup()

      -- Guard handle_close against right-clicks: right-click on close icon should
      -- open the context menu instead of closing the buffer.
      local orig_handle_close = _G.___bufferline_private and _G.___bufferline_private.handle_close
      if orig_handle_close then
        _G.___bufferline_private.handle_close = function(id, clicks, button, mod)
          require("config.bar_feedback").press("___bufferline_private.handle_close", id)
          if button == "r" then
            require("config.context_menu").open_buffer(id)
            return
          end
          vim.defer_fn(function()
            if vim.api.nvim_buf_is_valid(id) then orig_handle_close(id, clicks, button, mod) end
          end, 100)
        end
      end

      local original_click = _G.___bufferline_private.handle_click
      _G.___bufferline_private.handle_click = function(id, clicks, button, mods)
        require("config.bar_feedback").press("___bufferline_private.handle_click", id)
        return original_click(id, clicks, button, mods)
      end
      local original_render = _G.nvim_bufferline
      _G.nvim_bufferline = function()
        local line = require("config.bufferline_scroll").render(original_render)
        line = line:gsub("(%%%d+@v:lua%.___bufferline_private%.handle_close@)(.-)(%%X)", "%1 %2 %3")
        return require("config.bar_feedback").paint(line)
      end

      -- bufferline creates its DevIcon groups during setup.
      vim.defer_fn(function()
        require("config.ui_highlights").apply()
      end, 0)
    end,
  },
}
