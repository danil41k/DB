-- =====================================================================
-- Lab 05 | Крок 2: аналіз продуктивності трьох складних запитів
-- Запускається ДВІЧІ: до створення індексів (02_create_indexes.sql)
-- і після. Кожен запит краще виконати двічі підряд і брати другий
-- результат (щоб прибрати вплив «холодного» кешу).
--
-- Висновки, які шукаємо в плані: тип сканування (Seq Scan / Index Scan /
-- Bitmap Heap Scan), actual time, rows, Buffers, Execution Time.
-- =====================================================================

\echo
\echo '=== Запит 1: активність нових учасників (JOIN + GROUP BY + HAVING + ORDER BY) ==='
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    m.member_id,
    m.first_name,
    m.last_name,
    COUNT(mm.member_membership_id) AS memberships_bought,
    SUM(ms.price)                  AS total_spent
FROM members m
JOIN member_memberships mm ON mm.member_id = m.member_id
JOIN memberships ms        ON ms.membership_id = mm.membership_id
WHERE m.registration_date >= '2026-09-01'
GROUP BY m.member_id, m.first_name, m.last_name
HAVING COUNT(mm.member_membership_id) >= 2
ORDER BY total_spent DESC
LIMIT 20;

\echo
\echo '=== Запит 2: навантаження тренерів за жовтень 2026 (3 таблиці, агрегація) ==='
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    t.trainer_id,
    t.first_name,
    t.last_name,
    COUNT(DISTINCT ts.session_id) AS sessions_count,
    COUNT(a.attendance_id)        AS total_visits
FROM training_sessions ts
JOIN trainers t         ON t.trainer_id = ts.trainer_id
LEFT JOIN attendance a  ON a.session_id = ts.session_id
WHERE ts.session_date BETWEEN '2026-10-01' AND '2026-10-31'
GROUP BY t.trainer_id, t.first_name, t.last_name
ORDER BY total_visits DESC
LIMIT 10;

\echo
\echo '=== Запит 3: абонементи, що закінчуються в перший тиждень грудня 2026 ==='
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    mm.end_date,
    m.first_name,
    m.last_name,
    m.phone,
    ms.membership_name
FROM member_memberships mm
JOIN members m      ON m.member_id = mm.member_id
JOIN memberships ms ON ms.membership_id = mm.membership_id
WHERE mm.end_date BETWEEN '2026-12-01' AND '2026-12-07'
ORDER BY mm.end_date, m.last_name;
