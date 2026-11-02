local M = {
  _namespace = nil,
  _dragging_win = nil,
}

local function is_scrollbar_hover(mp)
  if not mp or not mp.winid or mp.winid <= 0 or not vim.api.nvim_win_is_valid(mp.winid) then
    return false, vim.api.nvim_get_current_win()
  end
  local cfg = vim.api.nvim_win_get_config(mp.winid)
  -- 1. Is mp.winid the satellite floating window itself?
  if cfg and cfg.relative == "win" and cfg.win and vim.api.nvim_win_is_valid(cfg.win) then
    -- Relative floats include menus and previews. Only satellite's own view
    -- carries these window properties and belongs to a registered scrollbar.
    local satellite = package.loaded["satellite.view"]
    local props = satellite and satellite.get_props and satellite.get_props(cfg.win)
    if cfg.focusable == false and props and vim.w[mp.winid].width == props.width
      and vim.w[mp.winid].height == props.height and vim.w[mp.winid].col == props.col then
      return true, cfg.win
    end
  end
  -- 2. Is the mouse hovering on the rightmost column inside an ordinary window?
  -- Exclude window separators (where mp.wincol == width + 1 or mp.line == 0).
  if cfg and cfg.relative == "" and not cfg.external then
    local width = vim.api.nvim_win_get_width(mp.winid)
    local height = vim.api.nvim_win_get_height(mp.winid)
    if mp.wincol and mp.wincol == width and (mp.line or 0) > 0
      and (mp.winrow or 0) >= 1 and (mp.winrow or 0) <= height then
      return true, mp.winid
    end
  end
  return false, mp.winid
end

local function scrollbar_jump(target_win, mp)
  if not target_win or not vim.api.nvim_win_is_valid(target_win) then return end
  local buf = vim.api.nvim_win_get_buf(target_win)
  local line_count = vim.api.nvim_buf_line_count(buf)
  local winheight = vim.api.nvim_win_get_height(target_win)
  if vim.wo[target_win].winbar ~= "" then
    winheight = math.max(1, winheight - 1)
  end
  local row = math.max(1, math.min(winheight, mp.winrow or 1))
  local ratio = (row - 1) / math.max(1, winheight - 1)
  local target_line = math.max(1, math.min(line_count, math.floor(ratio * (line_count - 1) + 1)))

  local cur_line = vim.api.nvim_win_get_cursor(target_win)[1]
  if cur_line == target_line then return end
  vim.api.nvim_win_set_cursor(target_win, { target_line, 0 })
  vim.api.nvim_win_call(target_win, function()
    vim.cmd("normal! zz")
  end)
  local ok_sat, sat = pcall(require, "satellite.view")
  if ok_sat and sat.enabled() then
    sat.schedule_refresh()
  end
  pcall(vim.cmd, "redraw")
end

local function scroll_win(direction)
  local mp = vim.fn.getmousepos()
  local _, win = is_scrollbar_hover(mp)
  if not win or not vim.api.nvim_win_is_valid(win) then
    win = vim.api.nvim_get_current_win()
  end
  local lines = 3
  local ok_opt, m_scroll = pcall(function() return vim.opt.mousescroll:get() end)
  if ok_opt and type(m_scroll) == "string" then
    local v = m_scroll:match("ver:(%d+)")
    if v then lines = tonumber(v) or 3 end
  end
  vim.api.nvim_win_call(win, function()
    if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "dropbar_menu" then
      -- Ctrl-E permits the last entry to reach the top, leaving empty rows.
      -- Menus stop as soon as the final page is fully visible.
      local view = vim.fn.winsaveview()
      local height = vim.api.nvim_win_get_height(win)
      local count = vim.api.nvim_buf_line_count(vim.api.nvim_win_get_buf(win))
      local last_top = math.max(1, count - height + 1)
      local top = math.max(1, math.min(last_top, view.topline + direction * lines))
      view.topline = top
      view.lnum = math.max(top, math.min(top + height - 1, view.lnum))
      view.skipcol = 0
      vim.fn.winrestview(view)
      return
    end
    local cmd = direction > 0 and ("normal! " .. lines .. "\x05") or ("normal! " .. lines .. "\x19")
    vim.cmd(cmd)
  end)
  local ok_sat, sat = pcall(require, "satellite.view")
  if ok_sat and sat.enabled() then
    sat.schedule_refresh()
  end
end

