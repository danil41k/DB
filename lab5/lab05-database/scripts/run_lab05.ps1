# Послідовно застосовує всі скрипти лабораторної №5 (PowerShell).
# Запускати з кореня проєкту:  .\scripts\run_lab05.ps1
# Результати EXPLAIN «до/після» зберігаються у results\.
$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
New-Item -ItemType Directory -Force -Path results, backups | Out-Null

function Run-Sql($file) {
    Write-Host ">>> $file"
    docker compose exec -T postgres psql -v ON_ERROR_STOP=1 -U postgres -d sportsclub -f "/lab05/$file"
    if ($LASTEXITCODE -ne 0) { throw "Помилка у $file" }
}

Run-Sql "00_seed_large_data.sql"

Write-Host ">>> EXPLAIN ДО індексів -> results\explain_before.txt"
docker compose exec -T postgres psql -U postgres -d sportsclub -f /lab05/01_explain_queries.sql |
    Tee-Object -FilePath results\explain_before.txt

Run-Sql "02_create_indexes.sql"

Write-Host ">>> EXPLAIN ПІСЛЯ індексів -> results\explain_after.txt"
docker compose exec -T postgres psql -U postgres -d sportsclub -f /lab05/01_explain_queries.sql |
    Tee-Object -FilePath results\explain_after.txt

foreach ($f in "03_views","04_audit_log_and_trigger","05_users_privileges",
               "06_rules_view","07_validation_triggers","08_audit_system","09_partial_indexes",
               "11_materialized_view","12_cascade_triggers","13_roles_hierarchy","14_maintenance_procedure") {
    Run-Sql "$f.sql"
}
Write-Host "Готово. Далі: scripts\backup.ps1, scripts\restore_test.ps1, scripts\monitor.ps1, 16_demo_checks.sql"
