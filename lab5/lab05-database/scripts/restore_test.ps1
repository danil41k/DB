# Відновлення останньої (або вказаної) копії в test_restore + порівняння з оригіналом.
#   .\scripts\restore_test.ps1 [-Dump backups\sportsclub_YYYYMMDD_HHMMSS.dump]
param([string]$Dump)
$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
if (-not $Dump) { $Dump = (Get-ChildItem backups\*.dump | Sort-Object LastWriteTime -Descending | Select-Object -First 1).FullName }
$name = Split-Path $Dump -Leaf

Write-Host ">>> Відновлення $name у test_restore"
docker compose exec -T postgres psql -U postgres -c "DROP DATABASE IF EXISTS test_restore;"
docker compose exec -T postgres psql -U postgres -c "CREATE DATABASE test_restore;"
docker compose exec -T postgres pg_restore -U postgres -d test_restore --no-owner "/backups/$name"

foreach ($db in "sportsclub", "test_restore") {
    Write-Host "`n===== $db ====="
    docker compose exec -T postgres psql -U postgres -d $db -f /lab05/10_backup_restore_verify.sql
}
