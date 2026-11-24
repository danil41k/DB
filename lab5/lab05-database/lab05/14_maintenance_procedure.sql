-- =====================================================================
-- Lab 05 | Рівень 3: збережена процедура автоматизованого
-- обслуговування БД: ANALYZE, REINDEX кожної таблиці, оновлення
-- матеріалізованого представлення. Кожен крок пишеться в maintenance_log.
--
-- VACUUM / REINDEX DATABASE / REINDEX CONCURRENTLY не можна виконувати
-- всередині процедури (вони не працюють у блоці транзакції) — для них:
--   docker compose exec postgres vacuumdb -U postgres -d sportsclub --analyze
-- =====================================================================

CREATE TABLE IF NOT EXISTS maintenance_log (
    log_id      SERIAL PRIMARY KEY,
    operation   TEXT NOT NULL,
    details     TEXT,
    duration_ms NUMERIC(12, 2),
    executed_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE OR REPLACE PROCEDURE maintain_database()
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    tbl RECORD;
    t0  TIMESTAMPTZ;
BEGIN
    -- 1. Статистика оптимізатора
    t0 := clock_timestamp();
    ANALYZE;
    INSERT INTO maintenance_log (operation, details, duration_ms)
    VALUES ('ANALYZE', 'Оновлено статистику оптимізатора',
            round((extract(epoch FROM clock_timestamp() - t0) * 1000)::numeric, 2));

    -- 2. Перебудова індексів усіх таблиць схеми public
    FOR tbl IN
        SELECT tablename FROM pg_tables WHERE schemaname = 'public' ORDER BY tablename
    LOOP
        t0 := clock_timestamp();
        EXECUTE format('REINDEX TABLE %I.%I', 'public', tbl.tablename);
        INSERT INTO maintenance_log (operation, details, duration_ms)
        VALUES ('REINDEX', 'Таблиця ' || tbl.tablename,
                round((extract(epoch FROM clock_timestamp() - t0) * 1000)::numeric, 2));
    END LOOP;

    -- 3. Оновлення матеріалізованого представлення
    t0 := clock_timestamp();
    REFRESH MATERIALIZED VIEW mv_monthly_membership_sales;
    INSERT INTO maintenance_log (operation, details, duration_ms)
    VALUES ('REFRESH MV', 'mv_monthly_membership_sales',
            round((extract(epoch FROM clock_timestamp() - t0) * 1000)::numeric, 2));

    RAISE NOTICE 'Обслуговування бази даних завершено успішно';
END;
$$;

-- Лише адміністратор (та власник) може викликати процедуру
REVOKE EXECUTE ON PROCEDURE maintain_database() FROM PUBLIC;
GRANT  EXECUTE ON PROCEDURE maintain_database() TO club_admin_role;

-- Виконання та перевірка журналу
CALL maintain_database();

SELECT log_id, operation, details, duration_ms, executed_at
FROM maintenance_log
ORDER BY log_id DESC
LIMIT 15;
