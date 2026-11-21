-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- Keep LazyVim default startup behavior:
-- restore session when available; otherwise show dashboard.

-- Closing the last named file leaves Neovim on its unnamed replacement buffer.
-- :enew / <leader>fn does not delete a named buffer, so a scratch buffer stays.
local dashboard_after_file_delete = false
local dashboard_group = vim.api.nvim_create_augroup("DashboardOnLastFile", { clear = true })
vim.api.nvim_create_autocmd("BufDelete", {
  group = dashboard_group,
  callback = function(args)
    local buf = args.buf
    if vim.bo[buf].buftype == "" and vim.api.nvim_buf_get_name(buf) ~= "" then
      dashboard_after_file_delete = true
    end
  end,
})
vim.api.nvim_create_autocmd("BufEnter", {
  group = dashboard_group,
  callback = function(args)
    vim.schedule(function()
      if not dashboard_after_file_delete then return end
      dashboard_after_file_delete = false
      if not vim.api.nvim_buf_is_valid(args.buf) or vim.api.nvim_get_current_buf() ~= args.buf then
        return
      end
      if vim.bo[args.buf].buftype ~= "" or vim.bo[args.buf].filetype == "dashboard" then
        return
      end
      if vim.bo[args.buf].modified or vim.api.nvim_buf_get_name(args.buf) ~= "" then
        return
      end
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if buf ~= args.buf and vim.api.nvim_buf_is_loaded(buf)
          and vim.bo[buf].buftype == "" and vim.api.nvim_buf_get_name(buf) ~= "" then
          return
        end
      end
      pcall(vim.cmd, "Dashboard")
    end)
  end,
})

local function set_cmdline_highlights()
  local normal = vim.api.nvim_get_hl(0, { name = "Normal", link = false })
  local bg, fg = normal.bg, normal.fg

  vim.api.nvim_set_hl(0, "MsgArea", { bg = bg, fg = fg })
  vim.api.nvim_set_hl(0, "Cmdline", { bg = bg, fg = fg })
  vim.api.nvim_set_hl(0, "CmdLine", { bg = bg, fg = fg })
  vim.api.nvim_set_hl(0, "CmdLinePrompt", { bg = bg, fg = fg })
  -- WinSeparator and VertSplit stay theme-owned.  Overriding either field
  -- here would erase the active theme's UI surface semantics.
end

vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("CmdlineHighlights", { clear = true }),
  callback = set_cmdline_highlights,
})

set_cmdline_highlights()

-- swapfile is off for new buffers. An old swap whose process is gone can be
-- edited. A live process still gets Neovim's prompt.
vim.api.nvim_create_autocmd("SwapExists", {
  group = vim.api.nvim_create_augroup("HandleSwapExists", { clear = true }),
  callback = function()
    local info = vim.fn.swapinfo(vim.v.swapname)
    local pid = info and info.pid or 0
    if type(pid) == "number" and pid > 0 then
      vim.fn.system({ "ps", "-p", tostring(pid) })
      if vim.v.shell_error == 0 then
        return
      end
    end
    vim.v.swapchoice = "e"
  end,
})

-- Window-isolated focus behaviors:
-- When a file is split into multiple windows, each split behaves like an
-- independent viewport. Inactive splits hide cursorline and switch to absolute
-- line numbers so the active window is immediately visually distinct.
local function is_standard_window(win)
  if not win or not vim.api.nvim_win_is_valid(win) then
    return false
  end
  local config = vim.api.nvim_win_get_config(win)
  if config.relative and config.relative ~= "" then
    return false
  end
  local buf = vim.api.nvim_win_get_buf(win)
  if not vim.api.nvim_buf_is_valid(buf) then
    return false
  end
  local buftype = vim.bo[buf].buftype
  if buftype == "nofile" or buftype == "terminal" or buftype == "prompt" or buftype == "quickfix" then
    return false
  end
  local filetype = vim.bo[buf].filetype
  if filetype == "dashboard" or filetype == "neo-tree" or filetype == "Trouble" then
    return false
  end
  return true
end

local function update_split_focus()
  local curwin = vim.api.nvim_get_current_win()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if is_standard_window(win) and not vim.wo[win].diff then
      local is_active = (win == curwin)
      vim.wo[win].cursorline = is_active
      if vim.wo[win].number then
        vim.wo[win].relativenumber = is_active
      end
    end
  end
end

local split_focus_group = vim.api.nvim_create_augroup("SplitWindowFocus", { clear = true })

vim.api.nvim_create_autocmd({ "WinEnter", "BufEnter", "FocusGained", "WinNew" }, {
  group = split_focus_group,
  callback = update_split_focus,
})

vim.api.nvim_create_autocmd({ "WinLeave", "BufLeave", "FocusLost" }, {
  group = split_focus_group,
  callback = function()
    local win = vim.api.nvim_get_current_win()
    if is_standard_window(win) and not vim.wo[win].diff then
      vim.wo[win].cursorline = false
      if vim.wo[win].number then
        vim.wo[win].relativenumber = false
      end
    end
  end,
})

-- Innermost surrounding pair highlight (`()`, `[]`, `{}`, `<>`, `""`, `''`, ````):
-- Highlights the content inside the nearest pair enclosing the cursor with
-- `MatchBackground`, while ignoring multi-line outer functions/blocks and
-- word pairs (`if`/`fi`/`then`/`else`).
local bracket_ns = vim.api.nvim_create_namespace("InnerBracketHighlight")
local bracket_pairs = {
  { "(", ")", "(", ")" },
  { "[", "]", "\\[", "\\]" },
  { "{", "}", "{", "}" },
}
local quote_chars = { '"', "'", "`" }

