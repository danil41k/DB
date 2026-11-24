-- =====================================================================
-- Lab 05 | Крок 5 (Рівень 1): таблиця audit_log + тригер логування
-- INSERT / UPDATE для таблиці trainers.
-- На рівні 2 (08_audit_system.sql) цей простий тригер замінюється
-- універсальним, щоб операції не логувалися двічі.
-- =====================================================================

CREATE TABLE IF NOT EXISTS audit_log (
    log_id      SERIAL PRIMARY KEY,
    table_name  VARCHAR(50) NOT NULL,
    operation   VARCHAR(10) NOT NULL
                CHECK (operation IN ('INSERT', 'UPDATE', 'DELETE')),
    record_id   INTEGER,
    old_values  JSONB,
    new_values  JSONB,
    changed_by  VARCHAR(100),
    changed_at  TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_audit_log_table_time
    ON audit_log (table_name, changed_at DESC);

CREATE OR REPLACE FUNCTION log_trainer_changes()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO audit_log (table_name, operation, record_id, new_values, changed_by)
        VALUES (TG_TABLE_NAME, TG_OP, NEW.trainer_id, to_jsonb(NEW), current_user);

    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO audit_log (table_name, operation, record_id, old_values, new_values, changed_by)
        VALUES (TG_TABLE_NAME, TG_OP, NEW.trainer_id, to_jsonb(OLD), to_jsonb(NEW), current_user);
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_trainers_log_iu ON trainers;

CREATE TRIGGER trg_trainers_log_iu
AFTER INSERT OR UPDATE ON trainers
FOR EACH ROW
EXECUTE FUNCTION log_trainer_changes();

-- ---------------------------------------------------------------
-- Тест (у транзакції з відкатом, щоб не засмічувати дані)
-- ---------------------------------------------------------------
BEGIN;

INSERT INTO trainers (first_name, last_name, specialization, phone, salary)
VALUES ('Тест', 'Тренер', 'Тестовий напрям', '0990000000', 20000);

UPDATE trainers SET salary = 25000 WHERE phone = '0990000000';

SELECT log_id, table_name, operation, record_id,
       old_values ->> 'salary' AS old_salary,
       new_values ->> 'salary' AS new_salary,
       changed_by, changed_at
FROM audit_log
ORDER BY log_id DESC
LIMIT 5;

ROLLBACK;
