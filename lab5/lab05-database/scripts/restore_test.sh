#!/usr/bin/env bash
# Відновлення останньої (або вказаної) копії в тестову БД test_restore
# та порівняння кількості записів з оригіналом.
#   bash scripts/restore_test.sh [backups/sportsclub_YYYYMMDD_HHMMSS.dump]
set -euo pipefail
DUMP=${1:-$(ls -t backups/*.dump | head -1)}
NAME=$(basename "$DUMP")
PSQL="docker compose exec -T postgres psql -U postgres"

echo ">>> Відновлення $NAME у test_restore"
$PSQL -c "DROP DATABASE IF EXISTS test_restore;"
$PSQL -c "CREATE DATABASE test_restore;"
docker compose exec -T postgres pg_restore -U postgres -d test_restore --no-owner "/backups/$NAME"

for db in sportsclub test_restore; do
  echo; echo "===== $db ====="
  $PSQL -d "$db" -f /lab05/10_backup_restore_verify.sql
done
