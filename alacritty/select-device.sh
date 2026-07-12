#!/usr/bin/env bash
# Points alacritty/devices/current.toml at the right per-device keyboard
# config for this machine. Safe to re-run any time (idempotent).
set -euo pipefail
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/devices"

if grep -qi microsoft /proc/version 2>/dev/null; then
  target=wsl.toml
else
  target=linux.toml
fi

ln -sf "$dir/$target" "$dir/current.toml"
echo "alacritty/devices/current.toml -> $target"
