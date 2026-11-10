-- Bootstrap lazy.nvim and the local Neovim configuration.
require("config.lazy")

-- Loaded early so the sidebar remembers its state without waiting for plugins.
require("config.sidebar_state").setup()
