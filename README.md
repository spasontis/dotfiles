# dotfiles

Personal configuration files for development environment.

## Contents

| Tool | Config | Location on system |
|------|--------|--------------------|
| tmux | `tmux/.tmux.conf` | `~/.tmux.conf` |
| Alacritty | `alacritty/alacritty.toml` | `%APPDATA%\alacritty\alacritty.toml` (Windows) |

## Apply

**tmux:**
```bash
ln -sf ~/dotfiles/tmux/.tmux.conf ~/.tmux.conf
```

**Alacritty (Windows):**
```powershell
Copy-Item alacritty\alacritty.toml "$env:APPDATA\alacritty\alacritty.toml"
```
