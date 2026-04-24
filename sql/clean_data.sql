
-- Description : Création des tables SILVER nettoyées
--               à partir des tables BRONZE brutes


USE DATABASE MY_GRP_LAB;
USE SCHEMA SILVER;
USE WAREHOUSE MY_GRP_WH;


-- 1. SILVER.CUSTOMER_DEMOGRAPHICS_CLEAN


CREATE OR REPLACE TABLE SILVER.CUSTOMER_DEMOGRAPHICS_CLEAN AS
WITH deduped AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY name) AS rn
    FROM BRONZE.CUSTOMER_DEMOGRAPHICS
    WHERE customer_id IS NOT NULL
)
SELECT
    customer_id,
    TRIM(name)                                                        AS name,
    TRY_TO_DATE(date_of_birth, 'YYYY-MM-DD')                          AS date_of_birth,
    DATEDIFF('year', TRY_TO_DATE(date_of_birth,'YYYY-MM-DD'), CURRENT_DATE) AS age,
    INITCAP(TRIM(gender))                                             AS gender,
    INITCAP(TRIM(region))                                             AS region,
    INITCAP(TRIM(country))                                            AS country,
    INITCAP(TRIM(city))                                               AS city,
    INITCAP(TRIM(marital_status))                                     AS marital_status,
    TRY_TO_NUMBER(REPLACE(REPLACE(annual_income, ' ', ''), ',', '.')) AS annual_income
FROM deduped
WHERE rn = 1
  AND TRY_TO_DATE(date_of_birth, 'YYYY-MM-DD') IS NOT NULL;

SELECT 'SILVER.CUSTOMER_DEMOGRAPHICS_CLEAN' AS table_name, COUNT(*) AS nb_rows
FROM SILVER.CUSTOMER_DEMOGRAPHICS_CLEAN;


-- 2. SILVER.CUSTOMER_SERVICE_INTERACTIONS_CLEAN

CREATE OR REPLACE TABLE SILVER.CUSTOMER_SERVICE_INTERACTIONS_CLEAN AS
WITH deduped AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY interaction_id ORDER BY interaction_date) AS rn
    FROM BRONZE.CUSTOMER_SERVICE_INTERACTIONS
    WHERE interaction_id IS NOT NULL
)
SELECT
    interaction_id,
    customer_id,
    TRY_TO_DATE(interaction_date, 'YYYY-MM-DD')          AS interaction_date,
    YEAR(TRY_TO_DATE(interaction_date, 'YYYY-MM-DD'))    AS interaction_year,
    TRIM(interaction_type)                               AS interaction_type,
    TRIM(issue_category)                                 AS issue_category,
    TRIM(description)                                    AS description,
    TRY_TO_NUMBER(TRIM(duration_minutes))                AS duration_minutes,
    TRIM(resolution_status)                              AS resolution_status,
    UPPER(TRIM(follow_up_required))                      AS follow_up_required,
    TRY_TO_NUMBER(TRIM(customer_satisfaction))           AS customer_satisfaction
FROM deduped
WHERE rn = 1
  AND TRY_TO_DATE(interaction_date, 'YYYY-MM-DD') IS NOT NULL
  AND TRY_TO_NUMBER(TRIM(customer_satisfaction)) BETWEEN 1 AND 5;

SELECT 'SILVER.CUSTOMER_SERVICE_INTERACTIONS_CLEAN' AS table_name, COUNT(*) AS nb_rows
FROM SILVER.CUSTOMER_SERVICE_INTERACTIONS_CLEAN;

-- 3. SILVER.FINANCIAL_TRANSACTIONS_CLEAN

CREATE OR REPLACE TABLE SILVER.FINANCIAL_TRANSACTIONS_CLEAN AS
WITH deduped AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY transaction_id ORDER BY transaction_date) AS rn
    FROM BRONZE.FINANCIAL_TRANSACTIONS
    WHERE transaction_id IS NOT NULL
)
SELECT
    transaction_id,
    TRY_TO_DATE(transaction_date, 'YYYY-MM-DD')                           AS transaction_date,
    YEAR(TRY_TO_DATE(transaction_date, 'YYYY-MM-DD'))                     AS transaction_year,
    MONTH(TRY_TO_DATE(transaction_date, 'YYYY-MM-DD'))                    AS transaction_month,
    DATE_TRUNC('month', TRY_TO_DATE(transaction_date, 'YYYY-MM-DD'))      AS transaction_month_dt,
    TRIM(transaction_type)                                                AS transaction_type,
    TRY_TO_NUMBER(REPLACE(REPLACE(amount, ' ', ''), ',', '.'), 10, 2)    AS amount,
    TRIM(payment_method)                                                  AS payment_method,
    TRIM(entity)                                                          AS entity,
    TRIM(region)                                                          AS region,
    TRIM(account_code)                                                    AS account_code
