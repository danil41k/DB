# Запуск моніторингу продуктивності; звіт зберігається в results\.
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
New-Item -ItemType Directory -Force -Path results | Out-Null
docker compose exec -T postgres psql -U postgres -d sportsclub -f /lab05/15_monitoring.sql |
    Tee-Object -FilePath "results\monitor_$stamp.txt"
Write-Host "Звіт збережено: results\monitor_$stamp.txt"
