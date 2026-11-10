-- Remembers the sidebar state: open/closed, last source tab and width.
local M = {}

local api = vim.api

M.sources = { "filesystem", "todos", "git_status", "symbols" }

---vim.g.vidiff is vim.NIL when unset, which is truthy in Lua; compare it properly.
---@return boolean
local function in_diff_session()
  local flag = vim.g.vidiff
  if flag ~= nil and flag ~= vim.NIL and flag ~= false and flag ~= 0 then
    return true
  end
  local diff = vim.o.diff
  return diff == true or diff == "diff"
end

local cached = nil
local cached_key = nil

---Sidebar state is remembered per working directory (project).
---@return string
local function state_path()
  local cwd = vim.fs.normalize(vim.uv.cwd() or vim.fn.getcwd() or "")
  return vim.fn.stdpath("state") .. "/sidebar/" .. vim.fn.sha256(cwd) .. ".json"
end

---@return table
local function defaults()
  return { open = false, source = "filesystem", width = 32 }
end

---@return table
function M.read()
  local key = state_path()
  if cached and cached_key == key then
    return cached
  end
  cached_key = key
  local ok, lines = pcall(vim.fn.readfile, key)
  if not ok or #lines == 0 then
    cached = defaults()
    return cached
  end
  local ok_decode, data = pcall(vim.json.decode, table.concat(lines, "\n"))
  if not ok_decode or type(data) ~= "table" then
    cached = defaults()
    return cached
  end
  local state = defaults()
  state.open = data.open == true
  state.width = tonumber(data.width) or state.width
  if type(data.source) == "string" and vim.tbl_contains(M.sources, data.source) then
    state.source = data.source
  end
  cached = state
  return cached
end

---@param state table
function M.write(state)
  cached = state
  local ok, encoded = pcall(vim.json.encode, state)
  if not ok then
    return
  end
  local path = state_path()
  pcall(vim.fn.mkdir, vim.fn.fnamemodify(path, ":h"), "p")
  pcall(vim.fn.writefile, { encoded }, path)
end

---Window hosting neo-tree or aerial, if any.
---@return integer|nil
function M.sidebar_win()
  for _, win in ipairs(api.nvim_list_wins()) do
    local ft = vim.bo[api.nvim_win_get_buf(win)].filetype
    if ft == "neo-tree" or ft == "aerial" then
      return win
    end
  end
  return nil
end

---Source currently displayed in the sidebar (nil when closed).
---@return string|nil
function M.current_source()
  local win = M.sidebar_win()
  if not win then
    return nil
  end
  local buf = api.nvim_win_get_buf(win)
  if vim.bo[buf].filetype == "aerial" then
    return "symbols"
  end
  local source = vim.b[buf].neo_tree_source
  if type(source) == "string" and vim.tbl_contains(M.sources, source) then
    return source
  end
  return nil
end

---Record the state as it is right now.
---@param force boolean|nil write even when no sidebar is visible (exit time)
function M.capture(force)
  local state = M.read()
  local win = M.sidebar_win()
  if win then
    state.open = true
    state.width = api.nvim_win_get_width(win)
    local source = M.current_source()
    if source then
      state.source = source
    end
  elseif force then
    state.open = false
  else
    return
  end
  M.write(state)
end

---Remember a source selection even while the sidebar is closed.
---@param source string
---@param width integer|nil
function M.remember(source, width)
  if not vim.tbl_contains(M.sources, source) then
    return
  end
  local state = M.read()
  state.source = source
  if width then
    state.width = width
  end
  M.write(state)
end

---Close neo-tree/aerial windows (used by diff sessions).
function M.close_sidebars()
  for _, win in ipairs(api.nvim_list_wins()) do
    local buf = api.nvim_win_get_buf(win)
    local ft = vim.bo[buf].filetype
    if ft == "neo-tree" or ft == "aerial" then
      pcall(api.nvim_win_close, win, true)
    end
  end
end

---Restore the sidebar when the previous session left it open.
function M.restore()
  local state = M.read()
  if not state.open then
    return
  end
  if #api.nvim_list_uis() == 0 then
    return
  end
  if in_diff_session() then
    return
  end
  if M.sidebar_win() then
    -- a restored session already opened it
    return
  end
  pcall(function()
    require("lazy").load({ plugins = { "neo-tree.nvim" } })
  end)
  local ok, tabs = pcall(require, "config.sidebar_tabs")
  if not ok then
    return
  end
  vim.defer_fn(function()
    pcall(function()
      tabs.select(state.source, { focus = false, width = state.width })
    end)
  end, 60)
end

function M.setup()
  if M.installed then
    return
  end
  M.installed = true
  local group = api.nvim_create_augroup("SidebarState", { clear = true })

  -- neo-tree/aerial create their windows through the API, which fires no
  -- BufWinEnter/WinNew/FileType autocmds, so poll the layout instead. One
  -- window scan every 1.5s is negligible and catches every open/close path.
  local uv = vim.uv or vim.loop
  local timer = uv.new_timer()
  local absent_since = nil

  local function persist(open)
    local state = M.read()
    if state.open == open then
      return
    end
    state.open = open
    M.write(state)
  end

  local function tick()
    if M.quitting then
      return
    end
    if in_diff_session() then
      if M.sidebar_win() then
        M.close_sidebars()
      end
      return
    end
    local win = M.sidebar_win()
    if win then
      absent_since = nil
      local state = M.read()
      local width = api.nvim_win_get_width(win)
      local source = M.current_source()
      local changed = not state.open or state.width ~= width or (source and state.source ~= source)
      if changed then
        state.open = true
        state.width = width
        if source then
          state.source = source
        end
        M.write(state)
      end
    elseif M.read().open then
      absent_since = absent_since or uv.now()
      -- only believe the close once it has survived a moment (startup churn)
      if uv.now() - absent_since > 1200 then
        persist(false)
        absent_since = nil
      end
    end
  end

  if timer then
    timer:start(1200, 1500, vim.schedule_wrap(tick))
    M.timer = timer
  end

  api.nvim_create_autocmd("VimLeavePre", {
    group = group,
    callback = function()
      M.quitting = true
      if M.timer then
        pcall(function()
          M.timer:stop()
        end)
      end
    end,
  })

  api.nvim_create_autocmd("VimEnter", {
    group = group,
    callback = function()
      -- give sessions/dashboard a moment to settle
      vim.defer_fn(function()
        if in_diff_session() then
          M.close_sidebars()
          return
        end
        M.restore()
      end, 150)
    end,
  })
end

return M