FROM deduped
WHERE rn = 1
  AND TRY_TO_DATE(transaction_date, 'YYYY-MM-DD') IS NOT NULL
  AND TRY_TO_NUMBER(REPLACE(REPLACE(amount, ' ', ''), ',', '.'), 10, 2) > 0;

SELECT 'SILVER.FINANCIAL_TRANSACTIONS_CLEAN' AS table_name, COUNT(*) AS nb_rows
FROM SILVER.FINANCIAL_TRANSACTIONS_CLEAN;

-- 4. SILVER.PROMOTIONS_CLEAN


CREATE OR REPLACE TABLE SILVER.PROMOTIONS_CLEAN AS
WITH deduped AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY promotion_id ORDER BY start_date) AS rn
    FROM BRONZE.PROMOTIONS_DATA
    WHERE promotion_id IS NOT NULL
)
SELECT
    promotion_id,
    TRIM(product_category)                                   AS product_category,
    TRIM(promotion_type)                                     AS promotion_type,
    TRY_TO_NUMBER(TRIM(discount_percentage), 5, 2)           AS discount_percentage,
    ROUND(TRY_TO_NUMBER(TRIM(discount_percentage), 5, 2)
          * 100, 1)                                          AS discount_pct_display,
    TRY_TO_DATE(start_date, 'YYYY-MM-DD')                    AS start_date,
    TRY_TO_DATE(end_date,   'YYYY-MM-DD')                    AS end_date,
    DATEDIFF('day',
             TRY_TO_DATE(start_date, 'YYYY-MM-DD'),
             TRY_TO_DATE(end_date,   'YYYY-MM-DD'))          AS duration_days,
    TRIM(region)                                             AS region
FROM deduped
WHERE rn = 1
  AND TRY_TO_DATE(start_date, 'YYYY-MM-DD') IS NOT NULL
  AND TRY_TO_DATE(end_date,   'YYYY-MM-DD') IS NOT NULL
  AND TRY_TO_DATE(end_date,   'YYYY-MM-DD') >= TRY_TO_DATE(start_date, 'YYYY-MM-DD')
  AND TRY_TO_NUMBER(TRIM(discount_percentage), 5, 2) BETWEEN 0 AND 1;

SELECT 'SILVER.PROMOTIONS_CLEAN' AS table_name, COUNT(*) AS nb_rows
FROM SILVER.PROMOTIONS_CLEAN;

-- 5. SILVER.MARKETING_CAMPAIGNS_CLEAN


CREATE OR REPLACE TABLE SILVER.MARKETING_CAMPAIGNS_CLEAN AS
WITH deduped AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY campaign_id ORDER BY start_date) AS rn
    FROM BRONZE.MARKETING_CAMPAIGNS
    WHERE campaign_id IS NOT NULL
)
SELECT
    campaign_id,
    TRIM(campaign_name)                                                        AS campaign_name,
    TRIM(campaign_type)                                                        AS campaign_type,
    TRIM(product_category)                                                     AS product_category,
    TRIM(target_audience)                                                      AS target_audience,
    TRY_TO_DATE(start_date, 'YYYY-MM-DD')                                      AS start_date,
    TRY_TO_DATE(end_date,   'YYYY-MM-DD')                                      AS end_date,
    YEAR(TRY_TO_DATE(start_date, 'YYYY-MM-DD'))                                AS campaign_year,
    DATEDIFF('day',
             TRY_TO_DATE(start_date, 'YYYY-MM-DD'),
             TRY_TO_DATE(end_date,   'YYYY-MM-DD'))                            AS duration_days,
    TRIM(region)                                                               AS region,
    TRY_TO_NUMBER(REPLACE(REPLACE(budget, ' ', ''), ',', '.'), 12, 2)         AS budget,
    TRY_TO_NUMBER(REPLACE(reach, ' ', ''))                                     AS reach,
    TRY_TO_NUMBER(TRIM(conversion_rate), 6, 4)                                 AS conversion_rate,
    -- Coût par lead estimé
    IFF(TRY_TO_NUMBER(REPLACE(reach, ' ', '')) > 0,
        TRY_TO_NUMBER(REPLACE(REPLACE(budget, ' ', ''), ',', '.'), 12, 2)
        / TRY_TO_NUMBER(REPLACE(reach, ' ', '')),
        NULL)                                                                  AS cost_per_person,
    -- Leads estimés
    ROUND(TRY_TO_NUMBER(REPLACE(reach, ' ', ''))
          * TRY_TO_NUMBER(TRIM(conversion_rate), 6, 4))                        AS estimated_conversions
