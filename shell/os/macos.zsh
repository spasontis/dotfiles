# macOS.

# VS Code CLI (`code` command)
export PATH="/Applications/Visual Studio Code.app/Contents/Resources/app/bin:$PATH"

# mysql-client homebrew не линкует в /opt/homebrew/bin — путь прописан вручную
export PATH="/opt/homebrew/opt/mysql-client/bin:$PATH"

# Ctrl+V — вставка системного буфера, тем же жестом, что в Claude Code и в
# tmux (prefix C-v). По умолчанию в zsh это quoted-insert, то есть нажатие
# выглядит как «ничего не произошло» — отсюда ощущение «скопировалось, а в
# обычный терминал не вставляется». Литеральный ввод, ради которого
# quoted-insert и нужен, переезжает на Ctrl+Q.
paste-from-clipboard() { LBUFFER+="$(pbpaste)" }
zle -N paste-from-clipboard
bindkey '^V' paste-from-clipboard
bindkey '^Q' quoted-insert
