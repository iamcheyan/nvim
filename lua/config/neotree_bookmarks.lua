-- Neo-tree source that lists code bookmarks grouped by file.
-- Loaded through package.preload as `neo-tree.sources.bookmarks`.
local api = vim.api
local manager = require("neo-tree.sources.manager")
local renderer = require("neo-tree.ui.renderer")

local M = {
  name = "bookmarks",
  display_name = " Bookmarks ",
  -- every source needs the shared component/command tables
  components = require("neo-tree.sources.common.components"),
  commands = require("neo-tree.sources.common.commands"),
}

local function bookmarks()
  return require("config.bookmarks")
end

---Build the tree: project root -> files -> bookmark entries.
---@param items table[]
---@param root string
---@return table[]
local function build_nodes(items, root)
  local by_file = {}
  local order = {}
  for _, item in ipairs(items) do
    if not by_file[item.file] then
      by_file[item.file] = {}
      order[#order + 1] = item.file
    end
    table.insert(by_file[item.file], item)
  end
  table.sort(order)

  local root_node = {
    id = root,
    name = vim.fn.fnamemodify(root, ":t"),
    type = "root",
    path = root,
    loaded = true,
    children = {},
  }

  for _, file in ipairs(order) do
    local entries = by_file[file]
    local file_node = {
      id = file,
      name = bookmarks().relative(file, root),
      type = "bookmark_file",
      path = file,
      loaded = true,
      extra = { file = file, lnum = entries[1].lnum },
      children = {},
    }
    for _, item in ipairs(entries) do
      file_node.children[#file_node.children + 1] = {
        id = string.format("%s:%d:%s", file, item.lnum, item.name),
        name = item.kind == "block" and bookmarks().label(item)
          or string.format("%s  %d", item.name, item.lnum),
        type = "bookmark",
        path = file,
        loaded = true,
        extra = { file = file, lnum = item.lnum, item = item },
      }
    end
    root_node.children[#root_node.children + 1] = file_node
  end

  return { root_node }
end

---Jump to the bookmark (or the file's first bookmark) under the cursor.
---@param state table
---@param node table|nil
function M.jump(state, node)
  node = node or (state.tree and state.tree:get_node())
  local extra = node and node.extra or {}
  local file = extra.file
  local lnum = extra.lnum
  if not file or not lnum then
    return
  end
  local target = vim.fn.win_getid(vim.fn.winnr("#"))
  if target == 0 or target == api.nvim_get_current_win() then
    target = api.nvim_get_current_win()
  end
  api.nvim_set_current_win(target)
  vim.cmd.edit({ args = { vim.fn.fnameescape(file) }, mods = { silent = true } })
  api.nvim_win_set_cursor(0, { lnum, 0 })
  vim.cmd("normal! zv")
end

---@param state table
local function attach_keys(state)
  if not state.bufnr or not api.nvim_buf_is_valid(state.bufnr) then
    return
  end
  local function handler()
    M.jump(state)
  end
  for _, lhs in ipairs({ "<cr>", "o", "l", "<2-LeftMouse>" }) do
    vim.keymap.set("n", lhs, handler, { buffer = state.bufnr, nowait = true, silent = true })
  end
  vim.keymap.set("n", "R", function()
    manager.refresh(M.name)
  end, { buffer = state.bufnr, nowait = true, silent = true, desc = "Refresh bookmarks" })
end

---@param state table
---@param path string|nil
---@param path_to_reveal string|nil
---@param callback function|nil
M.navigate = function(state, path, path_to_reveal, callback)
  state.path = path or bookmarks().project_root()
  bookmarks().scan(state.path, function(items)
    local nodes = build_nodes(items, state.path)
    local expanded = {}
    for _, file_node in ipairs(nodes[1].children or {}) do
      expanded[#expanded + 1] = file_node.id
    end
    vim.schedule(function()
      state.default_expanded_nodes = expanded
      renderer.show_nodes(nodes, state)
      attach_keys(state)
      if type(callback) == "function" then
        callback()
      end
    end)
  end)
end

---@param config table
M.setup = function(config, global_config)
  global_config = global_config or {}
  local events = require("neo-tree.events")
  manager.subscribe(M.name, {
    event = events.VIM_BUFFER_CHANGED,
    handler = function()
      local state = manager.get_state(M.name)
      if state and state.path and renderer.window_exists(state) then
        manager.refresh(M.name)
      end
    end,
  })
  if config.before_render then
    manager.subscribe(M.name, {
      event = events.BEFORE_RENDER,
      handler = function(state)
        config.before_render(state)
      end,
    })
  end
end

return M