FROM deduped
WHERE rn = 1
  AND TRY_TO_DATE(start_date, 'YYYY-MM-DD') IS NOT NULL
  AND TRY_TO_NUMBER(REPLACE(REPLACE(budget, ' ', ''), ',', '.'), 12, 2) > 0
  AND TRY_TO_NUMBER(TRIM(conversion_rate), 6, 4) BETWEEN 0 AND 1;

SELECT 'SILVER.MARKETING_CAMPAIGNS_CLEAN' AS table_name, COUNT(*) AS nb_rows
FROM SILVER.MARKETING_CAMPAIGNS_CLEAN;

-- 6_ SILVER.PRODUCT_REVIEWS_CLEAN

CREATE OR REPLACE TABLE SILVER.PRODUCT_REVIEWS_CLEAN AS
WITH deduped AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY review_id ORDER BY review_date) AS rn
    FROM BRONZE.PRODUCT_REVIEWS
    WHERE review_id IS NOT NULL
)
SELECT
    review_id,
    TRIM(product_id)                                     AS product_id,
    TRIM(reviewer_id)                                    AS reviewer_id,
    TRIM(reviewer_name)                                  AS reviewer_name,
    TRY_TO_NUMBER(TRIM(rating))                          AS rating,
    TRY_TO_DATE(review_date, 'YYYY-MM-DD')               AS review_date,
    YEAR(TRY_TO_DATE(review_date, 'YYYY-MM-DD'))         AS review_year,
    TRIM(review_title)                                   AS review_title,
    TRIM(review_text)                                    AS review_text,
    TRIM(product_category)                               AS product_category,
    -- Sentiment simplifié basé sur le rating
    CASE
        WHEN TRY_TO_NUMBER(TRIM(rating)) >= 4 THEN 'Positive'
        WHEN TRY_TO_NUMBER(TRIM(rating)) = 3  THEN 'Neutral'
        ELSE 'Negative'
    END AS sentiment
FROM deduped
WHERE rn = 1
  AND TRY_TO_DATE(review_date, 'YYYY-MM-DD') IS NOT NULL
  AND TRY_TO_NUMBER(TRIM(rating)) BETWEEN 1 AND 5;

SELECT 'SILVER.PRODUCT_REVIEWS_CLEAN' AS table_name, COUNT(*) AS nb_rows
FROM SILVER.PRODUCT_REVIEWS_CLEAN;

-- 7- SILVER.LOGISTICS_SHIPPING_CLEAN

CREATE OR REPLACE TABLE SILVER.LOGISTICS_SHIPPING_CLEAN AS
WITH deduped AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY shipment_id ORDER BY ship_date) AS rn
    FROM BRONZE.LOGISTICS_AND_SHIPPING
    WHERE shipment_id IS NOT NULL
)
SELECT
    shipment_id,
    TRIM(order_id)                                                       AS order_id,
    TRY_TO_DATE(ship_date, 'YYYY-MM-DD')                                 AS ship_date,
    TRY_TO_DATE(estimated_delivery, 'YYYY-MM-DD')                        AS estimated_delivery,
    DATEDIFF('day',
             TRY_TO_DATE(ship_date, 'YYYY-MM-DD'),
             TRY_TO_DATE(estimated_delivery, 'YYYY-MM-DD'))              AS delivery_days,
    TRIM(shipping_method)                                                AS shipping_method,
    TRIM(status)                                                         AS status,
    TRY_TO_NUMBER(REPLACE(REPLACE(shipping_cost, ' ', ''), ',', '.'), 10, 2) AS shipping_cost,
    TRIM(destination_region)                                             AS destination_region,
    TRIM(destination_country)                                            AS destination_country,
    TRIM(carrier)                                                        AS carrier
