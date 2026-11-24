-- =====================================================================
-- Lab 05 | Рівень 3: скрипт моніторингу продуктивності.
-- Запуск:  scripts/monitor.sh  (або scripts/monitor.ps1)
-- Потребує pg_stat_statements (увімкнено в docker-compose.yml через
-- shared_preload_libraries).
-- =====================================================================
\pset pager off
\pset null '-'

CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

\echo
\echo '########  МОНІТОРИНГ ПРОДУКТИВНОСТІ  ########'
SELECT now() AS report_time, current_database() AS database,
       pg_size_pretty(pg_database_size(current_database())) AS db_size,
       current_setting('shared_preload_libraries') AS preload_libraries;

\echo
\echo '=== 1. Розміри таблиць (дані / індекси) ==='
SELECT
    relname                                              AS table_name,
    n_live_tup                                           AS live_rows,
    pg_size_pretty(pg_table_size(relid))                 AS table_size,
    pg_size_pretty(pg_indexes_size(relid))               AS indexes_size,
    pg_size_pretty(pg_total_relation_size(relid))        AS total_size
FROM pg_stat_user_tables
ORDER BY pg_total_relation_size(relid) DESC;

\echo
\echo '=== 2. Використання індексів (від найпопулярніших) ==='
SELECT
    s.relname                                            AS table_name,
    s.indexrelname                                       AS index_name,
    s.idx_scan                                           AS index_scans,
    s.idx_tup_read                                       AS tuples_read,
    s.idx_tup_fetch                                      AS tuples_fetched,
    pg_size_pretty(pg_relation_size(s.indexrelid))       AS index_size
FROM pg_stat_user_indexes s
ORDER BY s.idx_scan DESC, s.relname, s.indexrelname;

\echo
\echo '=== 3. Невикористовувані індекси (кандидати на видалення; PK/UNIQUE не враховано) ==='
SELECT
    s.relname                                            AS table_name,
    s.indexrelname                                       AS index_name,
    s.idx_scan                                           AS index_scans,
    pg_size_pretty(pg_relation_size(s.indexrelid))       AS index_size
FROM pg_stat_user_indexes s
JOIN pg_index i ON i.indexrelid = s.indexrelid
WHERE s.idx_scan = 0
  AND NOT i.indisunique
  AND NOT i.indisprimary
ORDER BY pg_relation_size(s.indexrelid) DESC;

\echo
\echo '=== 4. Таблиці, що читаються послідовно (seq scan) частіше, ніж по індексу ==='
SELECT
    relname                                              AS table_name,
    seq_scan,
    seq_tup_read,
    COALESCE(idx_scan, 0)                                AS idx_scan,
    n_live_tup                                           AS live_rows,
    round(100.0 * COALESCE(idx_scan, 0)
          / NULLIF(seq_scan + COALESCE(idx_scan, 0), 0), 1) AS idx_usage_pct
FROM pg_stat_user_tables
WHERE n_live_tup > 1000
ORDER BY seq_tup_read DESC;

\echo
\echo '=== 5. Мертві кортежі та автообслуговування ==='
SELECT
    relname                                              AS table_name,
    n_live_tup,
    n_dead_tup,
    round(100.0 * n_dead_tup / NULLIF(n_live_tup + n_dead_tup, 0), 2) AS dead_pct,
    last_autovacuum,
    last_autoanalyze
FROM pg_stat_user_tables
ORDER BY n_dead_tup DESC
LIMIT 10;

\echo
\echo '=== 6. Коефіцієнт попадання в кеш (бажано > 99%) ==='
SELECT
    datname,
    blks_hit,
    blks_read,
    round(100.0 * blks_hit / NULLIF(blks_hit + blks_read, 0), 2) AS cache_hit_pct
FROM pg_stat_database
WHERE datname = current_database();

\echo
\echo '=== 7. ТОП-10 найповільніших запитів (за середнім часом виконання) ==='
SELECT
    left(regexp_replace(query, '\s+', ' ', 'g'), 90)     AS query,
    calls,
    round(total_exec_time::numeric, 2)                   AS total_ms,
    round(mean_exec_time::numeric, 2)                    AS mean_ms,
    round(max_exec_time::numeric, 2)                     AS max_ms,
    rows
FROM pg_stat_statements
WHERE dbid = (SELECT oid FROM pg_database WHERE datname = current_database())
  AND query NOT ILIKE '%pg_stat_statements%'
ORDER BY mean_exec_time DESC
LIMIT 10;

\echo
\echo '=== 8. ТОП-10 запитів за сумарним часом (найбільше навантаження) ==='
SELECT
    left(regexp_replace(query, '\s+', ' ', 'g'), 90)     AS query,
    calls,
    round(total_exec_time::numeric, 2)                   AS total_ms,
    round(mean_exec_time::numeric, 2)                    AS mean_ms
FROM pg_stat_statements
WHERE dbid = (SELECT oid FROM pg_database WHERE datname = current_database())
  AND query NOT ILIKE '%pg_stat_statements%'
ORDER BY total_exec_time DESC
LIMIT 10;

\echo
\echo '=== 9. Активні сеанси та довгі запити (> 1 с) ==='
SELECT pid, usename, state,
       now() - query_start AS running_for,
       left(regexp_replace(query, '\s+', ' ', 'g'), 70) AS query
FROM pg_stat_activity
WHERE datname = current_database()
  AND pid <> pg_backend_pid()
  AND state <> 'idle'
  AND now() - query_start > INTERVAL '1 second'
ORDER BY running_for DESC;

\echo
\echo '########  КІНЕЦЬ ЗВІТУ  ########'