function M.setup()
  if M._namespace then return end

  -- Ensure satellite's blocking <LeftMouse> mapping is removed if present
  pcall(vim.keymap.del, { "n", "v", "o", "i" }, "<LeftMouse>")

  -- Keep satellite scrollbars synced on WinResized (satellite only listens to WinScrolled/VimResized)
  vim.api.nvim_create_autocmd("WinResized", {
    group = vim.api.nvim_create_augroup("ScrollBarWinResizedSync", { clear = true }),
    callback = function()
      local ok_sat, sat = pcall(require, "satellite.view")
      if ok_sat and sat.enabled and sat.enabled() and sat.refresh_bars then
        pcall(sat.refresh_bars)
      end
    end,
  })

  local kmopts = { silent = true }
  vim.keymap.set({ "n", "i", "v", "x" }, "<ScrollWheelDown>", function()
    local mouse=vim.fn.getmousepos()
    local win=mouse and mouse.winid
    if win and win>0 and vim.api.nvim_win_is_valid(win)
      and vim.bo[vim.api.nvim_win_get_buf(win)].filetype=='dropbar_menu' then return end
    scroll_win(1)
  end, kmopts)
  vim.keymap.set({ "n", "i", "v", "x" }, "<ScrollWheelUp>", function()
    local mouse=vim.fn.getmousepos()
    local win=mouse and mouse.winid
    if win and win>0 and vim.api.nvim_win_is_valid(win)
      and vim.bo[vim.api.nvim_win_get_buf(win)].filetype=='dropbar_menu' then return end
    scroll_win(-1)
  end, kmopts)

  -- Native horizontal wheel scrolling can move every menu label off screen.
  -- Pass the original key through for ordinary editor windows.
  for _, key in ipairs({ "<ScrollWheelLeft>", "<ScrollWheelRight>" }) do
    vim.keymap.set({ "n", "i", "v", "x" }, key, function()
      local _, win = is_scrollbar_hover(vim.fn.getmousepos())
      if win and vim.api.nvim_win_is_valid(win)
        and vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "dropbar_menu" then
        return ""
      end
      return key
    end, { silent = true, expr = true })
  end

  M._namespace = vim.api.nvim_create_namespace("ScrollBarMouseEvents")
  local keycodes = {
    [vim.api.nvim_replace_termcodes("<LeftMouse>", true, false, true)] = "press",
    [vim.api.nvim_replace_termcodes("<LeftDrag>", true, false, true)] = "drag",
    [vim.api.nvim_replace_termcodes("<LeftRelease>", true, false, true)] = "release",
  }

  vim.on_key(function(key, typed)
    local raw_key = (typed and typed ~= "") and typed or key
    local action = keycodes[raw_key] or keycodes[key]
    if not action then return end
    local split_drag = package.loaded["config.split_mouse_drag"]
    if split_drag and split_drag.is_dragging and split_drag.is_dragging() then
      M._dragging_win = nil
      M._pending_jump_mp = nil
      return
    end
    local mp = vim.fn.getmousepos()
    if action == "press" then
      local is_bar, win = is_scrollbar_hover(mp)
      if is_bar then
        M._dragging_win = win
        M._press_col = mp.screencol
        M._press_row = mp.screenrow
        -- If this scrollbar is immediately adjacent to a split separator, defer the jump
        -- until vertical drag or release so horizontal split dragging never jumps the buffer.
        if split_drag and split_drag.find_separator and split_drag.find_separator(mp) then
          M._pending_jump_mp = mp
        else
          M._pending_jump_mp = nil
          scrollbar_jump(win, mp)
        end
        return ""
      else
        M._dragging_win = nil
        M._pending_jump_mp = nil
      end
    elseif action == "drag" and M._dragging_win then
      if M._press_col and M._press_row and mp.screencol and mp.screenrow then
        local dx = math.abs(mp.screencol - M._press_col)
        local dy = math.abs(mp.screenrow - M._press_row)
        if dx >= 1 and dx >= dy and split_drag and split_drag.is_dragging and split_drag.is_dragging() then
          M._dragging_win = nil
          M._pending_jump_mp = nil
          return
        end
        if dy == 0 and dx == 0 then
          return ""
        end
      end
      M._pending_jump_mp = nil
      if vim.api.nvim_win_is_valid(M._dragging_win) then
        scrollbar_jump(M._dragging_win, mp)
        return ""
      end
    elseif action == "release" and M._dragging_win then
      if M._pending_jump_mp and vim.api.nvim_win_is_valid(M._dragging_win) then
        scrollbar_jump(M._dragging_win, M._pending_jump_mp)
      end
      M._dragging_win = nil
      M._pending_jump_mp = nil
      return ""
    end
  end, M._namespace)

  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = vim.api.nvim_create_augroup("ScrollBarMouseEventsCleanup", { clear = true }),
    callback = function()
      if M._namespace then
        vim.on_key(nil, M._namespace)
        M._namespace = nil
      end
      M._dragging_win = nil
    end,
  })
end

return M