FROM deduped
WHERE rn = 1
  AND TRY_TO_DATE(ship_date, 'YYYY-MM-DD') IS NOT NULL
  AND TRY_TO_NUMBER(REPLACE(REPLACE(shipping_cost, ' ', ''), ',', '.'), 10, 2) > 0;

SELECT 'SILVER.LOGISTICS_SHIPPING_CLEAN' AS table_name, COUNT(*) AS nb_rows
FROM SILVER.LOGISTICS_SHIPPING_CLEAN;

-- 8_ SILVER.SUPPLIER_INFORMATION_CLEAN

CREATE OR REPLACE TABLE SILVER.SUPPLIER_INFORMATION_CLEAN AS
WITH deduped AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY supplier_id ORDER BY supplier_name) AS rn
    FROM BRONZE.SUPPLIER_INFORMATION
    WHERE supplier_id IS NOT NULL
)
SELECT
    supplier_id,
    TRIM(supplier_name)                          AS supplier_name,
    TRIM(product_category)                       AS product_category,
    INITCAP(TRIM(region))                        AS region,
    INITCAP(TRIM(country))                       AS country,
    INITCAP(TRIM(city))                          AS city,
    TRY_TO_NUMBER(TRIM(lead_time))               AS lead_time_days,
    TRY_TO_NUMBER(TRIM(reliability_score), 4, 2) AS reliability_score,
    UPPER(TRIM(quality_rating))                  AS quality_rating
FROM deduped
WHERE rn = 1
  AND TRY_TO_NUMBER(TRIM(lead_time))               IS NOT NULL
  AND TRY_TO_NUMBER(TRIM(reliability_score), 4, 2) BETWEEN 0 AND 1;

SELECT 'SILVER.SUPPLIER_INFORMATION_CLEAN' AS table_name, COUNT(*) AS nb_rows
FROM SILVER.SUPPLIER_INFORMATION_CLEAN;

-- 9. SILVER.EMPLOYEE_RECORDS_CLEAN

CREATE OR REPLACE TABLE SILVER.EMPLOYEE_RECORDS_CLEAN AS
WITH deduped AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY employee_id ORDER BY hire_date) AS rn
    FROM BRONZE.EMPLOYEE_RECORDS
    WHERE employee_id IS NOT NULL
)
SELECT
    employee_id,
    TRIM(name)                                                              AS name,
    TRY_TO_DATE(date_of_birth, 'YYYY-MM-DD')                               AS date_of_birth,
    TRY_TO_DATE(hire_date, 'YYYY-MM-DD')                                    AS hire_date,
    YEAR(TRY_TO_DATE(hire_date, 'YYYY-MM-DD'))                              AS hire_year,
    DATEDIFF('year',
             TRY_TO_DATE(hire_date, 'YYYY-MM-DD'),
             CURRENT_DATE)                                                  AS tenure_years,
    TRIM(department)                                                        AS department,
    TRIM(job_title)                                                         AS job_title,
    TRY_TO_NUMBER(REPLACE(REPLACE(salary, ' ', ''), ',', '.'), 12, 2)      AS salary,
    INITCAP(TRIM(region))                                                   AS region,
    INITCAP(TRIM(country))                                                  AS country,
    LOWER(TRIM(email))                                                      AS email
FROM deduped
WHERE rn = 1
  AND TRY_TO_DATE(hire_date, 'YYYY-MM-DD') IS NOT NULL
  AND TRY_TO_NUMBER(REPLACE(REPLACE(salary, ' ', ''), ',', '.'), 12, 2) > 0;

SELECT 'SILVER.EMPLOYEE_RECORDS_CLEAN' AS table_name, COUNT(*) AS nb_rows
FROM SILVER.EMPLOYEE_RECORDS_CLEAN;

-- 10. SILVER.INVENTORY_CLEAN

