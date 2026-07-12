# dotfiles

Personal configuration files for development environment.

## Contents

| Tool | Config | Location on system |
|------|--------|--------------------|
| tmux | `tmux/.tmux.conf` | `~/.tmux.conf` |
| Alacritty | `alacritty/alacritty.toml` | `%APPDATA%\alacritty\alacritty.toml` (Windows) / `~/.config/alacritty/alacritty.toml` (Linux/WSL) |

Both configs are a device-agnostic base plus per-device overrides in
`tmux/devices/` and `alacritty/devices/` (`wsl.*`, `linux.*`, and — for
tmux only — `remote.*`). This exists so that quirks specific to one
machine (see Keybindings below) don't have to leak into the shared base as
more devices get added. Device selection is automatic: tmux detects at
every load via `if-shell` (WSL via `/proc/version`, else hostname
`m0nstertrack` vs. anything else = remote); Alacritty has no runtime
conditionals, so `alacritty/devices/current.toml` is a local, untracked
symlink pointed at the right file by `alacritty/select-device.sh` (same
WSL/else detection). Alacritty is a local GUI terminal emulator, so it only
has `wsl`/`linux` profiles — no `remote`.

## Apply

**tmux:**
```bash
ln -sf ~/dotfiles/tmux/.tmux.conf ~/.tmux.conf
```
Requires [TPM](https://github.com/tmux-plugins/tpm) at `~/.tmux/plugins/tpm` for
the plugins listed in the config (`tmux-sensible`, `tmux-resurrect`,
`tmux-continuum`) to load — without it the config still applies, TPM just
won't run. Device detection happens automatically on every config load
(including `prefix r` reload), no extra step needed.

**Alacritty (Windows):**
```powershell
Copy-Item alacritty\alacritty.toml "$env:APPDATA\alacritty\alacritty.toml"
```

**Alacritty (Linux/WSL):**
```bash
cp ~/dotfiles/alacritty/alacritty.toml ~/.config/alacritty/alacritty.toml
~/dotfiles/alacritty/select-device.sh
```
`select-device.sh` is idempotent — safe to re-run any time (e.g. after
moving the dotfiles checkout to a new machine or restoring a snapshot) to
re-point `devices/current.toml` at the right profile.

## Keybindings

tmux prefix is `Ctrl+a` (not the tmux default `Ctrl+b`).

| Action | Key | RU (ЙЦУКЕН) duplicate (`devices/wsl.conf` only) |
|--------|-----|------------------------|
| Split horizontal | prefix `\` | — (same char on both layouts) |
| Split vertical | prefix `-` | — (same char on both layouts) |
| Resize down/up/right/left | prefix `j`/`k`/`l`/`h` | `о`/`л`/`д`/`р` |
| Zoom pane | prefix `m` | `ь` |
| Begin selection (copy-mode) | `v` | `м` |
| Copy selection (copy-mode) | `y` | `н` |

The RU duplicates live in `tmux/devices/wsl.conf` because the keyboard
layout there is switched at the Windows-host level (WSLg forwards the
already-translated character), so any tmux binding keyed on a specific
letter breaks under a non-Latin layout unless a duplicate binding is added
for the character that layout produces on the same physical key. Other
devices don't need them.

Alacritty `Ctrl+Shift+C`/`Ctrl+Shift+V` (copy/paste), in both
`alacritty/devices/wsl.toml` and `alacritty/devices/linux.toml`, bind by raw
scancode (`46`/`47`) instead of named keys, so they work regardless of the
active keyboard layout with a single binding each. Alacritty ships its own
`Ctrl+Shift+C`/`Ctrl+Shift+V` defaults keyed by named key (`"C"`/`"V"`),
which still match whenever the active layout produces that letter (e.g. EN)
and would fire alongside the scancode bindings above, pasting/copying
twice — so those two named defaults are explicitly disabled
(`action = "None"`) before the scancode bindings are added.
