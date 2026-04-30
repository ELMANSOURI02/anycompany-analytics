USE ROLE SYSADMIN;
USE DATABASE MY_GRP_LAB;
USE WAREHOUSE MY_GRP_WH;
SHOW DATABASES;
-- Analyse de l'évolution des ventes, performance par catégorie, région et segment
USE DATABASE MY_GRP_LAB;
USE WAREHOUSE MY_GRP_WH;
-- 1 – ÉVOLUTION GLOBALE DES VENTES DANS LE TEMPS
-- Ventes mensuelles (montant total et nombre de transactions)
SELECT
    transaction_month_dt                          AS month,
    TO_CHAR(transaction_month_dt, 'YYYY-MM')      AS month_label,
    COUNT(*)                                      AS nb_transactions,
    ROUND(SUM(amount), 2)                         AS total_revenue,
    ROUND(AVG(amount), 2)                         AS avg_transaction,
    ROUND(SUM(amount) - LAG(SUM(amount)) OVER (ORDER BY transaction_month_dt), 2) AS mom_delta,
    ROUND(
        (SUM(amount) - LAG(SUM(amount)) OVER (ORDER BY transaction_month_dt))
        / NULLIF(LAG(SUM(amount)) OVER (ORDER BY transaction_month_dt), 0) * 100,
    2) AS mom_growth_pct
FROM SILVER.FINANCIAL_TRANSACTIONS_CLEAN
WHERE transaction_type = 'Sale'
GROUP BY transaction_month_dt
ORDER BY transaction_month_dt;

-- Ventes annuelles avec croissance
SELECT
    transaction_year                                                             AS year,
    COUNT(*)                                                                     AS nb_transactions,
    ROUND(SUM(amount), 2)                                                        AS total_revenue,
    ROUND(AVG(amount), 2)                                                        AS avg_transaction,
    ROUND(
        (SUM(amount) - LAG(SUM(amount)) OVER (ORDER BY transaction_year))
        / NULLIF(LAG(SUM(amount)) OVER (ORDER BY transaction_year), 0) * 100,
    2) AS yoy_growth_pct
FROM SILVER.FINANCIAL_TRANSACTIONS_CLEAN
WHERE transaction_type = 'Sale'
GROUP BY transaction_year
ORDER BY transaction_year;
-- 2 PERFORMANCE PAR RÉGION
SELECT
    region,
    COUNT(*)                 AS nb_transactions,
    ROUND(SUM(amount), 2)    AS total_revenue,
    ROUND(AVG(amount), 2)    AS avg_transaction,
    ROUND(100 * SUM(amount) / SUM(SUM(amount)) OVER (), 2) AS revenue_share_pct
FROM SILVER.FINANCIAL_TRANSACTIONS_CLEAN
WHERE transaction_type = 'Sale'
  AND region IS NOT NULL
GROUP BY region
ORDER BY total_revenue DESC;

-- Top régions par an
SELECT
    transaction_year,
    region,
    ROUND(SUM(amount), 2) AS total_revenue,
    RANK() OVER (PARTITION BY transaction_year ORDER BY SUM(amount) DESC) AS rank_in_year
FROM SILVER.FINANCIAL_TRANSACTIONS_CLEAN
WHERE transaction_type = 'Sale'
  AND region IS NOT NULL
GROUP BY transaction_year, region
ORDER BY transaction_year, rank_in_year;

-- 3 – PERFORMANCE PAR MODE DE PAIEMENT

SELECT
    payment_method,
    COUNT(*)                AS nb_transactions,
    ROUND(SUM(amount), 2)   AS total_revenue,
    ROUND(AVG(amount), 2)   AS avg_amount,
    ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_transactions
FROM SILVER.FINANCIAL_TRANSACTIONS_CLEAN
WHERE transaction_type = 'Sale'
GROUP BY payment_method
ORDER BY total_revenue DESC;

-- 4 – RÉPARTITION DES TYPES DE TRANSACTIONS

SELECT
    transaction_type,
    COUNT(*)               AS nb_transactions,
    ROUND(SUM(amount), 2)  AS total_amount,
    ROUND(AVG(amount), 2)  AS avg_amount
FROM SILVER.FINANCIAL_TRANSACTIONS_CLEAN
GROUP BY transaction_type
ORDER BY total_amount DESC;

-- 2.5 – SEGMENTATION CLIENTS

-- Répartition par région
SELECT
    region,
    COUNT(*)                                                         AS nb_customers,
    ROUND(AVG(annual_income), 2)                                     AS avg_income,
    ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 2)                 AS pct_customers
FROM SILVER.CUSTOMER_DEMOGRAPHICS_CLEAN
WHERE region IS NOT NULL
GROUP BY region
ORDER BY nb_customers DESC;

-- Répartition par genre
SELECT
    gender,
    COUNT(*)                                         AS nb_customers,
    ROUND(AVG(annual_income), 2)                     AS avg_income,
    ROUND(AVG(age), 1)                               AS avg_age
FROM SILVER.CUSTOMER_DEMOGRAPHICS_CLEAN
GROUP BY gender
ORDER BY nb_customers DESC;

-- Répartition par statut marital
SELECT
    marital_status,
    COUNT(*)                     AS nb_customers,
    ROUND(AVG(annual_income), 2) AS avg_income
