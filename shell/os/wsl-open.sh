#!/usr/bin/env bash
# WSL. Открыть ссылку или файл в программе Windows по умолчанию.
#
# Ставится симлинком ~/.local/bin/xdg-open. В WSL штатного xdg-open и wslview
# нет, BROWSER пуст — программа, которая открывает ссылку сама (Claude Code в
# режиме "tui": "fullscreen" ловит щелчок по ссылке у себя), подсвечивает её
# и молча ничего не запускает. Alacritty тут не участвует: щелчок внутри tmux
# с mouse on до его подсказок не доходит.
#
# explorer.exe, а не cmd.exe /c start: cmd режет адрес по & и ругается на
# UNC-каталог WSL как текущий. explorer.exe возвращает 1 даже при успехе,
# поэтому код выхода свой.
set -u
[ $# -ge 1 ] || { echo "usage: xdg-open <url|file>" >&2; exit 1; }
target=$1
case "$target" in
  *://*|mailto:*) ;;
  *) [ -e "$target" ] && target=$(wslpath -w "$target") ;;
esac
explorer.exe "$target" >/dev/null 2>&1
exit 0
