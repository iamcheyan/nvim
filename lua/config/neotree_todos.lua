-- Neo-tree source listing todo-comments keywords, grouped by type and file.
-- Loaded as `neo-tree.sources.todos` through lua/neo-tree/sources/todos.lua.
local api = vim.api
local manager = require("neo-tree.sources.manager")
local renderer = require("neo-tree.ui.renderer")

local M = {
  name = "todos",
  display_name = " Todo ",
  components = require("neo-tree.sources.common.components"),
  commands = require("neo-tree.sources.common.commands"),
}

local function todo()
  return require("config.todo")
end

---@param items table[]
---@param root string
---@return table[]
local function build_nodes(items, root)
  local by_tag = {}
  for _, item in ipairs(items) do
    by_tag[item.tag] = by_tag[item.tag] or {}
    table.insert(by_tag[item.tag], item)
  end

  local nodes = {}
  local order = vim.deepcopy(todo().keywords)
  for tag in pairs(by_tag) do
    if not vim.tbl_contains(order, tag) then
      table.insert(order, tag)
    end
  end

  for _, tag in ipairs(order) do
    local entries = by_tag[tag]
    if entries then
      table.sort(entries, function(a, b)
        if a.filename == b.filename then
          return a.lnum < b.lnum
        end
        return a.filename < b.filename
      end)

      local tag_node = {
        id = "tag:" .. tag,
        name = string.format("%s %s (%d)", todo().icon(tag), tag, #entries),
        type = "todo_tag",
        loaded = true,
        children = {},
      }

      local by_file = {}
      local files = {}
      for _, item in ipairs(entries) do
        if not by_file[item.filename] then
          by_file[item.filename] = {}
          table.insert(files, item.filename)
        end
        table.insert(by_file[item.filename], item)
      end
      table.sort(files)

      for _, file in ipairs(files) do
        local file_node = {
          id = "file:" .. tag .. ":" .. file,
          name = M.relative(file, root),
          type = "todo_file",
          path = file,
          loaded = true,
          extra = { file = file, lnum = by_file[file][1].lnum },
          children = {},
        }
        for _, item in ipairs(by_file[file]) do
          file_node.children[#file_node.children + 1] = {
            id = string.format("todo:%s:%s:%d", tag, file, item.lnum),
            name = string.format("%s  L%d", item.message ~= "" and item.message or item.text, item.lnum),
            type = "todo_entry",
            path = file,
            loaded = true,
            extra = { file = file, lnum = item.lnum },
          }
        end
        tag_node.children[#tag_node.children + 1] = file_node
      end

      nodes[#nodes + 1] = tag_node
    end
  end

  return {
    {
      id = root,
      name = vim.fn.fnamemodify(root, ":t"),
      type = "root",
      path = root,
      loaded = true,
      children = nodes,
    },
  }
end

---@param file string
---@param root string
---@return string
function M.relative(file, root)
  local abs = vim.fn.fnamemodify(file, ":p")
  if abs:sub(1, #root) == root then
    return abs:sub(#root + 2)
  end
  return vim.fn.fnamemodify(file, ":~:.")
end

---@param state table
---@param node table|nil
function M.jump(state, node)
  node = node or (state.tree and state.tree:get_node())
  local extra = node and node.extra or {}
  if not extra.file or not extra.lnum then
    return
  end
  local target = vim.fn.win_getid(vim.fn.winnr("#"))
  if target == 0 or target == api.nvim_get_current_win() then
    target = api.nvim_get_current_win()
  end
  api.nvim_set_current_win(target)
  vim.cmd.edit({ args = { vim.fn.fnameescape(extra.file) }, mods = { silent = true } })
  api.nvim_win_set_cursor(0, { extra.lnum, 0 })
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
  end, { buffer = state.bufnr, nowait = true, silent = true, desc = "Refresh todos" })
end

---@param state table
---@param path string|nil
---@param path_to_reveal string|nil
---@param callback function|nil
M.navigate = function(state, path, path_to_reveal, callback)
  state.path = path or todo().root()
  -- draw the tree immediately so the window exists while the scan runs
  renderer.show_nodes({
    {
      id = state.path,
      name = vim.fn.fnamemodify(state.path, ":t"),
      type = "root",
      path = state.path,
      loaded = true,
      children = {
        { id = "loading", name = "Scanning…", type = "message", loaded = true },
      },
    },
  }, state)
  todo().scan(state.path, function(items)
    local nodes = build_nodes(items, state.path)
    local expanded = {}
    for _, tag_node in ipairs(nodes[1].children or {}) do
      expanded[#expanded + 1] = tag_node.id
      if #items <= 200 then
        for _, file_node in ipairs(tag_node.children or {}) do
          expanded[#expanded + 1] = file_node.id
        end
      end
    end
    vim.schedule(function()
      state.default_expanded_nodes = expanded
      renderer.show_nodes(nodes, state)
      attach_keys(state)
      if type(callback) == "function" then
        callback()
      end
    end)
  end, { ttl = 400 })
end

---@param config table
M.setup = function(config, global_config)
  local events = require("neo-tree.events")
  local group = api.nvim_create_augroup("TodoTreeRefresh", { clear = true })
  api.nvim_create_autocmd("User", {
    group = group,
    pattern = "TodoSidebarRefresh",
    callback = function()
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
