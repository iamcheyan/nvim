local M = {}
local owned_maps = {}
local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h:h")
local targets = { "all", "keymaps", "files", "statusline" }

local function key_id(lhs)
  lhs = lhs:gsub("<leader>", vim.g.mapleader or "\\"):gsub("<localleader>", vim.g.maplocalleader or "\\")
  return vim.api.nvim_replace_termcodes(lhs, true, true, true)
end

local function global_map(mode, lhs)
  local direct = vim.fn.maparg(lhs, mode, false, true)
  if type(direct) == "table" and not vim.tbl_isempty(direct) and direct.buffer == 0 then
    return direct
  end
  local id = key_id(lhs)
  for _, mapping in ipairs(vim.api.nvim_get_keymap(mode)) do
    if key_id(mapping.lhs) == id then return mapping end
  end
  return {}
end

local function map_options(mapping)
  return {
    expr = mapping.expr == 1, silent = mapping.silent == 1,
    nowait = mapping.nowait == 1, remap = mapping.noremap == 0,
    desc = mapping.desc,
  }
end

-- Track only these configuration files' global mappings. Buffer-local LSP or
-- plugin maps must not hide the mapping being recorded or cleaned up.
function M.track(owner, mode, lhs)
  local aliases = { v = { "x", "s" }, ["!"] = { "i", "c" }, [""] = { "n", "x", "s", "o" } }
  if aliases[mode] then
    for _, concrete in ipairs(aliases[mode]) do M.track(owner, concrete, lhs) end
    return
  end
  local installed = global_map(mode, lhs)
  if vim.tbl_isempty(installed) then return end
  owned_maps[owner] = owned_maps[owner] or {}
  owned_maps[owner][mode .. "\0" .. lhs] = {
    mode = mode, lhs = lhs, rhs = installed.callback or installed.rhs,
    opts = map_options(installed), installed = installed,
  }
end

function M.mapper(owner)
  owned_maps[owner] = owned_maps[owner] or {}
  return function(mode, lhs, rhs, opts)
    vim.keymap.set(mode, lhs, rhs, opts)
    for _, item_mode in ipairs(type(mode) == "table" and mode or { mode }) do
      M.track(owner, item_mode, lhs)
    end
  end
end

local function clear_maps(owner)
  for _, item in pairs(owned_maps[owner] or {}) do
    local current = global_map(item.mode, item.lhs)
    local same = true
    for _, key in ipairs({ "callback", "expr", "noremap", "silent", "nowait", "desc" }) do
      if current[key] ~= item.installed[key] then same = false; break end
    end
    local function normalize(rhs)
      return rhs and vim.api.nvim_replace_termcodes(rhs, true, true, true)
    end
    same = same and normalize(current.rhs) == normalize(item.installed.rhs)
    if same then pcall(vim.keymap.del, item.mode, item.lhs) end
  end
  owned_maps[owner] = {}
end

local function live_keymaps()
  local snapshot = {}
  for _, mode in ipairs({ "n", "x", "s", "o", "i", "c", "t", "l" }) do
    snapshot[mode] = {}
    for _, mapping in ipairs(vim.api.nvim_get_keymap(mode)) do
      snapshot[mode][key_id(mapping.lhs)] = mapping
    end
  end
  return snapshot
end

local function restore_keymaps(previous_maps, snapshot)
  local touched = {}
  for _, registry in ipairs({ owned_maps, previous_maps }) do
    for _, mappings in pairs(registry) do
      for _, item in pairs(mappings) do touched[item.mode .. "\0" .. key_id(item.lhs)] = item end
    end
  end
  for _, item in pairs(touched) do
    local previous = snapshot[item.mode][key_id(item.lhs)]
    if previous then
      vim.keymap.set(item.mode, item.lhs, previous.callback or previous.rhs, map_options(previous))
    else
      pcall(vim.keymap.del, item.mode, item.lhs)
    end
  end
  owned_maps = previous_maps
end

