#!/bin/bash

# ---------------------------------------------------
# Cловарь языков
# Неинтерпретируемые языки
declare -A compilers=(
    ["c-lcc-1.26"]="/opt/lcc-1.26/bin/lcc"
    ["c-lcc-1.27"]="/opt/lcc-1.27/bin/lcc"
    ["c-lcc-1.28"]="/opt/lcc-1.28/bin/lcc"
    ["c-lcc-1.29"]="/opt/lcc-1.28/bin/lcc"
    ["c-gcc-12"]="/opt/mcst/gcc-9.0.0-A.XXX.e2k-v5.5.10/bin/gcc"
    ["fortran-lcc-1.26"]="gfortran"
    ["fortran-lcc-1.27"]="gfortran"
    ["fortran-lcc-1.28"]="gfortran"
    ["fortran-lcc-1.29"]="gfortran"
    ["fortran-gccgo-12"]="/opt/mcst/gcc-9.0.0-A.XXX.e2k-v5.5.10/bin/gfortran"
    ["java-8"]="/usr/lib/jvm/java-8-openjdk-e2k/bin/java"
    ["java-11"]="/usr/lib/jvm/java-11-openjdk-e2k/bin/java"
    ["java-21"]="/usr/lib/jvm/java-11-openjdk-e2k/bin/java"
    ["rust-1.64"]="cargo run"
    ["go-1.17"]="/opt/mcst/gcc-9.0.0-A.XXX.e2k-v5.5.10/bin/go run"
)

#    ["vala"]="/usr/bin/valac"
# Кланг ручками ставим разные версии и запускаем по 1
#    ["clang-13"]="clang-13"
#    ["clang-17"]="clang-17"
#    ["clang-19"]="clang-19"
# В перспективе тоже самое для всех растов под разные ллвм

# Интерпретируемые языки
declare -A interpreters=(
    ["python3.9"]="/usr/bin/python3"
    ["nodejs-12"]="/usr/bin/node"
    ["gjs"]="/usr/bin/gjs"
    ["ruby"]="/usr/bin/ruby"
    ["perl"]="/usr/bin/perl"
    ["lua-5.1"]="/usr/bin/lua-5.1"
    ["luajit"]="/usr/bin/luajit-2.1.1738258586"
    ["php"]="/usr/bin/php"
)

# То что затащить не получилось
#    ["nodejs-18"]="/usr/bin/node"
#    ["dart"]="/usr/bin/dart"
#    ["mojo"]="/usr/bin/mojo"
# ... другие интерпретируемые языки

# ---------------------------------------------------
# Конфиги

#Кол-во итераций выполнений теста
iteration=10

#Выбор языков для тестов
#echo "${!compilers[@]}" "${!interpreters[@]}"
dirs=("${!compilers[@]}" "${!interpreters[@]}")

#Набор тестов
tests=( "matmul" "bedcov" "nqueen" "sudoku")
#tests=( "bedcov")

#Сохранение результатов
results_file="$PWD/build-graph-res/results/results-$(date +%d-%h-%m-%s).json"

# ---------------------------------------------------
# Функции

