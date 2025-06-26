import sys
import json
import random

def generate_version(template):
    parts = []
    for part in template.split('.'):
        if part == '*':
            parts.append(str(random.randint(0, 99)))
        else:
            parts.append(part)
    return '.'.join(parts)

def main():
    if len(sys.argv) != 3:
        print("Использование: python script.py <номер_версии> <файл_конфигурации>")
        sys.exit(1)
    
    base_version = sys.argv[1]
    config_file = sys.argv[2]
    
    try:
        with open(config_file, 'r') as f:
            config = json.load(f)
    except FileNotFoundError:
        print(f"Ошибка: Файл '{config_file}' не найден.")
        sys.exit(1)
    except json.JSONDecodeError:
        print("Ошибка: Некорректный формат JSON в конфигурационном файле.")
        sys.exit(1)
    
    templates = list(config.values())
    all_versions = []
    
    for template in templates:
        version1 = generate_version(template)
        version2 = generate_version(template)
        all_versions.append(version1)
        all_versions.append(version2)
    
    # Преобразование версий в списки чисел для сортировки
    def version_key(v):
        return [int(part) for part in v.split('.')]
    
    sorted_versions = sorted(all_versions, key=version_key)
    
    print("Отсортированный список всех версий:")
    for v in sorted_versions:
        print(v)
    
    # Преобразование базовой версии для сравнения
    base_parts = [int(part) for part in base_version.split('.')]
    older_versions = []
    
    for v in sorted_versions:
        v_parts = [int(part) for part in v.split('.')]
        if v_parts < base_parts:
            older_versions.append(v)
    
    print(f"\nВерсии старше {base_version}:")
    for v in older_versions:
        print(v)

if __name__ == "__main__":
    main()