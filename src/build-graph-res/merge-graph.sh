#!/usr/bin/env bash

if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <results_json_file_1> <results_json_file_2> <test_name>"
    exit 1
fi

results_file_1="$1"
results_file_2="$2"
test_name="$3"
output_file="combined-time-histogram-${test_name}.png"
gnuplot_script="./tmp/gnuplot-config-${test_name}.gp"
combined_data_file="./tmp/${test_name}_combined_data.dat"

mkdir -p ./tmp
mkdir -p ./results/graphs

# 1. Создаем массив объектов из первого файла
data1=$(jq -r --arg test_name "$test_name" '.[] | (.language) as $lang | .tests[] | select(.test_name == "\($test_name)") | {language: $lang, average: .average}' "$results_file_1")
#echo $data1
data2=$(jq -r --arg test_name "$test_name" '.[] | (.language) as $lang | .tests[] | select(.test_name == "\($test_name)") | {language: $lang, average: .average}' "$results_file_2")
#echo $data2

# 2. Составляем список языков (уникальные значения)
languages=$(
  { echo "$data1"; echo "$data2"; } | \
  grep -o '"language": "[^"]*"' | \
  cut -d '"' -f 4 | \
  sort -u
)
#echo $languages

# 3. Формируем данные для gnuplot
rm -rf $combined_data_file

for lang in $languages; do
    avg1=$(jq -r --arg test_name "$test_name" --arg lang "$lang" '.[] | select(.language == $lang) | .tests[] | select(.test_name == $test_name).average' "$results_file_1")
#    echo 1 lang=$lang avg1=$avg1
    if [ -z $avg1 ]; then avg1="0"; fi
    avg2=$(jq -r --arg test_name "$test_name" --arg lang "$lang" '.[] | select(.language == $lang) | .tests[] | select(.test_name == $test_name).average' "$results_file_2")
    if [ -z $avg2 ]; then avg2="0"; fi
#    echo 2 lang=$lang avg1=$avg1
#    echo lang=$lang avg1=$avg1 avg2=$avg2
    echo $lang $avg1 $avg2 >> $combined_data_file
done

# echo $combined_data_file

color1="#4B0082"
color2="#9370DB"
fontsize="11"

label1=$(echo $results_file_1 | grep -o -P '(?<=article-).*(?=\.json)')
label2=$(echo $results_file_2 | grep -o -P '(?<=article-).*(?=\.json)')

gnuplot << EOF
set terminal pngcairo enhanced size 1600,1200
set output './results/graphs/$output_file'
set title 'Performance Comparison'

set style data histogram
set style fill solid 0.7
set boxwidth 0.3 absolute

set style line 1 lc rgb "#4B0082"

set xtics rotate by -45 textcolor ls 1 font "Arial,16"
set xtics nomirror

# set ytics rotate by -45 textcolor ls 1 font "Arial,16"

set ylabel 'Время выполнения (сек)' font "Arial,20" textcolor ls 1
set title 'Сравнение производительности $label1 и $label2 - Тест:"$test_name"' font "Arial,20" textcolor ls 1
set key right top

set logscale y
set yrange [0.5:*]
set grid lc rgb "#9370DB" lw 2

plot \
     '< sort -k1,1n "$combined_data_file"' \
     using (column(0) - 0.18):(column(2)==0?1e-10:column(2)):xtic(1) title 'Результаты для $label1' with boxes linecolor rgb '$color1', \
     '' using (column(0) + 0.18):(column(3)==0?1e-10:column(3)) title 'Результаты для $label2' with boxes lc rgb '$color2', \
     '' using (column(0) - 0.31):(column(2)==0?1e-10:column(2)):(sprintf('%.1f', column(2))) with labels rotate by 45 offset char 1,1.3 tc rgb '$color1' font ',$fontsize' notitle, \
     '' using (column(0) + 0.11):(column(3)==0?1e-10:column(3)):(sprintf('%.1f', column(3))) with labels rotate by 45 offset char 1,1.2 tc rgb '$color2' font ',$fontsize' notitle 
EOF

echo "Graph generated: './results/graphs/$output_file'."
