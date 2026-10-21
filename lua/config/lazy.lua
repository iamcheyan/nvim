-- nvim/lua/lazy.lua

-- Set leader keys before lazy.nvim loads. lazy.nvim warns (and <leader>
-- mappings created by plugins would bind to the wrong key) if these aren't
-- set first. Values match LazyVim's defaults (lazyvim/config/options.lua).
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Load our options early (previously done by LazyVim's config.init()).
require("config.options")

-- Prefer the current Cargo CLI over an older system CLI, including GUI sessions.
local cargo_bin = (vim.env.CARGO_HOME or vim.fn.expand("~/.cargo")) .. "/bin"
if vim.fn.executable(cargo_bin .. "/tree-sitter") == 1 then
  vim.env.PATH = cargo_bin .. ":" .. (vim.env.PATH or "")
end

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-- All plugin specs live in this repository. Optional local development settings
-- are machine-local and never required by ordinary installations.
local spec = { { import = "plugins" } }
local local_file = (vim.env.XDG_CONFIG_HOME or vim.fn.expand("~/.config")) .. "/nvim-local.lua"
local local_opts = {}
if vim.fn.filereadable(local_file) == 1 then
  local_opts = dofile(local_file) or {}
end

-- Register the "LazyFile" pseudo-event so plugin specs using
-- `event = "LazyFile"` keep working. Mirrors LazyVim's original registration.
local Event = require("lazy.core.handler.event")
Event.mappings.LazyFile = { id = "LazyFile", event = { "BufReadPost", "BufNewFile", "BufWritePre" } }
Event.mappings["User LazyFile"] = Event.mappings.LazyFile

local function ensure_lockfile(path)
  local dir = vim.fn.fnamemodify(path, ":p:h")
  vim.fn.mkdir(dir, "p")
  if vim.fn.filereadable(path) == 0 then
    pcall(vim.fn.writefile, { "{}" }, path)
  end
  return path
end

local lockfile = ensure_lockfile(vim.fn.stdpath("config") .. "/lazy-lock.json")
if vim.fn.filewritable(lockfile) ~= 1 then
  lockfile = ensure_lockfile(vim.fn.stdpath("state") .. "/lazy-lock.json")
end

require("lazy").setup(vim.tbl_deep_extend("force", {
  -- Public configuration, including independently installable custom plugins.
  spec = spec,
  -- Force a concrete lockfile path to avoid nil/invalid values
  lockfile = lockfile,
  -- Don't open lockfile on startup
  open = false,
  defaults = {
    -- Specs with no lazy/event/cmd/keys/ft still load at startup. mason-lspconfig
    -- and nvim-web-devicons are in that set; flipping this to true would skip
    -- vim.lsp.enable and the icon overrides until something else required them.
    lazy = false,
    -- It's recommended to leave version=false for now, since a lot the plugin that support versioning,
    -- have outdated releases, which may break your Neovim install.
    version = false, -- always use the latest git commit
    -- version = "*", -- try installing the latest stable version for plugins that support semver
  },
  install = { colorscheme = { "blue" } },
  checker = {
    enabled = false, -- :Lazy check is manual; startup no longer calls GitHub
    notify = false,
  },
  performance = {
    rtp = {
      -- disable some rtp plugins
      disabled_plugins = {
        "gzip",
        -- "matchit",
        -- "matchparen",
        -- "netrwPlugin",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
  ui = {
    border = "single",
  },
}, local_opts))

-- Baseline <leader> keymaps ported from LazyVim's defaults and adapted to the
-- plugins we actually run (snacks picker, gitsigns, vim builtins).
require("config.keymaps-defaults")
-- Load personal keymaps last so they intentionally override compatibility
-- mappings when the same lhs is used.
require("config.keymaps")

-- Delek's palette is thousands of highlight entries. Load it with the first
-- Markdown buffer instead of at startup.
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("MarkdownTypographySetup", { clear = true }),
  pattern = "markdown",
  callback = function()
    require("config.markdown_typography").setup()
  end,
})
require("config.markdown_image_paste").setup()
require("config.scrollbar_scroll").setup()
require("config.autocmds")