FROM SILVER.CUSTOMER_DEMOGRAPHICS_CLEAN
WHERE marital_status IS NOT NULL
GROUP BY marital_status
ORDER BY nb_customers DESC;

-- Segments de revenus
SELECT
    CASE
        WHEN annual_income < 30000  THEN '< 30K'
        WHEN annual_income < 60000  THEN '30K–60K'
        WHEN annual_income < 100000 THEN '60K–100K'
        WHEN annual_income < 150000 THEN '100K–150K'
        ELSE '> 150K'
    END AS income_segment,
    COUNT(*) AS nb_customers,
    ROUND(AVG(annual_income), 2) AS avg_income
FROM SILVER.CUSTOMER_DEMOGRAPHICS_CLEAN
WHERE annual_income IS NOT NULL
GROUP BY income_segment
ORDER BY avg_income;

--6 – AVIS PRODUITS : DISTRIBUTION DES NOTES

-- Note moyenne par catégorie
SELECT
    product_category,
    COUNT(*)                  AS nb_reviews,
    ROUND(AVG(rating), 2)     AS avg_rating,
    SUM(CASE WHEN rating = 5 THEN 1 ELSE 0 END) AS five_stars,
    SUM(CASE WHEN rating = 1 THEN 1 ELSE 0 END) AS one_star,
    SUM(CASE WHEN sentiment = 'Positive' THEN 1 ELSE 0 END) AS positive_reviews,
    ROUND(100 * SUM(CASE WHEN sentiment = 'Positive' THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_positive
FROM SILVER.PRODUCT_REVIEWS_CLEAN
GROUP BY product_category
ORDER BY avg_rating DESC;

-- Évolution de la satisfaction dans le temps
SELECT
    review_year,
    ROUND(AVG(rating), 2)  AS avg_rating,
    COUNT(*)               AS nb_reviews
FROM SILVER.PRODUCT_REVIEWS_CLEAN
GROUP BY review_year
ORDER BY review_year;

-- 7 – SERVICE CLIENT : PERFORMANCE ET SATISFACTION

-- Taux de résolution par type d'interaction
SELECT
    interaction_type,
    resolution_status,
    COUNT(*) AS nb_interactions,
    ROUND(AVG(customer_satisfaction), 2) AS avg_satisfaction,
    ROUND(AVG(duration_minutes), 1)      AS avg_duration_min
FROM SILVER.CUSTOMER_SERVICE_INTERACTIONS_CLEAN
GROUP BY interaction_type, resolution_status
ORDER BY interaction_type, nb_interactions DESC;

-- Évolution de la satisfaction client par année
SELECT
    interaction_year,
    ROUND(AVG(customer_satisfaction), 2) AS avg_satisfaction,
    COUNT(*) AS nb_interactions,
    SUM(CASE WHEN resolution_status = 'Resolved' THEN 1 ELSE 0 END) AS resolved,
    ROUND(100 * SUM(CASE WHEN resolution_status = 'Resolved' THEN 1 ELSE 0 END) / COUNT(*), 1) AS resolution_rate_pct
FROM SILVER.CUSTOMER_SERVICE_INTERACTIONS_CLEAN
GROUP BY interaction_year
ORDER BY interaction_year;
-- 8 – LOGISTIQUE : PERFORMANCE DE LIVRAISON

-- Délai moyen par méthode d'expédition
SELECT
    shipping_method,
    status,
    COUNT(*)                         AS nb_shipments,
    ROUND(AVG(delivery_days), 1)     AS avg_delivery_days,
    ROUND(AVG(shipping_cost), 2)     AS avg_shipping_cost
FROM SILVER.LOGISTICS_SHIPPING_CLEAN
GROUP BY shipping_method, status
ORDER BY shipping_method, nb_shipments DESC;

-- Performance par région de destination
SELECT
    destination_region,
    COUNT(*)                                                              AS nb_shipments,
    ROUND(AVG(delivery_days), 1)                                          AS avg_delivery_days,
    SUM(CASE WHEN status = 'Delivered' THEN 1 ELSE 0 END)                AS delivered,
    ROUND(100 * SUM(CASE WHEN status = 'Delivered' THEN 1 ELSE 0 END)
               / COUNT(*), 1)                                            AS delivery_rate_pct
FROM SILVER.LOGISTICS_SHIPPING_CLEAN
WHERE destination_region IS NOT NULL
GROUP BY destination_region
ORDER BY nb_shipments DESC;

-- 9 – FOURNISSEURS : QUALITÉ ET FIABILITÉ


SELECT
    product_category,
    quality_rating,
    COUNT(*)                          AS nb_suppliers,
    ROUND(AVG(reliability_score), 2)  AS avg_reliability,
    ROUND(AVG(lead_time_days), 1)     AS avg_lead_time
FROM SILVER.SUPPLIER_INFORMATION_CLEAN
GROUP BY product_category, quality_rating
ORDER BY product_category, quality_rating;

-- 10  INVENTAIRE : RISQUE DE RUPTURE

SELECT
    product_category,
    region,
    COUNT(*) AS nb_products,
    SUM(current_stock) AS total_stock,
    SUM(CASE WHEN reorder_needed THEN 1 ELSE 0 END) AS products_at_risk,
    ROUND(100 * SUM(CASE WHEN reorder_needed THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_at_risk
FROM SILVER.INVENTORY_CLEAN
GROUP BY product_category, region
ORDER BY pct_at_risk DESC;

