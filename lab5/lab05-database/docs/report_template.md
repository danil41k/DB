# Звіт з лабораторної роботи №5

## Керування БД, оптимізація продуктивності та автоматизація

**ПІБ студента:** Остаповець Данило Олександрович

**Предметна область:** Система управління спортивним клубом

**Рівень виконання:** Рівень 3

---

# Мета роботи

Навчитися аналізувати та оптимізувати продуктивність бази даних за допомогою індексів та планів виконання запитів, автоматизувати роботу БД за допомогою тригерів і представлень, освоїти базові операції адміністрування PostgreSQL: керування правами доступу, резервне копіювання та моніторинг.

---

# 1. Середовище та підготовка даних

Використано PostgreSQL 17 у Docker (`postgres:17-alpine`) та pgAdmin. Робота виконана на базі даних `sportsclub` з лабораторної №4. До `docker-compose.yml` додано:

- `shared_preload_libraries=pg_stat_statements` — для моніторингу найповільніших запитів;
- томи `./lab05` (SQL-скрипти), `./backups` (резервні копії), `./results` (результати EXPLAIN і моніторингу).

```bash
docker compose up -d
docker compose exec postgres psql -U postgres -d sportsclub
```

На початкових 10 рядках у таблицях оптимізатор завжди обирає Sequential Scan, тому дані було збільшено скриптом `lab05/00_seed_large_data.sql` (`generate_series` + `random()`). Для швидкості на час наповнення вимкнено користувацькі тригери (`session_replication_role = replica`).

| Таблиця | Було | Стало |
|---|---|---|
| members | 10 | 100 010 |
| trainers | 10 | 60 |
| member_memberships | 10 | 150 010 |
| training_sessions | 10 | 20 010 |
| attendance | 10 | 500 010 |

![Скрін 0 — кількість записів після наповнення](screenshots/00_seed_counts.png)

---

# 2. Рівень 1

## 2.1 Аналіз продуктивності трьох запитів (до оптимізації)

Для аналізу використано `EXPLAIN (ANALYZE, BUFFERS)`. Запити — у файлі `lab05/01_explain_queries.sql`:

{{sql:01_explain_queries.sql}}

- **Запит 1** — активність нових учасників: 3 таблиці, `WHERE` за датою реєстрації, `GROUP BY`, `HAVING`, `ORDER BY`, `LIMIT`.
- **Запит 2** — навантаження тренерів за жовтень: фільтр за діапазоном дат, `LEFT JOIN` до 500 тис. відвідувань, `COUNT(DISTINCT)`.
- **Запит 3** — абонементи, що закінчуються в перший тиждень грудня: фільтр за діапазоном `end_date`, сортування.

![Скрін 1 — EXPLAIN ANALYZE запиту 1 до індексів](screenshots/01_explain_q1_before.png)

![Скрін 2 — EXPLAIN ANALYZE запиту 2 до індексів](screenshots/02_explain_q2_before.png)

![Скрін 3 — EXPLAIN ANALYZE запиту 3 до індексів](screenshots/03_explain_q3_before.png)

Спостереження до оптимізації (заповніть за своїми планами):

| Запит | Тип сканування великих таблиць | Rows у вузлі сканування | Shared buffers read/hit | Execution Time, мс |
|---|---|---|---|---|
| 1 | ___ (очікувано Seq Scan по `members` та `member_memberships`) | ___ | ___ | ___ |
| 2 | ___ (очікувано Seq Scan по `training_sessions`) | ___ | ___ | ___ |
| 3 | ___ (очікувано Seq Scan по `member_memberships`) | ___ | ___ | ___ |

## 2.2 Індекси та перевірка покращення

На основі планів визначено стовпці, що використовуються у `WHERE`, `JOIN` та `ORDER BY`. Зовнішній ключ `member_memberships.member_id` не мав індексу (PostgreSQL не створює його автоматично).

{{sql:02_create_indexes.sql}}

| Індекс | Таблиця / стовпець | Обґрунтування | Запит |
|---|---|---|---|
| `idx_members_registration_date` | `members(registration_date)` | фільтр `registration_date >= …` | 1 |
| `idx_member_memberships_member_id` | `member_memberships(member_id)` | JOIN за зовнішнім ключем | 1, 3 |
| `idx_training_sessions_session_date` | `training_sessions(session_date)` | діапазонний фільтр за датою | 2 |
| `idx_member_memberships_end_date` | `member_memberships(end_date)` | діапазонний фільтр + сортування | 3 |

![Скрін 4 — створення індексів та їх розмір](screenshots/04_indexes_created.png)

