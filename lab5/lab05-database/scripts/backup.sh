#!/usr/bin/env bash
# Резервне копіювання БД sportsclub (pg_dump): custom-формат + SQL-формат.
# Файли з'являються в ./backups (змонтовано в контейнер як /backups).
set -euo pipefail
STAMP=$(date +%Y%m%d_%H%M%S)
mkdir -p backups && chmod 777 backups   # щоб користувач postgres у контейнері міг писати

docker compose exec -T postgres pg_dump -U postgres -d sportsclub -F c -Z 6 -f "/backups/sportsclub_${STAMP}.dump"
docker compose exec -T postgres pg_dump -U postgres -d sportsclub          -f "/backups/sportsclub_${STAMP}.sql"

echo "Створено:"
ls -lh backups/sportsclub_${STAMP}.*
