#!/bin/sh

cleanup() {
    if [ -n "$TMPD" ] && [ -d "$TMPD" ]; then
        rm -rf "$TMPD"
    fi
}

trap cleanup EXIT INT TERM

if [ "$#" -ne 1 ] || [ ! -f "$1" ]; then
    echo "Использование: $0 <исходный_файл>" >&2
    exit 1
fi

src="$1"
dir=$(dirname "$src")
base=$(basename "$src")

# Ищем комментарий &Output:
output_line=$(grep -m1 '&Output:' "$src")
if [ -z "$output_line" ]; then
    echo "Ошибка: не найден '&Output:' в '$src'." >&2
    exit 2
fi

output_name=$(printf '%s\n' "$output_line" | sed 's/.*&Output:[[:space:]]*//')
if [ -z "$output_name" ]; then
    echo "Ошибка: не указано имя после '&Output:'." >&2
    exit 3
fi

# Создаём временный каталог
TMPD=$(mktemp -d) || { echo "Не удалось создать временный каталог." >&2; exit 4; }

# Копируем исходник
cp "$src" "$TMPD/" || { echo "Не удалось скопировать файл." >&2; exit 5; }

# Собираем в зависимости от расширения
case "$base" in
    *.cpp|*.cc|*.cxx)
        g++ -o "$TMPD/$output_name" "$TMPD/$base" || { echo "Ошибка компиляции C++." >&2; exit 10; }
        ;;
    *.c)
        gcc -o "$TMPD/$output_name" "$TMPD/$base" || { echo "Ошибка компиляции C." >&2; exit 11; }
        ;;
    *.tex)
        (cd "$TMPD" && pdflatex -interaction=nonstopmode "$base") || { echo "Ошибка компиляции TeX." >&2; exit 12; }
        default_pdf="${base%.tex}.pdf"
        if [ -f "$TMPD/$default_pdf" ] && [ "$output_name" != "$default_pdf" ]; then
            mv "$TMPD/$default_pdf" "$TMPD/$output_name"
        fi
        if [ ! -f "$TMPD/$output_name" ]; then
            echo "Выходной файл '$output_name' не создан." >&2
            exit 13
        fi
        ;;
    *)
        echo "Неподдерживаемое расширение: $base" >&2
        exit 6
        ;;
esac

# Копируем результат рядом с исходником
cp "$TMPD/$output_name" "$dir/" || { echo "Не удалось сохранить результат." >&2; exit 7; }

echo "Готово: $dir/$output_name"