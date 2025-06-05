#!/usr/bin/env bash

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <data_file>"
  exit 1
fi

data_file="$1"

# Проверка наличия файла данных
if [[ ! -f "$data_file" ]]; then
  echo "Data file '$data_file' not found!"
  exit 1
fi

# Создаем папку для gnuplot скриптов и выходных файлов
mkdir -p ./tmp
mkdir -p ./results/graphs

# Чтение файла данных и генерация gnuplot-скрипта для каждого теста
jq -c '.[] | {language: .language, tests: .tests[]}' "$data_file" | while IFS= read -r test; do
  # Извлекаем язык и данные о тесте
  language=$(echo "$test" | jq -r '.language')
  test_name=$(echo "$test" | jq -r '.tests.test_name')
  elapsed_times=$(echo "$test" | jq -r '.tests.elapsed_times | @csv' | tr -d '"')
  average=$(echo "$test" | jq -r '.tests.average')
  std_dev=$(echo "$test" | jq -r '.tests.standard_deviation')

  # Если значения времени пусты, пропускаем тест
  if [[ -z "$elapsed_times" ]]; then
    echo "Skipping test '$test_name' due to missing elapsed_times."
    continue
  fi

  # Имя файла для gnuplot
  gnuplot_script="${test_name// /_}_${language// /_}.gp"
  output_file="./${test_name// /_}_${language// /_}.png"  # Имя выходного файла

  # Получаем количество измерений
  IFS=',' read -r -a times_array <<< "$elapsed_times"
  n=${#times_array[@]}

  # Вычисляем конец диапазона по оси X
  xrange_max=$(echo "$n + 0.5" | bc)

  # Вычисляем верхнюю и нижнюю границы для закрашенной области
  upper=$(echo "$average + $std_dev" | bc -l)
  lower=$(echo "$average - $std_dev" | bc -l)

  # Обработка случая, когда std_dev равен 0
  if [[ "$std_dev" == "0" ]]; then
    upper="$average"
    lower="$average"
  fi

# Обработка случая с пустым диапазоном Y
  y_min=$(echo "$average - 5 * $std_dev" | bc -l)
  y_max=$(echo "$average + 5 * $std_dev" | bc -l)

  # Если y_min меньше 0, устанавливаем нижнюю границу в 0
  if (( $(echo "$y_min <= 0" | bc -l) )); then
    y_min=0
  fi

color_error="#EE82EE"
color_measure="#8A2BE2"
color_midle="#4B0082"

  # Создание gnuplot-скрипта с использованием here-document
  cat > ./tmp/"$gnuplot_script" <<EOF
set terminal pngcairo enhanced size 800,600 font "Arial,12"
set encoding utf8
set output '$output_file'

set style line 1 lc rgb "#4B0082"

set xlabel 'Номер измерения' font "Arial,12"
set ylabel 'Время выполнения (сек)' font "Arial,12"
set title 'Производительность $test_name на $language' font "Arial,14"

set grid lw 3 lc rgb 'gray'
set pointsize 1.5

average = $average
std_dev = $std_dev

set xrange [0.5:$xrange_max]
set yrange [$y_min:$y_max]

# Настройка заполнения области между кривыми
set style fill transparent solid 0.2 noborder

# Настройка легенды без полупрозрачного фона (для совместимости с вашей версией Gnuplot)
set key opaque
# set key box linewidth 1

# Добавляем закрашенную область между average - std_dev и average + std_dev
set object 1 rectangle from 0.5, $lower to $xrange_max, $upper fc rgb '${color_error}' fs transparent solid 0.2 noborder

# Построение графика
plot average + std_dev with lines lc rgb '${color_error}' dt (5,5) title 'Среднее ± Стандартное отклонение', \
     average - std_dev with lines lc rgb '${color_error}' dt (5,5) notitle, \
     average with lines lc rgb '${color_midle}' lw 2 title 'Среднее значение', \
     '-' using 1:2 with points pt 7 ps 1.5 lc rgb '${color_measure}' title 'Измерения'

# Данные измерений
EOF

  # Добавляем данные измерений прямо в скрипт Gnuplot
  {
    index=1
    for time in "${times_array[@]}"; do
      echo "$index $time"
      index=$((index + 1))
    done
    echo "e"
  } >> ./tmp/"$gnuplot_script"

  # Удаляем возможные невидимые символы из скрипта
  tr -d '\r' < ./tmp/"$gnuplot_script" > ./tmp/"$gnuplot_script".tmp && mv ./tmp/"$gnuplot_script".tmp ./tmp/"$gnuplot_script"

  # Запуск gnuplot для создания графика
  pushd ./results/graphs
  pwd
  gnuplot ../../tmp/"$gnuplot_script"
  popd
  echo "Gnuplot script saved as './tmp/$gnuplot_script'. Output saved as '$output_file'."

done
