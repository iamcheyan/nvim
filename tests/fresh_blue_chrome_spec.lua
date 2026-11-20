-- Bars and menus use Fresh Nostalgia; document surfaces stay Neovim Blue.
-- Run: nvim --headless -u NONE -l config/nvim/tests/fresh_blue_chrome_spec.lua
local this_file = debug.getinfo(1, "S").source:sub(2)
local nvim_root = vim.fn.fnamemodify(this_file, ":h:h")
vim.opt.runtimepath:prepend(nvim_root)
package.path = nvim_root .. "/lua/?.lua;" .. nvim_root .. "/lua/?/init.lua;" .. package.path
vim.cmd("filetype plugin indent on")
dofile(nvim_root .. "/lua/config/options.lua")

local ui = require("config.ui_highlights")
local fresh = ui.nostalgia_palette()
local function color_id(value)
  if type(value) == "string" and value:match("^#%x%x%x%x%x%x$") then
    return tonumber(value:sub(2), 16)
  end
  return value
end
local expected_fresh = {
  tab_active_fg = "#000000",
  tab_active_bg = "#aaaaaa",
  tab_inactive_fg = "#ffff55",
  tab_inactive_bg = "#000080",
  tab_separator_bg = "#0000aa",
  status_bar_fg = "#000000",
  status_bar_bg = "#00aaaa",
  status_palette_fg = "#ffffff",
  status_palette_bg = "#00aa00",
}
for key, value in pairs(expected_fresh) do
  assert(fresh[key] == value, "Fresh Nostalgia palette mismatch for " .. key)
end

local blue_groups = {
  "Normal", "NormalNC", "CursorLine", "ColorColumn", "LineNr", "LineNrAbove",
  "LineNrBelow", "CursorLineNr", "SignColumn", "FoldColumn", "Visual", "VisualNOS",
  "Search", "IncSearch", "CurSearch",
  "PmenuSbar", "PmenuThumb", "Comment", "String",
  "Function", "Type", "Identifier", "Keyword", "Operator", "DiagnosticError",
  "DiagnosticWarn", "DiagnosticInfo",
}
local blue_before = {}
for _, name in ipairs(blue_groups) do
  blue_before[name] = vim.api.nvim_get_hl(0, { name = name, link = false })
end
local blue_tab_selected = vim.api.nvim_get_hl(0, { name = "TabLineSel", link = false })
local document_bg = blue_before.Normal.bg
assert(vim.g.colors_name == "blue", "default colorscheme should remain Blue")
assert(document_bg == tonumber("000087", 16), "document background must remain #000087")

ui.apply()
assert(vim.api.nvim_get_hl(0, { name = "NormalFloat", link = false }).bg == document_bg)
assert(vim.api.nvim_get_hl(0, { name = "FloatBorder", link = false }).fg == 0xffffff)
for _, name in ipairs(blue_groups) do
  local current = vim.api.nvim_get_hl(0, { name = name, link = false })
  assert(vim.deep_equal(current, blue_before[name]), name .. " must remain on the built-in Blue colors")
end
assert(vim.api.nvim_get_hl(0, { name = "Normal", link = false }).bg == document_bg, "document background must remain unchanged")

local tabs = ui.bufferline_highlights()
assert(tabs.fill.bg == "NONE", "unused BufferLine fill should not paint a background")
assert(tabs.trunc_marker.bg == "NONE", "truncation count/arrow should not paint a background")
assert(tabs.buffer.bg == color_id(fresh.tab_separator_bg) and tabs.buffer.fg == 0xaaaaaa, "inactive tabs should use the muted Blue surface")
assert(tabs.buffer_selected.bg == document_bg and tabs.buffer_selected.fg == vim.api.nvim_get_hl(0, { name = "String", link = false }).fg, "active tab should blend into the document")
assert(tabs.buffer_selected.bold == false, "active tab should not be bold")
local tabline = vim.api.nvim_get_hl(0, { name = "TabLine", link = false })
local tabline_fill = vim.api.nvim_get_hl(0, { name = "TabLineFill", link = false })
local tabline_selected = vim.api.nvim_get_hl(0, { name = "TabLineSel", link = false })
assert(tabline.bg == color_id(fresh.tab_separator_bg) and tabline_fill.bg == color_id(fresh.tab_separator_bg), "native topbar should use Fresh Nostalgia")
assert(tabline_selected.bg == document_bg, "active native tab should blend into the document")
local winbar = vim.api.nvim_get_hl(0, { name = "WinBar", link = false })
local winbar_nc = vim.api.nvim_get_hl(0, { name = "WinBarNC", link = false })
assert(winbar.bg == document_bg and winbar.fg == 0x00ffff, "context WinBar should blend into the document with cyan text")
assert(vim.deep_equal(winbar_nc, winbar), "context WinBar should retain one palette when focus changes")
local bufferline_selected = vim.api.nvim_get_hl(0, { name = "BufferLineBufferSelected", link = false })
assert(bufferline_selected.bg == document_bg, "bufferline active tab should blend into the document")
assert(bufferline_selected.bold ~= true, "bufferline active tab should not be bold")

