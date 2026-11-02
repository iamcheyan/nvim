local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h:h")
vim.opt.runtimepath:prepend(root)

local win_search = require("config.win_search")
win_search.setup()
dofile(root .. "/lua/config/autocmds.lua")

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.cursorline = true

local buf = vim.api.nvim_create_buf(true, false)
vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
  "apple and banana",
  "only apple here",
  "banana and apple again",
  "final banana",
})

local w1 = vim.api.nvim_get_current_win()
vim.api.nvim_win_set_buf(w1, buf)
vim.cmd("vsplit")
local w2 = vim.api.nvim_get_current_win()

assert(w1 ~= w2, "Should have two split windows")

-- Test 1: Window focus isolation (cursorline and line numbers)
assert(vim.wo[w2].cursorline == true, "Active window must have cursorline enabled")
assert(vim.wo[w2].relativenumber == true, "Active window must have relativenumber enabled")
assert(vim.wo[w1].cursorline == false, "Inactive window must have cursorline disabled")
assert(vim.wo[w1].relativenumber == false, "Inactive window must have relativenumber disabled")
assert(vim.wo[w1].number == true, "Inactive window must retain absolute line numbers")

-- Test 2: Window-local search isolation (A on left, B on right)
-- Window 1 searches for 'apple'
win_search.set(w1, "apple")

-- Window 2 searches for 'banana'
win_search.set(w2, "banana")

-- Check that both windows have their own independent matches simultaneously!
local m1 = vim.fn.getmatches(w1)
local m2 = vim.fn.getmatches(w2)

assert(#m1 == 1, "w1 should have exactly 1 search match")
assert(m1[1].pattern == "apple", "w1 should match 'apple'")

assert(#m2 == 1, "w2 should have exactly 1 search match")
assert(m2[1].pattern == "banana", "w2 should match 'banana'")

-- Test 3: Switching between windows immediately restores query and prompt
vim.api.nvim_set_current_win(w1)
win_search.restore_reg(w1)
win_search.update_prompt(w1)
assert(vim.fn.getreg("/") == "apple", "w1 must restore search pattern to 'apple'")

vim.api.nvim_set_current_win(w2)
win_search.restore_reg(w2)
win_search.update_prompt(w2)
assert(vim.fn.getreg("/") == "banana", "w2 must restore search pattern to 'banana'")

-- Matches remain in place for both windows simultaneously (side-by-side comparison)
assert(vim.fn.getmatches(w1)[1].pattern == "apple", "w1 match must persist")
assert(vim.fn.getmatches(w2)[1].pattern == "banana", "w2 match must persist")

-- Test 4: Escape clears only current window and updates prompt
win_search.clear(w2)
assert(#vim.fn.getmatches(w2) == 0, "w2 match should be cleared")
assert(#vim.fn.getmatches(w1) == 1, "w1 match must still remain active")

print("split_window_focus_spec: OK")
