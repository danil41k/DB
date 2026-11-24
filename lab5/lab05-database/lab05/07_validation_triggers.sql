-- =====================================================================
-- Lab 05 | Рівень 2: BEFORE-тригери валідації даних.
-- Некоректні значення відхиляються через RAISE EXCEPTION
-- з кодом помилки check_violation (SQLSTATE 23514) та підказкою (HINT).
-- =====================================================================

-- ---------- members: email, телефон, дата народження ----------
CREATE OR REPLACE FUNCTION validate_member_data()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.email IS NOT NULL
       AND NEW.email !~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$' THEN
        RAISE EXCEPTION 'Некоректний email: %', NEW.email
            USING ERRCODE = 'check_violation',
                  HINT = 'Очікуваний формат: name@domain.com';
    END IF;

    IF NEW.phone !~ '^\+?[0-9]{10,15}$' THEN
        RAISE EXCEPTION 'Некоректний телефон: %', NEW.phone
            USING ERRCODE = 'check_violation',
                  HINT = 'Лише цифри (допускається ведучий +), довжина 10-15 символів';
    END IF;

    IF NEW.birth_date < DATE '1900-01-01'
       OR NEW.birth_date > CURRENT_DATE - INTERVAL '5 years' THEN
        RAISE EXCEPTION 'Некоректна дата народження: %', NEW.birth_date
            USING ERRCODE = 'check_violation',
                  HINT = 'Учаснику має бути щонайменше 5 років, дата не раніше 1900-01-01';
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_validate_members ON members;
CREATE TRIGGER trg_validate_members
BEFORE INSERT OR UPDATE ON members
FOR EACH ROW
EXECUTE FUNCTION validate_member_data();

-- ---------- training_sessions: час початку < часу завершення ----------
CREATE OR REPLACE FUNCTION validate_session_times()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.end_time <= NEW.start_time THEN
        RAISE EXCEPTION 'Час завершення (%) має бути пізніше за час початку (%)',
            NEW.end_time, NEW.start_time
            USING ERRCODE = 'check_violation';
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_validate_sessions ON training_sessions;
CREATE TRIGGER trg_validate_sessions
BEFORE INSERT OR UPDATE ON training_sessions
FOR EACH ROW
EXECUTE FUNCTION validate_session_times();

-- ---------- member_memberships: дата завершення > дати початку ----------
CREATE OR REPLACE FUNCTION validate_membership_dates()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.end_date <= NEW.start_date THEN
        RAISE EXCEPTION 'Дата завершення абонемента (%) має бути пізніше за дату початку (%)',
            NEW.end_date, NEW.start_date
            USING ERRCODE = 'check_violation';
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_validate_member_memberships ON member_memberships;
CREATE TRIGGER trg_validate_member_memberships
BEFORE INSERT OR UPDATE ON member_memberships
FOR EACH ROW
EXECUTE FUNCTION validate_membership_dates();

-- ---------------------------------------------------------------
-- Тести: некоректні дані відхиляються, помилка перехоплюється
-- (кожен блок у власній підтранзакції DO ... EXCEPTION)
-- ---------------------------------------------------------------
\echo
\echo '--- Тест 1: некоректний email ---'
DO $$
BEGIN
    INSERT INTO members (first_name, last_name, birth_date, phone, email)
    VALUES ('Тест', 'Email', '2000-01-01', '0991111111', 'invalid-email');
    RAISE NOTICE 'ПОМИЛКА: запис не мав пройти!';
EXCEPTION WHEN check_violation THEN
    RAISE NOTICE 'Відхилено тригером: %', SQLERRM;
END
$$;

\echo '--- Тест 2: некоректний телефон ---'
DO $$
BEGIN
    INSERT INTO members (first_name, last_name, birth_date, phone, email)
    VALUES ('Тест', 'Phone', '2000-01-01', '12345', 'ok@example.com');
    RAISE NOTICE 'ПОМИЛКА: запис не мав пройти!';
EXCEPTION WHEN check_violation THEN
    RAISE NOTICE 'Відхилено тригером: %', SQLERRM;
END
$$;

\echo '--- Тест 3: дата народження в майбутньому ---'
DO $$
BEGIN
    INSERT INTO members (first_name, last_name, birth_date, phone, email)
    VALUES ('Тест', 'Birth', CURRENT_DATE + 1, '0992222222', 'birth@example.com');
    RAISE NOTICE 'ПОМИЛКА: запис не мав пройти!';
EXCEPTION WHEN check_violation THEN
    RAISE NOTICE 'Відхилено тригером: %', SQLERRM;
END
$$;

\echo '--- Тест 4: тренування, що закінчується раніше, ніж починається ---'
DO $$
BEGIN
    INSERT INTO training_sessions (trainer_id, session_name, session_date, start_time, end_time, max_participants)
    VALUES (1, 'Тест', CURRENT_DATE, '12:00', '11:00', 10);
    RAISE NOTICE 'ПОМИЛКА: запис не мав пройти!';
EXCEPTION WHEN check_violation THEN
    RAISE NOTICE 'Відхилено тригером: %', SQLERRM;
END
$$;

\echo '--- Тест 5: коректний запис проходить (з відкатом) ---'
BEGIN;
INSERT INTO members (first_name, last_name, birth_date, phone, email)
VALUES ('Валід', 'Тест', '2000-01-01', '0993333333', 'valid@example.com')
RETURNING member_id, first_name, last_name, email;
ROLLBACK;
