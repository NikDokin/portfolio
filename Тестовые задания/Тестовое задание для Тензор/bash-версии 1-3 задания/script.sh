#!/bin/bash
set -e

generate_version() {
    local template=$1
    local version=""
    IFS='.' read -ra parts <<< "$template"
    
    for part in "${parts[@]}"; do
        if [ "$part" = "*" ]; then
            version+="$((RANDOM % 100))."
        else
            version+="$part."
        fi
    done
    
    echo "${version%.}"
}

version_compare() {
    local v1=(${1//./ }) v2=(${2//./ })
    
    for i in "${!v1[@]}"; do
        [ -z "${v2[i]}" ] && return 1
        [ "${v1[i]}" -lt "${v2[i]}" ] && return 0
        [ "${v1[i]}" -gt "${v2[i]}" ] && return 1
    done
    [ "${#v1[@]}" -lt "${#v2[@]}" ]
}

main() {
    [ $# -ne 2 ] && {
        echo "Использование: $0 <номер_версии> <файл_конфигурации>" >&2
        exit 1
    }
    
    local base_version=$1 config_file=$2
    [ ! -f "$config_file" ] && { echo "Файл не найден: $config_file" >&2; exit 1; }
    
    local templates=($(jq -r '.[]' "$config_file"))
    [ ${#templates[@]} -eq 0 ] && { echo "Некорректный JSON" >&2; exit 1; }
    
    local all_versions=()
    for template in "${templates[@]}"; do
        all_versions+=($(generate_version "$template"))
        all_versions+=($(generate_version "$template"))
    done
    
    echo "Отсортированный список всех версий:"
    printf "%s\n" "${all_versions[@]}" | sort -t '.' -n -k1,1 -k2,2 -k3,3
    
    echo -e "\nВерсии старше $base_version:"
    for version in "${all_versions[@]}"; do
        if version_compare "$version" "$base_version"; then
            echo "$version"
        fi
    done
}

main "$@"