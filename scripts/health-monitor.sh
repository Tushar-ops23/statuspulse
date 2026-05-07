#!/bin/bash

# Configuration
URL="http://localhost:8000/health"
LOG_FILE="/var/log/statuspulse-monitor.log"
DISK_THRESHOLD=80
MEM_THRESHOLD=90
WEBHOOK_URL=${ALERT_WEBHOOK_URL:-""}
DOMAIN=${DOMAIN:-"example.com"}

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

send_alert() {
    local message="$1"
    log "ALERT: $message"
    if [ -n "$WEBHOOK_URL" ]; then
        curl -s -X POST -H "Content-Type: application/json" \
            -d "{\"text\": \"🚨 StatusPulse Alert: $message\"}" "$WEBHOOK_URL"
    fi
}

# 1. Check App Health
HEALTH_JSON=$(curl -s --max-time 10 "$URL")
if [ $? -ne 0 ] || ! echo "$HEALTH_JSON" | grep -q "healthy"; then
    send_alert "Application health check failed or timed out! Response: $HEALTH_JSON"
fi

# 2. Check Disk Usage
DISK_USAGE=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
if [ "$DISK_USAGE" -gt "$DISK_THRESHOLD" ]; then
    send_alert "Disk usage critical: ${DISK_USAGE}%"
fi

# 3. Check Memory Usage
MEM_USAGE=$(free | grep Mem | awk '{print $3/$2 * 100.0}' | cut -d. -f1)
if [ "$MEM_USAGE" -gt "$MEM_THRESHOLD" ]; then
    send_alert "Memory usage critical: ${MEM_USAGE}%"
fi

# 4. Check Docker Containers
CONTAINERS=("statuspulse-app" "statuspulse-db" "statuspulse-redis" "statuspulse-proxy")
for container in "${CONTAINERS[@]}"; do
    if ! docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
        send_alert "Container $container is NOT running!"
    fi
done

# 5. Check TLS Expiry (within 14 days)
if [ -n "$DOMAIN" ] && [ "$DOMAIN" != "example.com" ]; then
    EXPIRY_DATE=$(echo | openssl s_client -servername "$DOMAIN" -connect "$DOMAIN":443 2>/dev/null | openssl x509 -noout -enddate | cut -d= -f2)
    if [ -n "$EXPIRY_DATE" ]; then
        EXPIRY_EPOCH=$(date -d "$EXPIRY_DATE" +%s)
        NOW_EPOCH=$(date +%s)
        DAYS_LEFT=$(( (EXPIRY_EPOCH - NOW_EPOCH) / 86400 ))
        if [ "$DAYS_LEFT" -lt 14 ]; then
            send_alert "TLS Certificate for $DOMAIN expires in $DAYS_LEFT days!"
        fi
    fi
fi

log "Health check completed successfully."
