CREATE OR REPLACE FUNCTION add_new_member(
    p_first_name VARCHAR,
    p_last_name VARCHAR,
    p_birth_date DATE,
    p_phone VARCHAR,
    p_email VARCHAR
)
RETURNS INTEGER
AS $$
DECLARE
    new_member_id INTEGER;
BEGIN

    INSERT INTO members
    (
        first_name,
        last_name,
        birth_date,
        phone,
        email
    )
    VALUES
    (
        p_first_name,
        p_last_name,
        p_birth_date,
        p_phone,
        p_email
    )
    RETURNING member_id
    INTO new_member_id;

    RETURN new_member_id;

END;
$$
LANGUAGE plpgsql;



CREATE OR REPLACE FUNCTION register_membership(
    p_member_id INTEGER,
    p_membership_id INTEGER,
    p_start_date DATE
)
RETURNS VOID
AS $$
DECLARE

    membership_duration INTEGER;

BEGIN

    SELECT duration_months
    INTO membership_duration
    FROM memberships
    WHERE membership_id = p_membership_id;

    INSERT INTO member_memberships
    (
        member_id,
        membership_id,
        start_date,
        end_date
    )
    VALUES
    (
        p_member_id,
        p_membership_id,
        p_start_date,
        p_start_date + (membership_duration || ' month')::INTERVAL
    );

END;
$$
LANGUAGE plpgsql;



CREATE OR REPLACE FUNCTION trainer_statistics(
    p_trainer_id INTEGER
)
RETURNS TABLE
(
    trainer_name TEXT,
    sessions_count BIGINT
)
AS $$
BEGIN

    RETURN QUERY

    SELECT
        t.first_name || ' ' || t.last_name,
        COUNT(ts.session_id)

    FROM trainers t

    LEFT JOIN training_sessions ts
        ON t.trainer_id = ts.trainer_id

    WHERE t.trainer_id = p_trainer_id

    GROUP BY
        t.first_name,
        t.last_name;

END;
$$
LANGUAGE plpgsql;