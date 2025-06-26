#!/bin/bash

PROCESS_NAME="test"
MONITORING_URL="https://test.com/monitoring/test/api"
STATE_FILE="/var/run/monitor_test.state"
LOG_FILE="/var/log/monitoring.log"

# Проверка запущен ли процесс
if pgrep -x "$PROCESS_NAME" > /dev/null; then
    current_state=1
else
    current_state=0
fi

# Чтение предыдущего состояния
prev_state=0
if [[ -f "$STATE_FILE" ]]; then
    prev_state=$(cat "$STATE_FILE")
fi

# Обработка состояния процесса
if [[ "$current_state" -eq 1 ]]; then
    # Логирование перезапуска
    if [[ "$prev_state" -eq 0 && -f "$STATE_FILE" ]]; then
        echo "$(date "+%Y-%m-%d %H:%M:%S") - Process $PROCESS_NAME was restarted" >> "$LOG_FILE"
    fi
    
    # Cтучимся
    if ! curl -s -o /dev/null --connect-timeout 5 --max-time 10 "$MONITORING_URL"; then
        echo "$(date "+%Y-%m-%d %H:%M:%S") - Monitoring server is not available" >> "$LOG_FILE"
    fi
    
    echo "1" > "$STATE_FILE"
else
    echo "0" > "$STATE_FILE"
fi