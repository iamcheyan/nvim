-- Cursor coordinates and their statusline navigation menu.
local M = {}

function M.new(statusline_colors)
  local menu = require("config.statusline.menu")
  local get_active_editor_win = menu.active_editor_win
  local open_statusline_menu = menu.open
  local PositionInfo = {
    update = { "CursorMoved", "BufEnter", "WinEnter", "WinScrolled" },
    provider = function()
      local win = get_active_editor_win()
      local cursor = vim.api.nvim_win_get_cursor(win)
      local line = cursor[1]
      local col = vim.api.nvim_win_call(win, function()
        return vim.fn.virtcol(".")
      end)
      local pos = cursor[2] + 1
      return string.format("L%dC%dP%d", line, col, pos)
    end,
    on_click = {
      name = "heirline_position_menu",
      callback = function(_, _, _, button)
        if button ~= "l" then return end
        local win = get_active_editor_win()
        local cursor = vim.api.nvim_win_get_cursor(win)
        local line = cursor[1]
        local col = vim.api.nvim_win_call(win, function()
          return vim.fn.virtcol(".")
        end)
        local pos = cursor[2] + 1
        open_statusline_menu("position", {
          {
            icon = "L",
            label = string.format("Line %d  —  current line number", line),
            action = function() vim.notify("L: current line number", vim.log.levels.INFO) end,
          },
          {
            icon = "C",
            label = string.format("Column %d  —  screen cell column", col),
            action = function() vim.notify("C: screen cell column", vim.log.levels.INFO) end,
          },
          {
            icon = "P",
            label = string.format("Position %d  —  byte position in line", pos),
            action = function() vim.notify("P: byte position in the current line", vim.log.levels.INFO) end,
          },
          { separator = true },
          {
            icon = "󰱼",
            label = "Go to line…",
            action = function()
              vim.ui.input({ prompt = "Go to line: ", default = tostring(line) }, function(value)
                local target = tonumber(value)
                if not target then return end
                local target_win = get_active_editor_win()
                local count = vim.api.nvim_buf_line_count(vim.api.nvim_win_get_buf(target_win))
                vim.api.nvim_win_set_cursor(target_win, { math.max(1, math.min(count, math.floor(target))), 0 })
              end)
            end,
          },
          {
            icon = "󰜴",
            label = "Go to column…",
            action = function()
              vim.ui.input({ prompt = "Go to screen column: ", default = tostring(col) }, function(value)
                local target = tonumber(value)
                if not target then return end
                local target_win = get_active_editor_win()
                local target_line = vim.api.nvim_win_get_cursor(target_win)[1]
                vim.api.nvim_win_call(target_win, function()
                  vim.api.nvim_win_set_cursor(target_win, { target_line, 0 })
                  vim.cmd.normal({ args = { tostring(math.max(1, math.floor(target))) .. "|" }, bang = true })
                end)
              end)
            end,
          },
          {
            icon = "󰅍",
            label = "Copy L/C/P position",
            action = function()
              vim.fn.setreg("+", string.format("L%dC%dP%d", line, col, pos))
              vim.notify("Copied cursor position", vim.log.levels.INFO)
            end,
          },
        }, "heirline_position_menu")
      end,
    },
    hl = function()
      return { fg = statusline_colors.text }
    end,
  }
  return PositionInfo
end

return M
