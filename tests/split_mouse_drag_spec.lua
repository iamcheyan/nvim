local this_file = debug.getinfo(1, "S").source:sub(2)
local nvim_root = vim.fn.fnamemodify(this_file, ":h:h")
vim.opt.runtimepath:prepend(nvim_root)
package.path = nvim_root .. "/lua/?.lua;" .. nvim_root .. "/lua/?/init.lua;" .. package.path

local split_drag = require("config.split_mouse_drag")
local scrollbar_scroll = require("config.scrollbar_scroll")

split_drag.setup()
scrollbar_scroll.setup()

vim.o.mouse = "a"
vim.o.laststatus = 3
vim.o.equalalways = false
vim.o.splitright = true
vim.o.splitbelow = true

vim.cmd("only")
local w_left = vim.api.nvim_get_current_win()
vim.cmd("vsplit")
local w_top_right = vim.api.nvim_get_current_win()
vim.cmd("split")
local w_bot_right = vim.api.nvim_get_current_win()

-- 1. Verify exact vertical separator detection
local pos_left = vim.api.nvim_win_get_position(w_left)
local width_left = vim.api.nvim_win_get_width(w_left)
local vsep_col = pos_left[2] + width_left + 1

local sep_v = split_drag.find_separator({ screencol = vsep_col, screenrow = pos_left[1] + 5 })
assert(sep_v and sep_v.type == "vertical" and sep_v.exact == true and sep_v.win == w_left,
  "Must detect exact vertical separator between left and right splits")

-- 2. Verify forgiving 1-cell margin detection around vertical separator
local sep_v_left = split_drag.find_separator({ screencol = vsep_col - 1, screenrow = pos_left[1] + 5 })
assert(sep_v_left and sep_v_left.type == "vertical" and sep_v_left.exact == false and sep_v_left.win == w_left,
  "Must detect 1-cell left margin of vertical separator for horizontal drag")

local sep_v_right = split_drag.find_separator({ screencol = vsep_col + 1, screenrow = pos_left[1] + 5 })
assert(sep_v_right and sep_v_right.type == "vertical" and sep_v_right.exact == false and sep_v_right.win == w_left,
  "Must detect 1-cell right margin of vertical separator for horizontal drag")

-- 3. Verify exact horizontal separator detection
local pos_tr = vim.api.nvim_win_get_position(w_top_right)
local height_tr = vim.api.nvim_win_get_height(w_top_right)
local hsep_row = pos_tr[1] + height_tr + 1

local sep_h = split_drag.find_separator({ screencol = pos_tr[2] + 5, screenrow = hsep_row })
assert(sep_h and sep_h.type == "horizontal" and sep_h.exact == true and sep_h.win == w_top_right,
  "Must detect exact horizontal separator between top-right and bottom-right splits")

-- 4. Verify sync_split_ui resizes treesitter_context and treesitter_context_line_number floating windows synchronously
local ctx_buf = vim.api.nvim_create_buf(false, true)
local ctx_win = vim.api.nvim_open_win(ctx_buf, false, {
  win = w_left,
  relative = "win",
  row = 0,
  col = 0,
  width = width_left,
  height = 1,
  focusable = false,
  style = "minimal",
})
vim.w[ctx_win].treesitter_context = true

local gutter_buf = vim.api.nvim_create_buf(false, true)
local gutter_win = vim.api.nvim_open_win(gutter_buf, false, {
  win = w_left,
  relative = "win",
  row = 0,
  col = 0,
  width = 10,
  height = 1,
  focusable = false,
  style = "minimal",
})
vim.w[gutter_win].treesitter_context_line_number = true

local new_width = math.max(12, width_left - 8)
vim.api.nvim_win_set_width(w_left, new_width)
split_drag.sync_split_ui()
local info_left = vim.fn.getwininfo(w_left)[1]
local expected_ctx_w = math.max(1, new_width - (info_left and info_left.textoff or 0))
local expected_gutter_w = math.max(1, info_left and info_left.textoff or 1)
assert(vim.api.nvim_win_get_width(ctx_win) == expected_ctx_w,
  "sync_split_ui must synchronously resize treesitter_context float to match parent split width")
assert(vim.api.nvim_win_get_width(gutter_win) == expected_gutter_w,
  "sync_split_ui must synchronously resize treesitter_context_line_number float to match parent gutter width")

vim.api.nvim_win_close(ctx_win, true)
vim.api.nvim_win_close(gutter_win, true)

-- 5. Verify perpendicular overlap in L-shaped 3-window layout (2 left stacked, 1 right full-height)
vim.cmd("only")
local w_tl = vim.api.nvim_get_current_win()
vim.cmd("vsplit")
local w_r = vim.api.nvim_get_current_win()
vim.api.nvim_set_current_win(w_tl)
vim.cmd("split")
local w_bl = vim.api.nvim_get_current_win()

local pos_bl = vim.api.nvim_win_get_position(w_bl)
local width_bl = vim.api.nvim_win_get_width(w_bl)
local sep_bl = split_drag.find_separator({
  screencol = pos_bl[2] + width_bl + 1,
  screenrow = pos_bl[1] + 2,
})
assert(sep_bl and sep_bl.type == "vertical" and sep_bl.win == w_bl and sep_bl.other_win == w_r,
  "Vertical separator at bottom-left row must match bottom-left win and full-height right other_win")

vim.cmd("only")
print("split_mouse_drag_spec: OK")