Повторний `EXPLAIN (ANALYZE, BUFFERS)` тих самих запитів після створення індексів та `ANALYZE`:

![Скрін 5 — запит 1 після індексів](screenshots/05_explain_q1_after.png)

![Скрін 6 — запит 2 після індексів](screenshots/06_explain_q2_after.png)

![Скрін 7 — запит 3 після індексів](screenshots/07_explain_q3_after.png)

Порівняння (відсоток покращення = (до − після) / до × 100 %):

| Запит | До, мс | Після, мс | Покращення, % | Тип сканування після |
|---|---|---|---|---|
| 1 | ___ | ___ | ___ | ___ (Index / Bitmap Scan) |
| 2 | ___ | ___ | ___ | ___ |
| 3 | ___ | ___ | ___ | ___ |

## 2.3 Представлення

Створено два представлення (`lab05/03_views.sql`). Перше — просте з `JOIN` (учасники з діючим абонементом), друге — складне з агрегацією (навантаження тренерів).

{{sql:03_views.sql}}

![Скрін 8 — v_active_memberships](screenshots/08_view_active_memberships.png)

![Скрін 9 — v_trainer_workload](screenshots/09_view_trainer_workload.png)

## 2.4 Тригер логування

Створено таблицю `audit_log` та тригер `trg_trainers_log_iu`, який логує `INSERT` і `UPDATE` у таблиці `trainers` (старі та нові значення зберігаються у форматі JSONB). Тест виконано у транзакції з відкатом.

{{sql:04_audit_log_and_trigger.sql}}

![Скрін 10 — результат роботи тригера (запис у audit_log)](screenshots/10_trigger_log_test.png)

## 2.5 Користувач з обмеженими правами

Створено `report_viewer`. Він може лише читати: безпечні стовпці `members` (без `phone` та `email`), таблиці `memberships`, `training_sessions` і два представлення. Таблиці `trainers` (зарплата), `users` (паролі) та `audit_log` недоступні, будь-який запис заборонено.

{{sql:05_users_privileges.sql}}

Перевірка підключенням від імені `report_viewer` (читання дозволено, заборонені стовпці/таблиці та запис дають `permission denied`):

![Скрін 11 — перевірка прав report_viewer](screenshots/11_report_viewer_check.png)

---

# 3. Рівень 2

## 3.1 Представлення, що оновлюється через правила (RULES)

`v_member_profile` об'єднує `members` з останнім абонементом (`LEFT JOIN LATERAL`), тому PostgreSQL не оновлює його автоматично. Поведінку `UPDATE` та `DELETE` задано правилами `DO INSTEAD`: оновлюються лише контактні дані в `members`, похідні стовпці ігноруються.

{{sql:06_rules_view.sql}}

![Скрін 12 — UPDATE через представлення з правилом](screenshots/12_rules_view.png)

> Система правил застаріла: документація PostgreSQL рекомендує для нових проєктів тригери `INSTEAD OF`. Правила використано для демонстрації механізму.

## 3.2 Тригери валідації

`BEFORE INSERT OR UPDATE`-тригери відхиляють некоректні дані через `RAISE EXCEPTION` з кодом `check_violation` (SQLSTATE 23514) та підказкою `HINT`: формат email і телефону, дата народження, час початку/завершення тренування, дати абонемента. У тестах помилка перехоплюється блоком `EXCEPTION`.

{{sql:07_validation_triggers.sql}}

![Скрін 13 — відхилення некоректних значень](screenshots/13_validation_triggers.png)

## 3.3 Система аудиту

Універсальна функція `audit_row_changes()` підключена до семи таблиць. Вона фіксує тип операції, назву таблиці, `record_id`, старі й нові значення, користувача (`session_user`) та час. Простий тригер рівня 1 видалено, щоб операції не дублювались.

{{sql:08_audit_system.sql}}

![Скрін 14 — audit_log: INSERT, UPDATE, DELETE](screenshots/14_audit_log_all_operations.png)

## 3.4 Часткові індекси

{{sql:09_partial_indexes.sql}}

Аналіз ефективності (заповніть за своїми результатами):

| Індекс | Предикат | Розмір | Повний аналог | Розмір повного |
|---|---|---|---|---|
| `idx_mm_end_date_current` | `end_date >= '2026-12-01'` | ___ | `idx_member_memberships_end_date` | ___ |
| `idx_sessions_big_groups` | `max_participants >= 35` | ___ | `idx_training_sessions_session_date` | ___ |

Запити A і B використовують часткові індекси (менший розмір → менше сторінок у `Buffers`), запит C із умовою поза предикатом використовує повний індекс.

![Скрін 15 — часткові індекси: розміри та плани](screenshots/15_partial_indexes.png)

