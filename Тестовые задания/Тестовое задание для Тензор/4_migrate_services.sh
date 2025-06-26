#!/bin/bash

# Получаем список всех юнитов, начинающихся с 'foobar-'
units=$(systemctl list-unit-files --no-legend 'foobar-*' | awk '{print $1}')

if [ -z "$units" ]; then
    echo "Не найдено ни одного юнита foobar-*"
    exit 0
fi

# Останавливаем все юниты
echo "Остановка юнитов..."
for unit in $units; do
    echo "Останавливаем $unit"
    systemctl stop "$unit"
done

# Обрабатываем каждый юнит
for unit in $units; do
    service_name="${unit#foobar-}"
    service_name="${service_name%.service}"  # Удаляем .service если есть
    
    # Пути к файлам и директориям
    old_dir="/opt/misc/$service_name"
    new_dir="/srv/data/$service_name"
    unit_file="/etc/systemd/system/$unit"
    
    # Проверка существования файла юнита
    if [ ! -f "$unit_file" ]; then
        echo "Файл юнита $unit_file не найден, пропускаем"
        continue
    fi
    
    # Переносим файлы сервиса
    if [ -d "$old_dir" ]; then
        echo "Переносим $old_dir -> $new_dir"
        mkdir -p "$(dirname "$new_dir")"
        mv "$old_dir" "$new_dir"
    else
        echo "Исходная директория $old_dir не найдена"
    fi
    
    # Обновляем пути в юнит-файле
    if [ -d "$new_dir" ]; then
        echo "Обновляем пути в $unit_file"
        
        # Обновляем WorkingDirectory
        sed -i "s|WorkingDirectory=/opt/misc/$service_name|WorkingDirectory=/srv/data/$service_name|g" "$unit_file"
        
        # Обновляем ExecStart
        sed -i "s|ExecStart=/opt/misc/$service_name|ExecStart=/srv/data/$service_name|g" "$unit_file"
    fi
done

# Перезагружаем systemd
systemctl daemon-reload
echo "Демон systemd перезагружен"

# Запускаем все юниты
echo "Запуск юнитов..."
for unit in $units; do
    echo "Запускаем $unit"
    systemctl start "$unit"
done

echo "Все операции завершены успешно"