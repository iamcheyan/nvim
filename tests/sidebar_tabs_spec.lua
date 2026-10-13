-- Run: nvim --headless -u NONE -l tests/sidebar_tabs_spec.lua
local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h:h")
vim.opt.rtp:prepend(root)
for _, name in ipairs({ "neo-tree.nvim", "plenary.nvim", "nui.nvim", "nvim-web-devicons", "bufferline.nvim", "aerial.nvim" }) do
  vim.opt.rtp:prepend(vim.fn.stdpath("data") .. "/lazy/" .. name)
end
vim.o.foldcolumn = "1"
vim.cmd("colorscheme blue")
require("config.ui_highlights").apply()
require("neo-tree").setup(dofile(root .. "/lua/plugins/neo-tree.lua")[1].opts)
local aerial_opts = dofile(root .. "/lua/plugins/aerial.lua")[1].opts
aerial_opts.backends = { "markdown" }
require("aerial").setup(aerial_opts)
local buffer_opts = dofile(root .. "/lua/plugins/bufferline.lua")[1].opts()
require("bufferline").setup({ options = { left_mouse_command = buffer_opts.options.left_mouse_command, offsets = {
  { filetype = "neo-tree", text = "", padding = 1 },
  { filetype = "aerial", text = "", padding = 1 },
} } })
local tabs = require("config.sidebar_tabs")
tabs.setup()
vim.bo.filetype = "markdown"
vim.api.nvim_buf_set_lines(0, 0, -1, false, { "# Title", "", "## Function" })
local editor = vim.api.nvim_get_current_win()
local file = vim.api.nvim_get_current_buf()
local sidebar

local function check_symbols_inset(win)
  assert(vim.fn.getwininfo(win)[1].textoff == 1,
    "symbols must have a one-cell inset immediately on opening")
  local column = vim.api.nvim_eval_statusline(vim.wo[win].statuscolumn,
    { winid = win, use_statuscol_lnum = 1 })
  assert(column.str == " ", "symbols inset must stay blank, without fold arrows")
end

-- Session restoration and :AerialOpen bypass sidebar_tabs.select().
for _, focus in ipairs({ true, false }) do
  require("aerial").open({ focus = focus, direction = "left" })
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "aerial" then
      check_symbols_inset(win)
    end
  end
  require("aerial").close()
  vim.api.nvim_set_current_win(editor)
end

