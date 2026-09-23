#!/usr/bin/perl
# Смена раскладки уже набранного текста: ЙЦУКЕН ↔ QWERTY.
#
# Читает текст со stdin, печатает переведённый в stdout без завершающего
# перевода строки. Перевод посимвольный, по тому, что дают те же физические
# клавиши в другой раскладке.
#
# Направление берётся из самого текста: чего больше, кириллицы или латиницы,
# в ту сторону и перевод; при равенстве — в кириллицу. Меняются только буквы
# и знаки той стороны, с которой переводим, остальное проходит насквозь.
# Букв нет вовсе — выход с кодом 1 и пустой вывод, менять нечего.
#
# Знаки препинания стоят в таблице наравне с буквами, и это не украшение:
# «привет,» набранное латиницей выглядит как «ghbdtn?» — запятая ЙЦУКЕН
# сидит на клавише «?» QWERTY. Без знаков перевод выходил бы наполовину.
# По той же причине здесь верхний ряд с цифрами: «"», «№», «;», «:», «?»
# приходят с Shift и в QWERTY дают «@», «#», «$», «^», «&».
use strict;
use warnings;
use utf8;

binmode STDIN,  ':encoding(UTF-8)';
binmode STDOUT, ':encoding(UTF-8)';

my $en = q(`qwertyuiop[]asdfghjkl;'zxcvbnm,./~QWERTYUIOP{}ASDFGHJKL:"ZXCVBNM<>?@#$^&);
my $ru = q(ёйцукенгшщзхъфывапролджэячсмитьбю.ЁЙЦУКЕНГШЩЗХЪФЫВАПРОЛДЖЭЯЧСМИТЬБЮ,"№;:?);

my @en = split //, $en;
my @ru = split //, $ru;
die "таблицы разной длины: ", scalar @en, " и ", scalar @ru, "\n"
	unless @en == @ru;

my (%to_ru, %to_en);
@to_ru{@en} = @ru;
@to_en{@ru} = @en;

my $text = do { local $/; <STDIN> };
exit 1 unless defined $text && length $text;

my $cyrillic = () = $text =~ /\p{Cyrillic}/g;
my $latin    = () = $text =~ /[A-Za-z]/g;
exit 1 unless $cyrillic || $latin;

my $map = $cyrillic > $latin ? \%to_en : \%to_ru;
print join '', map { defined $map->{$_} ? $map->{$_} : $_ } split //, $text;
