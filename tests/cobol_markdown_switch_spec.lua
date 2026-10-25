-- Regression spec: Switching between COBOL and Markdown buffers must never leak
-- COBOL window matches (such as CobolColumnOverflow error highlighting) into Markdown.
-- Run: nvim --headless -u init.lua -c "lua dofile('tests/cobol_markdown_switch_spec.lua')"

local nvim_root = vim.fn.stdpath("config")
vim.cmd("filetype plugin indent on")

local cobol = vim.api.nvim_create_buf(true, false)
vim.api.nvim_buf_set_name(cobol, "/tmp/smoke.cob")
vim.api.nvim_buf_set_lines(cobol, 0, -1, false, {
  "       IDENTIFICATION DIVISION.",
  "       PROGRAM-ID. SMOKE.",
  "       PROCEDURE DIVISION.",
  "           DISPLAY 'HELLO' " .. string.rep("X", 80), -- line exceeding column 72
})
vim.bo[cobol].filetype = "cobol"

local markdown = vim.api.nvim_create_buf(true, false)
vim.api.nvim_buf_set_name(markdown, "/tmp/smoke.md")
vim.api.nvim_buf_set_lines(markdown, 0, -1, false, {
  "# Heading 1",
  "",
  "This is a long markdown paragraph that exceeds 72 characters and should never show overflow error highlights when switching from COBOL.",
  "",
  "```cobol",
  "DISPLAY 'INSIDE CODE BLOCK'",
  "```",
})
vim.bo[markdown].filetype = "markdown"

-- 1. Start in COBOL
vim.api.nvim_win_set_buf(0, cobol)
local matches_in_cobol = vim.fn.getmatches(0)
assert(#matches_in_cobol > 0, "COBOL buffer must have window matches (e.g. CobolColumnOverflow)")

-- 2. Switch to Markdown
vim.api.nvim_win_set_buf(0, markdown)
local matches_in_md = vim.fn.getmatches(0)
for _, m in ipairs(matches_in_md) do
  assert(not vim.startswith(m.group, "Cobol"), "Cobol match must NOT remain in markdown window: " .. tostring(m.group))
end

-- 3. Switch back to COBOL
vim.api.nvim_win_set_buf(0, cobol)
local matches_in_cobol2 = vim.fn.getmatches(0)
assert(#matches_in_cobol2 > 0, "COBOL buffer must restore its window matches")

-- 4. Switch back to Markdown again
vim.api.nvim_win_set_buf(0, markdown)
local matches_in_md2 = vim.fn.getmatches(0)
for _, m in ipairs(matches_in_md2) do
  assert(not vim.startswith(m.group, "Cobol"), "Cobol match must NOT remain in markdown window on second switch: " .. tostring(m.group))
end

-- 5. Verify Markdown typography is active
local ns = vim.api.nvim_get_hl_ns({ winid = 0 })
assert(ns > 0, "Markdown window must have active typography namespace")
local normal = vim.api.nvim_get_hl(ns, { name = "Normal", link = false })
assert(normal.bg == 0xffffff, "Markdown background must be paper white (#ffffff)")

print("cobol_markdown_switch_spec: OK")
vim.cmd("qa!")
