#!/bin/bash
# ==============================================
# Database Backup Script
# ==============================================
# Creates a timestamped PostgreSQL backup
# Usage: bash scripts/backup-db.sh
# ==============================================

set -e

BACKUP_DIR="./backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="${BACKUP_DIR}/expense_tracker_${TIMESTAMP}.sql"
CONTAINER_NAME="expense-postgres"

# Create backup directory
mkdir -p ${BACKUP_DIR}

echo "📦 Creating database backup..."
echo "   Timestamp: ${TIMESTAMP}"

# Check if running in Docker or Kubernetes
if docker ps --format '{{.Names}}' | grep -q ${CONTAINER_NAME}; then
    # Docker backup
    docker exec ${CONTAINER_NAME} pg_dump \
        -U expense_user \
        -d expense_tracker \
        --no-owner \
        --no-acl \
        > ${BACKUP_FILE}
elif kubectl get pods -n expense-tracker 2>/dev/null | grep -q postgres; then
    # Kubernetes backup
    POD_NAME=$(kubectl get pods -n expense-tracker -l component=database -o jsonpath='{.items[0].metadata.name}')
    kubectl exec -n expense-tracker ${POD_NAME} -- pg_dump \
        -U expense_user \
        -d expense_tracker \
        --no-owner \
        --no-acl \
        > ${BACKUP_FILE}
else
    echo "❌ No running PostgreSQL container found!"
    exit 1
fi

# Compress backup
gzip ${BACKUP_FILE}
COMPRESSED_FILE="${BACKUP_FILE}.gz"

# Show result
SIZE=$(du -h ${COMPRESSED_FILE} | cut -f1)
echo "✅ Backup created: ${COMPRESSED_FILE} (${SIZE})"

# Clean old backups (keep last 7)
echo "🧹 Cleaning old backups (keeping last 7)..."
ls -t ${BACKUP_DIR}/*.sql.gz 2>/dev/null | tail -n +8 | xargs -r rm
echo "✅ Cleanup complete"
