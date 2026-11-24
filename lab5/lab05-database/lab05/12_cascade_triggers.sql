-- =====================================================================
-- Lab 05 | Рівень 3: каскадні тригери для складної бізнес-логіки.
--
-- Ланцюжок подій при реєстрації відвідування (attendance):
--
--  INSERT attendance
--    |-- BEFORE: trg_attendance_rules   -> перевірка абонемента, місць, дубліката
--    '-- AFTER : trg_attendance_ins     -> UPDATE members (visits_count, last_visit_date)
--          |-- BEFORE: trg_validate_members (валідація, з файлу 07)
--          |-- AFTER : trg_audit_members (запис у audit_log, з файлу 08)
--          '-- AFTER : trg_members_loyalty_bonus (кожні 10 відвідувань)
--                 '-- INSERT member_bonuses
--                        '-- AFTER: trg_audit_member_bonuses
--
--  DELETE training_sessions -> (FK CASCADE) DELETE attendance
--        -> trg_attendance_del -> UPDATE members (visits_count - 1)
--
--  DELETE trainers -> BEFORE: trg_trainer_delete_guard (немає майбутніх тренувань)
-- =====================================================================

-- ---------- нові стовпці та таблиця бонусів ----------
ALTER TABLE members
    ADD COLUMN IF NOT EXISTS visits_count    INTEGER NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS last_visit_date DATE;

CREATE TABLE IF NOT EXISTS member_bonuses (
    bonus_id    SERIAL PRIMARY KEY,
    member_id   INTEGER NOT NULL REFERENCES members(member_id) ON DELETE CASCADE,
    bonus_type  VARCHAR(50) NOT NULL,
    description TEXT,
    created_at  TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_member_bonuses_member_id ON member_bonuses (member_id);

-- Початкове значення лічильників з уже наявних відвідувань
-- (тригери вимкнено, щоб не створити сотні тисяч записів аудиту)
BEGIN;
SET LOCAL session_replication_role = replica;

UPDATE members m
SET visits_count    = c.cnt,
    last_visit_date = c.last_date
FROM (
    SELECT a.member_id,
           COUNT(*) AS cnt,
           MAX(ts.session_date) FILTER (WHERE ts.session_date <= CURRENT_DATE) AS last_date
    FROM attendance a
    JOIN training_sessions ts ON ts.session_id = a.session_id
    GROUP BY a.member_id
) c
WHERE c.member_id = m.member_id;

COMMIT;

-- ---------- 1. Бізнес-правила відвідування (BEFORE INSERT) ----------
CREATE OR REPLACE FUNCTION check_attendance_rules()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    s     RECORD;
    taken INTEGER;
BEGIN
    SELECT session_date, max_participants
    INTO s
    FROM training_sessions
    WHERE session_id = NEW.session_id;

    IF NOT FOUND THEN
        RETURN NEW;   -- неіснуюче тренування відхилить зовнішній ключ
    END IF;

    -- 1) у учасника має бути діючий абонемент на дату тренування
    IF NOT EXISTS (
        SELECT 1 FROM member_memberships
        WHERE member_id = NEW.member_id
          AND s.session_date BETWEEN start_date AND end_date
    ) THEN
        RAISE EXCEPTION 'Учасник % не має діючого абонемента на %', NEW.member_id, s.session_date
            USING ERRCODE = 'check_violation';
    END IF;

    -- 2) не можна записатися двічі на те саме тренування
    IF EXISTS (
        SELECT 1 FROM attendance
        WHERE member_id = NEW.member_id AND session_id = NEW.session_id
    ) THEN
        RAISE EXCEPTION 'Учасник % уже записаний на тренування %', NEW.member_id, NEW.session_id
            USING ERRCODE = 'unique_violation';
    END IF;

    -- 3) не можна перевищити максимальну кількість учасників
    SELECT COUNT(*) INTO taken FROM attendance WHERE session_id = NEW.session_id;
    IF taken >= s.max_participants THEN
        RAISE EXCEPTION 'Тренування % заповнене (% з % місць)', NEW.session_id, taken, s.max_participants
            USING ERRCODE = 'check_violation';
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_attendance_rules ON attendance;
CREATE TRIGGER trg_attendance_rules
BEFORE INSERT ON attendance
FOR EACH ROW
EXECUTE FUNCTION check_attendance_rules();

-- ---------- 2. Оновлення лічильників учасника (AFTER INSERT / DELETE) ----------
CREATE OR REPLACE FUNCTION attendance_after_insert()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_date DATE;
BEGIN
    SELECT session_date INTO v_date FROM training_sessions WHERE session_id = NEW.session_id;

    UPDATE members
    SET visits_count    = visits_count + 1,
        last_visit_date = GREATEST(COALESCE(last_visit_date, v_date), v_date)
    WHERE member_id = NEW.member_id;

    RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS trg_attendance_ins ON attendance;
