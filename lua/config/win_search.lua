local M = {}

local function refresh_scrollbar()
  local sat = package.loaded["satellite.view"]
  if sat and sat.enabled and sat.enabled() and sat.schedule_refresh then
    pcall(sat.schedule_refresh)
  end
end

local function vs()
  return package.loaded["viewsplit"]
end

--- Clear search match for a window
---@param win integer
function M.clear(win)
  if not win or not vim.api.nvim_win_is_valid(win) then
    return
  end
  local v = vs()
  if v and v.clear_search then
    v.clear_search(win)
    return
  end
  local id = vim.w[win].win_search_id
  if id then
    pcall(vim.fn.matchdelete, id, win)
    vim.w[win].win_search_id = nil
  end
  vim.w[win].win_search_pattern = nil
  if vim.api.nvim_win_is_valid(win) and vim.api.nvim_get_current_win() == win then
    if package.loaded["hlslens"] then
      pcall(require("hlslens").stop)
    end
    M.update_prompt(win)
  end
  refresh_scrollbar()
end

--- Set window-local search pattern and highlight
---@param win integer
---@param pattern string?
function M.set(win, pattern)
  if not win or not vim.api.nvim_win_is_valid(win) then
    return
  end
  local v = vs()
  if v and v.set_search then
    v.set_search(win, pattern)
    return
  end
  M.clear(win)
  if not pattern or pattern == "" then
    return
  end
  vim.w[win].win_search_pattern = pattern
  local ok, id = pcall(vim.fn.matchadd, "Search", pattern, 10, -1, { window = win })
  if ok then
    vim.w[win].win_search_id = id
  end
  if vim.api.nvim_win_is_valid(win) and vim.api.nvim_get_current_win() == win then
    M.update_prompt(win)
  end
  refresh_scrollbar()
end

--- Get window-local search pattern
---@param win integer
---@return string?
function M.get(win)
  if not win or not vim.api.nvim_win_is_valid(win) then
    return nil
  end
  local v = vs()
  if v and v.get_search then
    local pat = v.get_search(win)
    if pat then return pat end
  end
  return vim.w[win].win_search_pattern
end

--- Restore the window's search pattern to the search register @/
---@param win integer
function M.restore_reg(win)
  if not win or not vim.api.nvim_win_is_valid(win) then
    return
  end
  local v = vs()
  if v and v.restore_search_reg then
    v.restore_search_reg(win)
    return
  end
  local pattern = vim.w[win].win_search_pattern
  if pattern and pattern ~= "" then
    vim.fn.setreg("/", pattern)
  else
    if package.loaded["hlslens"] then
      pcall(require("hlslens").stop)
    end
  end
end

--- Show or clear the bottom search prompt matching the window's search state
---@param win integer
function M.update_prompt(win)
  if not win or not vim.api.nvim_win_is_valid(win) then
    return
  end
  local v = vs()
  if v and v.update_search_prompt then
    v.update_search_prompt(win)
    return
  end
  local pattern = vim.w[win].win_search_pattern
  if pattern and pattern ~= "" then
    local sc = {}
    pcall(function()
      sc = vim.fn.searchcount({ recompute = 1, maxcount = 9999 })
    end)
    local msg = "/" .. pattern
    if sc.total and sc.total > 0 then
      msg = msg .. string.format("       [%d/%d]", sc.current or 0, sc.total)
    end
    if package.loaded.noice then
      pcall(require("noice").cmd, "dismiss")
    end
    vim.api.nvim_echo({ { msg, "None" } }, false, {})
  else
    if package.loaded.noice then
      pcall(require("noice").cmd, "dismiss")
    end
    vim.cmd("echo")
  end
end

--- Strip any lingering search suppression from winhighlight
---@param win integer
function M.clean_winhl(win)
  if not win or not vim.api.nvim_win_is_valid(win) then
    return
  end
  local cur = vim.wo[win].winhighlight
  if cur and cur ~= "" then
    local filtered = {}
    for item in cur:gmatch("[^,]+") do
      local k = item:match("^([^:]+):")
      if k ~= "Search" and k ~= "CurSearch" and k ~= "IncSearch"
         and k ~= "HlSearchNear" and k ~= "HlSearchLens" and k ~= "HlSearchLensNear" then
        table.insert(filtered, item)
      end
    end
    vim.wo[win].winhighlight = table.concat(filtered, ",")
  end
end

function M.setup()
  -- Global hlsearch is disabled so Neovim does not globally illuminate matches
  -- across all split windows. Each window manages its own highlights.
  vim.opt.hlsearch = false

  -- Clean up any legacy Search:None mappings from all windows
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    M.clean_winhl(win)
  end

  local group = vim.api.nvim_create_augroup("WindowLocalSearch", { clear = true })

  vim.api.nvim_create_autocmd("SessionLoadPost", {
    group = group,
    callback = function()
      vim.opt.hlsearch = false
    end,
  })

  vim.api.nvim_create_autocmd("OptionSet", {
    group = group,
    pattern = "hlsearch",
    callback = function()
      if vim.o.hlsearch then
        vim.opt.hlsearch = false
      end
    end,
  })

  -- When a search is submitted via / or ?, attach highlight locally to the active window
  vim.api.nvim_create_autocmd("CmdlineLeave", {
    group = group,
    callback = function()
      if vs() then return end
      local ev = vim.v.event
      if not ev.abort and (ev.cmdtype == "/" or ev.cmdtype == "?") then
        local win = vim.api.nvim_get_current_win()
        vim.schedule(function()
          if vim.api.nvim_win_is_valid(win) then
            local pattern = vim.fn.getreg("/")
            M.set(win, pattern)
          end
        end)
      end
    end,
  })

  -- When entering a window, restore that window's search pattern to @/
  -- and immediately refresh the bottom search prompt without needing to press n
  vim.api.nvim_create_autocmd({ "WinEnter", "BufEnter", "FocusGained" }, {
    group = group,
    callback = function()
      if vs() then return end
      local win = vim.api.nvim_get_current_win()
      M.clean_winhl(win)
      M.restore_reg(win)
      vim.schedule(function()
        if vim.api.nvim_win_is_valid(win) and vim.api.nvim_get_current_win() == win then
          M.update_prompt(win)
        end
      end)
    end,
  })
end

return M
