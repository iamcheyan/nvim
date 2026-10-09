#!/usr/bin/env bash
# Standalone bootstrap; also works inside dotfiles/config/nvim.
set -Eeuo pipefail

fail() { printf 'nvim-init: %s\n' "$*" >&2; exit 1; }
link_only=0
skip_plugins=0
skip_install=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --link-only) link_only=1 ;;
    --skip-plugins) skip_plugins=1 ;;
    --skip-install) skip_install=1 ;;
    --help|-h)
      printf 'Usage: bash init.sh [--link-only] [--skip-plugins] [--skip-install]\n'
      printf 'Backs up existing configuration and links this checkout. Requires Neovim 0.12+.\n'
      exit 0 ;;
    *) fail "Unknown option: $1" ;;
  esac
  shift
done

# A downloaded /dev/fd script has no checkout; clone into ~/nvim first.
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
if [[ -f "$script_dir/init.lua" && -f "$script_dir/lua/config/lazy.lua" ]]; then
  source_dir="$script_dir"
else
  source_dir="${NVIM_SOURCE_DIR:-$HOME/nvim}"
  command -v git >/dev/null || fail 'Install git before bootstrapping.'
  if [[ ! -e "$source_dir" ]]; then
    git clone https://github.com/iamcheyan/nvim.git "$source_dir"
  fi
  [[ -f "$source_dir/init.lua" && -f "$source_dir/init.sh" ]] || fail "Not an nvim checkout: $source_dir"
  args=()
  (( link_only )) && args+=(--link-only)
  (( skip_plugins )) && args+=(--skip-plugins)
  (( skip_install )) && args+=(--skip-install)
  exec bash "$source_dir/init.sh" "${args[@]}"
fi

venv_supported() {
  local probe result=0
  probe="$(mktemp -d)"
  python3 -m venv "$probe/venv" >/dev/null 2>&1 || result=$?
  rm -rf -- "$probe"
  return "$result"
}

ensure_dependencies() {
  local missing=() tool
  for tool in git curl jq tar rg cc unzip python3 tree-sitter; do
    command -v "$tool" >/dev/null || missing+=("$tool")
  done
  venv_supported || missing+=(python3-venv)
  (( ${#missing[@]} == 0 )) && return 0
  (( skip_install == 0 )) || fail "Missing dependencies: ${missing[*]}"
  if [[ -r /etc/NIXOS ]]; then
    fail "Declare git, curl, jq, ripgrep, unzip, Python, Tree-sitter CLI and a C compiler in your NixOS configuration. Missing: ${missing[*]}"
  fi
  local elevate=()
  if [[ $(id -u) != 0 ]]; then
    command -v sudo >/dev/null || fail 'sudo is required to install missing dependencies.'
    elevate=(sudo)
  fi
  if command -v brew >/dev/null; then
    brew install git curl jq ripgrep unzip python tree-sitter
    command -v cc >/dev/null || fail 'Install Xcode Command Line Tools: xcode-select --install'
  elif command -v apt-get >/dev/null; then
    "${elevate[@]}" apt-get update
    "${elevate[@]}" apt-get install -y git curl jq ripgrep build-essential tar unzip python3 python3-venv python3-pip cargo
  elif command -v pacman >/dev/null; then
    "${elevate[@]}" pacman -S --needed --noconfirm git curl jq ripgrep base-devel tar unzip python python-pip tree-sitter-cli cargo
  else
    fail "Install these dependencies with your package manager: ${missing[*]}"
  fi
}

nvim_bin="$(command -v nvim || true)"
supported() { [[ -n "$nvim_bin" ]] && "$nvim_bin" --clean --headless '+lua if vim.fn.has("nvim-0.12") == 0 then vim.cmd("cquit") end' +qa >/dev/null 2>&1; }
if (( link_only == 0 )); then
  ensure_dependencies
  venv_supported || fail 'Install Python venv support (Debian: python3-venv).'
  cli_version="$(tree-sitter --version 2>/dev/null || true)"
  if ! python3 -c 'import re,sys; v=re.search(r"(\d+)\.(\d+)\.(\d+)",sys.argv[1]); sys.exit(0 if v and tuple(map(int,v.groups())) >= (0,26,1) else 1)' "$cli_version"; then
    (( skip_install == 0 )) || fail 'Tree-sitter CLI 0.26.1+ is required.'
    [[ ! -r /etc/NIXOS ]] || fail 'Declare tree-sitter CLI 0.26.1+ in your NixOS configuration.'
    command -v cargo >/dev/null || fail 'Install Rust/Cargo or tree-sitter-cli 0.26.1+ with your package manager.'
    cargo install tree-sitter-cli --locked --version 0.26.8
    export PATH="${CARGO_HOME:-$HOME/.cargo}/bin:$PATH"
  fi
  if ! supported; then
    (( skip_install == 0 )) || fail 'Neovim 0.12 or newer is required.'
    bash "$source_dir/scripts/install-neovim.sh"
    nvim_bin="$HOME/.local/bin/nvim"
    supported || fail 'Installed Neovim does not meet the minimum version.'
  fi
fi

config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
target="$config_home/nvim"
mkdir -p "$config_home"
# Compare physical directories so relative symlinks also remain untouched.
if [[ -d "$target" && "$(cd -- "$target" && pwd -P)" == "$source_dir" ]]; then
  printf 'Configuration already points to %s\n' "$source_dir"
else
  if [[ -e "$target" || -L "$target" ]]; then
    backup="$target.backup.$(date +%Y%m%d-%H%M%S).$$"
    mv -- "$target" "$backup"
    printf 'Existing configuration backed up to %s\n' "$backup"
  fi
  ln -s -- "$source_dir" "$target"
  printf 'Linked %s -> %s\n' "$target" "$source_dir"
fi

if (( link_only == 0 && skip_plugins == 0 )); then
  [[ -z "${NVIM_APPNAME:-}" || "$NVIM_APPNAME" == nvim ]] || fail 'Unset NVIM_APPNAME when installing the default nvim configuration.'
  "$nvim_bin" --headless '+Lazy! sync' +qa
fi
printf 'Ready. Configuration updates: git -C "%s" pull --ff-only\n' "$source_dir"
printf 'Open Neovim with: %s\n' "${nvim_bin:-nvim}"