CREATE OR REPLACE TABLE SILVER.INVENTORY_CLEAN AS
SELECT
    TRIM(product_id)                                         AS product_id,
    TRIM(product_category)                                   AS product_category,
    INITCAP(TRIM(region))                                    AS region,
    INITCAP(TRIM(country))                                   AS country,
    TRIM(warehouse)                                          AS warehouse,
    TRY_TO_NUMBER(TRIM(current_stock))                       AS current_stock,
    TRY_TO_NUMBER(TRIM(reorder_point))                       AS reorder_point,
    TRY_TO_NUMBER(TRIM(lead_time))                           AS lead_time_days,
    TRY_TO_DATE(last_restock_date, 'YYYY-MM-DD')             AS last_restock_date,
    -- Flag rupture imminente
    IFF(TRY_TO_NUMBER(TRIM(current_stock)) <=
        TRY_TO_NUMBER(TRIM(reorder_point)), TRUE, FALSE)     AS reorder_needed
FROM BRONZE.INVENTORY
WHERE product_id IS NOT NULL
  AND TRY_TO_NUMBER(TRIM(current_stock)) >= 0;

SELECT 'SILVER.INVENTORY_CLEAN' AS table_name, COUNT(*) AS nb_rows
FROM SILVER.INVENTORY_CLEAN;

-- 11. SILVER.STORE_LOCATIONS_CLEAN
CREATE OR REPLACE TABLE SILVER.STORE_LOCATIONS_CLEAN AS
WITH deduped AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY store_id ORDER BY store_name) AS rn
    FROM BRONZE.STORE_LOCATIONS
    WHERE store_id IS NOT NULL
)
SELECT
    store_id,
    TRIM(store_name)                           AS store_name,
    TRIM(store_type)                           AS store_type,
    INITCAP(TRIM(region))                      AS region,
    INITCAP(TRIM(country))                     AS country,
    INITCAP(TRIM(city))                        AS city,
    TRIM(address)                              AS address,
    TRY_TO_NUMBER(TRIM(postal_code))           AS postal_code,
    TRY_TO_NUMBER(TRIM(square_footage), 10, 2) AS square_footage,
    TRY_TO_NUMBER(TRIM(employee_count))        AS employee_count
FROM deduped
WHERE rn = 1;

SELECT 'SILVER.STORE_LOCATIONS_CLEAN' AS table_name, COUNT(*) AS nb_rows
FROM SILVER.STORE_LOCATIONS_CLEAN;

-- 
-- RÉCAPITULATIF SILVER


SELECT 'CUSTOMER_DEMOGRAPHICS_CLEAN'        AS table_name, COUNT(*) AS nb_rows FROM SILVER.CUSTOMER_DEMOGRAPHICS_CLEAN        UNION ALL
SELECT 'CUSTOMER_SERVICE_INTERACTIONS_CLEAN',               COUNT(*) FROM SILVER.CUSTOMER_SERVICE_INTERACTIONS_CLEAN        UNION ALL
SELECT 'FINANCIAL_TRANSACTIONS_CLEAN',                      COUNT(*) FROM SILVER.FINANCIAL_TRANSACTIONS_CLEAN               UNION ALL
SELECT 'PROMOTIONS_CLEAN',                                  COUNT(*) FROM SILVER.PROMOTIONS_CLEAN                           UNION ALL
SELECT 'MARKETING_CAMPAIGNS_CLEAN',                         COUNT(*) FROM SILVER.MARKETING_CAMPAIGNS_CLEAN                  UNION ALL
SELECT 'PRODUCT_REVIEWS_CLEAN',                             COUNT(*) FROM SILVER.PRODUCT_REVIEWS_CLEAN                      UNION ALL
SELECT 'LOGISTICS_SHIPPING_CLEAN',                          COUNT(*) FROM SILVER.LOGISTICS_SHIPPING_CLEAN                   UNION ALL
SELECT 'SUPPLIER_INFORMATION_CLEAN',                        COUNT(*) FROM SILVER.SUPPLIER_INFORMATION_CLEAN                 UNION ALL
SELECT 'EMPLOYEE_RECORDS_CLEAN',                            COUNT(*) FROM SILVER.EMPLOYEE_RECORDS_CLEAN                     UNION ALL
SELECT 'INVENTORY_CLEAN',                                   COUNT(*) FROM SILVER.INVENTORY_CLEAN                            UNION ALL
SELECT 'STORE_LOCATIONS_CLEAN',                             COUNT(*) FROM SILVER.STORE_LOCATIONS_CLEAN;
