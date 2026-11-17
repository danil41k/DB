CREATE VIEW members_with_memberships
AS

SELECT
    m.member_id,
    m.first_name,
    m.last_name,
    ms.membership_name,
    mm.start_date,
    mm.end_date

FROM members m

INNER JOIN member_memberships mm
    ON m.member_id = mm.member_id

INNER JOIN memberships ms
    ON ms.membership_id = mm.membership_id;



CREATE VIEW trainer_sessions_statistics
AS

SELECT
    t.trainer_id,
    t.first_name,
    t.last_name,
    t.specialization,
    COUNT(ts.session_id) AS total_sessions

FROM trainers t

LEFT JOIN training_sessions ts
    ON t.trainer_id = ts.trainer_id

GROUP BY
    t.trainer_id,
    t.first_name,
    t.last_name,
    t.specialization;



CREATE VIEW member_attendance_statistics
AS

SELECT
    m.member_id,
    m.first_name,
    m.last_name,
    COUNT(a.attendance_id) AS total_visits

FROM members m

LEFT JOIN attendance a
    ON m.member_id = a.member_id

GROUP BY
    m.member_id,
    m.first_name,
    m.last_name;