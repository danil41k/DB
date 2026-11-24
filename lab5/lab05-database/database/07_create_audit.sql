CREATE TABLE activity_log
(
    log_id SERIAL PRIMARY KEY,

    user_id INTEGER,

    action_name VARCHAR(100) NOT NULL,

    table_name VARCHAR(100),

    record_id INTEGER,

    action_details TEXT,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (user_id)
        REFERENCES users(user_id)
        ON DELETE SET NULL
);



CREATE OR REPLACE FUNCTION log_activity(
    p_user_id INTEGER,
    p_action_name VARCHAR,
    p_table_name VARCHAR,
    p_record_id INTEGER,
    p_action_details TEXT
)
RETURNS VOID
AS $$
BEGIN

    INSERT INTO activity_log
    (
        user_id,
        action_name,
        table_name,
        record_id,
        action_details
    )
    VALUES
    (
        p_user_id,
        p_action_name,
        p_table_name,
        p_record_id,
        p_action_details
    );

END;
$$
LANGUAGE plpgsql;



CREATE OR REPLACE FUNCTION audit_member_insert()
RETURNS TRIGGER
AS $$
BEGIN

    INSERT INTO activity_log
    (
        user_id,
        action_name,
        table_name,
        record_id,
        action_details
    )
    VALUES
    (
        NULL,
        'INSERT',
        'members',
        NEW.member_id,
        'New member was added'
    );

    RETURN NEW;

END;
$$
LANGUAGE plpgsql;



CREATE TRIGGER audit_members_insert_trigger
AFTER INSERT
ON members
FOR EACH ROW
EXECUTE FUNCTION audit_member_insert();



CREATE OR REPLACE FUNCTION audit_member_delete()
RETURNS TRIGGER
AS $$
BEGIN

    INSERT INTO activity_log
    (
        user_id,
        action_name,
        table_name,
        record_id,
        action_details
    )
    VALUES
    (
        NULL,
        'DELETE',
        'members',
        OLD.member_id,
        'Member was deleted'
    );

    RETURN OLD;

END;
$$
LANGUAGE plpgsql;



CREATE TRIGGER audit_members_delete_trigger
AFTER DELETE
ON members
FOR EACH ROW
EXECUTE FUNCTION audit_member_delete();