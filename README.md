# Neovim

Standalone Neovim configuration, also available as the `config/nvim` submodule
of [iamcheyan/dotfiles](https://github.com/iamcheyan/dotfiles).
Requires Neovim **0.12+**, Git, curl, jq, ripgrep, a C compiler, Python/venv, unzip, Tree-sitter CLI 0.26.1+, and a Nerd Font.
Linux and macOS are supported; WSL uses the Linux path.

## Install independently

```bash
git clone https://github.com/iamcheyan/nvim.git ~/nvim
bash ~/nvim/init.sh
```

Or bootstrap directly (requires Git and curl):

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/iamcheyan/nvim/main/init.sh)
```

The script links `${XDG_CONFIG_HOME:-$HOME/.config}/nvim` to the checkout,
backs up an existing file/directory/symlink, and installs plugins with lazy.nvim.
Repeated runs preserve the existing link. Bookmarks, sessions and plugin data
remain in Neovim's data/state directories.

Missing build/search/Python dependencies are installed through apt, pacman or Homebrew.
An outdated Tree-sitter CLI can be installed through Cargo (Rust is required).
When Neovim is missing or older than 0.12, the installer downloads an official
stable release, verifies its SHA-256 digest and installs it under `~/.local`.
On NixOS, declare missing packages in your system/Home Manager configuration.
If Neovim is installed locally, put `~/.local/bin` before system directories in PATH.

Options:

- `--link-only`: create the configuration link without installing anything.
- `--skip-plugins`: prepare dependencies and link; defer plugin installation to first launch.
- `--skip-install`: use existing dependencies; fail if anything required is missing.

## Update

```bash
git -C ~/nvim pull --ff-only
```

Run `:Lazy sync` inside Neovim to update plugins. `lazy-lock.json` is local and
ignored; keep it to preserve your installed plugin revisions.

## Install through dotfiles

The existing `dotfiles/init.sh` installs the nvim submodule and dotlink links
`~/dotfiles/config/nvim` to `~/.config/nvim`. No separate clone is needed.

Existing users migrating from the former ordinary directory should first commit
or back up local edits in `config/nvim`, then run:

```bash
cd ~/dotfiles
git pull --recurse-submodules
git submodule update --init --recursive
bash dotlink/dotlink link
```

`init.sh` enables local recursive Git operations. Subsequent `git pull` follows
the nvim revision recorded by dotfiles. Gitlinks pin revisions: pulling nvim's
latest main directly is a separate operation.

## Independent plugins and local development

VimQuest, contextline.nvim, cobol.nvim, batch.nvim and bookmark.nvim remain
independent public repositories. lazy.nvim installs them without chezmoi.

Clone the plugins you develop beneath `~/development/nvim-plugins`. Create
`${XDG_CONFIG_HOME:-$HOME/.config}/nvim-local.lua` outside this repository:

```lua
return {
  dev = {
    path = vim.fn.expand("~/development/nvim-plugins"),
    patterns = { "iamcheyan" },
    fallback = true,
  },
}
```

Directory names must match lazy.nvim plugin names (VimQuest uses `VimQuest.nvim`).
Only this machine uses the development checkouts; ordinary installations fetch GitHub.
Push plugin changes from their own repositories. Maintain the nvim checkout here,
then update the dotfiles submodule pointer when ready to distribute a version.

To edit directly inside the submodule, first run `git switch main` there; submodule
updates normally check out a detached revision. Never discard local changes to update.

Documentation: [plugin guide](docs/plugin-guide/README.md),
[Treesitter requirements](docs/reference/TREESITTER.md),
[mouse and clipboard](docs/guides/MOUSE-AND-CLIPBOARD.md).
