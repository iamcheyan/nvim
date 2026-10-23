-- Shared statusline popup menus. Keep focus in the source editor while the
-- menu owns temporary navigation mappings and its floating window.
local M = {}

local function get_active_editor_win()
  local id = tonumber(vim.g.statusline_winid)
  if id and id > 0 and vim.api.nvim_win_is_valid(id) and id ~= _G._statusline_menu_win then
    return id
  end
  local cur = vim.api.nvim_get_current_win()
  if cur ~= _G._statusline_menu_win then
    return cur
  end
  for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if w ~= _G._statusline_menu_win and vim.api.nvim_win_is_valid(w) then
      local b = vim.api.nvim_win_get_buf(w)
      if vim.bo[b].buftype == "" then
        return w
      end
    end
  end
  return cur
end

local function get_comp_col(click_name)
  if not click_name then return nil end
  local ok, heirline = pcall(require, "heirline")
  if not ok or not heirline.eval_statusline then return nil end
  local raw_str = heirline.eval_statusline()
  local needle = "%@v:lua." .. click_name .. "@"
  local p = raw_str:find(needle, 1, true)
  if not p then return nil end
  local marker = "|||TARGET|||"
  local marker_str = raw_str:sub(1, p - 1) .. marker .. raw_str:sub(p + #needle)
  local ev = vim.api.nvim_eval_statusline(marker_str, { highlights = false })
  local idx = ev.str:find(marker, 1, true)
  if idx then
    return vim.fn.strdisplaywidth(ev.str:sub(1, idx - 1))
  end
  return nil
end

local function save_and_set_buffer_maps(buf, handlers)
  local saved = {}
  for lhs, callback in pairs(handlers) do
    saved[lhs] = {}
    for _, mapping in ipairs(vim.api.nvim_buf_get_keymap(buf, "n")) do
      if mapping.lhs == lhs then table.insert(saved[lhs], mapping) end
    end
    vim.keymap.set("n", lhs, callback, {
      buffer = buf,
      nowait = true,
      silent = true,
      desc = "Statusline menu navigation",
    })
  end
  _G._statusline_menu_source_maps = { buf = buf, saved = saved }
end

local function restore_buffer_maps()
  local state = _G._statusline_menu_source_maps
  _G._statusline_menu_source_maps = nil
  if not state or not vim.api.nvim_buf_is_valid(state.buf) then return end
  for lhs, mappings in pairs(state.saved) do
    pcall(vim.keymap.del, "n", lhs, { buffer = state.buf })
    for _, mapping in ipairs(mappings) do
      local rhs = mapping.callback or mapping.rhs
      if rhs ~= nil then
        pcall(vim.keymap.set, "n", mapping.lhs or lhs, rhs, {
          buffer = state.buf,
          expr = mapping.expr == true or mapping.expr == 1,
          nowait = mapping.nowait == true or mapping.nowait == 1,
          silent = mapping.silent == true or mapping.silent == 1,
          remap = not (mapping.noremap == true or mapping.noremap == 1),
          desc = mapping.desc,
        })
      end
    end
  end
end

local function open_statusline_menu(menu_id, items, click_name)
  if _G._statusline_menu_id == menu_id and _G._statusline_menu_close then
    _G._statusline_menu_close()
    return
  end

  if _G._statusline_menu_close then
    _G._statusline_menu_close()
  elseif _G._statusline_menu_win and vim.api.nvim_win_is_valid(_G._statusline_menu_win) then
    pcall(vim.api.nvim_win_close, _G._statusline_menu_win, true)
  end
  _G._active_statusline_menu = menu_id
  local saved_mousemove = vim.o.mousemoveevent
  vim.o.mousemoveevent = true
  -- If window creation throws before close() exists, put the option back.
  -- Native confirm treats MouseMove as an invalid answer.
  vim.schedule(function()
    if not _G._statusline_menu_close then
      vim.o.mousemoveevent = saved_mousemove
    end
  end)

  local comp_col = get_comp_col(click_name)
  if not comp_col then
    if click_name == "heirline_git_menu" then
      comp_col = 1
    elseif click_name == "heirline_file_actions" then
      comp_col = 15
    else
      local mouse_pos = vim.fn.getmousepos()
      comp_col = (mouse_pos and mouse_pos.screencol and mouse_pos.screencol > 0) and mouse_pos.screencol or 10
    end
  end

  -- Keep menu state separate from statusline styling: opening a menu
  -- must not recolor the clicked segment or any other bar component.
  _G._statusline_menu_id = menu_id

  local display_lines = {}
  local actions = {}
  local max_len = 24

  for _, item in ipairs(items) do
    if item.separator then
      table.insert(display_lines, "  ──────────────────────────────")
      table.insert(actions, false)
    else
      local line = string.format("  %s  %s", item.icon or "•", item.label)
      local len = vim.fn.strdisplaywidth(line)
      if len > max_len then
        max_len = len
      end
      table.insert(display_lines, line)
      table.insert(actions, item.action)
    end
  end

  local win_width = math.min(max_len + 4, vim.o.columns - 2)

  local final_lines = {}
  for _, text in ipairs(display_lines) do
    local visual_len = vim.fn.strdisplaywidth(text)
    local pad_len = math.max(0, win_width - visual_len)
    table.insert(final_lines, text .. string.rep(" ", pad_len))
  end

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, final_lines)
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].filetype = "statusline_menu"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].modifiable = false

  local ns = vim.api.nvim_create_namespace("statusline_menu")
  for i, act in ipairs(actions) do
    if act == false then
      vim.api.nvim_buf_add_highlight(buf, ns, "FreshMenuMuted", i - 1, 0, -1)
    end
  end

  local col = comp_col
  if col + win_width > vim.o.columns - 1 then
    col = math.max(0, vim.o.columns - win_width - 1)
  end

  local statusline_row = vim.o.lines - vim.o.cmdheight - 1
  local win_height = math.min(#final_lines, math.max(1, statusline_row - 2))
  local row = math.max(0, statusline_row - win_height - 2)

  local src_win = get_active_editor_win()
  local src_buf = vim.api.nvim_win_get_buf(src_win)
  local win = vim.api.nvim_open_win(buf, false, {
    relative = "editor",
    row = row,
    col = col,
    width = win_width,
    height = win_height,
    style = "minimal",
    border = "single",
    zindex = 250,
  })

  vim.wo[win].cursorline = true
  vim.wo[win].cursorcolumn = false
  vim.wo[win].signcolumn = "no"
  vim.wo[win].winbar = ""
  vim.wo[win].scrolloff = 0
  vim.wo[win].sidescrolloff = 0
  vim.wo[win].wrap = false
  vim.wo[win].winhighlight = "NormalFloat:FreshMenu,FloatBorder:FreshMenuBorder,CursorLine:FreshMenuSelected"

  _G._statusline_menu_win = win
  _G._statusline_menu_buf = buf

  local closed = false
  local function close()
    if closed then return end
    closed = true
    if win and vim.api.nvim_win_is_valid(win) then
      pcall(vim.api.nvim_win_close, win, true)
    end
    _G._statusline_menu_win = nil
    _G._statusline_menu_buf = nil
    _G._statusline_menu_id = nil
    _G._active_statusline_menu = nil
    _G._statusline_menu_close = nil
    restore_buffer_maps()
    vim.o.mousemoveevent = saved_mousemove
    if _G._statusline_menu_autocmd then
      pcall(vim.api.nvim_del_augroup_by_id, _G._statusline_menu_autocmd)
      _G._statusline_menu_autocmd = nil
    end
    local feedback = require("config.bar_feedback")
    if feedback.on_redraw then feedback.on_redraw() end
    pcall(vim.cmd, "redrawstatus")
  end
  _G._statusline_menu_close = close

  local function execute_current()
    local ok, cur = pcall(vim.api.nvim_win_get_cursor, win)
    local line_idx = (ok and cur) and cur[1] or 1
    close()
    local act = actions[line_idx]
    if type(act) == "function" then
      vim.schedule(act)
    end
  end

  local function move_selection(delta)
    if not vim.api.nvim_win_is_valid(win) then return end
    local row = vim.api.nvim_win_get_cursor(win)[1] + delta
    while row >= 1 and row <= #final_lines do
      if type(actions[row]) == "function" then
        vim.api.nvim_win_set_cursor(win, { row, 0 })
        return
      end
      row = row + delta
    end
  end

  local function mouse_hover()
    local mp = vim.fn.getmousepos()
    if mp and mp.winid == win and type(actions[mp.line]) == "function" then
      vim.api.nvim_win_set_cursor(win, { mp.line, 0 })
    end
  end

  local function mouse_select()
    local mp = vim.fn.getmousepos()
    if mp and mp.winid == win and mp.line >= 1 and mp.line <= #final_lines then
      if type(actions[mp.line]) ~= "function" then return end
      vim.api.nvim_win_set_cursor(win, { mp.line, 0 })
      execute_current()
    else
      close()
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<LeftMouse>", true, false, true), "m", false)
    end
  end

  local function mouse_scroll(delta, key)
    local mp = vim.fn.getmousepos()
    local pos = vim.api.nvim_win_get_position(win)
    local inside = mp and mp.screenrow >= pos[1] + 1 and mp.screenrow <= pos[1] + win_height
      and mp.screencol >= pos[2] + 1 and mp.screencol <= pos[2] + win_width
    if inside then
      move_selection(delta)
    else
      close()
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(key, true, false, true), "m", false)
    end
  end

  local kmopts = { buffer = buf, nowait = true, silent = true }
  vim.keymap.set("n", "<CR>", execute_current, kmopts)
  vim.keymap.set("n", "<Space>", execute_current, kmopts)
  vim.keymap.set("n", "<MouseMove>", mouse_hover, kmopts)
  vim.keymap.set("n", "<LeftMouse>", mouse_select, kmopts)
  vim.keymap.set("n", "<ScrollWheelUp>", function() mouse_scroll(-1, "<ScrollWheelUp>") end, kmopts)
  vim.keymap.set("n", "<ScrollWheelDown>", function() mouse_scroll(1, "<ScrollWheelDown>") end, kmopts)
  vim.keymap.set("n", "q", close, kmopts)
  vim.keymap.set("n", "<Esc>", close, kmopts)

  save_and_set_buffer_maps(src_buf, {
    ["<Up>"] = function() move_selection(-1) end,
    ["k"] = function() move_selection(-1) end,
    ["<Down>"] = function() move_selection(1) end,
    ["j"] = function() move_selection(1) end,
    ["<CR>"] = execute_current,
    ["<Space>"] = execute_current,
    ["q"] = close,
    ["<Esc>"] = close,
    ["<MouseMove>"] = mouse_hover,
    ["<LeftMouse>"] = mouse_select,
    ["<ScrollWheelUp>"] = function() mouse_scroll(-1, "<ScrollWheelUp>") end,
    ["<ScrollWheelDown>"] = function() mouse_scroll(1, "<ScrollWheelDown>") end,
  })

  _G._statusline_menu_autocmd = vim.api.nvim_create_augroup("HeirlineStatuslineMenuLifetime", { clear = true })
  vim.api.nvim_create_autocmd({ "BufLeave", "WinLeave", "CursorMoved", "InsertEnter" }, {
    group = _G._statusline_menu_autocmd,
    buffer = src_buf,
    callback = close,
  })
  vim.api.nvim_create_autocmd("WinClosed", {
    group = _G._statusline_menu_autocmd,
    pattern = tostring(win),
    callback = close,
  })
end

M.open = open_statusline_menu
M.active_editor_win = get_active_editor_win

function M.close()
  if _G._statusline_menu_close then _G._statusline_menu_close() end
end

return M
