#!/bin/bash
# Status line reproducing the user's shell prompt style from ~/.bashrc:
#   PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
# (trailing "$" dropped per status line conventions)

input=$(cat)

user=$(whoami)
host=$(hostname -s)

cwd=$(echo "$input" | jq -r '.workspace.current_dir // empty')
[ -z "$cwd" ] && cwd=$(pwd)
# Отображаемый путь и путь для git — РАЗНЫЕ переменные: "~" в аргументе git -C
# не разворачивается (тильду раскрывает шелл, а здесь она уже часть строки), и
# на схлопнутом пути git молча не находил репозиторий ни разу — то есть ветка
# не показалась бы вообще нигде под $HOME.
# Тильда экранирована: в правой части ${x/y/z} bash делает tilde expansion, и
# незакавыченный ~ разворачивался обратно в /home/dmitrii — замена молча не
# давала ничего.
dir="${cwd/#$HOME/\~}"

branch=""
if git -C "$cwd" --no-optional-locks rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  branch=$(git -C "$cwd" --no-optional-locks branch --show-current 2>/dev/null)
  # Detached HEAD: имени ветки нет, показываем короткий хеш.
  [ -z "$branch" ] && branch=$(git -C "$cwd" --no-optional-locks rev-parse --short HEAD 2>/dev/null)
fi

model=$(echo "$input" | jq -r '.model.display_name // empty')

# Тема разговора: имя из /rename, иначе имя агента, иначе последний заголовок,
# который Claude Code сам пишет в журнал сессии (запись ai-title). Журнал
# читается с конца: заголовок обновляется по ходу разговора.
topic=$(echo "$input" | jq -r '.session_name // empty')
transcript=$(echo "$input" | jq -r '.transcript_path // empty')
# tac есть только в GNU coreutils; на macOS то же делает tail -r.
rev() { if command -v tac >/dev/null; then tac "$1"; else tail -r "$1"; fi; }
if [ -z "$topic" ] && [ -f "$transcript" ]; then
  for t in custom-title agent-name ai-title; do
    topic=$(rev "$transcript" | grep -m1 "\"type\":\"$t\"" | jq -r '.customTitle // .agentName // .aiTitle // empty' 2>/dev/null)
    [ -n "$topic" ] && break
  done
fi
[ ${#topic} -gt 50 ] && topic="${topic:0:49}…"

# Context usage: prefer the pre-calculated used_percentage field; fall back
# to computing it from total_input_tokens / context_window_size if absent.
ctx_pct=""
ctx_raw=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
if [ -n "$ctx_raw" ]; then
  ctx_pct=$(awk -v v="$ctx_raw" 'BEGIN{printf "%.0f", v}')
else
  total_input=$(echo "$input" | jq -r '.context_window.total_input_tokens // empty')
  window_size=$(echo "$input" | jq -r '.context_window.context_window_size // empty')
  if [ -n "$total_input" ] && [ -n "$window_size" ] && [ "$window_size" != "0" ]; then
    ctx_pct=$(awk -v i="$total_input" -v w="$window_size" 'BEGIN{printf "%.0f", (i/w)*100}')
  fi
fi

# Внутри tmux тема и контекст уходят в заголовок панели сверху: опции панели
# @claude_topic и @claude_ctx читает pane-border-format из tmux/.tmux.conf,
# здесь же для окна включается pane-border-status top и ставится опция окна
# @claude_header, по которой tmux прячет линии рамок. Окна без Claude Code
# заголовка не получают. "#" удваивается: значение подставляется в формат,
# и "#[" в теме tmux прочёл бы как стиль.
in_header=""
if [ -n "$TMUX_PANE" ] && command -v tmux >/dev/null; then
  t_topic="${topic//#/##}"
  t_ctx=""
  [ -n "$ctx_pct" ] && t_ctx="${ctx_pct}%"
  tmux set -p -t "$TMUX_PANE" @claude_topic "$t_topic" \; \
       set -p -t "$TMUX_PANE" @claude_ctx "$t_ctx" \; \
       set -w -t "$TMUX_PANE" pane-border-status top \; \
       set -w -t "$TMUX_PANE" @claude_header 1 2>/dev/null && in_header=1
fi

# Вне tmux две строки: панели узкие, и длинный путь обрезал всё, что за ним.
# Первая — тема, ветка, контекст; вторая — user@host:путь и модель.
# В tmux тема и контекст в заголовке, и строка одна: ветка первой, чтобы
# её не срезал длинный путь.
if [ -n "$in_header" ]; then
  [ -n "$branch" ] && printf '\033[02m(%s)\033[00m ' "$branch"
else
  line1=""
  [ -n "$topic" ] && line1=$(printf '\033[01;36m%s\033[00m' "$topic")
  [ -n "$branch" ] && line1="$line1$(printf ' \033[02m(%s)\033[00m' "$branch")"
  [ -n "$ctx_pct" ] && line1="$line1$(printf ' \033[02mctx:%s%%\033[00m' "$ctx_pct")"
  [ -n "$line1" ] && printf '%s\n' "${line1# }"
fi
printf '\033[01;32m%s@%s\033[00m:\033[01;34m%s\033[00m' "$user" "$host" "$dir"
[ -n "$model" ] && printf ' \033[02m[%s]\033[00m' "$model"
printf '\n'
