# dotfiles

Personal configuration files for development environment.

## Contents

| Tool | Config | Location on system |
|------|--------|--------------------|
| tmux | `tmux/.tmux.conf` | `~/.tmux.conf` |
| Alacritty | `alacritty/alacritty.toml` | `~/.config/alacritty/alacritty.toml` (macOS/Linux/WSL) / `%APPDATA%\alacritty\alacritty.toml` (Windows) |
| zsh | `shell/zshrc` | `~/.zshrc` |

## Layout

Every config is a shared base plus one per-OS profile:

```
tmux/.tmux.conf          alacritty/alacritty.toml     shell/zshrc
tmux/os/macos.conf       alacritty/os/macos.toml      shell/os/macos.zsh
tmux/os/linux.conf       alacritty/os/linux.toml      shell/os/linux.zsh
tmux/os/wsl.conf         alacritty/os/wsl.toml        shell/os/wsl.zsh
```

The split is by **operating system**, and only things that genuinely differ
per OS live in the profiles: which command reaches the system clipboard
(`pbcopy` / `wl-copy` / `xclip` / `clip.exe`), OS-only `PATH` entries, and
keyboard quirks caused by how that platform delivers keys. Everything else —
prefix, splits, resize, plugins, and the whole clipboard *mechanism* — stays
in the base, identical everywhere.

Detection is automatic and runs on every config load (including tmux
`prefix r`), so there is no per-machine setup step. **WSL is checked before
plain Linux**, because WSL is Linux too and would otherwise match its branch:

| Profile | Test |
|---------|------|
| macos | `uname -s` = `Darwin` |
| wsl | `microsoft` in `/proc/version` |
| linux | `uname -s` = `Linux` and not WSL |

Alacritty has no runtime conditionals, so `alacritty/os/current.toml` is a
local, untracked symlink pointed at the right profile by
`alacritty/select-device.sh` (same three-way test); the base imports that
fixed path.

There is deliberately **no `remote` profile.** Being on a server reached over
SSH is not a kind of machine, it is the absence of a clipboard tool — and
that is detected directly: `tmux/os/linux.conf` picks `wl-copy` or `xclip` if
either exists, and if neither does it leaves `copy-command` empty on purpose,
so copies still fill tmux's own buffer and travel outward over OSC 52
(`set-clipboard on`, in the base). One `if-shell` instead of a whole profile.

## Apply

**tmux:**
```bash
ln -sf ~/dotfiles/tmux/.tmux.conf ~/.tmux.conf
```
Requires [TPM](https://github.com/tmux-plugins/tpm) at `~/.tmux/plugins/tpm` for
the plugins listed in the config (`tmux-sensible`, `tmux-resurrect`,
`tmux-continuum`) to load — without it the config still applies, TPM just
won't run.

**zsh:**
```bash
ln -sf ~/dotfiles/shell/zshrc ~/.zshrc
```

**Alacritty (macOS/Linux/WSL):**
```bash
ln -sf ~/dotfiles/alacritty/alacritty.toml ~/.config/alacritty/alacritty.toml
~/dotfiles/alacritty/select-device.sh
```
`select-device.sh` is idempotent — safe to re-run any time (e.g. after moving
the dotfiles checkout to a new machine or restoring a snapshot) to re-point
`os/current.toml` at the right profile. Machines set up before the
`devices/` → `os/` rename **must re-run it once**: the old
`devices/current.toml` symlink is no longer imported.

**Alacritty (Windows):**
```powershell
Copy-Item alacritty\alacritty.toml "$env:APPDATA\alacritty\alacritty.toml"
```

## Keybindings

tmux prefix is `Ctrl+a` (not the tmux default `Ctrl+b`).

| Action | Key | RU (ЙЦУКЕН) duplicate (`os/wsl.conf` only) |
|--------|-----|------------------------|
| Split horizontal | prefix `\` | — (same char on both layouts) |
| Split vertical | prefix `-` | — (same char on both layouts) |
| Resize down/up/right/left | prefix `j`/`k`/`l`/`h` | `о`/`л`/`д`/`р` |
| Zoom pane | prefix `m` | `ь` |
| New session (asks for a name) | prefix `N` | — |
| Begin selection (copy-mode) | `v` | `м` |
| Copy selection (copy-mode) | `y` | `н` |
| Push tmux buffer to system clipboard | prefix `Ctrl+c` | — |
| Paste system clipboard into pane | prefix `Ctrl+v` | — |

The RU duplicates live in `tmux/os/wsl.conf` because the keyboard layout
there is switched at the Windows-host level (WSLg forwards the
already-translated character), so any tmux binding keyed on a specific letter
breaks under a non-Latin layout unless a duplicate binding is added for the
character that layout produces on the same physical key. Other systems don't
need them.

Alacritty `Ctrl+Shift+C`/`Ctrl+Shift+V` (copy/paste) are bound per OS.
`os/wsl.toml` binds by raw scancode (`46`/`47`) so a single binding works
under any layout, and explicitly disables Alacritty's own named `"C"`/`"V"`
defaults first (`action = "None"`) — otherwise both match under an EN layout
and the action fires twice. `os/linux.toml` keeps the named bindings and adds
RU duplicates (`С`/`М`) instead. `os/macos.toml` needs neither: the system
gesture there is `Cmd+C`/`Cmd+V`, and the named `Ctrl+Shift` pair is kept only
for muscle memory shared with the other machines.

## Clipboard

The goal is one gesture everywhere: **select with the mouse, paste anywhere.**
Four pieces make that work, and only the first is per-OS.

1. `copy-command` — set in the OS profile, the single place that knows how to
   reach the system clipboard. `copy-pipe-and-cancel` in the base is used
   *without* an argument, so it picks that command up and fills both the tmux
   buffer and the system clipboard at once.
2. `set-clipboard on` — accepts OSC 52 from applications inside a pane (vim,
   Claude Code) and forwards it out to the terminal. On a host with no
   clipboard tool of its own this is the only way out, which is why it sits in
   the base rather than a profile.
3. Mouse drag, double-click and triple-click are re-bound in the root table
   without tmux's default `#{mouse_any_flag}` branch. By default tmux hands
   the whole drag to any application that asked for the mouse (Claude Code,
   vim, htop), so a plain selection inside such a pane never reaches tmux and
   copies nothing. Clicks and the wheel are deliberately left to the
   application — taking those breaks its UI and scrolling.
4. `Ctrl+V` in zsh pastes the system clipboard. zsh binds `Ctrl+V` to
   `quoted-insert` by default, which looks like nothing happening; literal
   input moves to `Ctrl+Q`.

One case stays manual on purpose: tmux only forwards an application's OSC 52
outward from a **visible** pane of an attached session. Something copied by an
app in a background window lands in tmux's own buffer and nowhere else —
prefix `Ctrl+c` pushes it to the system clipboard.
