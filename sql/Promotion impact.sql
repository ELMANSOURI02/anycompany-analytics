-- Impact des promotions sur les ventes, sensibilité par catégorie et région

USE DATABASE MY_GRP_LAB;
USE WAREHOUSE MY_GRP_WH;

-- 1 VOLUME DE PROMOTIONS PAR CATÉGORIE ET RÉGION

SELECT
    product_category,
    region,
    COUNT(*)                               AS nb_promotions,
    ROUND(AVG(discount_pct_display), 1)    AS avg_discount_pct,
    ROUND(AVG(duration_days), 1)           AS avg_duration_days,
    MIN(start_date)                        AS first_promo_date,
    MAX(end_date)                          AS last_promo_date
FROM SILVER.PROMOTIONS_CLEAN
GROUP BY product_category, region
ORDER BY nb_promotions DESC;

-- 2. PROMOTIONS ACTIVES PAR MOIS


WITH months AS (
    SELECT DATEADD('month', SEQ4(), '2020-01-01'::DATE) AS month_start
    FROM TABLE(GENERATOR(ROWCOUNT => 72))  
),
promo_months AS (
    SELECT
        p.promotion_id,
        p.product_category,
        p.region,
        p.discount_pct_display,
        m.month_start
    FROM SILVER.PROMOTIONS_CLEAN p
    JOIN months m
      ON m.month_start BETWEEN DATE_TRUNC('month', p.start_date)
                           AND DATE_TRUNC('month', p.end_date)
)
SELECT
    TO_CHAR(month_start, 'YYYY-MM')   AS month,
    product_category,
    COUNT(*)                          AS nb_active_promotions,
    ROUND(AVG(discount_pct_display), 1) AS avg_discount_pct
FROM promo_months
GROUP BY month_start, product_category
ORDER BY month_start, product_category;

-- 3 – TRANSACTIONS PENDANT VS HORS PÉRIODE PROMOTIONNELLE


WITH promo_periods AS (
    SELECT
        region,
        product_category,
        start_date,
        end_date,
        discount_pct_display
    FROM SILVER.PROMOTIONS_CLEAN
),
sales_tagged AS (
    SELECT
        t.transaction_id,
        t.transaction_date,
        t.amount,
        t.region,
        t.transaction_year,
        t.transaction_month,
        CASE
            WHEN EXISTS (
                SELECT 1
                FROM promo_periods p
                WHERE p.region = t.region
                  AND t.transaction_date BETWEEN p.start_date AND p.end_date
            ) THEN TRUE ELSE FALSE
        END AS is_during_promo,
        (
            SELECT MAX(p.discount_pct_display)
            FROM promo_periods p
            WHERE p.region = t.region
              AND t.transaction_date BETWEEN p.start_date AND p.end_date
        ) AS max_active_discount
    FROM SILVER.FINANCIAL_TRANSACTIONS_CLEAN t
    WHERE transaction_type = 'Sale'
)
SELECT
    is_during_promo,
    COUNT(*)                 AS nb_transactions,
    ROUND(SUM(amount), 2)    AS total_revenue,
    ROUND(AVG(amount), 2)    AS avg_transaction_value,
    ROUND(AVG(max_active_discount), 2) AS avg_discount_applied
FROM sales_tagged
GROUP BY is_during_promo;

-- 4 – SENSIBILITÉ AUX PROMOTIONS PAR RÉGION


WITH promo_periods AS (
    SELECT region, start_date, end_date, discount_pct_display
    FROM SILVER.PROMOTIONS_CLEAN
),
sales_tagged AS (
    SELECT
        t.region,
        t.transaction_year,
        t.amount,
        CASE
            WHEN EXISTS (
                SELECT 1 FROM promo_periods p
                WHERE p.region = t.region
                  AND t.transaction_date BETWEEN p.start_date AND p.end_date
            ) THEN TRUE ELSE FALSE
        END AS is_during_promo
    FROM SILVER.FINANCIAL_TRANSACTIONS_CLEAN t
    WHERE transaction_type = 'Sale'
)
SELECT
    region,
    ROUND(AVG(CASE WHEN is_during_promo     THEN amount END), 2) AS avg_sale_with_promo,
    ROUND(AVG(CASE WHEN NOT is_during_promo THEN amount END), 2) AS avg_sale_without_promo,
    ROUND(
        (AVG(CASE WHEN is_during_promo     THEN amount END)
       - AVG(CASE WHEN NOT is_during_promo THEN amount END))
       / NULLIF(AVG(CASE WHEN NOT is_during_promo THEN amount END), 0) * 100,
    2) AS promo_uplift_pct
FROM sales_tagged
WHERE region IS NOT NULL
GROUP BY region
HAVING AVG(CASE WHEN is_during_promo THEN amount END) IS NOT NULL
   AND AVG(CASE WHEN NOT is_during_promo THEN amount END) IS NOT NULL
ORDER BY promo_uplift_pct DESC;

-- 5 – TOP TYPES DE PROMOTIONS PAR PERFORMANCE


SELECT
    promotion_type,
    product_category,
    COUNT(*)                            AS nb_promotions,
    ROUND(AVG(discount_pct_display), 1) AS avg_discount_pct,
    ROUND(AVG(duration_days), 1)        AS avg_duration_days
FROM SILVER.PROMOTIONS_CLEAN
GROUP BY promotion_type, product_category
ORDER BY nb_promotions DESC
LIMIT 20;


--6 – DURÉE DE PROMOTION ET PERFORMANCE


SELECT
    CASE
        WHEN duration_days <= 7  THEN '1-7 jours'
        WHEN duration_days <= 14 THEN '8-14 jours'
        WHEN duration_days <= 21 THEN '15-21 jours'
        ELSE '> 21 jours'
    END AS promo_duration_bucket,
    COUNT(*)                            AS nb_promotions,
    ROUND(AVG(discount_pct_display), 1) AS avg_discount_pct,
    product_category
FROM SILVER.PROMOTIONS_CLEAN
GROUP BY promo_duration_bucket, product_category
ORDER BY product_category, promo_duration_bucket;
