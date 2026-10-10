local M = {}

local function report(ok, err)
  if not ok then vim.notify(tostring(err), vim.log.levels.ERROR) end
  return ok
end

function M.new_file()
  vim.ui.input({ prompt = "New file: " }, function(path)
    if not path or vim.trim(path) == "" then return end
    path = vim.fn.expand(path)
    report(pcall(function()
      vim.fn.mkdir(vim.fn.fnamemodify(path, ":p:h"), "p")
      if vim.bo.buftype ~= "" and vim.bo.filetype ~= "dashboard" then
        local target
        for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
          local buf = vim.api.nvim_win_get_buf(win)
          if vim.bo[buf].buftype == "" or vim.bo[buf].filetype == "dashboard" then
            target = win
            break
          end
        end
        if target then vim.api.nvim_set_current_win(target) else vim.cmd("vsplit | enew") end
      end
      vim.cmd.edit({ args = { path } })
    end))
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
