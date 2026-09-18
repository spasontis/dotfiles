#!/bin/sh
# Зеркало биндингов tmux в русскую раскладку.
#
# Терминал отдаёт tmux СИМВОЛ, который дала раскладка, а не клавишу: под
# ЙЦУКЕН физическая j присылает «о», и биндинг на j не совпадает ни с чем.
# Это верно на всех платформах одинаково — раскладка не свойство машины,
# поэтому зеркало живёт в базе, а не в os/*.conf.
#
# Почему скрипт, а не список дублей руками: список молча отстаёт. Появился
# новый bind — дубля у него нет, и это заметно только когда рука промахнулась
# под русской раскладкой. Здесь дубли берутся из самого tmux: что забиндено —
# то и отзеркалено, включая биндинги tmux по умолчанию (prefix c, d, n, p, x,
# z, [, ] и остальные) и всё, что добавят позже.
#
# Таблицы: prefix и copy-mode-vi. root не трогаем — там только мышь.
#
# Запускается из конца .tmux.conf на каждой загрузке конфига, включая
# prefix r. Оговорка: if-shell в tmux асинхронен, поэтому теоретически
# зеркало может снять список до того, как доедут биндинги из os/*.conf; на
# практике там только Ctrl-сочетания (C-c, C-v) и мышь — буквенных нет.
set -eu

ru_twin() {
	case "$1" in
	q) printf 'й' ;; w) printf 'ц' ;; e) printf 'у' ;; r) printf 'к' ;;
	t) printf 'е' ;; y) printf 'н' ;; u) printf 'г' ;; i) printf 'ш' ;;
	o) printf 'щ' ;; p) printf 'з' ;; a) printf 'ф' ;; s) printf 'ы' ;;
	d) printf 'в' ;; f) printf 'а' ;; g) printf 'п' ;; h) printf 'р' ;;
	j) printf 'о' ;; k) printf 'л' ;; l) printf 'д' ;; z) printf 'я' ;;
	x) printf 'ч' ;; c) printf 'с' ;; v) printf 'м' ;; b) printf 'и' ;;
	n) printf 'т' ;; m) printf 'ь' ;;
	Q) printf 'Й' ;; W) printf 'Ц' ;; E) printf 'У' ;; R) printf 'К' ;;
	T) printf 'Е' ;; Y) printf 'Н' ;; U) printf 'Г' ;; I) printf 'Ш' ;;
	O) printf 'Щ' ;; P) printf 'З' ;; A) printf 'Ф' ;; S) printf 'Ы' ;;
	D) printf 'В' ;; F) printf 'А' ;; G) printf 'П' ;; H) printf 'Р' ;;
	J) printf 'О' ;; K) printf 'Л' ;; L) printf 'Д' ;; Z) printf 'Я' ;;
	X) printf 'Ч' ;; C) printf 'С' ;; V) printf 'М' ;; B) printf 'И' ;;
	N) printf 'Т' ;; M) printf 'Ь' ;;
	*) return 1 ;;
	esac
}

out="${TMPDIR:-/tmp}/tmux-ru-layout.$$"
: >"$out"

for table in prefix copy-mode-vi; do
	tmux list-keys -T "$table" | while IFS= read -r line; do
		key=$(printf '%s\n' "$line" |
			awk -v t="$table" '{for(i=1;i<NF;i++) if($i=="-T" && $(i+1)==t){print $(i+2); exit}}')
		# Только одиночные латинские буквы: у цифр, стрелок и знаков
		# препинания либо тот же символ в обеих раскладках, либо нет
		# пары вовсе.
		case "$key" in
		[a-zA-Z]) ;;
		*) continue ;;
		esac
		twin=$(ru_twin "$key") || continue

		# Меняем ТОЛЬКО поле ключа, строку не переформатируем: в командах
		# бывают кавычки и скобки, и переклейка полей испортила бы их.
		printf '%s\n' "$line" |
			sed "s|\(-T $table[[:space:]][[:space:]]*\)$key\([[:space:]]\)|\1$twin\2|" >>"$out"
	done
done

tmux source-file "$out"
rm -f "$out"
