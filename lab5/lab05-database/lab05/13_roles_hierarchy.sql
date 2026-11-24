-- =====================================================================
-- Lab 05 | Рівень 3: ієрархія ролей та прав доступу
--
--   club_admin_role      (адміністратор)  наслідує  club_moderator_role
--   club_moderator_role  (модератор)      наслідує  club_user_role
--   club_user_role       (звичайний користувач, лише читання публічних даних)
--
-- Логіни:  club_user -> club_user_role
--          club_moderator -> club_moderator_role
--          club_admin -> club_admin_role
-- =====================================================================

-- ---------- ролі-групи (NOLOGIN) ----------
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'club_user_role') THEN
        CREATE ROLE club_user_role NOLOGIN;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'club_moderator_role') THEN
        CREATE ROLE club_moderator_role NOLOGIN;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'club_admin_role') THEN
        CREATE ROLE club_admin_role NOLOGIN;
    END IF;
END
$$;

-- Ієрархія: адміністратор ⊃ модератор ⊃ користувач
GRANT club_user_role      TO club_moderator_role;
GRANT club_moderator_role TO club_admin_role;

-- ---------- 1. club_user_role: лише безпечне читання ----------
GRANT CONNECT ON DATABASE sportsclub TO club_user_role;
GRANT USAGE   ON SCHEMA public       TO club_user_role;

GRANT SELECT (member_id, first_name, last_name, registration_date) ON members  TO club_user_role;
GRANT SELECT (trainer_id, first_name, last_name, specialization)  ON trainers TO club_user_role;
GRANT SELECT ON memberships, training_sessions, equipment         TO club_user_role;
GRANT SELECT ON v_active_memberships, v_trainer_workload          TO club_user_role;

-- ---------- 2. club_moderator_role: щоденна робота персоналу ----------
GRANT SELECT ON members, memberships, member_memberships, training_sessions,
                attendance, equipment, member_bonuses, member_audit  TO club_moderator_role;
-- зарплату тренерів модератор не бачить
GRANT SELECT (trainer_id, first_name, last_name, specialization, phone) ON trainers TO club_moderator_role;
GRANT SELECT ON v_member_profile, mv_monthly_membership_sales          TO club_moderator_role;

-- INSERT / UPDATE лише потрібних стовпців members
-- (visits_count та last_visit_date змінюють тільки тригери)
GRANT INSERT (first_name, last_name, birth_date, phone, email, registration_date) ON members TO club_moderator_role;
GRANT UPDATE (first_name, last_name, birth_date, phone, email)                    ON members TO club_moderator_role;

GRANT INSERT, UPDATE ON member_memberships, training_sessions, attendance, equipment TO club_moderator_role;
GRANT DELETE         ON attendance                                                   TO club_moderator_role;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public                                        TO club_moderator_role;

-- ---------- 3. club_admin_role: повний доступ ----------
GRANT ALL PRIVILEGES ON ALL TABLES    IN SCHEMA public TO club_admin_role;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO club_admin_role;
GRANT ALL PRIVILEGES ON ALL ROUTINES  IN SCHEMA public TO club_admin_role;
-- вбудована роль: читання статистики сервера (pg_stat_statements тощо)
GRANT pg_monitor TO club_admin_role;

-- Права на ПОДАЛЬШІ таблиці/послідовності, створені власником (postgres)
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES    TO club_admin_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO club_admin_role;

-- ---------- Тригерні функції лаби 4: щоб модератор міг писати в журнали ----------
-- Функції аудиту з лаби 4 пишуть у member_audit / activity_log. Робимо їх
-- SECURITY DEFINER, щоб користувачам не потрібен був прямий доступ до цих таблиць.
ALTER FUNCTION log_member_insert()    SECURITY DEFINER SET search_path = public, pg_temp;
ALTER FUNCTION audit_member_insert()  SECURITY DEFINER SET search_path = public, pg_temp;
ALTER FUNCTION audit_member_delete()  SECURITY DEFINER SET search_path = public, pg_temp;

-- ---------- логіни ----------
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'club_user') THEN
        CREATE ROLE club_user LOGIN PASSWORD 'User_2026_Club!';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'club_moderator') THEN
        CREATE ROLE club_moderator LOGIN PASSWORD 'Mod_2026_Club!';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'club_admin') THEN
        CREATE ROLE club_admin LOGIN PASSWORD 'Adm_2026_Club!';
    END IF;
END
$$;

GRANT club_user_role      TO club_user;
GRANT club_moderator_role TO club_moderator;
GRANT club_admin_role     TO club_admin;

\echo
\echo 'Ієрархія ролей (хто в яку роль входить):'
SELECT r.rolname AS member, g.rolname AS member_of
FROM pg_auth_members am
JOIN pg_roles r ON r.oid = am.member
JOIN pg_roles g ON g.oid = am.roleid
WHERE r.rolname LIKE 'club_%' AND g.rolname LIKE 'club_%'
ORDER BY g.rolname, r.rolname;
