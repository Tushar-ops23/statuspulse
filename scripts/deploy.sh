#!/bin/bash
set -e

LOG_FILE="./deploy.log"
APP_NAME="statuspulse-app"
IMAGE_NAME="${IMAGE_NAME:-ghcr.io/tushar-ops23/statuspulse}"
TAG=${IMAGE_TAG:-"latest"}

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
    }

    log "User: $(whoami), Groups: $(groups)"
    log "Starting deployment for tag: $TAG"

    log "Ensuring database and redis are running..."
    sudo docker compose up -d postgres redis

    log "Pulling image $IMAGE_NAME:$TAG..."
    sudo docker pull "$IMAGE_NAME:$TAG"

    NEW_CONTAINER="${APP_NAME}_new"
    log "Starting new container $NEW_CONTAINER..."
    OLD_CONTAINER_ID=$(sudo docker ps -aqf "name=^${APP_NAME}$")

    sudo docker run -d \
        --name "$NEW_CONTAINER" \
            --network statuspulse-network \
                --env-file .env \
                    -e IMAGE_TAG="$TAG" \
                        "$IMAGE_NAME:$TAG"

                        log "Running health check on new container..."
                        MAX_RETRIES=10
                        COUNT=0
                        HEALTHY=false

                        while [ $COUNT -lt $MAX_RETRIES ]; do
                            if sudo docker exec "$NEW_CONTAINER" curl -s http://localhost:8000/health | grep -q "healthy"; then
                                    HEALTHY=true
                                            break
                                                fi
                                                    log "Waiting for container to be healthy... ($((COUNT+1))/$MAX_RETRIES)"
                                                        sleep 5
                                                            COUNT=$((COUNT+1))
                                                            done

                                                            if [ "$HEALTHY" = "true" ]; then
                                                                log "Container is healthy! Switching..."
                                                                    if [ ! -z "$OLD_CONTAINER_ID" ]; then
                                                                            sudo docker stop "$APP_NAME" || true
                                                                                    sudo docker rm "$APP_NAME" || true
                                                                                        fi
                                                                                            sudo docker rename "$NEW_CONTAINER" "$APP_NAME"
                                                                                                log "Deployment successful!"
                                                                                                else
                                                                                                    log "Deployment failed: Health check timed out"
                                                                                                        sudo docker stop "$NEW_CONTAINER" || true
                                                                                                            sudo docker rm "$NEW_CONTAINER" || true
                                                                                                                exit 1
                                                                                                                fi
                                                                                                                
