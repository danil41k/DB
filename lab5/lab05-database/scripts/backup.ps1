# Резервне копіювання БД sportsclub (pg_dump): custom-формат + SQL-формат.
# Файли з'являються в .\backups (змонтовано в контейнер як /backups).
$ErrorActionPreference = "Stop"
$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
New-Item -ItemType Directory -Force -Path backups | Out-Null

docker compose exec -T postgres pg_dump -U postgres -d sportsclub -F c -Z 6 -f "/backups/sportsclub_$stamp.dump"
docker compose exec -T postgres pg_dump -U postgres -d sportsclub -f "/backups/sportsclub_$stamp.sql"

Write-Host "Створено:"
Get-ChildItem backups\sportsclub_$stamp.* | Format-Table Name, @{n="Size, KB";e={[math]::Round($_.Length/1KB,1)}}
