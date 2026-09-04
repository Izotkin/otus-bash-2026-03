#!/bin/bash

file=""
search=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --file)
            file="$2"
            shift 2
            ;;
        --search)
            search="$2"
            shift 2
            ;;
        *)
            echo "Неизвестный параметр: $1"
            echo "Использование: $0 --file путь_к_файлу --search строка"
            exit 1
            ;;
    esac
done

if [[ -z $file ]]; then
    echo "Не указан файл через --file"
    exit 1
fi

if [[ -z $search ]]; then
    echo "Не указана строка поиска через --search"
    exit 1
fi

if [[ ! -f $file ]]; then
    echo "Файл $file не существует"
    exit 1
fi

abs_path=$(realpath "$file" 2>/dev/null)
if [[ -z $abs_path ]]; then
    if [[ $file == /* ]]; then
        abs_path="$file"
    else
        abs_path="$(pwd)/$file"
    fi
fi

count=$(grep -i -o "$search" "$file" 2>/dev/null | wc -l | tr -d ' ')

if [[ $count -gt 0 ]]; then
    echo "$count"
else
    echo "Не найдено ни одного совпадения в файле $abs_path"
    exit 1
fi