local function check(source)
  tabs.select(source)
  vim.wait(100, function() return false end)
  local expected = source == "symbols" and "aerial" or "neo-tree"
  assert(vim.bo.filetype == expected, source .. " must focus the selected sidebar")
  sidebar = sidebar or vim.api.nvim_get_current_win()
  assert(vim.api.nvim_get_current_win() == sidebar, "switches must reuse the sidebar window without collapsing the layout")
  assert(vim.api.nvim_win_get_width(sidebar) == 32, "all sources must keep the fixed width")
  assert(#vim.api.nvim_tabpage_list_wins(0) == 2, "only one sidebar should be open")
  assert(vim.api.nvim_win_get_buf(editor) == file, "editor buffer must survive switching")
  local expected_textoff = source == "symbols" and 1 or 0
  assert(vim.fn.getwininfo(vim.api.nvim_get_current_win())[1].textoff == expected_textoff,
    "symbols must have a one-cell left inset and tree sources must have no gutter")
  local offset = require("bufferline.offset").get()
  local rendered = vim.api.nvim_eval_statusline(offset.left, { use_tabline = true, maxwidth = offset.left_size })
  for _, label in ipairs({ "File", "Bufs", "Git", "Syms" }) do
    assert(rendered.str:find(label, 1, true), "missing " .. label)
  end
  for _, icon in ipairs({ "󰉓", "󰈚", "󰊢", "󰘦" }) do
    assert(rendered.str:find(icon, 1, true), "missing source icon " .. icon)
  end
  assert(rendered.width == offset.left_size, "tab width must match sidebar width")
  if source == "symbols" then
    check_symbols_inset(sidebar)
    local lines = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
    assert(lines:find("Title", 1, true), "symbols must contain the right editor's heading, not an empty buffer")
  end
end
for _ = 1, 6 do
  for _, source in ipairs({ "filesystem", "symbols", "buffers", "symbols", "git_status" }) do check(source) end
end
_G.__sidebar_source_click(4, 1, "l")
assert(vim.api.nvim_get_current_win() == editor, "sidebar tab clicks must preserve the right editor's focus")
assert(vim.api.nvim_win_get_buf(editor) == file, "sidebar tab clicks must preserve the right editor's file")
vim.api.nvim_set_current_win(sidebar)
assert(vim.bo.filetype == "aerial", "Syms click opens Aerial")
local outline_win = vim.api.nvim_get_current_win()
local another_file = vim.api.nvim_create_buf(true, false)
vim.api.nvim_buf_set_lines(another_file, 0, -1, false, { "# Another file" })
vim.bo[another_file].filetype = "markdown"
_G.___bufferline_private.handle_click(another_file, 1, "l", "")
vim.wait(100, function() return false end)
assert(vim.bo[vim.api.nvim_win_get_buf(outline_win)].filetype == "aerial", "file tab clicks must not replace the outline with file contents")
assert(vim.api.nvim_win_get_buf(editor) == another_file, "clicked file must open in the editor")
local updated = table.concat(vim.api.nvim_buf_get_lines(vim.api.nvim_win_get_buf(outline_win), 0, -1, false), "\n")
assert(updated:find("Another file", 1, true), "outline must follow the right editor's new file")
for round = 1, 12 do
  local target = round % 2 == 0 and file or another_file
  local title = target == file and "Title" or "Another file"
  _G.___bufferline_private.handle_click(target, 1, "l", "")
  for _, index in ipairs({ 1, 2, 3, 4 }) do
    _G.__sidebar_source_click(index, 1, "l")
    vim.wait(30, function() return false end)
    assert(vim.api.nvim_get_current_win() == editor, "repeated sidebar clicks must not steal editor focus")
    assert(vim.api.nvim_win_get_buf(editor) == target, "left navigation must not replace the right file")
  end
  vim.wait(100, function() return false end)
  local outline = vim.api.nvim_win_get_buf(sidebar)
  local lines = table.concat(vim.api.nvim_buf_get_lines(outline, 0, -1, false), "\n")
  assert(lines:find(title, 1, true), "repeated switches must render the current right file's symbols")
  assert(vim.b[outline].source_buffer == target, "outline must be bound to the right file")
  assert(vim.w[sidebar].source_win == editor, "outline must be bound to the right window")
end
vim.api.nvim_win_set_buf(editor, file)
vim.api.nvim_set_current_win(outline_win)
tabs.cycle(1)
assert(vim.bo.filetype == "neo-tree" and vim.b.neo_tree_source == "filesystem", "cycle wraps to File")
vim.api.nvim_set_current_win(editor)
tabs.toggle_symbols()
assert(vim.api.nvim_get_current_win() == editor, "leader cs must preserve editor focus")
assert(vim.bo[vim.api.nvim_win_get_buf(sidebar)].filetype == "aerial", "leader cs replaces tree with symbols")
tabs.toggle_symbols()
assert(#vim.api.nvim_tabpage_list_wins(0) == 1, "leader cs closes symbols")
tabs.toggle_symbols()
assert(vim.api.nvim_get_current_win() == editor, "opening symbols alone must preserve editor focus")
local fresh_sidebar
for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
  if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "aerial" then fresh_sidebar = win end
end
assert(fresh_sidebar, "symbols sidebar must open")
check_symbols_inset(fresh_sidebar)
tabs.select("filesystem")
vim.wait(100, function() return false end)
assert(#vim.api.nvim_tabpage_list_wins(0) == 2, "opening symbols first must still share one sidebar")
assert(vim.api.nvim_get_current_win() == fresh_sidebar, "symbols-first switch must reuse its window")
print("sidebar_tabs_spec: OK")
vim.cmd("qa!")
