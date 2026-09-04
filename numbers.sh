#!/bin/bash

if [[ $# -ne 1 ]]; then
    echo "Необходимо передать одно число"
    echo "Пример: $0 8"
    exit 1
fi

if [[ ! $1 =~ ^[0-9]+$ ]]; then
    echo "$1 не является положительным целым числом"
    exit 1
fi

n=$1

if [[ $n -lt 2 ]]; then
    echo "Число должно быть больше или равно 2"
    exit 1
fi

half=$((n / 2))

mult=1
for ((i=1; i<=half; i++)); do
    mult=$((mult * i))
done

sum=0
start=$((half + 1))

if [[ $((n % 2)) -ne 0 ]]; then
    start=$((half + 2))
fi

for ((i=start; i<=n; i++)); do
    sum=$((sum + i))
done

echo "mult: $mult"
echo "sum: $sum"