local function find_quote_pair(line, col, q)
  local positions = {}
  local i = 1
  local len = #line
  while i <= len do
    local c = line:sub(i, i)
    if c == "\\" then
      i = i + 2
    else
      if c == q then
        positions[#positions + 1] = i
      end
      i = i + 1
    end
  end
  for k = 1, #positions - 1, 2 do
    local s, e = positions[k], positions[k + 1]
    if col >= s and col <= e then
      return s, e
    end
  end
end

local function find_angle_pair(line, col)
  -- Match `<...>` on the current line while skipping comparison/shift/arrow
  -- operators (`<=`, `>=`, `<<`, `>>`, `->`, `=>`, `< ` or ` >`).
  local stack = {}
  local best_s, best_e
  local best_len = math.huge
  for i = 1, #line do
    local c = line:sub(i, i)
    if c == "<" then
      local next_c = line:sub(i + 1, i + 1)
      local prev_c = i > 1 and line:sub(i - 1, i - 1) or ""
      if next_c ~= "" and next_c ~= " " and next_c ~= "\t" and next_c ~= "=" and next_c ~= "<" and prev_c ~= "<" then
        stack[#stack + 1] = i
      end
    elseif c == ">" and #stack > 0 then
      local prev_c = i > 1 and line:sub(i - 1, i - 1) or ""
      local next_c = line:sub(i + 1, i + 1)
      if prev_c ~= " " and prev_c ~= "\t" and prev_c ~= "-" and prev_c ~= "=" and prev_c ~= ">" and next_c ~= ">" and next_c ~= "=" then
        local s = table.remove(stack)
        if col >= s and col <= i and (i - s) < best_len then
          best_s, best_e = s, i
          best_len = i - s
        end
      end
    end
  end
  return best_s, best_e
end

local function clear_bracket_highlight(buf)
  if buf and vim.api.nvim_buf_is_valid(buf) then
    vim.api.nvim_buf_clear_namespace(buf, bracket_ns, 0, -1)
  end
end

local function update_bracket_highlight()
  local win = vim.api.nvim_get_current_win()
  if not is_standard_window(win) then
    return
  end
  local buf = vim.api.nvim_win_get_buf(win)
  clear_bracket_highlight(buf)

  local mode = vim.api.nvim_get_mode().mode
  if mode:find("^[vV\22]") then
    return
  end

  local cursor = vim.api.nvim_win_get_cursor(win)
  local row, col = cursor[1], cursor[2] + 1
  local line = vim.api.nvim_buf_get_lines(buf, row - 1, row, false)[1] or ""
  local ch = line:sub(col, col)

  local best_open, best_close
  local best_span = math.huge
  local stopline_top = math.max(1, row - 8)
  local stopline_bot = math.min(vim.api.nvim_buf_line_count(buf), row + 8)

  for _, pair in ipairs(bracket_pairs) do
    local open_ch, close_ch, pat_open, pat_close = pair[1], pair[2], pair[3], pair[4]
    local open_flags = (ch == open_ch) and "bcnW" or "bnW"
    local close_flags = (ch == close_ch) and "cnW" or "nW"

    local open_pos = vim.fn.searchpairpos(pat_open, "", pat_close, open_flags, "0", stopline_top, 15)
    if open_pos[1] > 0 then
      local close_pos = vim.fn.searchpairpos(pat_open, "", pat_close, close_flags, "0", stopline_bot, 15)
      if close_pos[1] > 0 then
        local span = (close_pos[1] - open_pos[1]) * 10000 + (close_pos[2] - open_pos[2])
        -- Only highlight compact expressions (single line or up to 3 lines),
        -- never whole functions or control-flow blocks.
        if span >= 0 and (close_pos[1] - open_pos[1]) <= 2 and span < best_span then
          best_span = span
          best_open = open_pos
          best_close = close_pos
        end
      end
    end
  end

  for _, q in ipairs(quote_chars) do
    local s, e = find_quote_pair(line, col, q)
    if s and e then
      local span = e - s
      if span >= 0 and span < best_span then
        best_span = span
        best_open = { row, s }
        best_close = { row, e }
      end
    end
  end

  local as, ae = find_angle_pair(line, col)
  if as and ae then
    local span = ae - as
    if span >= 0 and span < best_span then
      best_span = span
      best_open = { row, as }
      best_close = { row, ae }
    end
  end

  if best_open and best_close then
    vim.api.nvim_buf_set_extmark(buf, bracket_ns, best_open[1] - 1, best_open[2] - 1, {
      end_row = best_close[1] - 1,
      end_col = best_close[2],
      hl_group = "MatchBackground",
      priority = 150,
    })
  end
end

local bracket_group = vim.api.nvim_create_augroup("InnerBracketHighlight", { clear = true })
vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI", "BufEnter", "WinEnter", "ModeChanged" }, {
  group = bracket_group,
  callback = update_bracket_highlight,
})
vim.api.nvim_create_autocmd({ "BufLeave", "WinLeave" }, {
  group = bracket_group,
  callback = function(args)
    clear_bracket_highlight(args.buf)
  end,
})
