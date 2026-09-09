# Нативный Linux.

# Ctrl+V — вставка системного буфера (обоснование см. в os/macos.zsh).
# Утилита та же, что выбирает tmux/os/linux.conf: Wayland — wl-paste,
# X11 — xclip. Если нет ни одной (сервер по SSH), биндинг не ставим вовсе:
# лучше оставить quoted-insert на месте, чем повесить пустышку.
if command -v wl-paste >/dev/null 2>&1; then
  paste-from-clipboard() { LBUFFER+="$(wl-paste --no-newline)" }
elif command -v xclip >/dev/null 2>&1; then
  paste-from-clipboard() { LBUFFER+="$(xclip -selection clipboard -out)" }
fi

if (( $+functions[paste-from-clipboard] )); then
  zle -N paste-from-clipboard
  bindkey '^V' paste-from-clipboard
  bindkey '^Q' quoted-insert
fi
