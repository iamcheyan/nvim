local M = {}

local function report(ok, err)
  if not ok then vim.notify(tostring(err), vim.log.levels.ERROR) end
  return ok
end

-- New files always get their own tab page. BufferLine remains a global file
-- list; switching an already-visible file should return to its existing window.
function M.open_buffer(buf)
  if not vim.api.nvim_buf_is_valid(buf) then return false end
  if vim.api.nvim_get_current_buf() == buf and vim.api.nvim_win_get_config(0).relative == "" then return true end
  local current = vim.api.nvim_get_current_tabpage()
  local tabs = { current }
  for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
    if tab ~= current then tabs[#tabs + 1] = tab end
  end
  for _, tab in ipairs(tabs) do
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
      if vim.api.nvim_win_get_buf(win) == buf and vim.api.nvim_win_get_config(win).relative == "" then
        vim.api.nvim_set_current_tabpage(tab)
        vim.api.nvim_set_current_win(win)
        return true
      end
    end
  end
  require("config.sidebar_tabs").open_buffer(buf)
  return true
end

function M.new_file(use_default)
  local cwd = vim.fn.getcwd()
  local function absolute(path)
    path = vim.fn.expand(path)
    if not path:match("^[/\\]") and not path:match("^%a:[/\\]") then
      path = cwd .. "/" .. path
    end
    return vim.fn.fnamemodify(path, ":p")
  end
  local function default_name()
    local name = "new-file.txt"
    local suffix = 2
    local function exists(candidate)
      local full = absolute(candidate)
      if vim.uv.fs_lstat(full) then return true end
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_get_name(buf) == full then return true end
      end
      return false
    end
    while exists(name) do
      name = "new-file-" .. suffix .. ".txt"
      suffix = suffix + 1
    end
    return name
  end

  local default = default_name()
  local function create(path)
    path = absolute(path)
    return report(pcall(function()
      vim.fn.mkdir(vim.fn.fnamemodify(path, ":p:h"), "p")
      vim.cmd.tabnew({ args = { path } })
    end))
  end

  if use_default then return create(default_name()) end

  vim.ui.input({ prompt = "New file: ", default = default, completion = "file" }, function(path)
    if path == nil then return end
    -- Recheck the suggested name when accepting it: another buffer or file
    -- may have claimed it while the asynchronous prompt was open.
    if vim.trim(path) == "" or path == default then path = default_name() end
    create(path)
  end)
end

function M.save(buf, done)
  done = done or function() end
  local function write(path)
    if not vim.api.nvim_buf_is_valid(buf) then return done(false) end
    local ok, err = pcall(vim.api.nvim_buf_call, buf, function()
      if path then
        vim.fn.mkdir(vim.fn.fnamemodify(path, ":p:h"), "p")
        vim.cmd.write({ args = { path } })
      else
        vim.cmd.write()
      end
    end)
    done(report(ok, err))
  end
  if vim.api.nvim_buf_get_name(buf) ~= "" then return write() end
  vim.ui.input({ prompt = "Save file as: " }, function(path)
    if not path or vim.trim(path) == "" then return done(false) end
    write(vim.fn.expand(path))
  end)
end

function M.close(buf, done)
  done = done or function() end
  if not vim.api.nvim_buf_is_valid(buf) then return done(true) end
  local function remove()
    local ok, err = pcall(function()
      require("snacks").bufdelete({ buf = buf, force = true })
    end)
    done(report(ok, err))
  end
  if not vim.bo[buf].modified then return remove() end
  local label = vim.api.nvim_buf_get_name(buf)
  if label == "" then label = "[New file]" end
  local choice = vim.fn.confirm("Save changes to " .. label .. "?", "&Save\n&Discard\n&Cancel", 3)
  if choice == 1 then
    M.save(buf, function(saved) if saved then remove() else done(false) end end)
  elseif choice == 2 then
    remove()
  else
    done(false)
  end
end

function M.close_many(ids)
  local index = 0
  local function next_buffer(proceed)
    if proceed == false then return end
    index = index + 1
    if ids[index] then M.close(ids[index], next_buffer) end
  end
  next_buffer(true)
end

function M.open_folder()
  vim.ui.input({ prompt = "Open folder: ", default = vim.fn.getcwd() .. "/", completion = "dir" }, function(path)
    if not path or path == "" then return end
    path = vim.fn.fnamemodify(vim.fn.expand(path), ":p")
    if vim.fn.isdirectory(path) ~= 1 then
      return vim.notify("Folder does not exist: " .. path, vim.log.levels.WARN)
    end
    report(pcall(function()
      vim.cmd.tcd({ args = { path } })
      require("neo-tree.command").execute({ action = "show", source = "filesystem", dir = path })
    end))
  end)
end

return M
