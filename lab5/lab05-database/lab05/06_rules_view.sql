-- =====================================================================
-- Lab 05 | Рівень 2: складне представлення, яке можна змінювати
-- через правила (RULES).
--
-- v_member_profile об'єднує members + (останній) абонемент через LATERAL.
-- PostgreSQL НЕ вміє автоматично оновлювати такі представлення, тому
-- поведінку UPDATE / DELETE задаємо вручну правилами DO INSTEAD.
-- (У документації PostgreSQL для нових проєктів рекомендують INSTEAD OF
--  тригери; правила тут — навчальна демонстрація механізму.)
-- =====================================================================

CREATE OR REPLACE VIEW v_member_profile AS
SELECT
    m.member_id,
    m.first_name,
    m.last_name,
    m.phone,
    m.email,
    cur.membership_name,
    cur.end_date AS membership_end_date
FROM members m
LEFT JOIN LATERAL (
    SELECT ms.membership_name, mm.end_date
    FROM member_memberships mm
    JOIN memberships ms ON ms.membership_id = mm.membership_id
    WHERE mm.member_id = m.member_id
    ORDER BY mm.end_date DESC
    LIMIT 1
) cur ON TRUE;

-- UPDATE через представлення змінює лише контактні дані в members.
-- Стовпці membership_name / membership_end_date ігноруються (вони похідні).
CREATE OR REPLACE RULE v_member_profile_update AS
ON UPDATE TO v_member_profile
DO INSTEAD
    UPDATE members
    SET first_name = NEW.first_name,
        last_name  = NEW.last_name,
        phone      = NEW.phone,
        email      = NEW.email
    WHERE member_id = OLD.member_id;

-- DELETE через представлення видаляє учасника (каскадно його абонементи
-- та відвідування завдяки ON DELETE CASCADE у схемі).
CREATE OR REPLACE RULE v_member_profile_delete AS
ON DELETE TO v_member_profile
DO INSTEAD
    DELETE FROM members WHERE member_id = OLD.member_id;

-- ---------------------------------------------------------------
-- Тест (з відкатом)
-- ---------------------------------------------------------------
BEGIN;

\echo 'До оновлення:'
SELECT member_id, first_name, last_name, phone, email, membership_name
FROM v_member_profile WHERE member_id = 1;

UPDATE v_member_profile
SET email = 'ivan.new@example.com', phone = '0501111112'
WHERE member_id = 1;

\echo 'Після оновлення через представлення:'
SELECT member_id, first_name, last_name, phone, email, membership_name
FROM v_member_profile WHERE member_id = 1;

\echo 'Те саме в базовій таблиці members:'
SELECT member_id, phone, email FROM members WHERE member_id = 1;

ROLLBACK;
