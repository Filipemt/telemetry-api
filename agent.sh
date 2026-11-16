#!/bin/bash

API_URL="http://localhost:8080/v1/telemetry"
API_KEY="local-dev-key-123"

echo "Starting continuous telemetry agent. Press [CTRL+C] to stop."

while true; do
    HOSTNAME=$(hostname)
    if [ "$(uname -s)" = "Darwin" ]; then
        CPU_USAGE=$(top -l 1 -n 0 | awk '/CPU usage/ {
            gsub("%", "", $3);
            gsub("%", "", $5);
            printf "%.2f", $3 + $5;
        }')
        MEM_TOTAL=$(sysctl -n hw.memsize | awk '{printf "%.0f", $1 / 1024 / 1024}')
        PAGE_SIZE=$(vm_stat | awk '/page size of/ {gsub("[^0-9]", "", $8); print $8}')
        MEM_USED=$(vm_stat | awk -v page_size="$PAGE_SIZE" '
            /Pages active/ || /Pages wired down/ || /Pages occupied by compressor/ {
                gsub("[^0-9]", "", $NF);
                total += $NF;
            }
            END { printf "%.0f", total * page_size / 1024 / 1024 }
        ')
        DISK_TOTAL=$(df -Pk / | awk 'NR==2 {printf "%.0f", $2 / 1024}')
        DISK_USED=$(df -Pk / | awk 'NR==2 {printf "%.0f", $3 / 1024}')
        BOOT_TIME=$(sysctl -n kern.boottime | awk -F'[ =}]+' '{gsub(",", "", $3); print $3}')
        UPTIME=$(($(date +%s) - BOOT_TIME))
    else
        CPU_IDLE=$(top -bn1 | awk '/Cpu\(s\)/ {gsub("%", "", $8); print $8}')
        CPU_USAGE=$(awk "BEGIN {printf \"%.2f\", 100 - $CPU_IDLE}")
        MEM_TOTAL=$(free -m | awk '/^Mem:/{print $2}')
        MEM_USED=$(free -m | awk '/^Mem:/{print $3}')
        DISK_TOTAL=$(df -BG / | awk 'NR==2 {gsub("G", "", $2); print $2}')
        DISK_USED=$(df -BG / | awk 'NR==2 {gsub("G", "", $3); print $3}')
        UPTIME=$(awk '{print int($1)}' /proc/uptime)
    fi

    PAYLOAD=$(cat <<EOF
{
  "hostname": "$HOSTNAME",
  "cpuUsagePercentage": $CPU_USAGE,
  "memoryTotalMb": $MEM_TOTAL,
  "memoryUsedMb": $MEM_USED,
  "diskTotalGb": $DISK_TOTAL,
  "diskUsedGb": $DISK_USED,
  "systemUptimeSeconds": $UPTIME
}
EOF
    )

    HTTP_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$API_URL" \
      -H "Content-Type: application/json" \
      -H "X-API-KEY: $API_KEY" \
      -d "$PAYLOAD")
    HTTP_STATUS=$(printf '%s\n' "$HTTP_RESPONSE" | tail -n 1)
    HTTP_BODY=$(printf '%s\n' "$HTTP_RESPONSE" | sed '$d')

    if [ "$HTTP_STATUS" = "201" ]; then
        echo "$(date -u +"%Y-%m-%dT%H:%M:%SZ") - INFO - Telemetry data successfully sent. HTTP Status: 201"
    else
        echo "$(date -u +"%Y-%m-%dT%H:%M:%SZ") - ERROR - Failed to send telemetry data. HTTP Status: $HTTP_STATUS Response: $HTTP_BODY"
    fi
done