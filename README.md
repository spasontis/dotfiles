# dotfiles

Personal configuration files for development environment.

## Contents

| Tool | Config | Location on system |
|------|--------|--------------------|
| tmux | `tmux/.tmux.conf` | `~/.tmux.conf` |
| Alacritty | `alacritty/alacritty.toml` | `%APPDATA%\alacritty\alacritty.toml` (Windows) / `~/.config/alacritty/alacritty.toml` (Linux/WSL) |

## Apply

**tmux:**
```bash
ln -sf ~/dotfiles/tmux/.tmux.conf ~/.tmux.conf
```
Requires [TPM](https://github.com/tmux-plugins/tpm) at `~/.tmux/plugins/tpm` for
the plugins listed in the config (`tmux-sensible`, `tmux-resurrect`,
`tmux-continuum`) to load — without it the config still applies, TPM just
won't run.

**Alacritty (Windows):**
```powershell
Copy-Item alacritty\alacritty.toml "$env:APPDATA\alacritty\alacritty.toml"
```

**Alacritty (Linux/WSL):**
```bash
cp ~/dotfiles/alacritty/alacritty.toml ~/.config/alacritty/alacritty.toml
```

## Keybindings

tmux prefix is `Ctrl+a` (not the tmux default `Ctrl+b`).

| Action | Key | RU (ЙЦУКЕН) duplicate |
|--------|-----|------------------------|
| Split horizontal | prefix `\` | — (same char on both layouts) |
| Split vertical | prefix `-` | — (same char on both layouts) |
| Resize down/up/right/left | prefix `j`/`k`/`l`/`h` | `о`/`л`/`д`/`р` |
| Zoom pane | prefix `m` | `ь` |
| Begin selection (copy-mode) | `v` | `м` |
| Copy selection (copy-mode) | `y` | `н` |

Alacritty `Ctrl+Shift+C`/`Ctrl+Shift+V` (copy/paste) bind by raw scancode
(`46`/`47`) instead of named keys, so they work regardless of the active
keyboard layout with a single binding each. (Named + scancode bindings for
the same key must not be combined — both would match on a matching keypress
and fire the action twice, e.g. pasting the clipboard content twice.)

The RU duplicates exist because the keyboard layout is switched at the
Windows-host level (WSLg forwards the already-translated character), so any
tmux binding keyed on a specific letter breaks under a non-Latin layout unless
a duplicate binding is added for the character that layout produces on the
same physical key.
