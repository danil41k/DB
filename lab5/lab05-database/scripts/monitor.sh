#!/usr/bin/env bash
# Запуск моніторингу продуктивності; звіт зберігається в results/.
set -euo pipefail
STAMP=$(date +%Y%m%d_%H%M%S)
mkdir -p results
docker compose exec -T postgres psql -U postgres -d sportsclub -f /lab05/15_monitoring.sql \
  | tee "results/monitor_${STAMP}.txt"
echo "Звіт збережено: results/monitor_${STAMP}.txt"