local function statusline_snapshot()
  local heirline = package.loaded.heirline
  local state = {
    module = heirline, objects = {}, options = {}, autocmds = {}, groups = {},
    redraw = package.loaded["config.bar_feedback"] and package.loaded["config.bar_feedback"].on_redraw,
  }
  for _, name in ipairs({ "statusline", "winbar", "tabline", "statuscolumn" }) do
    if heirline then state.objects[name] = heirline[name] end
    state.options[name] = vim.o[name]
  end
  state.options.laststatus = vim.o.laststatus
  for _, autocmd in ipairs(vim.api.nvim_get_autocmds({})) do
    if (autocmd.group_name or ""):match("^Heirline") then
      state.groups[autocmd.group_name] = true
      state.autocmds[#state.autocmds + 1] = autocmd
    end
  end
  return state
end

local function restore_statusline(state)
  package.loaded.heirline = state.module
  if state.module then
    for _, name in ipairs({ "statusline", "winbar", "tabline", "statuscolumn" }) do
      state.module[name] = state.objects[name]
    end
  end
  for name, value in pairs(state.options) do vim.o[name] = value end
  local groups = vim.deepcopy(state.groups)
  for _, autocmd in ipairs(vim.api.nvim_get_autocmds({})) do
    if (autocmd.group_name or ""):match("^Heirline") then groups[autocmd.group_name] = true end
  end
  for name in pairs(groups) do vim.api.nvim_create_augroup(name, { clear = true }) end
  for _, autocmd in ipairs(state.autocmds) do
    local opts = {
      group = autocmd.group_name, once = autocmd.once,
      desc = autocmd.desc,
    }
    if autocmd.callback then opts.callback = autocmd.callback else opts.command = autocmd.command end
    if autocmd.buflocal then opts.buffer = autocmd.buffer else opts.pattern = autocmd.pattern end
    vim.api.nvim_create_autocmd(autocmd.event, opts)
  end
  if package.loaded["config.bar_feedback"] then
    package.loaded["config.bar_feedback"].on_redraw = state.redraw
  end
  local utils = package.loaded["heirline.utils"]
  if state.module and utils and utils.on_colorscheme then pcall(utils.on_colorscheme) end
  pcall(vim.cmd, "redrawstatus")
end

local function sources(target)
  local files = {}
  local function add(path) files[#files + 1] = root .. "/lua/" .. path .. ".lua" end
  if target == "all" or target == "keymaps" then
    add("config/keymaps-defaults")
    add("config/keymaps")
    add("config/multicursor_keymaps")
  end
  if target == "all" or target == "files" then add("config/file_actions") end
  if target == "all" or target == "statusline" then
    add("plugins/heirline")
    vim.list_extend(files, vim.fn.globpath(root .. "/lua/config/statusline", "*.lua", false, true))
  end
  return files
end

local function reload_keymaps()
  clear_maps("multicursor")
  clear_maps("defaults")
  clear_maps("personal")
  package.loaded["config.multicursor_keymaps"] = nil
  local mc = package.loaded["multicursor-nvim"]
  if mc then require("config.multicursor_keymaps").apply(mc) end
  package.loaded["config.keymaps-defaults"] = nil
  package.loaded["config.keymaps"] = nil
  require("config.keymaps-defaults")
  require("config.keymaps")
end

local function reload_statusline()
  if _G._statusline_menu_close then _G._statusline_menu_close() end
  for name in pairs(package.loaded) do
    if name:match("^config%.statusline%.") then package.loaded[name] = nil end
  end
  package.loaded["plugins.heirline"] = nil
  local spec = require("plugins.heirline")[1]
  local opts = spec.opts()
  spec.config(nil, opts)
end

function M.reload(target)
  target = target or "all"
  if not vim.tbl_contains(targets, target) then
    local err = "Unknown reload target: " .. tostring(target)
    vim.notify(err, vim.log.levels.ERROR)
    return false, err
  end
  -- Reject syntax errors before touching the live configuration.
  for _, path in ipairs(sources(target)) do
    local chunk, err = loadfile(path)
    if not chunk then
      vim.notify("Configuration was not reloaded: " .. tostring(err), vim.log.levels.ERROR)
      return false, err
    end
  end
  if _G._statusline_menu_close then _G._statusline_menu_close() end
  local cached = {}
  for name, value in pairs(package.loaded) do cached[name] = value end
  local previous_maps = vim.deepcopy(owned_maps)
  local maps_snapshot = (target == "all" or target == "keymaps") and live_keymaps() or nil
  local bar_snapshot = (target == "all" or target == "statusline") and statusline_snapshot() or nil
  local ok, err = xpcall(function()
    if target == "all" or target == "files" then
      package.loaded["config.file_actions"] = nil
      require("config.file_actions")
    end
    if target == "all" or target == "keymaps" then reload_keymaps() end
    if target == "all" or target == "statusline" then reload_statusline() end
    vim.cmd("redrawstatus")
    vim.cmd("redrawtabline")
  end, debug.traceback)
  if not ok then
    -- Restore cached entry points and configuration-owned mappings on failure.
    for name in pairs(package.loaded) do
      if name == "plugins.heirline" or name:match("^config%.") then
        package.loaded[name] = cached[name]
      end
    end
    for name, value in pairs(cached) do
      if name == "plugins.heirline" or name:match("^config%.") then package.loaded[name] = value end
    end
    if maps_snapshot then restore_keymaps(previous_maps, maps_snapshot) end
    if bar_snapshot then restore_statusline(bar_snapshot) end
    vim.notify("Configuration reload failed: " .. tostring(err), vim.log.levels.ERROR)
    return false, err
  end
  vim.notify("Reloaded configuration: " .. target, vim.log.levels.INFO)
  return true
end

function M.menu()
  local items = {
    { label = "All supported modules", target = "all" },
    { label = "Keymaps", target = "keymaps" },
    { label = "File actions", target = "files" },
    { label = "Statusline and its menus", target = "statusline" },
  }
  vim.ui.select(items, {
    prompt = "Reload configuration (plugin installation and startup options require restart)",
    format_item = function(item) return item.label end,
  }, function(item)
    if item then M.reload(item.target) end
  end)
end

function M.setup()
  vim.api.nvim_create_user_command("ConfigReload", function(opts)
    if opts.args == "" then M.menu() else M.reload(opts.args) end
  end, {
    nargs = "?",
    force = true,
    desc = "Reload supported configuration modules",
    complete = function() return targets end,
  })
end

return M
