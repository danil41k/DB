CREATE TABLE member_audit
(
    audit_id SERIAL PRIMARY KEY,

    member_id INTEGER,

    action_type VARCHAR(20),

    action_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);



CREATE OR REPLACE FUNCTION log_member_insert()
RETURNS TRIGGER
AS $$
BEGIN

    INSERT INTO member_audit
    (
        member_id,
        action_type
    )
    VALUES
    (
        NEW.member_id,
        'INSERT'
    );

    RETURN NEW;

END;
$$
LANGUAGE plpgsql;



CREATE TRIGGER member_insert_trigger
AFTER INSERT
ON members
FOR EACH ROW
EXECUTE FUNCTION log_member_insert();



CREATE OR REPLACE FUNCTION validate_salary()
RETURNS TRIGGER
AS $$
BEGIN

    IF NEW.salary < 0 THEN

        RAISE EXCEPTION
        'Salary cannot be negative';

    END IF;

    RETURN NEW;

END;
$$
LANGUAGE plpgsql;



CREATE TRIGGER validate_salary_trigger
BEFORE INSERT OR UPDATE
ON trainers
FOR EACH ROW
EXECUTE FUNCTION validate_salary();