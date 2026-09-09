#!/usr/bin/env bash
# Points alacritty/os/current.toml at the right per-OS keyboard config for
# this machine. Safe to re-run any time (idempotent).
#
# Alacritty has no runtime conditionals, so the base config imports a fixed
# path and this script decides what that path resolves to. Order matters:
# WSL is checked before plain Linux, because WSL is Linux too.
set -euo pipefail
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/os"

if [ "$(uname -s)" = Darwin ]; then
  target=macos.toml
elif grep -qi microsoft /proc/version 2>/dev/null; then
  target=wsl.toml
else
  target=linux.toml
fi

ln -sf "$dir/$target" "$dir/current.toml"
echo "alacritty/os/current.toml -> $target"
