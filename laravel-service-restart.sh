#!/bin/bash

# Configuration
CPU_THRESHOLD=80
SERVICE_NAME="laravel.service"  # Laravel service name
LARAVEL_PATH="/home/laravel/project"  # Laravel project path
LOG_FILE="/var/log/laravel_monitor.log"

# Get CPU usage (average over last 2 samples to get more accurate reading)
cpu_usage=$(top -bn2 | grep "Cpu(s)" | tail -n1 | awk '{print $2 + $4}' | cut -d. -f1)

# Log CPU usage
echo "$(date): CPU Usage: ${cpu_usage}%" >> "$LOG_FILE"

# Check if CPU usage exceeds threshold
if [ "$cpu_usage" -gt "$CPU_THRESHOLD" ]; then
    echo "$(date): CPU usage is high (${cpu_usage}%). Restarting Laravel service..." >> "$LOG_FILE"
    
    # Stop the service
    sudo systemctl stop "$SERVICE_NAME"
    
    # Clear Laravel cache
    cd "$LARAVEL_PATH" || exit
    php artisan optimize:clear
    
    # Start the service
    sudo systemctl start "$SERVICE_NAME"
    
    if [ $? -eq 0 ]; then
        echo "$(date): Service restart and cache clear successful" >> "$LOG_FILE"
    else
        echo "$(date): Service restart failed" >> "$LOG_FILE"
    fi
fi
