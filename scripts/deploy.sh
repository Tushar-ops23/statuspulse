#!/bin/bash
set -e

LOG_FILE="./deploy.log"

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "Starting deployment..."

if [ ! -f .env ]; then
    log "Creating .env file..."
    cat <<EOF > .env
DB_NAME=statuspulse
DB_USER=postgres
DB_PASSWORD=postgres
DB_HOST=postgres
REDIS_HOST=redis
EOF
fi

log "Pulling latest images..."
sudo docker compose pull

log "Starting services..."
sudo docker compose up -d

log "Deployment successful!"
