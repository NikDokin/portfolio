# Создаем скрипт
sudo nano /usr/local/bin/monitor_test.sh  # исправлено имя файла

# Выдаём права
sudo chmod 755 /usr/local/bin/monitor_test.sh

# Создаем сервис и таймер
sudo nano /etc/systemd/system/monitor-test.service
sudo nano /etc/systemd/system/monitor-test.timer

# Создаем лог и права 
sudo touch /var/log/monitoring.log
sudo chown root:root /var/log/monitoring.log
sudo chmod 644 /var/log/monitoring.log

# Перезагружаем, включаем автозапуск и запускаем таймер
sudo systemctl daemon-reload
sudo systemctl enable monitor-test.timer
sudo systemctl start monitor-test.timer

# Проверить статус таймера
systemctl status monitor-test.timer

# Просмотр логов
tail -f /var/log/monitoring.log

# Тестовый запуск скрипта
sudo /usr/local/bin/monitor_test.sh

# После перезагрузки системы проверить автозапуск
sudo systemctl is-enabled monitor-test.timer

# Для отладки просмотр журнала systemd
journalctl -u monitor-test.service -f

## Скрипт будет автоматически запускаться сразу после загрузки системы (когда сеть будет готова) и каждую минуту проверять состояние процесса.