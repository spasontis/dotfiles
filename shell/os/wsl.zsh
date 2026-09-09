# WSL.

# Ctrl+V — вставка системного буфера Windows (обоснование см. в os/macos.zsh).
# Get-Clipboard отдаёт строки с CRLF, \r убираем — иначе вставка рвёт строку.
paste-from-clipboard() { LBUFFER+="${$(powershell.exe -NoProfile -Command Get-Clipboard)//$'\r'/}" }
zle -N paste-from-clipboard
bindkey '^V' paste-from-clipboard
bindkey '^Q' quoted-insert
