-- Sticky context header should be a solid, slightly darker surface with no
-- frame around it.
-- Run: nvim --headless -u NONE -l tests/treesitter_context_style_spec.lua
local this_file = debug.getinfo(1, "S").source:sub(2)
local nvim_root = vim.fn.fnamemodify(this_file, ":h:h")
vim.opt.runtimepath:prepend(nvim_root)
package.path = nvim_root .. "/lua/?.lua;" .. nvim_root .. "/lua/?/init.lua;" .. package.path
vim.cmd("filetype plugin indent on")
dofile(nvim_root .. "/lua/config/options.lua")

assert(vim.g.colors_name == "blue", "context styling test expects the default blue theme")

local ui = require("config.ui_highlights")
ui.apply()
ui.apply()

local function channels(color)
  return math.floor(color / 65536) % 256, math.floor(color / 256) % 256, color % 256
end

local normal = vim.api.nvim_get_hl(0, { name = "Normal", link = false })
local context = vim.api.nvim_get_hl(0, { name = "TreesitterContext", link = false })
local context_number = vim.api.nvim_get_hl(0, { name = "TreesitterContextLineNumber", link = false })
local context_bottom = vim.api.nvim_get_hl(0, { name = "TreesitterContextBottom", link = false })

local nr, ng, nb = channels(normal.bg)
local cr, cg, cb = channels(context.bg)
assert(cr == 0 and cg == 0 and cb > 0, "context surface should stay blue")
assert(cb < nb and nr == 0 and ng == 0, "context surface should be a darker blue than Normal")
assert(context.fg == normal.fg, "context text should inherit the document foreground")
assert(context_number.bg == context.bg, "line number gutter must share the opaque context surface")
assert(context_number.ctermbg == context.ctermbg, "terminal fallback must stay opaque too")
assert(context.ctermbg < normal.ctermbg, "terminal fallback should also be darker")
assert(context_bottom.bg == context.bg, "bottom line should keep the context surface")
assert(context_bottom.fg == nil, "bottom line must not replace the syntax foreground")
assert(context_bottom.underline == true, "bottom line must have underline divider")
assert(context_bottom.sp ~= nil, "bottom line must define underline color")

-- Test pitch-black theme (e.g. oceanblack): surface must be elevated above 0, not pitch black
pcall(vim.cmd.colorscheme, "oceanblack")
ui.apply()
local black_ctx = vim.api.nvim_get_hl(0, { name = "TreesitterContext", link = false })
local black_bottom = vim.api.nvim_get_hl(0, { name = "TreesitterContextBottom", link = false })
assert(black_ctx.bg and black_ctx.bg > 0, "black theme must elevate context surface above pitch black")
assert(black_bottom.underline == true and black_bottom.sp ~= nil, "black theme must have distinct underline divider")

-- Test light theme (e.g. delek): surface must be a subtle paper tint, not dark gray
pcall(vim.cmd.colorscheme, "delek")
ui.apply()
local delek_ctx = vim.api.nvim_get_hl(0, { name = "TreesitterContext", link = false })
local delek_bottom = vim.api.nvim_get_hl(0, { name = "TreesitterContextBottom", link = false })
assert(delek_ctx.bg and delek_ctx.bg > 0xe0e0e0, "light theme context surface must stay light paper")
assert(delek_bottom.underline == true and delek_bottom.sp ~= nil, "light theme must have distinct underline divider")

-- Restore blue theme
pcall(vim.cmd.colorscheme, "blue")
ui.apply()

-- Test Markdown window typography integration
local md = require("config.markdown_typography")
md.setup()
local md_buf = vim.api.nvim_create_buf(true, false)
vim.bo[md_buf].filetype = "markdown"
vim.api.nvim_win_set_buf(0, md_buf)
vim.api.nvim_exec_autocmds("FileType", { buffer = md_buf })
vim.api.nvim_exec_autocmds("BufEnter", { buffer = md_buf })

local md_winhl = vim.wo[0].winhighlight
assert(md_winhl:match("TreesitterContext:MdTypographyTreesitterContext"), "markdown window must map TreesitterContext")
assert(md_winhl:match("TreesitterContextBottom:MdTypographyTreesitterContextBottom"), "markdown window must map TreesitterContextBottom")

local md_ctx_hl = vim.api.nvim_get_hl(0, { name = "MdTypographyTreesitterContext", link = false })
assert(md_ctx_hl.bg == 0xf5f5f5, "markdown context must use light paper background")

local spec = dofile(nvim_root .. "/lua/plugins/treesitter-context.lua")[1]
assert(spec.opts.separator == nil, "context header must not draw a separator border")

-- The global float adapter must leave the plugin's borderless float alone.
local buf = vim.api.nvim_create_buf(false, true)
local win = vim.api.nvim_open_win(buf, false, {
  relative = "editor",
  row = 1,
  col = 1,
  width = 5,
  height = 1,
  style = "minimal",
  focusable = false,
  border = "none",
})
assert(vim.api.nvim_win_get_config(win).border == "none", "context floats must not gain a single border")
vim.api.nvim_win_close(win, true)

print("treesitter_context_style_spec: OK")
