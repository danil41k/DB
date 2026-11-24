#!/usr/bin/env bash
# Послідовно застосовує всі скрипти лабораторної №5.
# Запускати з кореня проєкту:  bash scripts/run_lab05.sh
# Результати EXPLAIN «до/після» зберігаються у results/.
set -euo pipefail

PSQL="docker compose exec -T postgres psql -v ON_ERROR_STOP=1 -U postgres -d sportsclub"
run() { echo ">>> $1"; $PSQL -f "/lab05/$1"; }

mkdir -p results backups

run 00_seed_large_data.sql

echo ">>> EXPLAIN ДО індексів -> results/explain_before.txt"
$PSQL -f /lab05/01_explain_queries.sql | tee results/explain_before.txt

run 02_create_indexes.sql

echo ">>> EXPLAIN ПІСЛЯ індексів -> results/explain_after.txt"
$PSQL -f /lab05/01_explain_queries.sql | tee results/explain_after.txt

for f in 03_views 04_audit_log_and_trigger 05_users_privileges \
         06_rules_view 07_validation_triggers 08_audit_system 09_partial_indexes \
         11_materialized_view 12_cascade_triggers 13_roles_hierarchy 14_maintenance_procedure; do
  run "$f.sql"
done

echo "Готово. Далі: scripts/backup.sh, scripts/restore_test.sh, scripts/monitor.sh, 16_demo_checks.sql"
