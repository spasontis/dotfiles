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

tmux/ru-layout.sh        alacritty/ru-layout.toml     — keyboard layout,
                                                        shared by every OS
```

Keyboard layout is deliberately **not** part of that split: ЙЦУКЕН is not a
kind of machine, so the RU twins of every binding live in the shared
`ru-layout.*` files — see [the rule](#keyboard-layout-the-rule).

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

**Alacritty (Windows, run from WSL):**
```bash
~/dotfiles/alacritty/build-windows.sh
```
A plain copy of the base config is **not** enough since the per-OS split: on
Windows Alacritty is a Windows program and resolves `~` against the Windows
home (`C:\Users\<name>`), where this checkout does not exist, so both imports
dangle and neither the RU layout table nor the OS profile ever loads — with no
error anywhere. Alacritty has no second search path and no runtime
conditionals to work around that, so the script flattens the three files —
base without its `import` block, then one `[keyboard]` section with the RU
twins followed by the OS profile — into a single generated
`%APPDATA%\alacritty\alacritty.toml`. Re-run it after editing any of the
three; it takes a profile name as an optional argument (`wsl` by default) and
backs up a hand-written config once before replacing it.

## Keybindings

tmux prefix is `Ctrl+a` (not the tmux default `Ctrl+b`).

| Action | Key | RU (ЙЦУКЕН) |
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
| Broadcast `/clear` to every Claude Code pane in the window | prefix `B` | — |
| Select the Claude Code input line | prefix `a` | `ф` |
| Reset stuck bracketed-paste mode | prefix `P` | — |

The RU column is not maintained by hand — see the rule below.

## Keyboard layout (the rule)

**Every binding must work under both layouts, EN and ЙЦУКЕН. A change that
adds or moves a binding is not finished until its RU twin works too.** Nobody
should have to switch the layout to press a key, and no binding may fail
silently because the layout was Russian at that moment.

Why it breaks: neither tmux nor Alacritty sees a *key*, both see the
**character the layout produced**. Under ЙЦУКЕН the physical `V` sends `м`,
so a binding written for `V` matches nothing at all and the keypress does
nothing — no error, no beep. Alacritty additionally builds control codes out
of the Latin letter, so `Ctrl+A`, `Ctrl+C`, `Ctrl+V` produce no control byte
under a Cyrillic layout either, and neither tmux's prefix nor `Ctrl+C` reaches
the program.

The layout is **not a property of the machine**, so none of this belongs in
`os/*` — it is the same on macOS, Linux and WSL. Three places cover it:

| Layer | File | What it does |
|-------|------|--------------|
| tmux | `tmux/ru-layout.sh` | Mirrors **every** letter binding of the `prefix` and `copy-mode-vi` tables into ЙЦУКЕН. Run from the end of `.tmux.conf` on every config load, including prefix `r`. |
| Alacritty, `Ctrl`+letter | `alacritty/ru-layout.toml` | Sends the control code the Latin twin would send (`Ctrl+ф` → `\u0001`, i.e. `Ctrl+A`). Imported by the base config before the OS profile. |
| Alacritty, copy/paste gesture | `alacritty/os/*.toml` | The gesture itself differs per OS, so the RU twin lives next to it: `Cmd+С`/`Cmd+М` and `Ctrl+Shift+С`/`Ctrl+Shift+М` on macOS, `Ctrl+Shift+С`/`М` on Linux. |

The tmux side is a script and not a hand-written list on purpose: a list goes
stale silently, and you only find out when your hand misses under the Russian
layout. The script reads the bindings back out of tmux, so new bindings — and
tmux's own defaults (prefix `c`, `d`, `n`, `p`, `x`, `z`, `[`, `]`, …) — are
covered the moment they exist. **When you add a tmux binding you do nothing.**

When you add an *Alacritty* binding you add the RU twin by hand, in the same
file, in the same commit. Two traps there:

- `os/wsl.toml` binds copy/paste by raw scancode (`46`/`47`), which is already
  layout-independent, and disables Alacritty's named `"C"`/`"V"` defaults
  (`action = "None"`) so they don't fire twice. **Do not add Cyrillic twins
  there** — the scancode binding and a character binding would both match the
  same keypress and paste twice.
- Some keys have no RU twin at all: `$`, `?`, `{`, `}` do not exist on ЙЦУКЕН,
  and `,` `.` are the same character in both layouts, so a Cyrillic duplicate
  for them would override an EN binding instead of adding one.

One gap is left open knowingly: `Alt`+letter (zsh's `Alt+f`/`Alt+b`/`Alt+d`
word motions) has no RU twin. Nothing here binds `Alt`, and on macOS
Alacritty leaves `Option` to typing special characters (`option_as_alt` is
unset), so those sequences are not produced there in the first place. If
`Alt`+letter ever gets bound, it needs the same treatment as `Ctrl`+letter in
`ru-layout.toml` — the escape prefix plus the Latin letter.

History: the RU duplicates used to sit in `tmux/os/wsl.conf` under the note
"other machines don't need them", and `os/macos.toml` claimed that
`Control|Shift` keeps the Latin letter on macOS. Both were wrong and both cost
a debugging session on 18.09.2026 — the symptom was "can't paste into Claude
Code", and the paste path itself turned out to be healthy end to end.

## Bracketed paste

A terminal wraps pasted text in `ESC[200~` … `ESC[201~` so the receiving
program can tell a paste from typing. A program opts in by emitting
`ESC[?2004h`, and the markers only make sense to one that did. When they
reach a program that did not, the `ESC` is swallowed as an Escape keypress
and the rest lands in the input as literal text — a stray `[200~` at the
start of whatever you pasted.

Two things here guard against that:

`default-terminal` is `tmux-256color`, not `screen-256color`. The latter's
terminfo describes neither bracketed paste (`BE`/`BD`) nor italics (`sitm`),
so a program that checks terminfo before opting in never does, and every
paste the outer terminal wrapped arrives as garbage. `tmux-256color` is
picked only if `infocmp` finds it locally, because `TERM` travels over ssh
and a host with older ncurses would report a terminal it cannot describe.
Note that the setting applies to *new* panes — existing ones keep the `TERM`
they were started with.

The `Ctrl+v` paste bindings pass `-p`, which wraps the text only when the
program in the pane has asked for bracketed paste. Without it a multi-line
paste arrives as bare newlines, and a TUI that reads those as submissions —
Claude Code does — sends the text as several separate messages.

That leaves the case no config can prevent: a TUI that enables the mode and
is killed before it can disable it leaves the terminal wrapping pastes for
whatever runs next. prefix `P` clears that without restarting the pane.

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
   the whole drag to any application that asked for the mouse (vim, htop,
   mc), so a plain selection inside such a pane never reaches tmux and copies
   nothing. Clicks and the wheel are deliberately left to the application —
   taking those breaks its UI and scrolling. Claude Code is the one exception
   and keeps its drags; see *Claude Code in fullscreen mode* below.
4. `Ctrl+V` in zsh pastes the system clipboard. zsh binds `Ctrl+V` to
   `quoted-insert` by default, which looks like nothing happening; literal
   input moves to `Ctrl+Q`.

One case stays manual on purpose: tmux only forwards an application's OSC 52
outward from a **visible** pane of an attached session. Something copied by an
app in a background window lands in tmux's own buffer and nowhere else —
prefix `Ctrl+c` pushes it to the system clipboard.

## Claude Code in fullscreen mode

Checked 18.09.2026 against Claude Code 2.1.276.

`"tui": "fullscreen"` in `~/.claude/settings.json` (`/tui default` switches
back, `/config` toggles it) makes Claude Code draw on the **alternate
screen**. Two consequences, both of which look like "copying out of Claude
Code is broken":

- tmux keeps no history for an alternate-screen pane: `#{history_size}` is
  1–6 lines against a 50000 limit. Copy mode, `capture-pane` and history
  search see the current screen and nothing else; whatever scrolled away does
  not exist as far as tmux is concerned. The wheel goes to the application in
  any case — `#{alternate_on}` is part of tmux's default `WheelUpPane`.
- Claude Code in this mode brings its **own** scrollback, its own mouse
  selection, and copy-on-select (setting `copyOnSelect`, on by default). It
  writes the result through three paths at once: the native tool (`pbcopy`
  here), `tmux load-buffer -w`, and OSC 52. The first one does not depend on
  tmux forwarding anything, so this also works from a background pane — the
  manual `prefix Ctrl+c` case above does not apply to it.

So the rule in item 3 is inverted for these panes: taking their drags swaps a
working selection that has scrollback for a copy mode that has none, and
swallows the double-click that expands a collapsed tool result. The base
config therefore hands drag and double/triple click back to panes that are on
the alternate screen *and* whose `#{pane_current_command}` is `claude` or
looks like a version number (`2_1_276` — the native installer runs the binary
straight out of `~/.local/share/claude/versions/<version>`, so the process is
named after it). The `#{alternate_on}` half of that test matters: under
`/tui default` Claude Code draws on the normal screen, everything lands in
tmux's history, and selection should stay with tmux like everywhere else.

Not verified by hand: the gesture itself. The change follows from the
configuration and from the strings in the binary, not from a mouse.

Two keyboard routes bypass all of the above: `/copy [N]` copies the Nth
assistant message from the end (`copyFullResponse` decides full text versus
code blocks only), and `/export` copies or writes out the whole conversation.

### Selecting the input line — prefix `a`

Those two routes cover what has already been said; `prefix a` covers the text
still being typed. It runs `tmux/claude-select-input.sh`, which drops the pane
into copy mode with the selection already set on the input text and nothing
else — no frame rules, no `❯` marker, no trailing padding. `y` copies it,
`Escape` drops it, exactly as after a mouse selection.

The input is found by shape, not by process name: the script takes the lowest
full-width `─` rule on the screen and the nearest rule above it, and the input
sits between them, however many lines it wraps to. The marker is `❯` followed
by a NO-BREAK SPACE (U+00A0) and is not an anchor on its own — the same marker
precedes every message already sent, higher up in the transcript.

Columns are never counted. `start-of-line` plus two `cursor-right` clears the
marker at either width, because tmux steps over the padding cell of a wide
character, and tmux's own `end-of-line` stops at the last non-space character
of the line, so trailing padding cannot get in.

Checked 23.09.2026. The frame layout was read off a live 2.1.280 pane; the
search for it was run against live 2.1.278 and 2.1.280 screens, full and
empty; the copy-mode half — where the selection starts and ends — was run on a
pane reproducing those bytes, because testing it on a live pane means taking
over somebody's screen.

Limits, from the same run: a wrapped input carries the two-space indent tmux
sees at the start of each continuation line; an input too long for the frame
is selected only as far as the frame shows it; a pane whose marker is not `❯`
plus U+00A0 is reported on the status line and left untouched.

The key held `last-window` before: tmux-sensible binds the prefix without
`Ctrl` to it, and the prefix here is `C-a`. The binding therefore sits below
the tpm `run` line, or the plugin takes the key back on every config load.
