-- =====================================================================
-- Lab 05 | Крок 2: наповнення БД великою кількістю тестових даних
-- Без великого обсягу даних оптимізатор завжди обере Seq Scan і ефекту
-- від індексів не буде видно.
--
-- Результат: ~100 010 учасників, 60 тренерів, 150 010 абонементів,
--            20 010 тренувань, 500 010 записів відвідувань.
-- Запускати ОДИН раз (phone/email унікальні -> повторний запуск дасть помилку).
-- =====================================================================
\set ON_ERROR_STOP on
\timing on

BEGIN;

-- Вимикаємо користувацькі тригери на час масового наповнення
-- (потрібні права суперкористувача; в Docker це користувач postgres)
SET LOCAL session_replication_role = replica;

-- ---------- members: +100 000 ----------
INSERT INTO members (first_name, last_name, birth_date, phone, email, registration_date)
SELECT
    (ARRAY['Іван','Олег','Марія','Юлія','Андрій','Максим','Оксана','Тарас',
           'Назар','Ірина','Софія','Артем','Дарина','Богдан','Анна'])[1 + floor(random() * 15)::int],
    (ARRAY['Петренко','Савчук','Коваль','Гнатюк','Мельник','Левицький','Романюк',
           'Шевчук','Климчук','Сидорук','Бондар','Ткачук','Кравчук','Олійник',
           'Мазур','Жук','Коваленко','Лисенко','Руденко','Поліщук'])[1 + floor(random() * 20)::int],
    DATE '1970-01-01' + floor(random() * 11000)::int,
    '9' || lpad(g::text, 9, '0'),
    'member' || g || '@example.com',
    CURRENT_DATE - floor(random() * 1000)::int
FROM generate_series(1, 100000) AS g;

-- ---------- trainers: +50 ----------
INSERT INTO trainers (first_name, last_name, specialization, phone, salary)
SELECT
    (ARRAY['Сергій','Руслан','Олена','Марина','Антон','Віктор','Дмитро','Катерина'])[1 + floor(random() * 8)::int],
    (ARRAY['Бойко','Демчук','Лісова','Козак','Ковчук','Гуменюк','Паламарчук','Мороз'])[1 + floor(random() * 8)::int],
    (ARRAY['Фітнес','Бокс','Йога','Пілатес','Кросфіт','Кардіо','TRX','Стретчинг'])[1 + floor(random() * 8)::int],
    '8' || lpad(g::text, 9, '0'),
    15000 + floor(random() * 20000)::int
FROM generate_series(1, 50) AS g;

-- ---------- member_memberships: +150 000 ----------
WITH s AS MATERIALIZED (
    SELECT
        1 + floor(random() * (SELECT count(*) FROM members))::int     AS member_id,
        1 + floor(random() * (SELECT count(*) FROM memberships))::int AS membership_id,
        CURRENT_DATE - floor(random() * 700)::int                     AS start_date
    FROM generate_series(1, 150000)
)
INSERT INTO member_memberships (member_id, membership_id, start_date, end_date)
SELECT
    s.member_id,
    s.membership_id,
    s.start_date,
    (s.start_date + make_interval(months => ms.duration_months))::date
FROM s
JOIN memberships ms ON ms.membership_id = s.membership_id;

-- ---------- training_sessions: +20 000 ----------
WITH s AS MATERIALIZED (
    SELECT
        g,
        1 + floor(random() * 60)::int   AS trainer_id,
        7 + floor(random() * 14)::int   AS h,            -- 7..20
        CURRENT_DATE + (floor(random() * 1000)::int - 700) AS session_date,
        10 + floor(random() * 31)::int  AS max_participants   -- 10..40
    FROM generate_series(1, 20000) AS g
)
INSERT INTO training_sessions
    (trainer_id, session_name, session_date, start_time, end_time, max_participants)
SELECT
    trainer_id,
    (ARRAY['Йога','Кросфіт','Бокс','Пілатес','Кардіо','TRX','Стретчинг','Силове'])[1 + (g % 8)] || ' #' || g,
    session_date,
    make_time(h, 0, 0),
    make_time(h + 1, 0, 0),
    max_participants
FROM s;

-- ---------- attendance: +500 000 ----------
INSERT INTO attendance (member_id, session_id)
SELECT
    1 + floor(random() * (SELECT count(*) FROM members))::int,
    1 + floor(random() * (SELECT count(*) FROM training_sessions))::int
FROM generate_series(1, 500000);

COMMIT;

-- Оновлюємо статистику оптимізатора
ANALYZE;

SELECT 'members' AS table_name, count(*) FROM members
UNION ALL SELECT 'trainers',            count(*) FROM trainers
UNION ALL SELECT 'member_memberships',  count(*) FROM member_memberships
UNION ALL SELECT 'training_sessions',   count(*) FROM training_sessions
UNION ALL SELECT 'attendance',          count(*) FROM attendance;
