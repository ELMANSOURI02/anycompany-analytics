USE DATABASE MY_GRP_LAB;
USE WAREHOUSE MY_GRP_WH;

SELECT
    campaign_year,
    COUNT(*) AS nb_campaigns,
    ROUND(SUM(budget), 2) AS total_budget,
    ROUND(AVG(budget), 2) AS avg_budget_per_campaign,
    SUM(reach) AS total_reach,
    SUM(estimated_conversions) AS total_estimated_conversions,
    ROUND(AVG(conversion_rate) * 100, 2) AS avg_conversion_rate_pct
FROM SILVER.MARKETING_CAMPAIGNS_CLEAN
GROUP BY campaign_year
ORDER BY campaign_year;

SELECT
    campaign_type,
    COUNT(*) AS nb_campaigns,
    ROUND(SUM(budget), 2) AS total_budget,
    ROUND(AVG(budget), 2) AS avg_budget,
    SUM(reach) AS total_reach,
    SUM(estimated_conversions) AS total_conversions,
    ROUND(AVG(conversion_rate) * 100, 3) AS avg_conversion_rate_pct,
    ROUND(AVG(cost_per_person), 4) AS avg_cost_per_person,
    ROUND(SUM(estimated_conversions) / NULLIF(SUM(budget), 0) * 1000, 2) AS conversions_per_1k_budget
FROM SILVER.MARKETING_CAMPAIGNS_CLEAN
GROUP BY campaign_type
ORDER BY avg_conversion_rate_pct DESC;

SELECT
    product_category,
    COUNT(*) AS nb_campaigns,
    ROUND(SUM(budget), 2) AS total_budget,
    SUM(estimated_conversions) AS total_conversions,
    ROUND(AVG(conversion_rate) * 100, 3) AS avg_conversion_rate_pct,
    ROUND(SUM(budget) / NULLIF(SUM(estimated_conversions), 0), 2) AS cost_per_conversion
FROM SILVER.MARKETING_CAMPAIGNS_CLEAN
GROUP BY product_category
ORDER BY avg_conversion_rate_pct DESC;

SELECT
    region,
    COUNT(*) AS nb_campaigns,
    ROUND(SUM(budget), 2) AS total_budget,
    SUM(reach) AS total_reach,
    SUM(estimated_conversions) AS total_conversions,
    ROUND(AVG(conversion_rate) * 100, 3) AS avg_conversion_rate_pct,
    ROUND(SUM(budget) / NULLIF(SUM(estimated_conversions), 0), 2) AS cost_per_conversion
FROM SILVER.MARKETING_CAMPAIGNS_CLEAN
WHERE region IS NOT NULL
GROUP BY region
ORDER BY avg_conversion_rate_pct DESC;

SELECT
    target_audience,
    COUNT(*) AS nb_campaigns,
    ROUND(AVG(budget), 2) AS avg_budget,
    ROUND(AVG(conversion_rate) * 100, 3) AS avg_conversion_rate_pct,
    SUM(estimated_conversions) AS total_conversions,
    ROUND(SUM(budget) / NULLIF(SUM(estimated_conversions), 0), 2) AS cost_per_conversion
FROM SILVER.MARKETING_CAMPAIGNS_CLEAN
WHERE target_audience IS NOT NULL
GROUP BY target_audience
ORDER BY avg_conversion_rate_pct DESC;

SELECT
    campaign_id,
    campaign_name,
    campaign_type,
    product_category,
    region,
    target_audience,
    campaign_year,
    ROUND(budget, 2) AS budget,
    reach,
    estimated_conversions,
    ROUND(conversion_rate * 100, 3) AS conversion_rate_pct,
    ROUND(cost_per_person, 4) AS cost_per_person,
    duration_days
FROM SILVER.MARKETING_CAMPAIGNS_CLEAN
ORDER BY conversion_rate DESC
LIMIT 10;

WITH monthly_sales AS (
    SELECT
        region,
        transaction_year AS year,
        transaction_month AS month,
        ROUND(SUM(amount), 2) AS total_sales
    FROM SILVER.FINANCIAL_TRANSACTIONS_CLEAN
    WHERE transaction_type = 'Sale'
    GROUP BY region, transaction_year, transaction_month
),
monthly_campaigns AS (
    SELECT
        region,
        campaign_year AS year,
        MONTH(start_date) AS month,
        ROUND(SUM(budget), 2) AS total_campaign_budget,
        ROUND(AVG(conversion_rate) * 100, 3) AS avg_conversion_rate
    FROM SILVER.MARKETING_CAMPAIGNS_CLEAN
    GROUP BY region, campaign_year, MONTH(start_date)
)
SELECT
    s.region,
    s.year,
    s.month,
    s.total_sales,
    c.total_campaign_budget,
    c.avg_conversion_rate,
    ROUND(s.total_sales / NULLIF(c.total_campaign_budget, 0), 2) AS sales_to_budget_ratio
FROM monthly_sales s
LEFT JOIN monthly_campaigns c
    ON s.region = c.region
    AND s.year = c.year
    AND s.month = c.month
WHERE c.total_campaign_budget IS NOT NULL
ORDER BY s.year, s.month, s.region;

SELECT
    campaign_type,
    product_category,
    COUNT(*) AS nb_campaigns,
    ROUND(AVG(conversion_rate) * 100, 3) AS avg_conversion_pct,
    ROUND(SUM(budget), 0) AS total_budget
FROM SILVER.MARKETING_CAMPAIGNS_CLEAN
GROUP BY campaign_type, product_category
ORDER BY avg_conversion_pct DESC;

WITH campaign_categories AS (
    SELECT DISTINCT LOWER(product_category) AS product_category
    FROM SILVER.MARKETING_CAMPAIGNS_CLEAN
),
reviews_tagged AS (
    SELECT
        r.product_category,
        r.rating,
        r.review_year,
        CASE WHEN c.product_category IS NOT NULL THEN TRUE ELSE FALSE END AS has_campaign
    FROM SILVER.PRODUCT_REVIEWS_CLEAN r
    LEFT JOIN campaign_categories c ON LOWER(r.product_category) = c.product_category
)
SELECT
    product_category,
    has_campaign,
    COUNT(*) AS nb_reviews,
    ROUND(AVG(rating), 2) AS avg_rating
FROM reviews_tagged
GROUP BY product_category, has_campaign
ORDER BY product_category, has_campaign;

SELECT * FROM SILVER.PRODUCT_REVIEWS_CLEAN LIMIT 10;
