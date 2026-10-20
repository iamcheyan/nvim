local M = { anchor = nil }

local function find_index(components, id)
  for index, component in ipairs(components or {}) do
    if component.id == id then return index end
  end
end

local function rewrite_buffer_highlights(line, id, direction)
  if not id then return line end
  local marker = "%%" .. id .. "@v:lua%.___bufferline_private%.handle_click@"
  local marker_start, marker_end = line:find(marker)
  if not marker_start then return line end

  -- A tab click region can contain a nested close-button click region, so
  -- match the corresponding outer %X instead of stopping at the first one.
  local depth, cursor, segment_end = 1, marker_end + 1, nil
  local click_start = "%%%d+@v:lua%.___bufferline_private%.[%w_]+@"
  while depth > 0 do
    local nested_start, nested_end = line:find(click_start, cursor)
    local close_start, close_end = line:find("%%X", cursor)
    if not close_start then return line end
    if nested_start and nested_start < close_start then
      depth = depth + 1
      cursor = nested_end + 1
    else
      depth = depth - 1
      if depth == 0 then
        segment_end = close_start
      else
        cursor = close_end + 1
      end
    end
  end

  local segment = line:sub(marker_end + 1, segment_end - 1)
  if direction == "inactive" then
    segment = segment:gsub("%%#(BufferLine[%w]+)Selected#", function(group)
      return "%#" .. group:gsub("Selected$", "") .. "#"
    end)
  else
    segment = segment:gsub("%%#(BufferLine[%w]+)Visible#", function(group)
      return "%#" .. group:gsub("Visible$", "Selected") .. "#"
    end)
  end
  return line:sub(1, marker_start - 1)
    .. "%" .. id .. "@v:lua.___bufferline_private.handle_click@"
    .. segment .. "%X" .. line:sub(segment_end + 2)
end

---Render around a virtual tab anchor without changing the current buffer.
function M.render(render_bufferline)
  local anchor = M.anchor
  local current_buf = vim.api.nvim_get_current_buf()
  if not anchor or anchor == current_buf then
    M.anchor = nil
    return render_bufferline()
  end

  local ok_models, models = pcall(require, "bufferline.models")
  local ok_state, state = pcall(require, "bufferline.state")
  if not ok_models or not ok_state or not find_index(state.components, anchor) then
    M.anchor = nil
    return render_bufferline()
  end

  local original_current = models.Buffer.current
  models.Buffer.current = function(self)
    return self.id == anchor
  end
  local ok, line = pcall(render_bufferline)
  models.Buffer.current = original_current
  if not ok then error(line) end

  -- The virtual anchor controls only truncation. Keep the actual current
  -- buffer's visual selection and sorter position truthful.
  line = rewrite_buffer_highlights(line, anchor, "inactive")
  line = rewrite_buffer_highlights(line, current_buf, "selected")
  local current_index = find_index(state.components, current_buf)
  if current_index then state.set({ current_element_index = current_index }) end
  return line
end

local function forward_mouse_wheel(key)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(key, true, false, true), "n", false)
end

local function scroll_tabs(direction, key)
  local mouse = vim.fn.getmousepos()
  if not mouse or mouse.screenrow ~= 1 then
    forward_mouse_wheel(key)
    return
  end

  local ok, state = pcall(require, "bufferline.state")
  if not ok then
    forward_mouse_wheel(key)
    return
  end

  local current_buf = vim.api.nvim_get_current_buf()
  local index = find_index(state.components, M.anchor or current_buf)
  if not index then return end

  local next_index = index + direction
  if next_index < 1 or next_index > #state.components then return end

  M.anchor = state.components[next_index].id
  require("bufferline.ui").refresh()
end

function M.setup()
  -- Intentionally do not hijack mouse wheel for tab cycling.
  -- Document scrolling is handled cleanly without jumping across document tabs.
  vim.api.nvim_create_autocmd("BufEnter", {
    group = vim.api.nvim_create_augroup("BufferLineScrollAnchor", { clear = true }),
    callback = function() M.anchor = nil end,
    desc = "Center buffer tabs on the newly selected buffer",
  })
end

return M
