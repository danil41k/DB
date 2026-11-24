-- =====================================================================
-- Lab 05 | Крок 6 (Рівень 1): користувач з обмеженими правами
-- report_viewer може лише ЧИТАТИ частину даних:
--   * з members — тільки 4 «безпечні» стовпці (без phone / email);
--   * з trainers — доступу немає (там salary);
--   * таблиця users (паролі) і audit_log недоступні;
--   * два представлення — повний доступ на читання.
-- Пароль змініть на власний!
-- =====================================================================

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'report_viewer') THEN
        CREATE ROLE report_viewer LOGIN PASSWORD 'Rv_2026_Sp0rt!';
    END IF;
END
$$;

GRANT CONNECT ON DATABASE sportsclub TO report_viewer;
GRANT USAGE   ON SCHEMA public       TO report_viewer;

-- Права на стовпці (column-level privileges)
GRANT SELECT (member_id, first_name, last_name, registration_date) ON members TO report_viewer;
GRANT SELECT ON memberships, training_sessions TO report_viewer;

-- Представлення виконуються з правами власника, тому report_viewer бачить
-- через них дані, до базових таблиць яких прямого доступу не має.
GRANT SELECT ON v_active_memberships, v_trainer_workload TO report_viewer;

-- Перевірка виданих прав
\echo
\echo 'Права report_viewer на рівні таблиць:'
SELECT table_name, privilege_type
FROM information_schema.role_table_grants
WHERE grantee = 'report_viewer'
ORDER BY table_name, privilege_type;

\echo 'Права report_viewer на рівні стовпців:'
SELECT table_name, column_name, privilege_type
FROM information_schema.role_column_grants
WHERE grantee = 'report_viewer' AND table_schema = 'public'
ORDER BY table_name, column_name;
