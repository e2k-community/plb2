#!/usr/bin/env bash

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <results_json_file> <test_name>"
    exit 1
fi

results_file="$1"  # JSON файл с результатами
test_name="$2"     # Название теста
output_file="time-histogram-${test_name}.png"
data_file="./tmp/${test_name}_data.dat"
sorted_data_file="./tmp/${test_name}_sorted_data.dat"


color_bedcov='#4B0082'
color_matmul='#800080'
color_nqueen='#9932CC'
color_sudoku='#8A2BE2'

# Определение цвета в зависимости от имени теста
case "$test_name" in
    bedcov)
        color="$color_bedcov"
        ;;
    matmul)
        color="$color_matmul"
        ;;
    nqueen)
        color="$color_nqueen"
        ;;
    sudoku)
        color="$color_sudoku"
        ;;
    *)
        color="'grey'"
        ;;
esac

mkdir -p ./tmp

# Удаление старого файла данных, если он существует
> "$data_file"

echo "Processing JSON data from '$results_file' to collect information for '$test_name'..."

# Обработка JSON-файла для сбора данных
jq -c --arg test_name "$test_name" '.[] | {language: .language, tests: [.tests[] | select(.test_name == $test_name) | {average: .average}]}' "$results_file" | while read -r line; do
    language=$(echo "$line" | jq -r '.language')
    average=$(echo "$line" | jq -r '.tests[0].average')  # Извлечение среднего значения (если оно существует)

    if [[ -n "$language" && -n "$average" ]]; then
	#rounded_average=$(printf "%.1f" "$average")
        echo "$language $average" >> "$data_file"
    fi
done

# Проверка на наличие данных
if [[ ! -s "$data_file" ]]; then
    echo "No data collected for '$test_name'."
    exit 1
fi

# Сортировка данных по среднему времени (второй столбец)
sort -k2,2n "$data_file" > "$sorted_data_file"

mkdir -p ./results/graphs

gnuplot_script="gnuplot-config-${test_name}.gp"
echo "\
set terminal pngcairo enhanced size 1000,800
set output './results/graphs/$output_file'
set encoding utf8

set style data histogram
set style fill solid 0.8
set boxwidth 0.5

set key opaque
set key left top

set xlabel 'Язык программирования'
set ylabel 'Время выполнения (сек)'
set title 'Тест: \"$test_name\". Логарифмический масштаб по оси Y'
set grid

set logscale y
set yrange [0.5:*]

set xtics rotate by -45
set xtics nomirror

plot \"$sorted_data_file\" using 2:xtic(1) linecolor rgb '$color' title '$test_name' with boxes, \
     '' using 0:2:(sprintf('%.1f', \$2)) with labels offset 0,0.5  tc rgb '$color' font ',8' notitle

" > "./tmp/$gnuplot_script"

echo "Gnuplot script saved to './tmp/$gnuplot_script'."

gnuplot ./tmp/"$gnuplot_script"

echo "Graph generated: './results/graphs/$output_file'."
