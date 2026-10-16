local M = {}

local IMAGE_EXTENSIONS = {
  png = true,
  jpg = true,
  jpeg = true,
  gif = true,
  webp = true,
  svg = true,
  bmp = true,
  avif = true,
  ico = true,
}

---Clipboard image MIME types in preference order, with the file extension used on disk
local CLIPBOARD_IMAGE_TYPES = {
  { mime = "image/png", ext = ".png" },
  { mime = "image/jpeg", ext = ".jpg" },
  { mime = "image/webp", ext = ".webp" },
}

---Cleans up a candidate path string (trims whitespace, quotes, file:// protocol)
---@param str string
---@return string
local function clean_path(str)
  if type(str) ~= "string" then return "" end
  local p = vim.trim(str)
  -- Remove enclosing quotes
  if (p:sub(1, 1) == '"' and p:sub(-1) == '"') or (p:sub(1, 1) == "'" and p:sub(-1) == "'") then
    p = p:sub(2, -2)
  end
  -- Strip file:// protocol
  if p:sub(1, 7) == "file://" then
    p = p:sub(8)
  end
  -- Expand tilde ~
  if p:sub(1, 2) == "~/" then
    p = (os.getenv("HOME") or "") .. p:sub(2)
  end
  return vim.trim(p)
end

---Check if path is an existing image file on disk
---@param path string
---@return boolean, string|nil
function M.is_image_file(path)
  local cleaned = clean_path(path)
  if cleaned == "" then return false end
  local ext = cleaned:match("%.([%a%d]+)$")
  if not ext or not IMAGE_EXTENSIONS[ext:lower()] then
    return false
  end
  local stat = vim.uv.fs_stat(cleaned)
  if stat and stat.type == "file" then
    return true, cleaned
  end
  return false
end

---Get an available unique filename in the target directory
---@param assets_dir string
---@param ext string
---@return string filename, string full_path
local function get_target_filepath(assets_dir, ext)
  local date_str = os.date("%Y%m%d-%H%M%S")
  local base_name = string.format("image-%s.%s", date_str, ext:lower())
  local full_path = vim.fs.joinpath(assets_dir, base_name)
  if not vim.uv.fs_stat(full_path) then
    return base_name, full_path
  end
  local counter = 1
  while true do
    local alt_name = string.format("image-%s-%d.%s", date_str, counter, ext:lower())
    local alt_path = vim.fs.joinpath(assets_dir, alt_name)
    if not vim.uv.fs_stat(alt_path) then
      return alt_name, alt_path
    end
    counter = counter + 1
  end
end

---Save or copy image to assets directory relative to current document
---@param source_path string
---@param bufnr? number
---@return string|nil rel_path, string|nil err
function M.save_image_to_assets(source_path, bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local bufname = vim.api.nvim_buf_get_name(bufnr)
  local doc_dir
  if bufname and bufname ~= "" then
    doc_dir = vim.fs.dirname(bufname)
  else
    doc_dir = vim.fn.getcwd()
  end

  local assets_dir = vim.fs.joinpath(doc_dir, "assets")
  local ok, mkdir_err = pcall(vim.fn.mkdir, assets_dir, "p")
  if not ok then
    return nil, "Failed to create assets directory: " .. tostring(mkdir_err)
  end

  local ext = source_path:match("%.([%a%d]+)$") or "png"
  local filename, full_path = get_target_filepath(assets_dir, ext)

  local copy_ok, copy_err = vim.uv.fs_copyfile(source_path, full_path)
  if not copy_ok then
    return nil, "Failed to copy image: " .. tostring(copy_err)
  end

  return "assets/" .. filename, nil
end

---Ensure WAYLAND_DISPLAY is pointing to a live socket if on Linux/Wayland
local function ensure_wayland_display()
  local runtime_dir = vim.env.XDG_RUNTIME_DIR
  if not runtime_dir or runtime_dir == "" then
    local uid = (vim.uv.getuid and vim.uv.getuid()) or vim.fn.getuid()
    runtime_dir = "/run/user/" .. tostring(uid)
  end

  local function is_valid(name)
    if not name or name == "" then return false end
    local sock = vim.fs.joinpath(runtime_dir, name)
    local stat = vim.uv.fs_stat(sock)
    return stat and stat.type == "socket"
  end

  if is_valid(vim.env.WAYLAND_DISPLAY) then
    return true
  end

  local handle = vim.uv.fs_scandir(runtime_dir)
  if handle then
    local candidates = {}
    while true do
      local name = vim.uv.fs_scandir_next(handle)
      if not name then break end
      if name:match("^wayland%-%d+$") and not name:match("%.lock$") and is_valid(name) then
        table.insert(candidates, name)
      end
    end
    if #candidates > 0 then
      table.sort(candidates)
      vim.env.WAYLAND_DISPLAY = candidates[#candidates]
      return true
    end
  end
  return false
end

---Pick the preferred clipboard image MIME type present in an availability listing
---@param available string
---@return table|nil entry
local function pick_clipboard_image_type(available)
  local types = {}
  for mime in available:gmatch("%S+") do
    types[mime] = true
  end
  for _, entry in ipairs(CLIPBOARD_IMAGE_TYPES) do
    if types[entry.mime] then return entry end
  end
  return nil
end

local clipboard_request_id = 0

---Read a MIME type through kitty's OSC 5522 clipboard protocol. Neovim owns
---the terminal, so a child `kitten clipboard` cannot open /dev/tty here.
---@param mime string "." lists available types without prompting for permission
---@param target? string write binary chunks directly to this file
---@param timeout integer milliseconds
---@return string|boolean|nil listing or successful file read
local function read_kitty_clipboard(mime, target, timeout)
  if not vim.api.nvim_ui_send or #vim.api.nvim_list_uis() == 0 then return nil end

  clipboard_request_id = clipboard_request_id + 1
  local id = string.format("nvim-%d-%d", vim.fn.getpid(), clipboard_request_id)
  local done, accepted, bytes_written = false, false, 0
  local chunks = {}
  local file
  local prefix = "\27]5522;"
  local autocmd = vim.api.nvim_create_autocmd("TermResponse", {
    callback = function(ev)
      local sequence = ev.data.sequence
      if sequence:sub(1, #prefix) ~= prefix then return end
      local header, payload = sequence:sub(#prefix + 1):match("^([^;]+);?(.*)$")
      if not header or header:sub(1, 10) ~= "type=read:" or header:match(":id=([%w%-%_+%.]+)") ~= id then
        return
      end
      local status = header:match(":status=([A-Z]+)")
      if status == "OK" then
        accepted = true
      elseif status == "DATA" and accepted then
        local encoded_mime = header:match(":mime=([^:]+)")
        local mime_ok, response_mime = pcall(vim.base64.decode, encoded_mime or "")
        local data_ok, data = pcall(vim.base64.decode, payload)
        if not mime_ok or response_mime ~= mime or not data_ok then
          accepted, done = false, true
          return
        end
        if target then
          if not file then file = io.open(target, "wb") end
          if not file then
            accepted, done = false, true
            return
          end
          if not file:write(data) then
            accepted, done = false, true
            return
          end
          bytes_written = bytes_written + #data
        else
          chunks[#chunks + 1] = data
        end
      elseif status == "DONE" then
        done = true
      else
        accepted, done = false, true
      end
    end,
  })

  local query = prefix .. "type=read:id=" .. id .. ";" .. vim.base64.encode(mime) .. "\27\\"
  if vim.env.TMUX then
    query = "\27Ptmux;" .. query:gsub("\27", "\27\27") .. "\27\\"
  end
  vim.api.nvim_ui_send(query)
  vim.wait(timeout, function() return done end, 10)
  vim.api.nvim_del_autocmd(autocmd)
  if file and not file:close() then accepted = false end
  if not (done and accepted) then
    if target then pcall(vim.uv.fs_unlink, target) end
    return nil
  end
  if target then
    if bytes_written > 0 then return true end
    pcall(vim.uv.fs_unlink, target)
    return nil
  end
  return table.concat(chunks)
end

---Read image data from the local Kitty clipboard over SSH (also through tmux).
---@param tmp_file string temporary file prefix
---@return string|nil temp_path
local function dump_clipboard_image_via_kitty(tmp_file)
  local listing = read_kitty_clipboard(".", nil, 1000)
  if type(listing) ~= "string" then return nil end
  local entry = pick_clipboard_image_type(listing)
  if not entry then return nil end

  local target = tmp_file .. entry.ext
  if read_kitty_clipboard(entry.mime, target, 60000) then return target end
  return nil
end

---Try to fetch image from system clipboard raw bytes (wl-paste/xclip/Kitty)
---@return string|nil temp_path
local function dump_clipboard_bytes_to_temp()
  local tmp_file = vim.fn.tempname()

  if vim.fn.executable("wl-paste") == 1 and ensure_wayland_display() then
    local types = vim.fn.system("wl-paste --list-types 2>/dev/null")
    if types and types ~= "" then
      for _, entry in ipairs(CLIPBOARD_IMAGE_TYPES) do
        if types:find(entry.mime, 1, true) then
          local target_tmp = tmp_file .. entry.ext
          vim.fn.system(string.format("wl-paste --type '%s' > '%s' 2>/dev/null", entry.mime, target_tmp))
          local stat = vim.uv.fs_stat(target_tmp)
          if stat and stat.size > 0 then
            return target_tmp
          end
        end
      end
    end
  end
  if vim.fn.executable("xclip") == 1 then
    local targets = vim.fn.system("xclip -selection clipboard -t TARGETS -o 2>/dev/null")
    if targets and targets ~= "" then
      for _, entry in ipairs(CLIPBOARD_IMAGE_TYPES) do
        if targets:find(entry.mime, 1, true) then
          local target_tmp = tmp_file .. entry.ext
          vim.fn.system(string.format("xclip -selection clipboard -t '%s' -o > '%s' 2>/dev/null", entry.mime, target_tmp))
          local stat = vim.uv.fs_stat(target_tmp)
          if stat and stat.size > 0 then
            return target_tmp
          end
        end
      end
    end
  end

  -- Wayland/X11 remain preferred; OSC 5522 reaches Kitty through SSH/tmux.
  return dump_clipboard_image_via_kitty(tmp_file)
end

---Scans a line for image paths, copies them to assets/, and replaces them with Markdown links.
---@param line string
---@param bufnr? number
---@return string new_line, number replacements_count
function M.replace_image_paths_in_text(line, bufnr)
  if type(line) ~= "string" or line == "" then
    return line, 0
  end

  -- Don't re-convert already formatted markdown image links like ![](assets/...)
  local replacements = 0
  local tokens = {}
  for token in line:gmatch("%S+") do
    table.insert(tokens, token)
  end

  local result = line
  for _, token in ipairs(tokens) do
    -- Skip tokens already inside markdown link parentheses
    local is_img, clean = M.is_image_file(token)
    if is_img and clean then
      local rel_path, err = M.save_image_to_assets(clean, bufnr)
      if rel_path then
        local md_link = string.format("![](%s)", rel_path)
        -- Escape special pattern chars for gsub
        local escaped = vim.pesc(token)
        local replaced, count = result:gsub(escaped, md_link, 1)
        if count > 0 then
          result = replaced
          replacements = replacements + 1
          vim.notify(string.format("Archived: %s -> %s", clean, rel_path), vim.log.levels.INFO)
        end
      end
    end
  end

  return result, replacements
end

---Paste image from system clipboard (+ or *) or raw clipboard bytes into Markdown buffer
---@param bufnr? number
---@return boolean success
function M.paste_image(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  -- Check system clipboard registers (+ and *) for image paths.
  -- Intentionally DO NOT check register '"' (unnamed) to avoid pasting stale old files.
  for _, reg in ipairs({ "+", "*" }) do
    local ok, content = pcall(vim.fn.getreg, reg)
    if ok and content and content ~= "" then
      local new_text, count = M.replace_image_paths_in_text(content, bufnr)
      if count > 0 then
        local row, _ = unpack(vim.api.nvim_win_get_cursor(0))
        local cur_line = vim.api.nvim_get_current_line()
        local lines = vim.split(vim.trim(new_text), "\n", { plain = true })
        if vim.trim(cur_line) == "" then
          vim.api.nvim_buf_set_lines(bufnr, row - 1, row, false, lines)
          vim.api.nvim_win_set_cursor(0, { row - 1 + #lines, 0 })
        else
          vim.api.nvim_buf_set_lines(bufnr, row, row, false, lines)
          vim.api.nvim_win_set_cursor(0, { row + #lines, 0 })
        end
        return true
      end
    end
  end

  -- If no file path found in registers, check system clipboard for raw image bytes
  local temp_path = dump_clipboard_bytes_to_temp()
  if temp_path then
    local rel_path, err = M.save_image_to_assets(temp_path, bufnr)
    pcall(vim.uv.fs_unlink, temp_path)
    if rel_path then
      local markdown_link = string.format("![](%s)", rel_path)
      local row, _ = unpack(vim.api.nvim_win_get_cursor(0))
      local cur_line = vim.api.nvim_get_current_line()
      if vim.trim(cur_line) == "" then
        vim.api.nvim_buf_set_lines(bufnr, row - 1, row, false, { markdown_link })
        vim.api.nvim_win_set_cursor(0, { row, 0 })
      else
        vim.api.nvim_buf_set_lines(bufnr, row, row, false, { markdown_link })
        vim.api.nvim_win_set_cursor(0, { row + 1, 0 })
      end
      vim.notify(string.format("Saved clipboard image: %s", rel_path), vim.log.levels.INFO)
      return true
    else
      vim.notify(err or "Failed to save clipboard image", vim.log.levels.ERROR)
      return false
    end
  end

  vim.notify("No image or image file path found in system clipboard (+ or *)", vim.log.levels.WARN)
  return false
end

---Convert any image path on the current line into an archived assets link
---@return boolean
function M.convert_image_under_cursor()
  local line = vim.api.nvim_get_current_line()
  local new_line, count = M.replace_image_paths_in_text(line)
  if count == 0 then
    vim.notify("No existing image file path found on current line", vim.log.levels.WARN)
    return false
  end
  vim.api.nvim_set_current_line(new_line)
  return true
end

---Hook into vim.paste so pasting an image path in Markdown auto-converts to assets/
function M.setup()
  vim.api.nvim_create_user_command("PasteImage", function()
    M.paste_image()
  end, { desc = "Paste image into Markdown assets/ directory" })

  vim.api.nvim_create_user_command("ConvertImageUnderCursor", function()
    M.convert_image_under_cursor()
  end, { desc = "Convert image path on current line to Markdown assets/ link" })

  -- Hook vim.paste for seamless drag-and-drop or terminal paste in Markdown
  local orig_paste = vim.paste
  vim.paste = function(lines, phase)
    if vim.bo.filetype == "markdown" and type(lines) == "table" then
      local modified = false
      local new_lines = {}
      for _, line in ipairs(lines) do
        local new_line, count = M.replace_image_paths_in_text(line)
        if count > 0 then
          modified = true
        end
        table.insert(new_lines, new_line)
      end
      if modified then
        return orig_paste(new_lines, phase)
      end
    end
    return orig_paste(lines, phase)
  end

  -- Markdown keymaps
  vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("MarkdownImagePasteKeymaps", { clear = true }),
    pattern = "markdown",
    callback = function(args)
      local bufnr = args.buffer
      vim.keymap.set("n", "<leader>p", function()
        M.paste_image(bufnr)
      end, { buffer = bufnr, desc = "Paste image to assets/ and insert Markdown link" })

      vim.keymap.set("n", "<leader>pi", function()
        M.paste_image(bufnr)
      end, { buffer = bufnr, desc = "Paste image to assets/ and insert Markdown link" })

      vim.keymap.set("n", "<leader>ci", function()
        M.convert_image_under_cursor()
      end, { buffer = bufnr, desc = "Convert image path under cursor to assets/ link" })
    end,
  })
end

return M
