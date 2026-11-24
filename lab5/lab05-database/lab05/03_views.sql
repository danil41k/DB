-- =====================================================================
-- Lab 05 | Крок 4: два представлення для часто використовуваних запитів
-- (у лабі 4 вже є members_with_memberships, trainer_sessions_statistics,
--  member_attendance_statistics — ці нові їх доповнюють)
-- =====================================================================

-- 1) Простий JOIN: учасники з діючим на сьогодні абонементом
CREATE OR REPLACE VIEW v_active_memberships AS
SELECT
    m.member_id,
    m.first_name,
    m.last_name,
    ms.membership_name,
    mm.start_date,
    mm.end_date,
    (mm.end_date - CURRENT_DATE) AS days_left
FROM member_memberships mm
JOIN members m      ON m.member_id = mm.member_id
JOIN memberships ms ON ms.membership_id = mm.membership_id
WHERE CURRENT_DATE BETWEEN mm.start_date AND mm.end_date;

-- 2) Складне, з агрегацією: навантаження тренерів
CREATE OR REPLACE VIEW v_trainer_workload AS
SELECT
    t.trainer_id,
    t.first_name || ' ' || t.last_name                      AS trainer_name,
    t.specialization,
    COUNT(DISTINCT ts.session_id)                           AS sessions_count,
    COUNT(a.attendance_id)                                  AS total_visits,
    ROUND(COUNT(a.attendance_id)::numeric
          / NULLIF(COUNT(DISTINCT ts.session_id), 0), 1)    AS avg_visits_per_session
FROM trainers t
LEFT JOIN training_sessions ts ON ts.trainer_id = t.trainer_id
LEFT JOIN attendance a         ON a.session_id = ts.session_id
GROUP BY t.trainer_id, t.first_name, t.last_name, t.specialization;

-- Перевірка
SELECT * FROM v_active_memberships ORDER BY days_left LIMIT 10;
SELECT * FROM v_trainer_workload ORDER BY total_visits DESC LIMIT 10;
