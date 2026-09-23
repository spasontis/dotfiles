#!/usr/bin/env bash
# Keep tmux-resurrect's `last` pointing at a non-empty snapshot.
#
# Called synchronously from .tmux.conf before tpm, so it runs before
# tmux-continuum restores on server start.
#
# Why: when the tmux server dies in the middle of a continuum autosave, the
# save leaves a 0-byte snapshot and still moves `last` onto it. The next server
# then "restores" nothing and every session looks wiped, although the previous
# snapshot is intact. Seen 23.09.2026: tmux 3.4 segfaulted at 19:54:30, the
# snapshot of that second is empty, the one from 19:45 held 26 panes.
#
# If `last` is missing, dangling or empty, it is moved to the newest non-empty
# snapshot. Empty snapshots are left in place: the save rotation removes them.
set -u

dir=$(tmux show-option -gqv @resurrect-dir 2>/dev/null)
dir=${dir/#\~/$HOME}
if [ -z "$dir" ]; then
  # Same fallback order as tmux-resurrect: legacy dir if it exists, else XDG.
  if [ -d "$HOME/.tmux/resurrect" ]; then
    dir="$HOME/.tmux/resurrect"
  else
    dir="${XDG_DATA_HOME:-$HOME/.local/share}/tmux/resurrect"
  fi
fi
[ -d "$dir" ] || exit 0

last="$dir/last"
[ -s "$last" ] && exit 0

# ls -t sorts by mtime; snapshot names carry no spaces.
for f in $(ls -1t "$dir"/tmux_resurrect_*.txt 2>/dev/null); do
  if [ -s "$f" ]; then
    ln -sfn "$(basename "$f")" "$last"
    tmux display-message "resurrect: last -> $(basename "$f")" 2>/dev/null
    exit 0
  fi
done
exit 0
