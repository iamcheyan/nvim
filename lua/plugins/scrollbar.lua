return {
  {
    "lewis6991/satellite.nvim",
    event = { "BufReadPost", "BufNewFile" },
    opts = {
      current_only = false,
      winblend = 0,
      zindex = 40,
      excluded_filetypes = {
        "local_popup_menu",
        "dropbar_menu",
        "dropbar_menu_fzf",
        "DressingInput",
        "cmp_docs",
        "cmp_menu",
        "blink-cmp-menu",
        "noice",
        "prompt",
        "TelescopePrompt",
        "neo-tree",
        "aerial",
        "help",
        "lazy",
        "mason",
      },
      handlers = {
        cursor = {
          enable = true,
          overlap = true,
          priority = 100,
        },
        search = {
          enable = true,
        },
        diagnostic = {
          enable = true,
        },
        gitsigns = {
          enable = true,
        },
        marks = {
          enable = true,
          show_builtins = false,
        },
      },
    },
    config = function(_, opts)
      require("satellite").setup(opts)
      -- Disable satellite.nvim's built-in <LeftMouse> keymap (which uses a blocking
      -- getchar() loop that interferes with split separator dragging and vim.on_key).
      -- Scrollbar clicking, dragging, and wheel scrolling are handled by scrollbar_scroll.lua.
      for _, mode in ipairs({ "n", "v", "x", "s", "o", "i" }) do
        pcall(vim.keymap.del, mode, "<LeftMouse>")
      end

      -- Make satellite's search scrollbar handler window-local so each split's
      -- scrollbar independently reflects its own vim.w[winid].win_search_pattern
      -- even with global hlsearch disabled.
      local ok_hd, handlers = pcall(require, "satellite.handlers")
      local ok_ut, sat_util = pcall(require, "satellite.util")
      if ok_hd and ok_ut and type(handlers) == "table" then
        pcall(handlers.init)
        for _, h in ipairs(handlers.handlers or {}) do
          if h.name == "search" then
            local symbols = (h.config and h.config.symbols) or { "⠂", "⠅", "⠇", "⠗", "⠟", "⠿" }
            h.update = function(bufnr, winid)
              if not vim.api.nvim_buf_is_valid(bufnr) or not vim.api.nvim_win_is_valid(winid) then
                return {}
              end
              local ok_w, pattern = pcall(function()
                return vim.w[winid].win_search_pattern
              end)
              pattern = (ok_w and pattern) or ""
              if winid == vim.api.nvim_get_current_win() and vim.api.nvim_get_mode().mode == "c" then
                local cmdtype = vim.fn.getcmdtype()
                if cmdtype == "/" or cmdtype == "?" then
                  pattern = vim.fn.getcmdline()
                end
              end
              if not pattern or pattern == "" then
                return {}
              end
              local marks_by_pos = {}
              local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, true)
              local cursor_lnum = vim.api.nvim_win_get_cursor(winid)[1]
              local smartcase = pattern:find("[A-Z]") ~= nil
              local full_pat = pattern
              if vim.o.ignorecase and vim.o.smartcase and smartcase and not vim.startswith(pattern, "\\C") then
                full_pat = "\\C" .. pattern
              end
              for lnum, line in ipairs(lines) do
                local count = 0
                local ok_m, col = pcall(vim.fn.match, line, full_pat, 0, 1)
                if ok_m and col and col >= 0 then
                  count = 1
                end
                if count > 0 then
                  local pos = sat_util.row_to_barpos(winid, lnum - 1)
                  local prev = marks_by_pos[pos] and marks_by_pos[pos].count or 0
                  local total = math.min(#symbols, prev + count)
                  if lnum == cursor_lnum then
                    marks_by_pos[pos] = {
                      count = total,
                      highlight = "SatelliteSearchCurrent",
                      unique = true,
                    }
                  elseif not (marks_by_pos[pos] and marks_by_pos[pos].unique) then
                    marks_by_pos[pos] = {
                      count = total,
                      highlight = "SatelliteSearch",
                    }
                  end
                end
              end
              local ret = {}
              for pos, mark in pairs(marks_by_pos) do
                ret[#ret + 1] = {
                  pos = pos,
                  unique = mark.unique,
                  highlight = mark.highlight or "SatelliteSearch",
                  symbol = symbols[mark.count] or symbols[#symbols],
                }
              end
              return ret
            end
          end
        end
      end

      require("config.scrollbar_scroll").setup()
    end,
  },
}
