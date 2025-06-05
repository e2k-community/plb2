#!/bin/bash

# Значение по умолчанию: включать стандартное отклонение
include_std=1

# Парсинг опций
while [[ "$1" == --* ]]; do
    case "$1" in
        --no-std )
            include_std=0
            shift
            ;;
        * )
            echo "Неизвестная опция: $1"
            echo "Использование: $0 [--no-std] input_file"
            exit 1
    esac
done

input_file=$1
output_file="${1}.md"

# Проверка наличия входного файла
if [ -z "$input_file" ]; then
    echo "Использование: $0 [--no-std] input_file"
    exit 1
fi

# Извлечение названий тестов
test_names=($(jq -r '.[0].tests[].test_name' "$input_file"))
# echo $test_names
# Формирование заголовка
header="| Language/Tests"
separator="|---------------"
for test_name in "${test_names[@]}"; do
    header+=" | $test_name (sec)"
    separator+="|--------------------"
done
header+=" |"
separator+="|"

# Сбор данных по языкам
rows=""
languages=($(jq -r '.[].language' "$input_file"))

for language in "${languages[@]}"; do
    row="| $language"
    for test_name in "${test_names[@]}"; do
        if [ "$include_std" -eq 1 ]; then
            # С включением стандартного отклонения
            result=$(jq -r --arg lang "$language" --arg test "$test_name" \
                '.[] | select(.language == $lang) | .tests[] | select(.test_name == $test) | "\(.average) ± \(.standard_deviation)"' "$input_file")
        else
            # Только среднее значение
            result=$(jq -r --arg lang "$language" --arg test "$test_name" \
                '.[] | select(.language == $lang) | .tests[] | select(.test_name == $test) | "\(.average)"' "$input_file")
        fi
        if [ -z "$result" ] || [ "$result" == "null" ]; then
            result="N/A"
        fi
        row+=" | $result"
    done
    row+=" |"
    rows+="$row"$'\n'
done

# Запись в файл
{
    echo "$header"
    echo "$separator"
    echo -e "$rows"
} > "$output_file"

echo "Markdown таблица сохранена в '$output_file'"
