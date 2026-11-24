-- =====================================================================
-- Lab 05 | Рівень 2: повноцінна система аудиту (audit_log)
-- Один універсальний тригер фіксує INSERT / UPDATE / DELETE у всіх
-- основних таблицях: тип операції, таблицю, час, користувача,
-- старі та нові значення (для UPDATE — обидва).
--
-- Назва ключового стовпця передається аргументом тригера (TG_ARGV[0]),
-- тому одна функція працює для будь-якої таблиці.
--
-- SECURITY DEFINER + session_user: функція пише в audit_log з правами
-- власника (користувачам не потрібен прямий доступ до audit_log), а ім'я
-- користувача беремо через session_user, бо current_user у SECURITY
-- DEFINER-функції був би власником функції.
-- =====================================================================

CREATE OR REPLACE FUNCTION audit_row_changes()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    pk_col TEXT := TG_ARGV[0];
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO audit_log (table_name, operation, record_id, new_values, changed_by)
        VALUES (TG_TABLE_NAME, TG_OP, (to_jsonb(NEW) ->> pk_col)::integer,
                to_jsonb(NEW), session_user);
        RETURN NEW;

    ELSIF TG_OP = 'UPDATE' THEN
        -- не логуємо «порожні» оновлення, що нічого не змінили
        IF to_jsonb(OLD) = to_jsonb(NEW) THEN
            RETURN NEW;
        END IF;
        INSERT INTO audit_log (table_name, operation, record_id, old_values, new_values, changed_by)
        VALUES (TG_TABLE_NAME, TG_OP, (to_jsonb(NEW) ->> pk_col)::integer,
                to_jsonb(OLD), to_jsonb(NEW), session_user);
        RETURN NEW;

    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO audit_log (table_name, operation, record_id, old_values, changed_by)
        VALUES (TG_TABLE_NAME, TG_OP, (to_jsonb(OLD) ->> pk_col)::integer,
                to_jsonb(OLD), session_user);
        RETURN OLD;
    END IF;

    RETURN NULL;
END;
$$;

-- Простий тригер рівня 1 більше не потрібен (інакше INSERT/UPDATE
-- trainers логувалися б двічі)
DROP TRIGGER IF EXISTS trg_trainers_log_iu ON trainers;

-- Підключаємо універсальний тригер до всіх основних таблиць
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN
        SELECT * FROM (VALUES
            ('members',            'member_id'),
            ('trainers',           'trainer_id'),
            ('memberships',        'membership_id'),
            ('member_memberships', 'member_membership_id'),
            ('training_sessions',  'session_id'),
            ('attendance',         'attendance_id'),
            ('equipment',          'equipment_id')
        ) AS t(tbl, pk)
    LOOP
        EXECUTE format('DROP TRIGGER IF EXISTS trg_audit_%1$s ON %1$I', r.tbl);
        EXECUTE format(
            'CREATE TRIGGER trg_audit_%1$s
             AFTER INSERT OR UPDATE OR DELETE ON %1$I
             FOR EACH ROW EXECUTE FUNCTION audit_row_changes(%2$L)',
            r.tbl, r.pk);
    END LOOP;
END
$$;

\echo
\echo 'Тригери аудиту:'
SELECT event_object_table AS table_name, trigger_name,
       string_agg(DISTINCT event_manipulation, ', ' ORDER BY event_manipulation) AS events
FROM information_schema.triggers
WHERE trigger_name LIKE 'trg_audit_%'
GROUP BY event_object_table, trigger_name
ORDER BY event_object_table;

-- ---------------------------------------------------------------
-- Тест: INSERT -> UPDATE -> DELETE одного запису (equipment)
-- ---------------------------------------------------------------
BEGIN;

INSERT INTO equipment (equipment_name, quantity, purchase_date, condition)
VALUES ('Тестова гантеля', 5, CURRENT_DATE, 'New');

UPDATE equipment SET quantity = 8, condition = 'Good'
WHERE equipment_name = 'Тестова гантеля';

DELETE FROM equipment WHERE equipment_name = 'Тестова гантеля';

SELECT log_id, table_name, operation, record_id,
       old_values ->> 'quantity' AS old_qty,
       new_values ->> 'quantity' AS new_qty,
       changed_by, changed_at
FROM audit_log
WHERE table_name = 'equipment'
ORDER BY log_id DESC
LIMIT 3;

ROLLBACK;
