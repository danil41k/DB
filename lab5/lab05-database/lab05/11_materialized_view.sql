-- =====================================================================
-- Lab 05 | Рівень 3: матеріалізоване представлення з агрегованими
-- даними + автоматичне оновлення через тригер.
-- =====================================================================

CREATE MATERIALIZED VIEW IF NOT EXISTS mv_monthly_membership_sales AS
SELECT
    date_trunc('month', mm.start_date)::date AS sale_month,
    COUNT(*)                                  AS memberships_sold,
    SUM(ms.price)                             AS revenue,
    ROUND(AVG(ms.price), 2)                   AS avg_price
FROM member_memberships mm
JOIN memberships ms ON ms.membership_id = mm.membership_id
GROUP BY date_trunc('month', mm.start_date)::date
WITH DATA;

-- Унікальний індекс потрібен для REFRESH ... CONCURRENTLY
CREATE UNIQUE INDEX IF NOT EXISTS idx_mv_monthly_sales_month
    ON mv_monthly_membership_sales (sale_month);

-- Функція тригера: SECURITY DEFINER, бо REFRESH може виконати лише
-- власник представлення (інакше модератор, який додав абонемент,
-- отримав би помилку прав).
CREATE OR REPLACE FUNCTION refresh_mv_monthly_sales()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY mv_monthly_membership_sales;
    RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS trg_refresh_mv_monthly_sales ON member_memberships;
CREATE TRIGGER trg_refresh_mv_monthly_sales
AFTER INSERT OR UPDATE OR DELETE ON member_memberships
FOR EACH STATEMENT
EXECUTE FUNCTION refresh_mv_monthly_sales();

-- ---------------------------------------------------------------
-- Тест: продаж абонемента автоматично змінює агрегати
-- ---------------------------------------------------------------
\echo
\echo 'Останні місяці ДО продажу абонемента:'
SELECT * FROM mv_monthly_membership_sales ORDER BY sale_month DESC LIMIT 3;

BEGIN;
-- «Піврічний» (id=3) коштує 3900, продаж сьогодні
INSERT INTO member_memberships (member_id, membership_id, start_date, end_date)
VALUES (1, 3, CURRENT_DATE, (CURRENT_DATE + INTERVAL '6 months')::date);

\echo 'ПІСЛЯ продажу (в тій самій транзакції, без ручного REFRESH):'
SELECT * FROM mv_monthly_membership_sales ORDER BY sale_month DESC LIMIT 3;
ROLLBACK;

\echo 'ПІСЛЯ відкату (тригер на DELETE/ROLLBACK не потрібен — відкат скасовує і REFRESH):'
SELECT * FROM mv_monthly_membership_sales ORDER BY sale_month DESC LIMIT 3;
