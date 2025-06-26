import requests
import datetime
import statistics

url = "https://yandex.com/time/sync.json?geo=213"

# a) Выполнение запроса и вывод сырого ответа
print("a) Сырой ответ сервера:")
response = requests.get(url)
print(response.text)
print("\n" + "-"*50 + "\n")

# b) Человеко-понятное время и временная зона
data = response.json()

# Извлекаем timestamp в миллисекундах
server_time_ms = data['time']

# Преобразуем в datetime (UTC)
server_dt_utc = datetime.datetime.fromtimestamp(server_time_ms / 1000.0, tz=datetime.timezone.utc)

# Извлекаем информацию о временной зоне
clock_data = data['clocks']['213']
time_zone_name = clock_data['name']
offset_ms = clock_data['offset']

# Конвертируем смещение в часы
offset_hours = offset_ms / (1000 * 60 * 60)

# Создаем объект временной зоны
timezone = datetime.timezone(datetime.timedelta(hours=offset_hours))

# Конвертируем серверное время в локальную временную зону
local_dt = server_dt_utc.astimezone(timezone)

# Форматируем время
human_time = local_dt.strftime("%d.%m.%Y %H:%M:%S")

print(f"b) Текущее время: {human_time}")
print(f"   Временная зона: {time_zone_name} (UTC{'+' if offset_hours >= 0 else ''}{offset_hours:.1f})")
print("\n" + "-"*50 + "\n")

# c) и d) Расчет дельты времени для 5 запросов
deltas = []
print("c) Замеры дельты времени:")
for i in range(5):
    # Фиксация времени ДО запроса (UTC)
    local_before = datetime.datetime.now(datetime.timezone.utc)
    
    # Выполнение запроса
    response = requests.get(url)
    data = response.json()
    
    # Получение серверного времени
    server_time_ms = data['time']
    server_dt_utc = datetime.datetime.fromtimestamp(server_time_ms / 1000.0, tz=datetime.timezone.utc)
    
    # Расчет дельты в секундах
    delta = (server_dt_utc - local_before).total_seconds()
    deltas.append(delta)
    print(f"Запрос #{i+1}: {delta:.6f} сек")

# Расчет средней дельты
avg_delta = statistics.mean(deltas)
print("\nd) Средняя дельта:")
print(f"{avg_delta:.6f} сек")
print(f"   ({avg_delta*1000:.2f} мс)")