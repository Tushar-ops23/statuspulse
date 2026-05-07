#!/bin/bash
set -e

# Configuration
LOG_FILE="./deploy.log"
APP_NAME="statuspulse-app"
IMAGE_NAME="${IMAGE_NAME:-ghcr.io/tushar-ops23/statuspulse}"
TAG=${IMAGE_TAG:-"latest"}

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "Starting deployment for tag: $TAG"

# 0. Ensure infra is up
log "Ensuring database and redis are running..."
docker compose up -d postgres redis

# 1. Pull latest image
log "Pulling image $IMAGE_NAME:$TAG..."
docker pull "$IMAGE_NAME:$TAG"

# 2. Start new container on a temporary name
NEW_CONTAINER="${APP_NAME}_new"
log "Starting new container $NEW_CONTAINER..."

# Get current container ID to rollback if needed
OLD_CONTAINER_ID=$(docker ps -aqf "name=^${APP_NAME}$")

docker run -d \
    --name "$NEW_CONTAINER" \
    --network statuspulse-network \
    --env-file .env \
    -e IMAGE_TAG="$TAG" \
    "$IMAGE_NAME:$TAG"

# 3. Health check
log "Running health check on new container..."
MAX_RETRIES=10
COUNT=0
HEALTHY=false

while [ $COUNT -lt $MAX_RETRIES ]; do
    if docker exec "$NEW_CONTAINER" curl -s http://localhost:8000/health | grep -q "healthy"; then
        HEALTHY=true
        break
    fi
    log "Waiting for container to be healthy... ($((COUNT+1))/$MAX_RETRIES)"
    sleep 5
    COUNT=$((COUNT+1))
done

if [ "$HEALTHY" = true ]; then
    log "New container is healthy. Switching traffic..."
    
    # Stop and remove old container
    if [ -n "$OLD_CONTAINER_ID" ]; then
        docker stop "$OLD_CONTAINER_ID"
        docker rm "$OLD_CONTAINER_ID"
    fi
    
    # Rename new container to official name
    docker rename "$NEW_CONTAINER" "$APP_NAME"
    
    log "Deployment successful!"
else
    log "ERROR: New container failed health check. Rolling back..."
    docker stop "$NEW_CONTAINER"
    docker rm "$NEW_CONTAINER"
    
    if [ -n "$OLD_CONTAINER_ID" ]; then
        docker start "$OLD_CONTAINER_ID"
        log "Rollback complete: Old container restarted."
    else
        log "CRITICAL: No old container to roll back to!"
    fi
    exit 1
fi
