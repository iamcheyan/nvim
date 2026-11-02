local M = {
  _namespace = nil,
  _drag = nil,
}

local keycodes = {}
for _, name in ipairs({ "<LeftMouse>", "<LeftDrag>", "<LeftRelease>" }) do
  keycodes[vim.api.nvim_replace_termcodes(name, true, false, true)] = name
end

---Get list of standard tiled windows (excluding floats)
---@return integer[]
local function get_tiled_windows()
  local wins = {}
  for _, w in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_is_valid(w) then
      local cfg = vim.api.nvim_win_get_config(w)
      if (not cfg.relative or cfg.relative == "") and not cfg.external then
        table.insert(wins, w)
      end
    end
  end
  return wins
end

---Determine if the mouse position is on or immediately adjacent to a window separator.
---@param mp table Result of vim.fn.getmousepos()
---@return table|nil
function M.find_separator(mp)
  if not mp or not mp.screencol or not mp.screenrow then return nil end
  -- Do not intercept mouse events when a Dropbar breadcrumb menu is open
  local dm = package.loaded["config.dropbar_mouse"]
  if dm and dm.get_current and dm.get_current() ~= nil then
    return nil
  end

  local scol, srow = mp.screencol, mp.screenrow
  local wins = get_tiled_windows()
  if #wins <= 1 then return nil end

  local function v_overlaps(other_pos, other_height)
    return srow >= other_pos[1] + 1 and srow <= other_pos[1] + other_height + 1
  end

  local function h_overlaps(other_pos, other_width)
    return scol >= other_pos[2] + 1 and scol <= other_pos[2] + other_width + 1
  end

  -- 1. Exact hit on vertical separators (│) between side-by-side windows:
  for _, w in ipairs(wins) do
    local pos = vim.api.nvim_win_get_position(w) -- [row, col] (0-based)
    local width = vim.api.nvim_win_get_width(w)
    local height = vim.api.nvim_win_get_height(w)
    local sep_col = pos[2] + width + 1 -- 1-based screen column

    if scol == sep_col and srow >= pos[1] + 1 and srow <= pos[1] + height + 1 then
      for _, other in ipairs(wins) do
        if other ~= w then
          local other_pos = vim.api.nvim_win_get_position(other)
          local other_height = vim.api.nvim_win_get_height(other)
          if other_pos[2] == pos[2] + width + 1 and v_overlaps(other_pos, other_height) then
            return {
              type = "vertical",
              exact = true,
              win = w,
              other_win = other,
              start_col = scol,
              start_row = srow,
              start_width = width,
              other_start_width = vim.api.nvim_win_get_width(other),
            }
          end
        end
      end
    end
  end

  -- 2. Exact hit on horizontal separators (─) between vertically stacked windows:
  for _, w in ipairs(wins) do
    local pos = vim.api.nvim_win_get_position(w) -- [row, col] (0-based)
    local width = vim.api.nvim_win_get_width(w)
    local height = vim.api.nvim_win_get_height(w)
    local sep_row = pos[1] + height + 1 -- 1-based screen row

    if srow == sep_row and scol >= pos[2] + 1 and scol <= pos[2] + width + 1 then
      for _, other in ipairs(wins) do
        if other ~= w then
          local other_pos = vim.api.nvim_win_get_position(other)
          local other_width = vim.api.nvim_win_get_width(other)
          if other_pos[1] == pos[1] + height + 1 and h_overlaps(other_pos, other_width) then
            return {
              type = "horizontal",
              exact = true,
              win = w,
              other_win = other,
              start_col = scol,
              start_row = srow,
              start_height = height,
              other_start_height = vim.api.nvim_win_get_height(other),
            }
          end
        end
      end
    end
  end

  -- 3. Forgiving 1-cell margin around vertical separator (scrollbar column or 1st line-number column):
  -- Engages only if the user drags horizontally.
  for _, w in ipairs(wins) do
    local pos = vim.api.nvim_win_get_position(w)
    local width = vim.api.nvim_win_get_width(w)
    local height = vim.api.nvim_win_get_height(w)
    local sep_col = pos[2] + width + 1

    if (scol == sep_col - 1 or scol == sep_col + 1) and srow >= pos[1] + 1 and srow <= pos[1] + height then
      for _, other in ipairs(wins) do
        if other ~= w then
          local other_pos = vim.api.nvim_win_get_position(other)
          local other_height = vim.api.nvim_win_get_height(other)
          if other_pos[2] == pos[2] + width + 1 and v_overlaps(other_pos, other_height) then
            return {
              type = "vertical",
              exact = false,
              win = w,
              other_win = other,
              start_col = scol,
              start_row = srow,
              start_width = width,
              other_start_width = vim.api.nvim_win_get_width(other),
            }
          end
        end
      end
    end
  end

  -- 4. Forgiving 1-row margin below horizontal separator (the lower split's Winbar row):
  -- Preserves normal Dropbar clicks, engages only if the user drags vertically.
  for _, w in ipairs(wins) do
    local pos = vim.api.nvim_win_get_position(w)
    local width = vim.api.nvim_win_get_width(w)
    local height = vim.api.nvim_win_get_height(w)
    local sep_row = pos[1] + height + 1

    if srow == sep_row + 1 and scol >= pos[2] + 1 and scol <= pos[2] + width then
      for _, other in ipairs(wins) do
        if other ~= w then
          local other_pos = vim.api.nvim_win_get_position(other)
          local other_width = vim.api.nvim_win_get_width(other)
          if other_pos[1] == pos[1] + height + 1 and h_overlaps(other_pos, other_width) then
            return {
              type = "horizontal",
              exact = false,
              win = w,
              other_win = other,
              start_col = scol,
              start_row = srow,
              start_height = height,
              other_start_height = vim.api.nvim_win_get_height(other),
            }
          end
        end
      end
    end
  end

  return nil
end

function M.is_dragging()
  return M._drag ~= nil and (M._drag.exact or M._drag.engaged)
end

---Synchronously update split-dependent floating UI elements (satellite scrollbars,
---treesitter-context sticky headers, dropbar winbars, and horizontal leftcol)
---before redrawing during a live mouse drag.
function M.sync_split_ui()
  local tiled_wins = get_tiled_windows()

  -- 1. If widening a nowrap window allows the cursor to fit without horizontal
  -- scrolling, reset leftcol to 0 so the left edge of the code is visible again.
  for _, w in ipairs(tiled_wins) do
    if not vim.wo[w].wrap then
      local info = vim.fn.getwininfo(w)[1]
      if info and (info.leftcol or 0) > 0 then
        local text_cols = math.max(1, info.width - (info.textoff or 0))
        local cur_col = vim.api.nvim_win_get_cursor(w)[2]
        if cur_col + 1 <= text_cols then
          pcall(vim.api.nvim_win_call, w, function()
            local view = vim.fn.winsaveview()
            if (view.leftcol or 0) > 0 then
              view.leftcol = 0
              vim.fn.winrestview(view)
            end
          end)
        end
      end
    end
  end

  -- 2. Synchronously reposition and redraw satellite.nvim scrollbar floats
  local sat = package.loaded["satellite.view"]
  if sat and sat.enabled and sat.enabled() and sat.refresh_bars then
    pcall(sat.refresh_bars)
  end

  -- 3. Synchronously resize nvim-treesitter-context floating headers to match split width
  for _, fw in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_is_valid(fw) then
      if vim.w[fw].treesitter_context then
        local cfg = vim.api.nvim_win_get_config(fw)
        if cfg.relative == "win" and cfg.win and vim.api.nvim_win_is_valid(cfg.win) then
          local pw = vim.api.nvim_win_get_width(cfg.win)
          local info = vim.fn.getwininfo(cfg.win)[1]
          local gw = info and info.textoff or 0
          local tw = math.max(1, pw - gw)
          if cfg.width ~= tw or cfg.col ~= gw then
            pcall(vim.api.nvim_win_set_config, fw, {
              win = cfg.win,
              relative = "win",
              row = cfg.row or 0,
              col = gw,
              width = tw,
              height = cfg.height,
            })
          end
        end
      elseif vim.w[fw].treesitter_context_line_number then
        local cfg = vim.api.nvim_win_get_config(fw)
        if cfg.relative == "win" and cfg.win and vim.api.nvim_win_is_valid(cfg.win) then
          local info = vim.fn.getwininfo(cfg.win)[1]
          local gw = math.max(1, info and info.textoff or 1)
          if cfg.width ~= gw then
            pcall(vim.api.nvim_win_set_config, fw, {
              win = cfg.win,
              relative = "win",
              row = cfg.row or 0,
              col = 0,
              width = gw,
              height = cfg.height,
            })
          end
        end
      end
    end
  end

  -- 4. Synchronously refresh dropbar.nvim breadcrumb winbars for all tiled splits
  local db = package.loaded["dropbar.utils"]
  if db and db.bar and db.bar.exec then
    for _, w in ipairs(tiled_wins) do
      pcall(db.bar.exec, "update", { win = w })
    end
  end

  -- 5. Invalidate cached fold virtual text widths in nvim-ufo so folded lines
  -- re-truncate cleanly to the new split width on the next redraw
  local ufo_fold = package.loaded["ufo.fold"]
  if ufo_fold and ufo_fold.get then
    for _, w in ipairs(tiled_wins) do
      local ok_b, buf = pcall(vim.api.nvim_win_get_buf, w)
      if ok_b and buf then
        local fb = ufo_fold.get(buf)
        if fb and fb.foldedLineCount and fb.foldedLineCount > 0 and fb.foldedLines then
          for _, fl in pairs(fb.foldedLines) do
            if type(fl) == "table" then
              fl.virtText = nil
            end
          end
        end
      end
    end
  end
end

local function handle_key(key, typed)
  local raw_key = (typed and typed ~= "") and typed or key
  local key_name = keycodes[raw_key] or keycodes[key]
  if not key_name then return end
  local mp = vim.fn.getmousepos()

  if key_name == "<LeftMouse>" then
    local sep = M.find_separator(mp)
    if sep then
      M._drag = sep
      if sep.exact then
        sep.engaged = true
        return ""
      end
    else
      M._drag = nil
    end
  elseif key_name == "<LeftDrag>" and M._drag then
    local drag = M._drag
    local dx = (mp.screencol or drag.start_col) - drag.start_col
    local dy = (mp.screenrow or drag.start_row) - drag.start_row

    if not drag.engaged then
      if drag.type == "vertical" then
        if math.abs(dx) >= 1 and math.abs(dx) >= math.abs(dy) then
          drag.engaged = true
        elseif math.abs(dy) >= 2 and math.abs(dx) == 0 then
          M._drag = nil
          return
        else
          return ""
        end
      elseif drag.type == "horizontal" then
        if math.abs(dy) >= 1 and math.abs(dy) >= math.abs(dx) then
          drag.engaged = true
        elseif math.abs(dx) >= 2 and math.abs(dy) == 0 then
          M._drag = nil
          return
        else
          return ""
        end
      end
    end

    if drag.type == "vertical" and vim.api.nvim_win_is_valid(drag.win) then
      local new_width = math.max(10, drag.start_width + dx)
      local before_w = vim.api.nvim_win_get_width(drag.win)
      local changed = false
      if before_w ~= new_width then
        pcall(vim.api.nvim_win_set_width, drag.win, new_width)
        changed = vim.api.nvim_win_get_width(drag.win) ~= before_w
      end
      if not changed and drag.other_win and vim.api.nvim_win_is_valid(drag.other_win) and drag.other_start_width then
        local other_new = math.max(10, drag.other_start_width - dx)
        local other_before = vim.api.nvim_win_get_width(drag.other_win)
        if other_before ~= other_new then
          pcall(vim.api.nvim_win_set_width, drag.other_win, other_new)
          changed = vim.api.nvim_win_get_width(drag.other_win) ~= other_before
        end
      end
      if changed then
        M.sync_split_ui()
        pcall(vim.cmd, "redraw")
      end
      return ""
    elseif drag.type == "horizontal" and vim.api.nvim_win_is_valid(drag.win) then
      local new_height = math.max(3, drag.start_height + dy)
      local before_h = vim.api.nvim_win_get_height(drag.win)
      local changed = false
      if before_h ~= new_height then
        pcall(vim.api.nvim_win_set_height, drag.win, new_height)
        changed = vim.api.nvim_win_get_height(drag.win) ~= before_h
      end
      if not changed and drag.other_win and vim.api.nvim_win_is_valid(drag.other_win) and drag.other_start_height then
        local other_new = math.max(3, drag.other_start_height - dy)
        local other_before = vim.api.nvim_win_get_height(drag.other_win)
        if other_before ~= other_new then
          pcall(vim.api.nvim_win_set_height, drag.other_win, other_new)
          changed = vim.api.nvim_win_get_height(drag.other_win) ~= other_before
        end
      end
      if changed then
        M.sync_split_ui()
        pcall(vim.cmd, "redraw")
      end
      return ""
    end
  elseif key_name == "<LeftRelease>" and M._drag then
    local was_engaged = M._drag.engaged
    M._drag = nil
    if was_engaged then
      M.sync_split_ui()
      pcall(vim.api.nvim_exec_autocmds, "WinResized", { modeline = false })
      pcall(vim.api.nvim_exec_autocmds, "WinScrolled", { modeline = false })
      pcall(vim.cmd, "redraw")
      return ""
    end
  end
end

function M.setup()
  if M._namespace then return end
  M._namespace = vim.api.nvim_create_namespace("SplitMouseDrag")
  vim.on_key(handle_key, M._namespace)

  local group = vim.api.nvim_create_augroup("SplitMouseDragCleanup", { clear = true })
  vim.api.nvim_create_autocmd("WinResized", {
    group = group,
    callback = function()
      M.sync_split_ui()
    end,
  })
  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = group,
    callback = function()
      if M._namespace then
        vim.on_key(nil, M._namespace)
        M._namespace = nil
      end
      M._drag = nil
    end,
  })
end

return M