## 3.5 Резервне копіювання та відновлення

Резервна копія створюється `pg_dump` у двох форматах: custom (`-F c`, стиснення, вибіркове відновлення) та plain SQL. Відновлення перевірено в окремій базі `test_restore`, після чого кількість записів і об'єктів порівнювалась з оригіналом (`lab05/10_backup_restore_verify.sql`).

```bash
# резервна копія (scripts/backup.sh | backup.ps1)
docker compose exec -T postgres pg_dump -U postgres -d sportsclub -F c -Z 6 -f /backups/sportsclub_<дата>.dump
docker compose exec -T postgres pg_dump -U postgres -d sportsclub -f /backups/sportsclub_<дата>.sql

# відновлення (scripts/restore_test.sh | restore_test.ps1)
docker compose exec -T postgres psql -U postgres -c "CREATE DATABASE test_restore;"
docker compose exec -T postgres pg_restore -U postgres -d test_restore --no-owner /backups/sportsclub_<дата>.dump
```

![Скрін 16 — створені файли резервних копій](screenshots/16_backup_files.png)

![Скрін 17 — порівняння sportsclub та test_restore після відновлення](screenshots/17_restore_verify.png)

---

# 4. Рівень 3

## 4.1 Матеріалізоване представлення з автоматичним оновленням

`mv_monthly_membership_sales` зберігає агреговані місячні продажі абонементів (кількість, виручка, середня ціна). Унікальний індекс дозволяє `REFRESH … CONCURRENTLY`. Тригер `FOR EACH STATEMENT` на `member_memberships` оновлює представлення після кожної зміни. Функція тригера — `SECURITY DEFINER`, бо оновити представлення може лише його власник.

{{sql:11_materialized_view.sql}}

![Скрін 18 — автоматичне оновлення матеріалізованого представлення](screenshots/18_materialized_view_refresh.png)

> Оновлення після кожного оператора — навчальний підхід. На великих навантаженнях його замінюють оновленням за розкладом (`pg_cron`) або інкрементальною таблицею-підсумком.

## 4.2 Каскадні тригери

Реалізовано ланцюжок: реєстрація відвідування перевіряється (діючий абонемент, вільні місця, дублікат) → оновлює лічильники учасника → це оновлення запускає валідацію, аудит і нарахування бонусу лояльності кожні 10 відвідувань → бонус теж потрапляє в аудит. Видалення тренування каскадно видаляє відвідування й зменшує лічильники. Тренера з майбутніми тренуваннями видалити не можна.

{{sql:12_cascade_triggers.sql}}

![Скрін 19 — каскад тригерів (лічильник, бонус, аудит, відхилені операції)](screenshots/19_cascade_triggers.png)

## 4.3 Ієрархія ролей

```
club_admin_role  ──наслідує──▶  club_moderator_role  ──наслідує──▶  club_user_role
   (адміністратор)                   (модератор)                      (користувач)
```

| Можливість | club_user | club_moderator | club_admin |
|---|---|---|---|
| Читання безпечних стовпців members, trainers (без phone/salary), memberships, training_sessions, equipment | ✅ | ✅ | ✅ |
| Читання v_active_memberships, v_trainer_workload | ✅ | ✅ | ✅ |
| Читання phone/email учасників, attendance, member_memberships, bonuses | ❌ | ✅ | ✅ |
| Читання v_member_profile, mv_monthly_membership_sales | ❌ | ✅ | ✅ |
| Читання trainers.salary, users, audit_log, maintenance_log | ❌ | ❌ | ✅ |
| INSERT/UPDATE: members (контактні стовпці), member_memberships, training_sessions, attendance, equipment | ❌ | ✅ | ✅ |
| UPDATE members.visits_count / last_visit_date вручну | ❌ | ❌ (лише тригери) | ✅ |
| DELETE: attendance | ❌ | ✅ | ✅ |
| DELETE: решта таблиць | ❌ | ❌ | ✅ |
| CALL maintain_database(), pg_monitor | ❌ | ❌ | ✅ |

Логіни: `club_user`, `club_moderator`, `club_admin` (паролі задаються у `13_roles_hierarchy.sql` — змініть на власні).

{{sql:13_roles_hierarchy.sql}}

![Скрін 20 — перевірка прав трьох ролей](screenshots/20_roles_hierarchy_check.png)

## 4.4 Процедура автоматизованого обслуговування

`maintain_database()` оновлює статистику (`ANALYZE`), перебудовує індекси кожної таблиці (`REINDEX TABLE`) та оновлює матеріалізоване представлення; кожен крок і його тривалість пишуться в `maintenance_log`. `VACUUM` і `REINDEX CONCURRENTLY` у процедурі виконувати не можна (вони не працюють у блоці транзакції) — для них використовується `vacuumdb` за розкладом. Виклик дозволено лише адміністратору.

