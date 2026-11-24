-- =====================================================================
-- Lab 05 | Рівень 2: часткові індекси + аналіз їх ефективності
-- Предикат WHERE часткового індексу має складатися лише з IMMUTABLE
-- виразів, тому використовуємо константні межі (не CURRENT_DATE / NOW()).
-- =====================================================================

-- 1) Абонементи, що діють/закінчуються з грудня 2026 (актуальні записи)
CREATE INDEX IF NOT EXISTS idx_mm_end_date_current
    ON member_memberships (end_date)
    WHERE end_date >= '2026-12-01';

-- 2) Великі групи (>= 35 учасників): рідкісна підмножина тренувань
CREATE INDEX IF NOT EXISTS idx_sessions_big_groups
    ON training_sessions (session_date)
    WHERE max_participants >= 35;

ANALYZE member_memberships;
ANALYZE training_sessions;

\echo
\echo '=== Порівняння розміру повних та часткових індексів ==='
SELECT
    c.relname                                  AS index_name,
    pg_size_pretty(pg_relation_size(c.oid))    AS size,
    pg_relation_size(c.oid)                    AS size_bytes,
    pg_get_expr(i.indpred, i.indrelid)         AS partial_predicate
FROM pg_class c
JOIN pg_index i ON i.indexrelid = c.oid
WHERE c.relname IN ('idx_member_memberships_end_date', 'idx_mm_end_date_current',
                    'idx_training_sessions_session_date', 'idx_sessions_big_groups')
ORDER BY c.relname;

\echo
\echo '=== Запит A: має використати часткові індекси (умова вкладається у предикат) ==='
EXPLAIN (ANALYZE, BUFFERS)
SELECT member_membership_id, member_id, end_date
FROM member_memberships
WHERE end_date >= '2026-12-01' AND end_date < '2026-12-04';

\echo
\echo '=== Запит B: великі групи ==='
EXPLAIN (ANALYZE, BUFFERS)
SELECT session_id, session_name, session_date, max_participants
FROM training_sessions
WHERE max_participants >= 35
  AND session_date BETWEEN '2026-10-01' AND '2026-12-31'
ORDER BY session_date;

\echo
\echo '=== Запит C (контроль): умова ПОЗА предикатом часткового індексу ==='
\echo '    часткові індекси тут не застосовуються — використовується повний індекс'
EXPLAIN (ANALYZE, BUFFERS)
SELECT member_membership_id, member_id, end_date
FROM member_memberships
WHERE end_date >= '2026-06-01' AND end_date < '2026-06-04';
