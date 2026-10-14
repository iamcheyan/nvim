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

---Try to fetch image from system clipboard raw bytes (xclip/wl-paste)
---@return string|nil temp_path
local function dump_clipboard_bytes_to_temp()
  local tmp_file = vim.fn.tempname() .. ".png"
  if vim.fn.executable("wl-paste") == 1 then
    local types = vim.fn.system("wl-paste --list-types 2>/dev/null")
    if types and types:find("image/png") then
      vim.fn.system(string.format("wl-paste --type image/png > '%s' 2>/dev/null", tmp_file))
      local stat = vim.uv.fs_stat(tmp_file)
      if stat and stat.size > 0 then
        return tmp_file
      end
    end
  end
  if vim.fn.executable("xclip") == 1 then
    local targets = vim.fn.system("xclip -selection clipboard -t TARGETS -o 2>/dev/null")
    if targets and targets:find("image/png") then
      vim.fn.system(string.format("xclip -selection clipboard -t image/png -o > '%s' 2>/dev/null", tmp_file))
      local stat = vim.uv.fs_stat(tmp_file)
      if stat and stat.size > 0 then
        return tmp_file
      end
    end
  end
  return nil
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
    local content = vim.fn.getreg(reg)
    if content and content ~= "" then
      local new_text, count = M.replace_image_paths_in_text(content, bufnr)
      if count > 0 then
        local row, col = unpack(vim.api.nvim_win_get_cursor(0))
        local cur_line = vim.api.nvim_get_current_line()
        if vim.trim(cur_line) == "" then
          vim.api.nvim_set_current_line(new_text)
        else
          vim.api.nvim_buf_set_lines(bufnr, row, row, false, { new_text })
          vim.api.nvim_win_set_cursor(0, { row + 1, 0 })
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
      local row, col = unpack(vim.api.nvim_win_get_cursor(0))
      local cur_line = vim.api.nvim_get_current_line()
      if vim.trim(cur_line) == "" then
        vim.api.nvim_set_current_line(markdown_link)
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
