# Лабораторна робота №5 — Керування БД, оптимізація продуктивності та автоматизація

**Студент:** Остаповець Данило Олександрович  
**Предметна область:** Система управління спортивним клубом (БД `sportsclub` з лаби 4)  
**Рівень:** 3  
**Звіт:** [`docs/report.md`](docs/report.md) 

## Швидкий старт

```bash
docker compose up -d                  # перезапустить контейнер з pg_stat_statements (дані в томі збережуться)
bash scripts/run_lab05.sh             # Windows: .\scripts\run_lab05.ps1
```

`run_lab05` послідовно: наповнює БД великим обсягом даних → знімає EXPLAIN **до** індексів (`results/explain_before.txt`) → створює індекси → знімає EXPLAIN **після** (`results/explain_after.txt`) → застосовує решту скриптів.

```bash
docker compose exec -T postgres psql -U postgres -d sportsclub -f /lab05/01_explain_queries.sql
```

Далі: `scripts/backup.*`, `scripts/restore_test.*`, `scripts/monitor.*`, `lab05/16_demo_checks.sql`.

> Якщо БД створюється з нуля (`docker compose down -v`), спершу автоматично виконаються `database/01…07`, після чого запустіть `run_lab05`.

## Файли

| Файл | Рівень | Що робить |
|---|---|---|
| `lab05/00_seed_large_data.sql` | 1 | Наповнення: 100 тис. учасників, 150 тис. абонементів, 500 тис. відвідувань |
| `lab05/01_explain_queries.sql` | 1 | 3 складні запити з `EXPLAIN (ANALYZE, BUFFERS)` |
| `lab05/02_create_indexes.sql` (+`02b_drop…`) | 1 | 4 індекси; скрипт скидання для повторного заміру |
| `lab05/03_views.sql` | 1 | 2 представлення |
| `lab05/04_audit_log_and_trigger.sql` | 1 | `audit_log` + тригер INSERT/UPDATE для `trainers` |
| `lab05/05_users_privileges.sql` | 1 | Користувач `report_viewer` з обмеженими правами (у т.ч. на рівні стовпців) |
| `lab05/06_rules_view.sql` | 2 | Складне представлення, що оновлюється через RULES |
| `lab05/07_validation_triggers.sql` | 2 | Тригери валідації з відхиленням некоректних даних |
| `lab05/08_audit_system.sql` | 2 | Універсальний аудит INSERT/UPDATE/DELETE у 7 таблицях |
| `lab05/09_partial_indexes.sql` | 2 | Часткові індекси + аналіз ефективності |
| `lab05/10_backup_restore_verify.sql`, `scripts/backup.*`, `scripts/restore_test.*` | 2 | `pg_dump` / `pg_restore` та звірка результату |
| `lab05/11_materialized_view.sql` | 3 | Матеріалізоване представлення + автооновлення тригером |
| `lab05/12_cascade_triggers.sql` | 3 | Ланцюжок каскадних тригерів (відвідування → лічильники → бонуси → аудит) |
| `lab05/13_roles_hierarchy.sql` | 3 | Ролі: адміністратор ⊃ модератор ⊃ користувач |
| `lab05/14_maintenance_procedure.sql` | 3 | Процедура `maintain_database()` (ANALYZE, REINDEX, REFRESH MV) |
| `lab05/15_monitoring.sql`, `scripts/monitor.*` | 3 | Моніторинг: індекси, невикористовувані індекси, повільні запити |
| `lab05/16_demo_checks.sql` | — | Перевірки прав/аудиту для скріншотів |
| `tools/build_report.py` | — | Перезбирає `docs/report.md` з `docs/report_template.md` та SQL-файлів |

## Зміни щодо лаби 4

- `docker-compose.yml`: `pg_stat_statements`, томи `lab05`, `backups`, `results`.
- Таблиця `members` отримала стовпці `visits_count`, `last_visit_date` (веб- та консольний застосунки не зачеплені — вони вибирають стовпці явно).
- Тригери валідації тепер відхиляють некоректні email/телефон/дату народження і в застосунках лаби 4.