CREATE TRIGGER trg_attendance_ins
AFTER INSERT ON attendance
FOR EACH ROW
EXECUTE FUNCTION attendance_after_insert();

CREATE OR REPLACE FUNCTION attendance_after_delete()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    UPDATE members
    SET visits_count = GREATEST(visits_count - 1, 0)
    WHERE member_id = OLD.member_id;

    RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS trg_attendance_del ON attendance;
CREATE TRIGGER trg_attendance_del
AFTER DELETE ON attendance
FOR EACH ROW
EXECUTE FUNCTION attendance_after_delete();

-- ---------- 3. Бонус лояльності кожні 10 відвідувань ----------
CREATE OR REPLACE FUNCTION members_loyalty_bonus()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    INSERT INTO member_bonuses (member_id, bonus_type, description)
    VALUES (NEW.member_id, 'LOYALTY',
            format('Досягнуто %s відвідувань', (NEW.visits_count / 10) * 10));
    RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS trg_members_loyalty_bonus ON members;
CREATE TRIGGER trg_members_loyalty_bonus
AFTER UPDATE OF visits_count ON members
FOR EACH ROW
WHEN (NEW.visits_count / 10 > OLD.visits_count / 10)
EXECUTE FUNCTION members_loyalty_bonus();

-- ---------- 4. Захист від видалення тренера з майбутніми тренуваннями ----------
CREATE OR REPLACE FUNCTION trainer_delete_guard()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM training_sessions
        WHERE trainer_id = OLD.trainer_id AND session_date >= CURRENT_DATE
    ) THEN
        RAISE EXCEPTION 'Не можна видалити тренера %: у нього є заплановані тренування', OLD.trainer_id
            USING ERRCODE = 'restrict_violation',
                  HINT = 'Спершу перепризначте або скасуйте його майбутні тренування';
    END IF;
    RETURN OLD;
END;
$$;

DROP TRIGGER IF EXISTS trg_trainer_delete_guard ON trainers;
CREATE TRIGGER trg_trainer_delete_guard
BEFORE DELETE ON trainers
FOR EACH ROW
EXECUTE FUNCTION trainer_delete_guard();

-- Аудит для таблиці бонусів (функція з файлу 08)
DROP TRIGGER IF EXISTS trg_audit_member_bonuses ON member_bonuses;
CREATE TRIGGER trg_audit_member_bonuses
AFTER INSERT OR UPDATE OR DELETE ON member_bonuses
FOR EACH ROW
EXECUTE FUNCTION audit_row_changes('bonus_id');

-- ---------------------------------------------------------------
-- Демонстрація каскаду (усе в транзакції з відкатом)
-- ---------------------------------------------------------------
\set ON_ERROR_STOP off
BEGIN;

SELECT add_new_member('Каскад', 'Тестовий', '2000-01-01', '0990000001', 'cascade@example.com') AS test_member \gset
SELECT register_membership(:test_member, 1, CURRENT_DATE);

INSERT INTO training_sessions (trainer_id, session_name, session_date, start_time, end_time, max_participants)
VALUES (1, 'Cascade demo', CURRENT_DATE, '10:00', '11:00', 2)
RETURNING session_id AS test_session \gset

-- імітуємо 9 попередніх відвідувань (UPDATE visits_count не запускає бонус: 0/10 = 0, 9/10 = 0)
UPDATE members SET visits_count = 9 WHERE member_id = :test_member;

\echo '--- Крок 1: реєстрація відвідування -> лічильник 9 -> 10 -> бонус ---'
INSERT INTO attendance (member_id, session_id) VALUES (:test_member, :test_session);

SELECT member_id, visits_count, last_visit_date FROM members WHERE member_id = :test_member;
SELECT bonus_id, member_id, bonus_type, description FROM member_bonuses WHERE member_id = :test_member;
SELECT table_name, operation, record_id, changed_by
FROM audit_log WHERE table_name IN ('members', 'member_bonuses', 'attendance')
  AND (new_values ->> 'member_id')::int = :test_member
ORDER BY log_id;

\echo '--- Крок 2: повторний запис на те саме тренування -> відхилено ---'
INSERT INTO attendance (member_id, session_id) VALUES (:test_member, :test_session);
ROLLBACK;   -- помилка вище перервала транзакцію, відкат прибирає всі тестові дані

BEGIN;
\echo '--- Крок 3: учасник без абонемента -> відхилено ---'
SELECT add_new_member('Без', 'Абонемента', '2000-01-01', '0990000002', 'noplan@example.com') AS no_plan_member \gset
INSERT INTO attendance (member_id, session_id)
SELECT :no_plan_member, 1;   -- сесія №1 (з даних лаби 4)
ROLLBACK;

BEGIN;
\echo '--- Крок 4: видалення тренера з майбутніми тренуваннями -> відхилено ---'
DELETE FROM trainers WHERE trainer_id = 1;
ROLLBACK;
\set ON_ERROR_STOP on
