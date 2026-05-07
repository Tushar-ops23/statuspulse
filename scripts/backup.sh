#!/bin/bash

# Configuration
BACKUP_DIR="/backups/postgres"
TIMESTAMP=$(date +%Y-%m-%d_%H%M%S)
BACKUP_FILE="statuspulse_db_${TIMESTAMP}.sql.gz"
CONTAINER_NAME="statuspulse-db"
DB_NAME=${DB_NAME:-"statuspulse"}
DB_USER=${DB_USER:-"postgres"}
RETENTION_DAYS=7
S3_BUCKET=${S3_BUCKET:-""}
LOG_FILE="/var/log/statuspulse-backup.log"

mkdir -p "$BACKUP_DIR"

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

log "Starting database backup..."

# 1. Dump database
if docker exec "$CONTAINER_NAME" pg_dump -U "$DB_USER" "$DB_NAME" | gzip > "$BACKUP_DIR/$BACKUP_FILE"; then
    log "Backup successful: $BACKUP_FILE"
else
    log "ERROR: Backup failed!"
    exit 1
fi

# 2. Upload to S3 (optional)
if [ -n "$S3_BUCKET" ]; then
    log "Uploading to S3..."
    if aws s3 cp "$BACKUP_DIR/$BACKUP_FILE" "s3://$S3_BUCKET/backups/$BACKUP_FILE"; then
        log "S3 Upload successful."
    else
        log "WARNING: S3 Upload failed!"
    fi
fi

# 3. Retention policy (keep last 7 days)
log "Cleaning up old backups..."
find "$BACKUP_DIR" -type f -name "statuspulse_db_*.sql.gz" -mtime +$RETENTION_DAYS -delete
log "Cleanup complete."
