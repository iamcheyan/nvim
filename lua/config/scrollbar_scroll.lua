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
  -- 2. Is the mouse hovering on the rightmost column of an ordinary window?
  if cfg and cfg.relative == "" and not cfg.external then
    local width = vim.api.nvim_win_get_width(mp.winid)
    if mp.wincol and mp.wincol >= width then
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

  vim.api.nvim_win_set_cursor(target_win, { target_line, 0 })
  vim.api.nvim_win_call(target_win, function()
    vim.cmd("normal! zz")
  end)
  local ok_sat, sat = pcall(require, "satellite.view")
  if ok_sat and sat.enabled() then
    sat.schedule_refresh()
  end
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

  local kmopts = { silent = true }
  vim.keymap.set({ "n", "i", "v", "x" }, "<ScrollWheelDown>", function() scroll_win(1) end, kmopts)
  vim.keymap.set({ "n", "i", "v", "x" }, "<ScrollWheelUp>", function() scroll_win(-1) end, kmopts)

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

  vim.on_key(function(key)
    local action = keycodes[key]
    if not action then return end
    local mp = vim.fn.getmousepos()
    if action == "press" then
      local is_bar, win = is_scrollbar_hover(mp)
      if is_bar then
        M._dragging_win = win
        scrollbar_jump(win, mp)
        return ""
      else
        M._dragging_win = nil
      end
    elseif action == "drag" and M._dragging_win then
      if vim.api.nvim_win_is_valid(M._dragging_win) then
        scrollbar_jump(M._dragging_win, mp)
        return ""
      end
    elseif action == "release" and M._dragging_win then
      M._dragging_win = nil
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
