SELECT
    first_name,
    last_name,
    phone
FROM members
ORDER BY last_name;


SELECT
    m.first_name,
    m.last_name,
    ms.membership_name,
    ms.price
FROM member_memberships mm
INNER JOIN members m
    ON mm.member_id = m.member_id
INNER JOIN memberships ms
    ON mm.membership_id = ms.membership_id
ORDER BY m.last_name;


SELECT
    t.first_name,
    t.last_name,
    COUNT(ts.session_id) AS total_sessions
FROM trainers t
LEFT JOIN training_sessions ts
    ON t.trainer_id = ts.trainer_id
GROUP BY
    t.trainer_id,
    t.first_name,
    t.last_name
ORDER BY total_sessions DESC;


SELECT
    session_name,
    max_participants
FROM training_sessions
WHERE max_participants >
(
    SELECT AVG(max_participants)
    FROM training_sessions
);


SELECT
    m.first_name,
    m.last_name,
    ts.session_name,
    ts.session_date,
    tr.first_name || ' ' || tr.last_name AS trainer_name
FROM attendance a
INNER JOIN members m
    ON a.member_id = m.member_id
INNER JOIN training_sessions ts
    ON a.session_id = ts.session_id
INNER JOIN trainers tr
    ON ts.trainer_id = tr.trainer_id
ORDER BY ts.session_date;


SELECT
    COUNT(*) AS total_members
FROM members;


SELECT
    AVG(price) AS average_membership_price
FROM memberships;


SELECT
    equipment_name,
    quantity
FROM equipment
ORDER BY quantity DESC;


SELECT
    first_name,
    last_name,
    salary
FROM trainers
ORDER BY salary DESC;


SELECT
    session_name,
    session_date
FROM training_sessions
ORDER BY session_date;