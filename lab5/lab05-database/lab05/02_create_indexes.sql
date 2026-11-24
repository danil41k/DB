-- =====================================================================
-- Lab 05 | Крок 3: індекси для оптимізації найповільніших запитів
-- (потрібні мінімум 3; тут 4 — по одному-два на кожен запит)
-- =====================================================================

-- Запит 1: фільтр WHERE m.registration_date >= ...
CREATE INDEX IF NOT EXISTS idx_members_registration_date
    ON members (registration_date);

-- Запит 1 і 3: JOIN member_memberships -> members.
-- PostgreSQL НЕ створює індекс на зовнішній ключ автоматично.
CREATE INDEX IF NOT EXISTS idx_member_memberships_member_id
    ON member_memberships (member_id);

-- Запит 2: фільтр за діапазоном дат тренувань
CREATE INDEX IF NOT EXISTS idx_training_sessions_session_date
    ON training_sessions (session_date);

-- Запит 3: фільтр за діапазоном end_date + сортування
CREATE INDEX IF NOT EXISTS idx_member_memberships_end_date
    ON member_memberships (end_date);

-- Оновлюємо статистику, щоб оптимізатор врахував нові індекси
ANALYZE members;
ANALYZE member_memberships;
ANALYZE training_sessions;

\echo
\echo 'Створені індекси та їх розмір:'
SELECT
    indexrelname                                   AS index_name,
    relname                                        AS table_name,
    pg_size_pretty(pg_relation_size(indexrelid))   AS index_size
FROM pg_stat_user_indexes
WHERE indexrelname IN (
    'idx_members_registration_date',
    'idx_member_memberships_member_id',
    'idx_training_sessions_session_date',
    'idx_member_memberships_end_date')
ORDER BY indexrelname;
