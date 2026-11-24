-- =====================================================================
-- Lab 05 | Рівень 2: перевірка резервного копіювання / відновлення.
-- Виконується в обох базах (sportsclub і test_restore) — результати
-- мають збігатися. Самі pg_dump / pg_restore — у scripts/backup.* та
-- scripts/restore_test.* (див. README).
-- =====================================================================
SELECT current_database() AS database,
       (SELECT count(*) FROM members)            AS members,
       (SELECT count(*) FROM trainers)           AS trainers,
       (SELECT count(*) FROM member_memberships) AS member_memberships,
       (SELECT count(*) FROM training_sessions)  AS training_sessions,
       (SELECT count(*) FROM attendance)         AS attendance,
       (SELECT count(*) FROM audit_log)          AS audit_log;

\echo 'Об''єкти схеми (мають збігатися):'
SELECT
    (SELECT count(*) FROM pg_tables  WHERE schemaname = 'public') AS tables,
    (SELECT count(*) FROM pg_views   WHERE schemaname = 'public') AS views,
    (SELECT count(*) FROM pg_indexes WHERE schemaname = 'public') AS indexes,
    (SELECT count(*) FROM pg_trigger WHERE NOT tgisinternal)      AS triggers;
