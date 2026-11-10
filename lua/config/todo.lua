-- Todo keywords (todo-comments.nvim) with insert / delete / list / sidebar glue.
-- The keywords are exactly the ones todo-comments.nvim ships with; nothing is
-- stored outside the source comments.
local M = {}

local api = vim.api
local uv = vim.uv or vim.loop

M.keywords = { "TODO", "HACK", "WARN", "PERF", "NOTE", "TEST" }

-- Nerd Font icons used by the sidebar (override with M.setup({ icons = {...} }))
M.icons = {
  TODO = "󰄱",
  HACK = "󰈸",
  WARN = "󰀪",
  PERF = "󰒡",
  NOTE = "󰋼",
  TEST = "󰙨",
}

M.cache = {}
M.generation = 0
M.head_watch = nil

---@param tag string
---@return string
function M.icon(tag)
  return M.icons[tag] or ""
end

---@return string
function M.root()
  local buf = api.nvim_buf_get_name(0)
  local start = buf ~= "" and buf or (uv.cwd() or ".")
  return vim.fs.root(start, { ".git" }) or (uv.cwd() or ".")
end

---Comment leader for the current buffer, e.g. "#" / "--" / "//".
---@param bufnr integer
---@return string
function M.comment_prefix(bufnr)
  local cs = vim.bo[bufnr].commentstring or "# %s"
  return vim.trim(cs:match("^(.-)%%s") or "#")
end

---@param line string
---@return string|nil tag
---@return integer|nil start
---@return integer|nil finish
function M.match(line)
  local ok, start, finish, tag = pcall(require("todo-comments.highlight").match, line)
  if not ok or not start then
    return nil
  end
  return tag, start, finish
end

