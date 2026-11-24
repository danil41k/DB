-- Необов'язковий скрипт: видалення індексів лаби 5, щоб можна було
-- повторно зняти замір «ДО» (наприклад, якщо забули скрін).
-- Після цього знову виконайте 01_explain_queries.sql.
DROP INDEX IF EXISTS idx_members_registration_date;
DROP INDEX IF EXISTS idx_member_memberships_member_id;
DROP INDEX IF EXISTS idx_training_sessions_session_date;
DROP INDEX IF EXISTS idx_member_memberships_end_date;
ANALYZE;
