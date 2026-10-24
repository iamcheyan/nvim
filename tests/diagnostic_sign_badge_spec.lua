-- Diagnostic sign badge styling regression spec.
-- Verify that diagnostic signs in gutter have high-contrast background badges.
-- Run: nvim --headless -u NONE -l tests/diagnostic_sign_badge_spec.lua

local this_file = debug.getinfo(1, "S").source:sub(2)
local nvim_root = vim.fn.fnamemodify(this_file, ":h:h")
vim.opt.runtimepath:prepend(nvim_root)
package.path = nvim_root .. "/lua/?.lua;" .. nvim_root .. "/lua/?/init.lua;" .. package.path
vim.cmd("filetype plugin indent on")
dofile(nvim_root .. "/lua/config/options.lua")

local ui = require("config.ui_highlights")
ui.apply()

local err = vim.api.nvim_get_hl(0, { name = "DiagnosticSignError", link = false })
assert(err.bg ~= nil, "DiagnosticSignError must have an opaque background for badge prominence")
assert(err.fg ~= nil, "DiagnosticSignError must have a high-contrast foreground")
assert(err.bold == true, "DiagnosticSignError must be bold")

local warn = vim.api.nvim_get_hl(0, { name = "DiagnosticSignWarn", link = false })
assert(warn.bg ~= nil, "DiagnosticSignWarn must have an opaque background")
assert(warn.fg ~= nil, "DiagnosticSignWarn must have a high-contrast foreground")
assert(warn.bold == true, "DiagnosticSignWarn must be bold")

local info = vim.api.nvim_get_hl(0, { name = "DiagnosticSignInfo", link = false })
assert(info.bg ~= nil, "DiagnosticSignInfo must have an opaque background")
assert(info.bold == true, "DiagnosticSignInfo must be bold")

local hint = vim.api.nvim_get_hl(0, { name = "DiagnosticSignHint", link = false })
assert(hint.bg ~= nil, "DiagnosticSignHint must have an opaque background")
assert(hint.bold == true, "DiagnosticSignHint must be bold")

-- Ensure re-applying colorscheme maintains the badge styles
pcall(vim.cmd.colorscheme, "nostalgia")
ui.apply()
local err_nostalgia = vim.api.nvim_get_hl(0, { name = "DiagnosticSignError", link = false })
assert(err_nostalgia.bg ~= nil, "DiagnosticSignError must preserve background on colorscheme switch")

-- Ensure Nerd Font icons are populated in vim.diagnostic.config when have_nerd_font is set
local diag_cfg = vim.diagnostic.config()
assert(diag_cfg.signs and diag_cfg.signs.text, "diagnostic signs must specify text when Nerd Font is enabled")
assert(diag_cfg.signs.text[vim.diagnostic.severity.WARN] == " ", "Warning sign icon mismatch")
assert(diag_cfg.signs.text[vim.diagnostic.severity.ERROR] == " ", "Error sign icon mismatch")
assert(diag_cfg.signs.text[vim.diagnostic.severity.INFO] == " ", "Info sign icon mismatch")
assert(diag_cfg.signs.text[vim.diagnostic.severity.HINT] == " ", "Hint sign icon mismatch")

-- Ensure statuscolumn formats diagnostic sign badges without trailing space in the badge highlight
local lazy_snacks = vim.fn.stdpath("data") .. "/lazy/snacks.nvim"
if vim.fn.isdirectory(lazy_snacks) == 1 then
  vim.opt.runtimepath:prepend(lazy_snacks)
  local snacks_spec = dofile(nvim_root .. "/lua/plugins/snacks.lua")[1]
  pcall(snacks_spec.config, nil, snacks_spec.opts)
  local sc = require("snacks.statuscolumn")
  local formatted_warn = sc.icon({ text = " ", texthl = "DiagnosticSignWarn", type = "sign" })
  assert(formatted_warn == "%#DiagnosticSignWarn#%* ", "Diagnostic badge must isolate glyph to center icon")
end

-- Ensure Neo-tree diagnostics are fully disabled for performance
local nt_spec = dofile(nvim_root .. "/lua/plugins/neo-tree.lua")[1]
assert(nt_spec.opts.enable_diagnostics == false, "Neo-tree diagnostics must be disabled for performance")

print("diagnostic_sign_badge_spec: OK")