---Insert "<comment> TAG: " above the cursor line and enter insert mode.
---@param tag string
function M.add(tag)
  tag = tag or "TODO"
  if not vim.tbl_contains(M.keywords, tag) then
    vim.notify("Unknown todo keyword: " .. tag, vim.log.levels.ERROR)
    return
  end
  local bufnr = api.nvim_get_current_buf()
  local row = math.max(1, api.nvim_win_get_cursor(0)[1])
  local line = api.nvim_buf_get_lines(bufnr, row - 1, row, false)[1] or ""
  local indent = line:match("^%s*") or ""
  local prefix = M.comment_prefix(bufnr)
  local text = indent .. prefix .. " " .. tag .. ": "
  api.nvim_buf_set_lines(bufnr, row - 1, row - 1, false, { text })
  api.nvim_win_set_cursor(0, { row, #text })
  vim.cmd("startinsert!")
  M.refresh()
end

---Delete the todo line under the cursor (only when it carries a keyword).
function M.delete()
  local bufnr = api.nvim_get_current_buf()
  local row = math.max(1, api.nvim_win_get_cursor(0)[1])
  local line = api.nvim_buf_get_lines(bufnr, row - 1, row, false)[1] or ""
  local tag = M.match(line)
  if not tag then
    vim.notify("No todo keyword on this line", vim.log.levels.WARN)
    return
  end
  api.nvim_buf_set_lines(bufnr, row - 1, row, false, {})
  vim.notify("Deleted " .. tag .. " comment", vim.log.levels.INFO)
  M.refresh()
end

---Jump to the next/previous keyword in the current buffer (official API).
---@param direction "next"|"prev"
function M.jump(direction)
  local todo = require("todo-comments")
  local opts = { keywords = M.keywords }
  if direction == "prev" then
    todo.jump_prev(opts)
  else
    todo.jump_next(opts)
  end
end

---Scan one buffer without touching disk.
---@param bufnr integer
---@return table[]
function M.buffer_items(bufnr)
  bufnr = bufnr or api.nvim_get_current_buf()
  local file = api.nvim_buf_get_name(bufnr)
  local items = {}
  local lines = api.nvim_buf_get_lines(bufnr, 0, -1, false)
  for index, line in ipairs(lines) do
    local tag, start, finish = M.match(line)
    if tag then
      items[#items + 1] = {
        filename = file,
        bufnr = bufnr,
        lnum = index,
        col = start,
        tag = tag,
        text = vim.trim(line:sub(start)),
        message = vim.trim(line:sub((finish or start) + 1)),
      }
    end
  end
  return items
end

---Async project scan with a short-lived cache (avoids rescans on every redraw).
---@param root string
---@param callback fun(items: table[])
---@param opts table|nil
function M.scan(root, callback, opts)
  opts = opts or {}
  root = root or M.root()
  local cached = M.cache[root]
  local ttl = opts.ttl or 800
  if cached and (uv.now() - cached.at) < ttl then
    callback(cached.items)
    return
  end
  local generation = M.generation
  -- todo-comments may not be set up yet during startup; wait for it once.
  local config = require("todo-comments.config")
  if not config.loaded then
    if (opts.wait or 0) >= 20 then
      callback({})
      return
    end
    opts.wait = (opts.wait or 0) + 1
    vim.defer_fn(function()
      M.scan(root, callback, opts)
    end, 120)
    return
  end
  require("todo-comments.search").search(function(items)
    if generation ~= M.generation then
      return
    end
    M.cache[root] = { items = items, at = uv.now() }
    callback(items)
  end, {
    cwd = root,
    keywords = table.concat(M.keywords, ","),
    disable_not_found_warnings = true,
  })
end

---Invalidate caches and ask the sidebar to redraw.
function M.refresh()
  M.generation = M.generation + 1
  M.cache = {}
  api.nvim_exec_autocmds("User", { pattern = "TodoSidebarRefresh" })
end

---@param name string
---@return boolean
local function has(name)
  return pcall(require, name)
end

---Project-wide list: Snacks > Telescope > fzf-lua > quickfix.
function M.list_project()
  local root = M.root()
  local ok_snacks, Snacks = pcall(require, "snacks")
  if ok_snacks and Snacks.picker and Snacks.picker.todo_comments then
    Snacks.picker.todo_comments({ keywords = M.keywords, cwd = root })
    return
  end
  if has("telescope") then
    vim.cmd("TodoTelescope keywords=" .. table.concat(M.keywords, ","))
    return
  end
  if has("fzf-lua") then
    M.scan(root, function(items)
      local fzf = require("fzf-lua")
      fzf.fzf_exec(vim.tbl_map(function(item)
        return string.format("%s:%d:%s: %s", vim.fn.fnamemodify(item.filename, ":."), item.lnum, item.tag, item.message)
      end, items), {
        actions = {
          ["default"] = function(selected)
            local file, lnum = (selected[1] or ""):match("^(.-):(%d+):")
            if file then
              vim.cmd.edit(vim.fn.fnameescape(file))
              api.nvim_win_set_cursor(0, { tonumber(lnum), 0 })
            end
          end,
        },
      })
    end)
    return
  end
  M.scan(root, function(items)
    vim.fn.setqflist({}, " ", { title = "Todo", items = items })
    vim.cmd("copen")
  end)
end

---Current buffer list (Telescope table picker; quickfix fallback).
function M.list_buffer()
  local items = M.buffer_items()
  if #items == 0 then
    vim.notify("No todo keywords in this buffer", vim.log.levels.WARN)
    return
  end
  local ok, pickers = pcall(require, "telescope.pickers")
  if not ok then
    vim.fn.setqflist({}, " ", { title = "Todo (buffer)", items = items })
    vim.cmd("copen")
    return
  end
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  local previewers = require("telescope.previewers")
  local file = api.nvim_buf_get_name(0)

  local function entry_maker(item)
    return {
      value = item,
      display = string.format("%s %-5s %4d  %s", M.icon(item.tag), item.tag, item.lnum, item.message),
      ordinal = item.tag .. " " .. item.message,
      path = file,
      filename = file,
      lnum = item.lnum,
      col = item.col or 1,
    }
  end

  pickers
    .new({}, {
      prompt_title = "Todo · " .. vim.fn.fnamemodify(file, ":t"),
      finder = finders.new_table({ results = items, entry_maker = entry_maker }),
      sorter = conf.generic_sorter({}),
      previewer = previewers.vim_buffer_cat.new({}),
      layout_config = { width = 0.85, height = 0.7, horizontal = { preview_width = 0.5, preview_cutoff = 60 } },
      attach_mappings = function(prompt_bufnr)
        actions.select_default:replace(function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          if selection then
            api.nvim_win_set_cursor(0, { selection.value.lnum, 0 })
          end
        end)
        return true
      end,
    })
    :find()
end

---Open the sidebar on the Todo source.
---@param root string|nil
function M.panel(root)
  -- neo-tree is lazy-loaded on :Neotree; make sure it is present first
  pcall(function()
    require("lazy").load({ plugins = { "neo-tree.nvim" } })
  end)
  require("neo-tree.command").execute({ source = "todos", dir = root or M.root(), toggle = true })
end

---Watch .git/HEAD so checkouts refresh the sidebar without polling.
---@param root string
local function watch_git_head(root)
  if M.head_watch then
    pcall(function()
      M.head_watch:stop()
      M.head_watch:close()
    end)
    M.head_watch = nil
  end
  local path = root .. "/.git/HEAD"
  if vim.fn.filereadable(path) == 0 then
    return
  end
  local handle = uv.new_fs_event()
  if not handle then
    return
  end
  handle:start(path, {}, vim.schedule_wrap(function()
    M.refresh()
  end))
  M.head_watch = handle
end

---@param opts table|nil
function M.setup(opts)
  opts = opts or {}
  if opts.icons then
    M.icons = vim.tbl_extend("force", M.icons, opts.icons)
  end

  api.nvim_set_hl(0, "TodoTagName", { default = true, link = "Title" })
  api.nvim_set_hl(0, "TodoFileName", { default = true, link = "Comment" })
  api.nvim_set_hl(0, "TodoEntryName", { default = true, link = "Normal" })

  local group = api.nvim_create_augroup("TodoKeywords", { clear = true })

  local function debounce_refresh()
    vim.defer_fn(function()
      M.cache = {}
      api.nvim_exec_autocmds("User", { pattern = "TodoSidebarRefresh" })
    end, 300)
  end

  api.nvim_create_autocmd({ "BufWritePost", "BufEnter", "FileChangedShellPost" }, {
    group = group,
    callback = debounce_refresh,
  })
  api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "InsertLeave" }, {
    group = group,
    callback = debounce_refresh,
  })
  api.nvim_create_autocmd("BufEnter", {
    group = group,
    callback = function()
      watch_git_head(M.root())
    end,
  })
  watch_git_head(M.root())

  api.nvim_create_user_command("TodoAdd", function(args)
    M.add(args.args ~= "" and args.args or "TODO")
  end, { nargs = "*", desc = "Insert a todo keyword comment" })
  api.nvim_create_user_command("TodoDelete", function()
    M.delete()
  end, { desc = "Delete the todo keyword line under the cursor" })
  api.nvim_create_user_command("TodoList", function()
    M.list_project()
  end, { desc = "List every todo in the project" })
  api.nvim_create_user_command("TodoBuffer", function()
    M.list_buffer()
  end, { desc = "List todos in the current buffer" })
  api.nvim_create_user_command("TodoPanel", function()
    M.panel()
  end, { desc = "Open the Todo sidebar" })
  api.nvim_create_user_command("TodoNext", function()
    M.jump("next")
  end, { desc = "Next todo keyword" })
  api.nvim_create_user_command("TodoPrev", function()
    M.jump("prev")
  end, { desc = "Previous todo keyword" })
end

return M
