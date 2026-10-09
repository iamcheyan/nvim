# Neovim configuration

This public repository is the canonical configuration source. It can be checked
out at ~/nvim or as dotfiles/config/nvim. Never assume a particular checkout path.
Edit source files; init.sh links the checkout into the Neovim configuration path.

- Require Neovim 0.12+. Keep Treesitter and textobjects on their main branches.
- Self-authored plugins have independent public Git repositories. Declare them
  in lua/plugins; edit their own development checkouts rather than vendoring code.
- Never commit credentials, local state, personal paths or nvim-local.lua.
- Keep standalone and dotfiles installation paths working.
- Before changes to the installer, run bash tests/init_spec.sh and bash -n init.sh.
- Run the relevant headless Lua regression specs and git diff --check.
- lazy-lock.json is intentionally ignored and remains machine-local.
