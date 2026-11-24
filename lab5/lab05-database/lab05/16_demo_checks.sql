-- =====================================================================
-- Lab 05 | Демонстраційні перевірки для скріншотів (рівні 1-3).
-- Це лише перевірки: нічого не створює, ніякі дані не змінює
-- (усі тести у транзакціях з ROLLBACK або з очищенням).
-- Помилки доступу ТАК і мають бути — це доказ обмежень прав.
--
-- Запуск:
--   docker compose exec -T postgres psql -U postgres -d sportsclub -f /lab05/16_demo_checks.sql
-- Або виконуйте блоки по одному в pgAdmin (Query Tool).
-- =====================================================================
\set ON_ERROR_STOP off
\pset pager off

\echo
\echo '################ [СКРІН 11] report_viewer (Рівень 1) ################'
SET SESSION AUTHORIZATION report_viewer;
SELECT current_user AS i_am;
\echo '-- дозволено: безпечні стовпці members'
SELECT member_id, first_name, last_name, registration_date FROM members LIMIT 3;
\echo '-- дозволено: представлення'
SELECT * FROM v_trainer_workload ORDER BY total_visits DESC LIMIT 3;
\echo '-- ЗАБОРОНЕНО: телефон/email (стовпці без права SELECT)'
SELECT phone, email FROM members LIMIT 3;
\echo '-- ЗАБОРОНЕНО: таблиця trainers (є salary)'
SELECT * FROM trainers LIMIT 3;
\echo '-- ЗАБОРОНЕНО: таблиця users (паролі)'
SELECT * FROM users;
\echo '-- ЗАБОРОНЕНО: запис'
INSERT INTO equipment (equipment_name, quantity) VALUES ('Хакерська штанга', 1);
UPDATE members SET last_name = 'Hacked' WHERE member_id = 1;
DELETE FROM members WHERE member_id = 1;
RESET SESSION AUTHORIZATION;

\echo
\echo '################ [СКРІН 14] audit_log: INSERT / UPDATE / DELETE (Рівень 2) ################'
BEGIN;
INSERT INTO equipment (equipment_name, quantity, purchase_date, condition)
VALUES ('Аудит-гантеля', 5, CURRENT_DATE, 'New');
UPDATE equipment SET quantity = 8 WHERE equipment_name = 'Аудит-гантеля';
DELETE FROM equipment WHERE equipment_name = 'Аудит-гантеля';
SELECT log_id, table_name, operation, record_id,
       old_values ->> 'quantity' AS old_qty,
       new_values ->> 'quantity' AS new_qty,
       changed_by, changed_at
FROM audit_log WHERE table_name = 'equipment' ORDER BY log_id DESC LIMIT 3;
ROLLBACK;

\echo
\echo '################ [СКРІН 20] Ієрархія ролей (Рівень 3) ################'
\echo '=== club_user (звичайний користувач) ==='
SET SESSION AUTHORIZATION club_user;
SELECT current_user AS i_am;
SELECT member_id, first_name, last_name FROM members LIMIT 2;        -- OK
SELECT phone FROM members LIMIT 2;                                    -- ЗАБОРОНЕНО
SELECT * FROM attendance LIMIT 2;                                     -- ЗАБОРОНЕНО
INSERT INTO equipment (equipment_name, quantity) VALUES ('X', 1);     -- ЗАБОРОНЕНО
RESET SESSION AUTHORIZATION;

\echo '=== club_moderator (модератор) ==='
SET SESSION AUTHORIZATION club_moderator;
SELECT current_user AS i_am;
SELECT member_id, first_name, phone FROM members LIMIT 2;             -- OK (бачить телефон)
SELECT trainer_id, last_name, salary FROM trainers LIMIT 2;           -- ЗАБОРОНЕНО (salary)
SELECT * FROM audit_log LIMIT 1;                                      -- ЗАБОРОНЕНО
UPDATE members SET visits_count = 999 WHERE member_id = 1;            -- ЗАБОРОНЕНО (стовпець керує тригер)
INSERT INTO equipment (equipment_name, quantity, condition)
VALUES ('Модераторський килимок', 3, 'New');                          -- OK
DELETE FROM equipment WHERE equipment_name = 'Модераторський килимок'; -- ЗАБОРОНЕНО (DELETE лише для attendance)
RESET SESSION AUTHORIZATION;

\echo '=== club_admin (адміністратор) ==='
SET SESSION AUTHORIZATION club_admin;
SELECT current_user AS i_am;
SELECT trainer_id, last_name, salary FROM trainers LIMIT 2;           -- OK
SELECT log_id, table_name, operation, changed_by FROM audit_log ORDER BY log_id DESC LIMIT 3;  -- OK
DELETE FROM equipment WHERE equipment_name = 'Модераторський килимок'; -- OK (прибираємо тестовий запис)
RESET SESSION AUTHORIZATION;

\echo '=== club_moderator не може запустити обслуговування, club_admin — може ==='
SET SESSION AUTHORIZATION club_moderator;
CALL maintain_database();                                             -- ЗАБОРОНЕНО
RESET SESSION AUTHORIZATION;

\echo
\echo '################ Підсумок прав за ролями ################'
SELECT grantee, table_name, string_agg(privilege_type, ', ' ORDER BY privilege_type) AS privileges
FROM information_schema.role_table_grants
WHERE grantee IN ('club_user_role', 'club_moderator_role', 'club_admin_role')
  AND table_name IN ('members', 'trainers', 'attendance', 'audit_log', 'users')
GROUP BY grantee, table_name
ORDER BY grantee, table_name;
