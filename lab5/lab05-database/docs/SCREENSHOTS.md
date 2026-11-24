# Скріншоти для звіту (лабораторна №5)

Збережіть кожен скрін у `docs/screenshots/` **з точною назвою файлу** з таблиці — тоді вони автоматично з'являться у `docs/report.md`.
Усі команди запускати з кореня проєкту. Для читабельної кирилиці у терміналі краще Windows Terminal / PowerShell, або виконуйте SQL в pgAdmin (Query Tool).

Скорочення: `PSQL` = `docker compose exec -T postgres psql -U postgres -d sportsclub`

| № | Файл | Що виконати | Що має бути видно на скріні | Розділ звіту |
|---|---|---|---|---|
| 0 | `00_seed_counts.png` | `PSQL -f /lab05/00_seed_large_data.sql` | Підсумкова таблиця з кількістю рядків (100 010 / 60 / 150 010 / 20 010 / 500 010) | 1 |
| 1 | `01_explain_q1_before.png` | Спершу переконайтесь, що індексів лаби 5 ще немає. `PSQL -f /lab05/01_explain_queries.sql` | План **запиту 1**: Seq Scan і рядок **Execution Time** (виконайте двічі, знімайте другий результат) | 2.1 |
| 2 | `02_explain_q2_before.png` | той самий запуск | План **запиту 2** + Execution Time | 2.1 |
| 3 | `03_explain_q3_before.png` | той самий запуск | План **запиту 3** + Execution Time | 2.1 |
| 4 | `04_indexes_created.png` | `PSQL -f /lab05/02_create_indexes.sql` | Рядки `CREATE INDEX` та таблиця створених індексів із розмірами | 2.2 |
| 5 | `05_explain_q1_after.png` | `PSQL -f /lab05/01_explain_queries.sql` ще раз | План **запиту 1** після: Index/Bitmap Scan + Execution Time | 2.2 |
| 6 | `06_explain_q2_after.png` | той самий запуск | План **запиту 2** після | 2.2 |
| 7 | `07_explain_q3_after.png` | той самий запуск | План **запиту 3** після | 2.2 |
| 8 | `08_view_active_memberships.png` | `PSQL -f /lab05/03_views.sql` | `CREATE VIEW` + результат `SELECT * FROM v_active_memberships` | 2.3 |
| 9 | `09_view_trainer_workload.png` | той самий запуск | Результат `SELECT * FROM v_trainer_workload` | 2.3 |
| 10 | `10_trigger_log_test.png` | `PSQL -f /lab05/04_audit_log_and_trigger.sql` | Вивід тесту: у `audit_log` рядки INSERT та UPDATE (old_salary → new_salary, changed_by) | 2.4 |
| 11 | `11_report_viewer_check.png` | `PSQL -f /lab05/05_users_privileges.sql`, потім `PSQL -f /lab05/16_demo_checks.sql` — блок `[СКРІН 11]` | Дозволений SELECT і помилки `permission denied` для phone / trainers / users / INSERT | 2.5 |
| 12 | `12_rules_view.png` | `PSQL -f /lab05/06_rules_view.sql` | «До» / «Після оновлення через представлення» / «У базовій таблиці» — змінені email та phone | 3.1 |
| 13 | `13_validation_triggers.png` | `PSQL -f /lab05/07_validation_triggers.sql` | NOTICE «Відхилено тригером: …» для 4 тестів + успішний тест 5 | 3.2 |
| 14 | `14_audit_log_all_operations.png` | `PSQL -f /lab05/08_audit_system.sql` (або блок `[СКРІН 14]` у 16_demo_checks.sql) | `audit_log`: INSERT, UPDATE (old/new qty), DELETE; `changed_by`; список тригерів `trg_audit_*` | 3.3 |
| 15 | `15_partial_indexes.png` | `PSQL -f /lab05/09_partial_indexes.sql` | Таблиця розмірів (частковий менший за повний) + плани A, B з частковими індексами (можна 2 скріни, склейте) | 3.4 |
| 16 | `16_backup_files.png` | `bash scripts/backup.sh` (або `.\scripts\backup.ps1`) | Команда pg_dump та список файлів `.dump` і `.sql` з розмірами в `backups/` | 3.5 |
| 17 | `17_restore_verify.png` | `bash scripts/restore_test.sh` (або `.ps1`) | pg_restore у `test_restore` і **однакові** кількості записів для `sportsclub` та `test_restore` | 3.5 |
| 18 | `18_materialized_view_refresh.png` | `PSQL -f /lab05/11_materialized_view.sql` | Агрегати «до» і «після» продажу абонемента (змінились без ручного REFRESH) | 4.1 |
| 19 | `19_cascade_triggers.png` | `PSQL -f /lab05/12_cascade_triggers.sql` | visits_count 9→10, запис у `member_bonuses`, рядки аудиту; помилки: дубль, немає абонемента, видалення тренера | 4.2 |
| 20 | `20_roles_hierarchy_check.png` | `PSQL -f /lab05/13_roles_hierarchy.sql`, потім `PSQL -f /lab05/16_demo_checks.sql` — блок `[СКРІН 20]` | Три блоки club_user / club_moderator / club_admin: що дозволено, де `permission denied`; ієрархія ролей (можна 2-3 скріни, склейте) | 4.3 |
| 21 | `21_maintenance_procedure.png` | `PSQL -f /lab05/14_maintenance_procedure.sql` | `NOTICE: Обслуговування … завершено` і `maintenance_log` (ANALYZE, REINDEX по таблицях, REFRESH MV) | 4.4 |
| 22 | `22_monitoring_indexes.png` | `bash scripts/monitor.sh` (або `.ps1`) | Розділи 2 і 3 звіту: використання індексів та невикористовувані | 4.5 |
| 23 | `23_monitoring_slow_queries.png` | той самий запуск | Розділи 7-8: ТОП найповільніших запитів із `pg_stat_statements` | 4.5 |