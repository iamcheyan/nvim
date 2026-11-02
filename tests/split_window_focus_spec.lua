local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h:h")
vim.opt.runtimepath:prepend(root)

local win_search = require("config.win_search")
win_search.setup()

-- hlslens incremental search must not re-enable global hlsearch: doing so
-- bypasses the per-window matches below and highlights every split globally.
local hlslens_path = vim.fn.expand("~/.local/share/nvim/lazy/nvim-hlslens")
if vim.fn.isdirectory(hlslens_path) == 1 then
  vim.opt.runtimepath:append(hlslens_path)
  require("hlslens").setup({ enable_incsearch = false })
end

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
-- Exercise the real /pattern<CR> path so CmdlineLeave handlers run.
local function search_in_window(win, pattern)
  vim.api.nvim_set_current_win(win)
  vim.api.nvim_feedkeys(
    vim.api.nvim_replace_termcodes("/" .. pattern .. "<CR>", true, false, true),
    "xt",
    false
  )
  vim.wait(50)
end

search_in_window(w1, "apple")
assert(vim.o.hlsearch == false, "search must not re-enable global hlsearch")
search_in_window(w2, "banana")
assert(vim.o.hlsearch == false, "search in another split must not re-enable global hlsearch")

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

-- Test 5: With viewsplit.nvim loaded, win_search and viewsplit must not create duplicate matches
local vs_path = vim.fn.expand("~/.local/share/nvim/lazy/viewsplit.nvim")
if vim.fn.isdirectory(vs_path) == 1 then
  vim.opt.runtimepath:prepend(vs_path)
  local viewsplit = require("viewsplit")
  viewsplit.setup({ search = true, selection = true, jumps = true, marks = true, scroll = true })

  search_in_window(w1, "apple")
  search_in_window(w2, "banana")
  assert(#vim.fn.getmatches(w1) == 1 and vim.fn.getmatches(w1)[1].pattern == "apple",
    "w1 must have exactly 1 match when both win_search and viewsplit are active")
  assert(#vim.fn.getmatches(w2) == 1 and vim.fn.getmatches(w2)[1].pattern == "banana",
    "w2 must have exactly 1 match when both win_search and viewsplit are active")

  win_search.clear(w1)
  assert(#vim.fn.getmatches(w1) == 0, "win_search.clear(w1) must clear viewsplit match completely")
  assert(#vim.fn.getmatches(w2) == 1, "w2 match must remain intact")

  -- Regression: session restore (`set hlsearch`) must not re-enable global hlsearch
  vim.cmd("set hlsearch")
  assert(vim.o.hlsearch == false, "global hlsearch must stay disabled even if session script runs set hlsearch")
end

print("split_window_focus_spec: OK")