run_test() {
    local results_file="$results_file"
    local command="$2"        # Команда для выполнения теста
    local test_name="$1"      # Имя теста

    local results=()          # Массив для хранения результатов тестов

    local elapsed_times=()    # Массив для хранения времен выполнения

    for (( i = 1; i <= iteration; i++ )); do
        echo "i=$i, iteration=$iteration"
        local start_time=$(date +%s%N)

        # Выполнение команды на основе типа теста
        if [[ "$dir" == "java-11" ]] || [[ "$dir" == "java-8" ]]; then
            echo "command: ./$test_name"
            "$command" "$test_name" &> /dev/null

        elif [[ "$dir" == "vala" ]]; then
            echo "command: ./$test_name 1500"
            ./$test_name 1500 &> /dev/null

        elif [[ -n "${interpreters[$dir]}" ]]; then
            echo "command: $command"
            echo "test-name: $test_name"
            $command "$test_name" &> /dev/null

        else
            ./$test_name &> /dev/null # Другие компилируемые языки
        fi

        local end_time=$(date +%s%N)
        local elapsed_time=$((end_time - start_time))
        # Сохраним результат в наносекундах и потом преобразуем в секунды
        local elapsed_seconds=$(echo "scale=6; $elapsed_time/1000000000" | bc)

        echo "Время выполнения ($dir) $test_name: $elapsed_seconds секунд"

        # Сохранение времени выполнения в массив
        elapsed_times+=("$elapsed_seconds")
    done

    # Вычисление среднего времени выполнения
    local sum=0
    for time in "${elapsed_times[@]}"; do
        sum=$(echo "$sum + $time" | bc)
    done
    local count=${#elapsed_times[@]}
    local average=$(echo "scale=6; $sum / $count" | bc)

    # Вычисление дисперсии и стандартного отклонения
    local variance_sum=0
    for time in "${elapsed_times[@]}"; do
        variance_sum=$(echo "$variance_sum + ($time - $average)^2" | bc)
    done
    local variance=$(echo "scale=6; $variance_sum / $count" | bc)
    local standard_deviation=$(echo "scale=6; sqrt($variance)" | bc)

    # Формирование строки с временем
    local times_string=$(IFS=", "; echo "${elapsed_times[*]}")

    if [[ -n "${interpreters[$dir]}" ]]; then
		test_name="${test_name%.*}"
		echo $test_name
    fi

    # Создание JSON объекта для результата текущего теста
    local test_result=$(jq -n \
        --arg test_name "$test_name" \
        --argjson elapsed_times "[$times_string]" \
        --argjson average "$average" \
        --argjson variance "$variance" \
        --argjson standard_deviation "$standard_deviation" \
        '{test_name: $test_name, elapsed_times: $elapsed_times, average: $average, variance: $variance, standard_deviation: $standard_deviation}')

    # Проверка, существует ли файл результатов
    if [[ -f "$results_file" ]]; then
        # Если файл существует, обновляем его
        if jq -e --arg lang "$dir" '.[] | select(.language == $lang)' "$results_file" > /dev/null; then
            # Добавляем тест в уже существующий язык
            jq --arg lang "$dir" --argjson test "$test_result" \
               '(.[] | select(.language == $lang) | .tests) += [$test]' "$results_file" > temp.json && mv temp.json "$results_file"
        else
            # Если язык не существует, добавляем новый объект для языка
            jq --arg lang "$dir" --argjson test "$test_result" \
               '. += [{language: $lang, tests: [$test]}]' "$results_file" > temp.json && mv temp.json "$results_file"
        fi
    else
        # Если файла нет, создаем новый массив с первым результатом
        jq -n --arg lang "$dir" --argjson test "$test_result" \
            '[{language: $lang, tests: [$test]}]' > "$results_file"
    fi
}

# ---------------------------------------------------
# Меин

for dir in "${dirs[@]}"; do
    # Переходим в директорию с тестами для текущего языка
    cd "$dir" || { echo "Ошибка: не удалось перейти в директорию $dir"; continue; }
    if [[ "$dir" == "lcc-1.26" ]] || [[ "$dir" == "fortran-1.26" ]]  || [[ "$dir" == "go-1.26" ]] || \
	[[ "$dir" == "lcc-1.27" ]] || [[ "$dir" == "fortran-1.27" ]] || [[ "$dir" == "go-1.27" ]] || \
	[[ "$dir" == "lcc-1.28" ]] || [[ "$dir" == "fortran-1.28" ]] || [[ "$dir" == "go-1.28" ]] || [[ "$dir" == "lcc-1.29" ]] || [[ "$dir" == "fortran-1.29" ]]; then
	    if [[ "$dir" == "lcc-1.26" ]] || [[ "$dir" == "fortran-1.26" ]] || [[ "$dir" == "go-1.26" ]]; then
		    version_path="/opt/lcc-1.26"
	    elif [[ "$dir" == "lcc-1.27" ]] || [[ "$dir" == "fortran-1.27" ]] || [[ "$dir" == "go-1.27" ]]; then
		    version_path="/opt/lcc-1.27"
	    elif [[ "$dir" == "lcc-1.28" ]] || [[ "$dir" == "fortran-1.28" ]] || [[ "$dir" == "go-1.28" ]]; then
		    version_path="/opt/lcc-1.28"
	    elif [[ "$dir" == "lcc-1.29" ]] || [[ "$dir" == "fortran-1.29" ]]; then
		    version_path="/opt/lcc-1.29"
	    else
		    echo "Неизвестная версия: $dir"
		    exit 1
	    fi

    # Установка выбранной версии и выполнение теста
    sudo alternatives --set gcc-dir "$version_path"
    echo $(gcc --version)
    echo $(gfortran --version)
    fi

    echo Перехожу в директорию: $dir
    if [[ -n "${compilers[$dir]}" ]]; then
    make clean
    make
    fi
    for test in "${tests[@]}"; do
        if [[ -n "${compilers[$dir]}" ]]; then
            command="${compilers[$dir]}"            
            if [[ "$dir" == "java-11" ]] || [[ "$dir" == "java-8" ]]; then
                if [[ -f "$test.class" ]]; then
                    run_test "$test" "${compilers[$dir]}" 
                fi
            elif [[ -x "$test" ]]; then
		echo runing $test
                run_test $test
            fi

        elif [[ -n "${interpreters[$dir]}" ]]; then
            command="${interpreters[$dir]}"
            if [[ -f "./$test.py" ]]; then
                run_test "$test.py" "$command"
            elif [[ -f "./$test.pl" ]] && [[ "$dir" == "perl" ]]; then
                run_test "$test.pl" "$command"
            elif [[ -f "./$test.rb" ]] && [[ "$dir" == "ruby" ]]; then
                run_test "$test.rb" "$command"
            elif [[ -f "./$test.lua" ]] && [[ "$dir" == "lua-5.1" ]]; then
                run_test "$test.lua" "$command"
            elif [[ -f "./$test.lua" ]] && [[ "$dir" == "luajit" ]]; then
                run_test "$test.lua" "$command"
            elif [[ -f "./$test.php" ]] && [[ "$dir" == "php" ]]; then
                run_test "$test.php" "$command"
            elif [[ -f "./$test.js" ]] && [[ "$dir" == "nodejs-18" ]]; then
                run_test "$test.js" "$command"
            elif [[ -f "./$test.js" ]] && [[ "$dir" == "gjs" ]]; then
                run_test "$test.js" "$command"
            else
                echo "$dir: $test не найден"
            fi
        else
            echo "Неизвестный язык: $dir"
        fi
    done
    cd .. # Возвращаемся в исходную директорию
done

echo "Результаты записаны в $results_file"
# ---------------------------------------------------