{{sql:14_maintenance_procedure.sql}}

![Скрін 21 — CALL maintain_database() та maintenance_log](screenshots/21_maintenance_procedure.png)

## 4.5 Моніторинг продуктивності

Скрипт `lab05/15_monitoring.sql` (запуск — `scripts/monitor.sh` або `monitor.ps1`, звіт зберігається у `results/`) виводить: розміри таблиць та індексів, статистику використання індексів, невикористовувані індекси, співвідношення seq/idx сканувань, мертві кортежі, hit-ratio кешу, ТОП-10 найповільніших запитів та ТОП-10 за сумарним часом (`pg_stat_statements`), довгі активні запити.

![Скрін 22 — використання індексів та невикористовувані індекси](screenshots/22_monitoring_indexes.png)

![Скрін 23 — найповільніші запити (pg_stat_statements)](screenshots/23_monitoring_slow_queries.png)

Висновки з моніторингу (заповніть за своїм звітом): найчастіше використовується індекс `___`; невикористовувані індекси: `___`; найповільніший запит: `___` (середній час ___ мс).

---

# 5. Висновки та рекомендації

У лабораторній роботі виконано всі завдання рівнів 1–3.

1. **Продуктивність.** На обсязі ~500 тис. рядків індекси на стовпцях фільтрації та зовнішніх ключах прискорили запити 1, 2 і 3 на ___ %, ___ % та ___ % відповідно: Sequential Scan замінилися на Index/Bitmap Scan, значно зменшилась кількість прочитаних буферів. Особливо важливим виявився індекс на зовнішній ключ `member_memberships.member_id`, який PostgreSQL не створює автоматично.
2. **Часткові індекси** (`WHERE end_date >= …`, `WHERE max_participants >= 35`) значно менші за повні (___ проти ___) і використовуються для запитів, умова яких вкладається в предикат; їх доцільно застосовувати для «гарячих» підмножин даних.
3. **Автоматизація.** Тригери валідації не допускають некоректних даних у БД незалежно від застосунку; універсальний аудит фіксує всі зміни з користувачем та старими/новими значеннями; каскадні тригери підтримують узгодженість лічильників і бонусів без коду в застосунку; матеріалізоване представлення віддає агрегати миттєво.
4. **Безпека.** Принцип мінімальних привілеїв: права на рівні стовпців (без `phone`, `salary`), доступ до даних через представлення, ієрархія ролей, `SECURITY DEFINER`-функції для тригерів, щоб користувачам не потрібен був прямий доступ до журналів.
5. **Адміністрування.** `pg_dump` + `pg_restore` перевірено відновленням у тестову БД зі звіркою кількості записів; процедура обслуговування й скрипт моніторингу автоматизують рутину.

**Рекомендації:**

- Не створювати індекси «про запас»: кожен уповільнює `INSERT/UPDATE/DELETE`; раз на певний час перевіряти невикористовувані індекси (розділ 4.5).
- Оновлення матеріалізованого представлення після кожного оператора замінити на розклад (`pg_cron`) або інкрементальну таблицю-підсумок при зростанні навантаження.
- Для таблиці `audit_log` налаштувати партиціювання/архівацію, бо вона зростатиме швидше за інші.
- Резервні копії виконувати за розкладом і зберігати поза сервером; для відновлення на довільний момент часу налаштувати `pg_basebackup` та архівацію WAL (PITR).
- У лабораторних скриптах використано навчальні паролі; у реальній системі — власні, зберігати поза репозиторієм.
- Замість застарілих правил (RULES) у нових проєктах використовувати тригери `INSTEAD OF`.

---

# Додаток: структура та відтворення

```
lab05-database/
├── docker-compose.yml          # + pg_stat_statements, томи lab05 / backups / results
├── database/                   # скрипти лаби 4 (ініціалізація БД)
├── lab05/                      # SQL-скрипти лаби 5 (00 … 16)
├── scripts/                    # backup / restore_test / monitor / run_lab05 (.sh та .ps1)
├── docs/                       # report.md, SCREENSHOTS.md, screenshots/
├── console_app/, web_app/      # застосунки з лаби 4
└── tools/build_report.py       # збирає report.md із шаблону та SQL-файлів
```

```bash
docker compose up -d
bash scripts/run_lab05.sh          # або .\scripts\run_lab05.ps1
bash scripts/backup.sh && bash scripts/restore_test.sh
bash scripts/monitor.sh
```
