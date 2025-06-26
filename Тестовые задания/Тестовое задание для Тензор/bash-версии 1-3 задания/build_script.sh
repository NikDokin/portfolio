#!/bin/bash
set -e

setup_logging() {
    exec > >(awk '{print strftime("%Y-%m-%d %H:%M:%S") " $0}') 2>&1
}

clone_repository() {
    local repo_url=$1 temp_dir=$2
    echo "Клонирование репозитория: $repo_url"
    if ! git clone "$repo_url" "$temp_dir" &>/dev/null; then
        echo "Ошибка клонирования" >&2
        exit 1
    fi
    echo "Репозиторий успешно клонирован"
}

clean_directory() {
    local temp_dir=$1 src_path=$2
    local base_dir="${src_path%%/*}"
    echo "Очистка директории, оставляем только: $base_dir"
    
    find "$temp_dir" -mindepth 1 -maxdepth 1 ! -name "$base_dir" -exec rm -rf {} +
    echo "Директория очищена, сохранен только: $base_dir"
}

create_version_json() {
    local temp_dir=$1 src_path=$2 version=$3
    local target_dir="$temp_dir/$src_path"
    echo "Создание version.json в: $target_dir"
    
    [ ! -d "$target_dir" ] && { echo "Директория не найдена: $target_dir" >&2; exit 1; }
    
    local files=()
    while IFS= read -r -d $'\0' file; do
        files+=("$(basename "$file")")
    done < <(find "$target_dir" \( -name '*.py' -o -name '*.js' -o -name '*.sh' \) -print0)
    
    cat > "$target_dir/version.json" <<EOF
{
  "name": "hello world",
  "version": "$version",
  "files": $(json_array "${files[@]}")
}
EOF
    echo "Файл version.json создан: $target_dir/version.json"
    echo "${files[@]}"
}

json_array() {
    local first=1
    printf "["
    for item in "$@"; do
        [ $first -eq 1 ] && first=0 || printf ","
        printf "\"%s\"" "$item"
    done
    printf "]"
}

create_archive() {
    local temp_dir=$1 src_path=$2 version=$3
    local last_dir="${src_path##*/}"
    local current_date=$(date +"%d%m%Y")
    local archive_name="${last_dir}${current_date}"
    
    echo "Создание архива: $archive_name.zip"
    (cd "$temp_dir/$src_path" && zip -qr "$archive_name.zip" .)
    mv "$temp_dir/$src_path/$archive_name.zip" .
    
    echo "Архив создан: $PWD/$archive_name.zip"
    echo "$PWD/$archive_name.zip"
}

main() {
    [ $# -ne 3 ] && { 
        echo "Использование: $0 <repo_url> <src_path> <version>" >&2
        exit 1
    }
    
    local repo_url=$1 src_path=$2 version=$3
    local temp_dir="temp_repo"
    local start_time=$(date +%s)
    
    setup_logging
    echo "Начало работы скрипта"
    
    [ -d "$temp_dir" ] && rm -rf "$temp_dir"
    
    clone_repository "$repo_url" "$temp_dir"
    clean_directory "$temp_dir" "$src_path"
    local files_list=$(create_version_json "$temp_dir" "$src_path" "$version")
    local archive_path=$(create_archive "$temp_dir" "$src_path" "$version")
    
    rm -rf "$temp_dir"
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    echo "Скрипт выполнен за $duration секунд"
    echo -e "\nРезультаты:"
    echo "1. Создан архив: $(basename "$archive_path")"
    echo "2. Файлы в version.json: $files_list"
    echo "3. Версия: $version"
}

main "$@"