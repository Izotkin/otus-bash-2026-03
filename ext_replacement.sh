#!/bin/bash

files=()
ext=""
new_ext=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --file)
            files+=("$2")
            shift 2
            ;;
        --extension)
            ext="$2"
            shift 2
            ;;
        --replacement)
            new_ext="$2"
            shift 2
            ;;
        *)
            echo "Неизвестный параметр: $1"
            echo "Использование: $0 --file файл1 --file файл2 --extension txt --replacement sh"
            exit 1
            ;;
    esac
done

if [[ ${#files[@]} -eq 0 ]]; then
    echo "Не указаны файлы через --file"
    exit 1
fi

if [[ -z $ext ]]; then
    echo "Не указано расширение для замены через --extension"
    exit 1
fi

if [[ -z $new_ext ]]; then
    echo "Не указано новое расширение через --replacement"
    exit 1
fi

script_dir=$(dirname "$(realpath "$0" 2>/dev/null || echo "$0")")

for f in "${files[@]}"; do
    if [[ -f "$f" ]]; then
        file_path="$f"
    elif [[ -f "$script_dir/$f" ]]; then
        file_path="$script_dir/$f"
    elif [[ -f "$script_dir/../$f" ]]; then
        file_path="$script_dir/../$f"
    else
        echo "Файл $f не найден" >&2
        continue
    fi

    abs_path=$(realpath "$file_path" 2>/dev/null || echo "$file_path")
    filename=$(basename "$abs_path")
    dir=$(dirname "$abs_path")

    if [[ $filename == *.$ext ]]; then
        base_without_ext="${filename%.$ext}"
        new_file="$dir/${base_without_ext}.$new_ext"

        if [[ -e $new_file ]]; then
            echo "Файл $new_file уже существует" >&2
            continue
        fi

        if mv "$file_path" "$new_file" 2>/dev/null; then
            echo "$(realpath "$new_file" 2>/dev/null || echo "$new_file")"
        else
            echo "Не удалось переименовать $file_path" >&2
        fi
    else
        echo "Файл $abs_path не имеет расширения .$ext" >&2
    fi
done