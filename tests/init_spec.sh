#!/usr/bin/env bash
set -euo pipefail
root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
tmp="$(mktemp -d)"
trap 'rm -rf -- "$tmp"' EXIT
mkdir -p "$tmp/profile/.config/nvim" "$tmp/checkout with spaces/lua/config"
printf 'keep me\n' > "$tmp/profile/.config/nvim/user.lua"
cp "$root/init.sh" "$tmp/checkout with spaces/init.sh"
cp "$root/init.lua" "$tmp/checkout with spaces/init.lua"
cp "$root/lua/config/lazy.lua" "$tmp/checkout with spaces/lua/config/lazy.lua"
run() { HOME="$tmp/profile" XDG_CONFIG_HOME="$tmp/profile/.config" bash "$tmp/checkout with spaces/init.sh" --link-only; }
run
[[ $(readlink "$tmp/profile/.config/nvim") == "$tmp/checkout with spaces" ]]
backups=("$tmp/profile/.config/"nvim.backup.*)
[[ ${#backups[@]} == 1 && $(cat "${backups[0]}/user.lua") == 'keep me' ]]
run
backups=("$tmp/profile/.config/"nvim.backup.*)
[[ ${#backups[@]} == 1 ]]
rm "$tmp/profile/.config/nvim"
ln -s "$tmp/missing" "$tmp/profile/.config/nvim"
run
[[ $(readlink "$tmp/profile/.config/nvim") == "$tmp/checkout with spaces" ]]
if HOME="$tmp/profile" bash "$root/init.sh" --unknown >/dev/null 2>&1; then
  echo 'unknown option unexpectedly succeeded' >&2; exit 1
fi
HOME="$tmp/profile" XDG_CONFIG_HOME="$tmp/xdg" bash "$root/init.sh" --link-only
[[ $(readlink "$tmp/xdg/nvim") == "$root" ]]
printf 'init_spec: OK\n'
