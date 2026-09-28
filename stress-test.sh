#!/bin/bash

# Целевой URL
URL="http://10.38.89.249:30080/redblue"

# Количество параллельных запросов в одной "волне"
BATCH_SIZE=100

# Интервал между волнами (в секундах). 0.1 = 100 мс
INTERVAL=0.1

echo "Запуск нагрузки на $URL"
echo "Волна: $BATCH_SIZE запросов каждые $INTERVAL сек."
echo "Для остановки нажмите Ctrl+C"
echo "----------------------------------------"

# Счетчик волн
WAVE=0

while true; do
    WAVE=$((WAVE + 1))
    
    # Запускаем пачку запросов в фоне
    for ((i=1; i<=BATCH_SIZE; i++)); do
        curl -s "$URL" > /dev/null &
    done
    
    echo "Волна #$WAVE отправлена (PID последнего: $!)"
    
    # Ждем указанный интервал
    sleep $INTERVAL
done