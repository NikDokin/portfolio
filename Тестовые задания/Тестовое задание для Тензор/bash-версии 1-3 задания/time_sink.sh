#!/bin/bash

# Проверка зависимостей
check_dependencies() {
    local dependencies=("curl" "jq" "bc")
    for dep in "${dependencies[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            echo "Ошибка: $dep не установлен"
            exit 1
        fi
    done
}

check_dependencies

URL="https://yandex.com/time/sync.json?geo=213"

# a) Сырой ответ сервера
echo "a) Сырой ответ сервера:"
curl -s "$URL"
echo -e "\n--------------------------------------------------\n"

# b) Человеко-понятное время и временная зона
response=$(curl -s "$URL")
time_ms=$(echo "$response" | jq -r '.time')
offset_ms=$(echo "$response" | jq -r '.clocks."213".offset')
tz_name=$(echo "$response" | jq -r '.clocks."213".name')

# Преобразуем время в секунды
time_sec=$(echo "scale=3; $time_ms / 1000" | bc)

# Вычисляем локальное время (UTC + смещение)
local_time_sec=$(echo "scale=3; $time_sec + $offset_ms/1000" | bc)

# Форматируем дату и время
human_time=$(date -d "@$local_time_sec" +"%d.%m.%Y %H:%M:%S")

# Форматируем смещение часового пояса
if [ "$offset_ms" -ge 0 ]; then
    offset_sign="+"
else
    offset_sign=""
fi
offset_hours=$(echo "scale=1; $offset_ms / 3600000" | bc)

echo "b) Текущее время: $human_time"
echo "   Временная зона: $tz_name (UTC$offset_sign$offset_hours)"
echo -e "\n--------------------------------------------------\n"

# c) и d) Серия из 5 замеров дельты
echo "c) Замеры дельты времени:"
deltas=()
for i in {1..5}; do
    # Фиксируем время до запроса (UTC в наносекундах)
    start_ns=$(date +%s%N)
    
    # Выполняем запрос
    response=$(curl -s "$URL")
    time_ms=$(echo "$response" | jq -r '.time')
    
    # Получаем текущее время UTC в наносекундах
    end_ns=$(date +%s%N)
    
    # Вычисляем среднее время запроса (между start и end)
    mid_ns=$(( (start_ns + end_ns) / 2 ))
    
    # Конвертируем серверное время в наносекунды
    server_ns=$(( time_ms * 1000000 ))
    
    # Вычисляем дельту в секундах
    delta_s=$(echo "scale=9; ($server_ns - $mid_ns) / 1000000000" | bc)
    deltas+=("$delta_s")
    
    printf "Запрос #%d: %.6f сек\n" $i $delta_s
done

# Рассчет средней дельты
sum=0
for delta in "${deltas[@]}"; do
    sum=$(echo "scale=9; $sum + $delta" | bc)
done
avg_delta=$(echo "scale=9; $sum / ${#deltas[@]}" | bc)
avg_ms=$(echo "scale=2; $avg_delta * 1000" | bc)

echo -e "\nd) Средняя дельта:"
printf "%.6f сек\n" $avg_delta
printf "   (%.2f мс)\n" $avg_ms