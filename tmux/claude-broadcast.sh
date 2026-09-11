#!/usr/bin/env bash
# Type one line of input into every Claude Code pane of a single tmux window.
#
#   claude-broadcast.sh <window-id> <text>
#
# Bound in .tmux.conf, where tmux expands #{window_id} against the window the
# key was pressed in. That matters because run-shell is async: by the time this
# script runs, the "current" window may no longer be the one you were looking
# at, so the target is pinned at key-press time rather than looked up here.
set -euo pipefail

win=${1:?usage: claude-broadcast.sh <window-id> <text>}
text=${2:?usage: claude-broadcast.sh <window-id> <text>}

# pane_current_command is the pane's foreground process. Filtering on it is not
# cosmetic: without it the text lands in shell panes too, where it is executed
# as a command rather than typed into a TUI.
mapfile -t panes < <(
  tmux list-panes -t "$win" -F '#{pane_id} #{pane_in_mode} #{pane_dead} #{pane_current_command}'
)

sent=0
for line in "${panes[@]}"; do
  read -r pane in_mode dead cmd <<<"$line"
  [ "$dead" = 0 ] || continue
  [ "$cmd" = claude ] || continue

  # A pane sitting in copy-mode routes send-keys into the copy-mode keytable,
  # where the payload is swallowed as vi motions. Easy to hit here, since a
  # mouse drag enters copy-mode. Drop back to the application first.
  if [ "$in_mode" = 1 ]; then
    tmux send-keys -t "$pane" -X cancel
  fi

  # -l sends the string literally (no key-name parsing, so "Enter" or "C-c" in
  # the text stay text); -- keeps a leading dash from being read as an option.
  #
  # Deliberately not paste-buffer: that wraps the payload in bracketed-paste
  # markers, and Claude Code then treats it as pasted content instead of a
  # submitted line.
  tmux send-keys -t "$pane" -l -- "$text"

  # Claude Code opens a filtered command menu the moment "/" is typed. Enter
  # sent in the same burst can be read against the menu rather than the input
  # line, so give the TUI a frame to settle.
  sleep 0.15
  tmux send-keys -t "$pane" Enter

  sent=$((sent + 1))
done

# send-keys is invisible in unfocused panes, so say what happened.
tmux display-message "broadcast '${text}' -> ${sent} claude pane(s)"