-- Markdown links String to Constant. The selected tab should keep the Blue
-- syntax accent instead of falling back to Normal's yellow foreground.
local string_highlight = blue_before.String
vim.api.nvim_set_hl(0, "String", { link = "Constant" })
ui.apply()
local blue_syntax_fg = vim.api.nvim_get_hl(0, { name = "Constant", link = false }).fg
assert(ui.bufferline_highlights().buffer_selected.fg == blue_syntax_fg, "selected tab should resolve linked String foreground")
vim.api.nvim_set_hl(0, "String", string_highlight)
ui.apply()

local status = vim.api.nvim_get_hl(0, { name = "StatusLine", link = false })
local status_nc = vim.api.nvim_get_hl(0, { name = "StatusLineNC", link = false })
assert(status.bg == document_bg and status.fg == blue_before.Normal.fg, "bottom bar should blend into the document")
assert(status_nc.bg == document_bg and status_nc.fg == blue_before.Normal.fg, "inactive bottom bar should blend into the document")
assert(status.bold ~= true and status_nc.bold ~= true, "bottom bars should not be bold")
local status_accent = vim.api.nvim_get_hl(0, { name = "FreshStatusLineAccent", link = false })
assert(status_accent.bg == document_bg and status_accent.fg == blue_before.Normal.fg, "bottom-bar segments should use document colors")
local status_warning = vim.api.nvim_get_hl(0, { name = "FreshStatusLineWarning", link = false })
assert(status_warning.bg == document_bg and status_warning.fg == blue_before.Normal.fg, "bottom-bar warning should use document colors")

assert(vim.api.nvim_get_hl(0, { name = "SatelliteBackground", link = false }).bg == color_id(fresh.tab_separator_bg), "scrollbar track should use the muted Blue surface")
assert(vim.api.nvim_get_hl(0, { name = "SatelliteBar", link = false }).bg == blue_tab_selected.bg, "scrollbar thumb should remain Blue")

local heirline_spec = dofile(nvim_root .. "/lua/plugins/heirline.lua")[1]
local statusline_opts = heirline_spec.opts().statusline
local statusline_style = statusline_opts.hl()
assert(color_id(statusline_style.bg) == document_bg, "Heirline bottom bar should blend into the document")
assert(color_id(statusline_style.fg) == status.fg, "Heirline bottom-bar text should use document text color")
assert(statusline_style.bold == false, "Heirline bottom bar should not be bold")
local function find_component(component, predicate)
  if predicate(component) then return component end
  for _, child in ipairs(component) do
    local found = find_component(child, predicate)
    if found then return found end
  end
end
local caps_component = assert(find_component(statusline_opts, function(component)
  local text = component[2] and component[2].provider
  if type(text) ~= "function" then return false end
  local ok, value = pcall(text)
  return ok and type(value) == "string" and value:match("^CAPS ")
end), "Caps Lock status must be present")
assert(caps_component.on_click == nil, "Caps Lock status should only display state")
_G._heirline_caps_lock_on = false
assert(caps_component[2].provider() == "CAPS OFF", "Caps Lock status should report normal state")
_G._heirline_caps_lock_on = true
assert(caps_component[2].provider() == "CAPS ON", "Caps Lock status should report uppercase state")
_G._heirline_caps_lock_on = false

print("fresh_blue_chrome_spec: OK")
