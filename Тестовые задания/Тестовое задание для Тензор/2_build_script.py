import os
import sys
import json
import shutil
import subprocess
from datetime import datetime
import logging
import glob

def setup_logging():
    """Настройка логирования с временными метками"""
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(message)s',
        datefmt='%Y-%m-%d %H:%M:%S'
    )

def clone_repository(repo_url, temp_dir):
    """Клонирование репозитория"""
    logging.info(f"Клонирование репозитория: {repo_url}")
    result = subprocess.run(
        ["git", "clone", repo_url, temp_dir],
        capture_output=True,
        text=True
    )
    if result.returncode != 0:
        logging.error(f"Ошибка клонирования: {result.stderr}")
        sys.exit(1)
    logging.info("Репозиторий успешно клонирован")

def clean_directory(temp_dir, src_path):
    """Очистка директории, оставляем только нужный путь"""
    logging.info(f"Очистка директории, оставляем только: {src_path}")
    
    # Получаем первый компонент пути
    base_dir = src_path.split('/')[0]
    
    # Удаляем все в корне, кроме базовой директории
    for item in os.listdir(temp_dir):
        item_path = os.path.join(temp_dir, item)
        if item != base_dir:
            if os.path.isdir(item_path):
                shutil.rmtree(item_path)
            else:
                os.remove(item_path)
    
    logging.info(f"Директория очищена, сохранен только: {base_dir}")

def create_version_json(temp_dir, src_path, version):
    """Создание файла version.json"""
    logging.info(f"Создание version.json в: {src_path}")
    
    target_dir = os.path.join(temp_dir, src_path)
    if not os.path.exists(target_dir):
        logging.error(f"Директория не найдена: {target_dir}")
        sys.exit(1)
    
    # Сбор списка файлов
    file_types = ('*.py', '*.js', '*.sh')
    files = []
    for ext in file_types:
        files.extend(
            [os.path.basename(f) for f in glob.glob(os.path.join(target_dir, ext))]
    
    # Формируем данные
    version_data = {
        "name": "hello world",
        "version": version,
        "files": files
    }
    
    # Записываем файл
    version_path = os.path.join(target_dir, "version.json")
    with open(version_path, 'w') as f:
        json.dump(version_data, f, indent=2)
    
    logging.info(f"Файл version.json создан: {version_path}")
    return files

def create_archive(temp_dir, src_path, version):
    """Создание архива с исходным кодом"""
    logging.info("Создание архива")
    
    # Получаем имя последней директории
    last_dir = os.path.basename(src_path)
    
    # Форматируем дату
    current_date = datetime.now().strftime("%d%m%Y")
    archive_name = f"{last_dir}{current_date}"
    
    # Создаем архив
    source_dir = os.path.join(temp_dir, src_path)
    shutil.make_archive(archive_name, 'zip', source_dir)
    
    archive_path = f"{os.getcwd()}/{archive_name}.zip"
    logging.info(f"Архив создан: {archive_path}")
    return archive_path

def main():
    if len(sys.argv) != 4:
        print("Использование: python build_script.py <repo_url> <src_path> <version>")
        sys.exit(1)
    
    repo_url = sys.argv[1]
    src_path = sys.argv[2]
    version = sys.argv[3]
    
    setup_logging()
    start_time = datetime.now()
    logging.info(f"Начало работы скрипта")
    
    # Создаем временную директорию
    temp_dir = "temp_repo"
    if os.path.exists(temp_dir):
        shutil.rmtree(temp_dir)
    
    # Основной процесс
    clone_repository(repo_url, temp_dir)
    clean_directory(temp_dir, src_path)
    files_list = create_version_json(temp_dir, src_path, version)
    archive_path = create_archive(temp_dir, src_path, version)
    
    # Финализация
    shutil.rmtree(temp_dir)
    end_time = datetime.now()
    duration = (end_time - start_time).total_seconds()
    
    logging.info(f"Скрипт выполнен за {duration:.2f} секунд")
    print("\nРезультаты:")
    print(f"1. Создан архив: {os.path.basename(archive_path)}")
    print(f"2. Файлы в version.json: {files_list}")
    print(f"3. Версия: {version}")

if __name__ == "__main__":
    main()