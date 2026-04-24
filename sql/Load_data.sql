
-- ÉTAPE 1 – ENVIRONNEMENT

-- Créer la base de données principale
CREATE DATABASE IF NOT EXISTS MY_GRP_LAB;
USE DATABASE MY_GRP_LAB;

-- Créer les schémas
CREATE SCHEMA IF NOT EXISTS BRONZE;  -- Données brutes
CREATE SCHEMA IF NOT EXISTS SILVER;  -- Données nettoyées
CREATE SCHEMA IF NOT EXISTS ANALYTICS; -- Data Products / KPIs

-- Créer un entrepôt de calcul
CREATE WAREHOUSE IF NOT EXISTS MY_GRP_WH
    WITH WAREHOUSE_SIZE = 'SMALL'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE;

USE WAREHOUSE MY_GRP_WH;

-- ÉTAPE 2 – STAGE S3
USE SCHEMA BRONZE;

CREATE OR REPLACE STAGE S3_FOOD_BEVERAGE
    URL = 's3://logbrain-datalake/datasets/food-beverage/'
    FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1 NULL_IF = ('', 'NULL'));

-- Vérifier le contenu du stage
LIST @S3_FOOD_BEVERAGE;

-- ÉTAPE 3 – CRÉATION DES TABLES BRONZE
-- ============================================================

-- 1. customer_demographics
CREATE OR REPLACE TABLE BRONZE.CUSTOMER_DEMOGRAPHICS (
    customer_id       VARCHAR(20),
    name              VARCHAR(150),
    date_of_birth     VARCHAR(20),       -- brut : nettoyage en SILVER
    gender            VARCHAR(20),
    region            VARCHAR(100),
    country           VARCHAR(100),
    city              VARCHAR(100),
    marital_status    VARCHAR(50),
    annual_income     VARCHAR(30)        -- peut contenir espaces/virgules
);

-- 2. customer_service_interactions

CREATE OR REPLACE TABLE BRONZE.CUSTOMER_SERVICE_INTERACTIONS (
    interaction_id        VARCHAR(20),
    customer_id           VARCHAR(20),
    interaction_date      VARCHAR(20),
    interaction_type      VARCHAR(50),
    issue_category        VARCHAR(100),
    description           VARCHAR(2000),
    duration_minutes      VARCHAR(10),
    resolution_status     VARCHAR(50),
    follow_up_required    VARCHAR(10),
    customer_satisfaction VARCHAR(5)
);

-- 3. financial_transactions

CREATE OR REPLACE TABLE BRONZE.FINANCIAL_TRANSACTIONS (
    transaction_id    VARCHAR(20),
    transaction_date  VARCHAR(20),
    transaction_type  VARCHAR(50),
    amount            VARCHAR(30),       -- peut contenir espaces
    payment_method    VARCHAR(50),
    entity            VARCHAR(200),
    region            VARCHAR(100),
    account_code      VARCHAR(20)
);

-- 4. promotions_data

CREATE OR REPLACE TABLE BRONZE.PROMOTIONS_DATA (
    promotion_id          VARCHAR(20),
    product_category      VARCHAR(100),
    promotion_type        VARCHAR(100),
    discount_percentage   VARCHAR(10),
    start_date            VARCHAR(20),
    end_date              VARCHAR(20),
    region                VARCHAR(100)
);

-- 5. marketing_campaigns

CREATE OR REPLACE TABLE BRONZE.MARKETING_CAMPAIGNS (
    campaign_id       VARCHAR(20),
    campaign_name     VARCHAR(200),
    campaign_type     VARCHAR(100),
    product_category  VARCHAR(100),
    target_audience   VARCHAR(100),
    start_date        VARCHAR(20),
    end_date          VARCHAR(20),
    region            VARCHAR(100),
    budget            VARCHAR(30),
    reach             VARCHAR(20),
    conversion_rate   VARCHAR(10)
);

-- 6. product_reviews

CREATE OR REPLACE TABLE BRONZE.PRODUCT_REVIEWS (
    review_id         VARCHAR(20),
    product_id        VARCHAR(50),
    reviewer_id       VARCHAR(50),
    reviewer_name     VARCHAR(150),
    rating            VARCHAR(5),
    review_date       VARCHAR(20),
    review_title      VARCHAR(300),
    review_text       VARCHAR(5000),
    product_category  VARCHAR(100)
);

-- 7. logistics_and_shipping

CREATE OR REPLACE TABLE BRONZE.LOGISTICS_AND_SHIPPING (
    shipment_id          VARCHAR(20),
    order_id             VARCHAR(20),
    ship_date            VARCHAR(20),
    estimated_delivery   VARCHAR(20),
    shipping_method      VARCHAR(50),
    status               VARCHAR(50),
    shipping_cost        VARCHAR(20),
    destination_region   VARCHAR(100),
    destination_country  VARCHAR(100),
    carrier              VARCHAR(200)
);

-- 8. supplier_information

CREATE OR REPLACE TABLE BRONZE.SUPPLIER_INFORMATION (
    supplier_id        VARCHAR(20),
    supplier_name      VARCHAR(200),
    product_category   VARCHAR(100),
    region             VARCHAR(100),
    country            VARCHAR(100),
    city               VARCHAR(100),
    lead_time          VARCHAR(10),
    reliability_score  VARCHAR(10),
    quality_rating     VARCHAR(5)
);

-- 9. employee_records
CREATE OR REPLACE TABLE BRONZE.EMPLOYEE_RECORDS (
    employee_id    VARCHAR(20),
    name           VARCHAR(150),
    date_of_birth  VARCHAR(20),
    hire_date      VARCHAR(20),
    department     VARCHAR(100),
    job_title      VARCHAR(150),
    salary         VARCHAR(30),
    region         VARCHAR(100),
    country        VARCHAR(100),
    email          VARCHAR(200)
);

-- 10. inventory (JSON)

CREATE OR REPLACE TABLE BRONZE.INVENTORY_RAW (
    raw_json VARIANT
);

-- 11. store_locations (JSON)

CREATE OR REPLACE TABLE BRONZE.STORE_LOCATIONS_RAW (
    raw_json VARIANT
);

-- ÉTAPE 4 – CHARGEMENT DES DONNÉES (COPY INTO)

CREATE OR REPLACE FILE FORMAT CSV_FORMAT
    TYPE = 'CSV'
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    SKIP_HEADER = 1
    NULL_IF = ('', 'NULL', 'null')
    EMPTY_FIELD_AS_NULL = TRUE
    TRIM_SPACE = TRUE;

CREATE OR REPLACE FILE FORMAT JSON_FORMAT
    TYPE = 'JSON'
    STRIP_OUTER_ARRAY = TRUE;

-- 1. customer_demographics
COPY INTO BRONZE.CUSTOMER_DEMOGRAPHICS
FROM @S3_FOOD_BEVERAGE/customer_demographics.csv
FILE_FORMAT = (FORMAT_NAME = 'CSV_FORMAT')
ON_ERROR = 'CONTINUE';

-- 2. customer_service_interactions
COPY INTO BRONZE.CUSTOMER_SERVICE_INTERACTIONS
FROM @S3_FOOD_BEVERAGE/customer_service_interactions.csv
FILE_FORMAT = (FORMAT_NAME = 'CSV_FORMAT')
ON_ERROR = 'CONTINUE';

-- 3. financial_transactions
COPY INTO BRONZE.FINANCIAL_TRANSACTIONS
FROM @S3_FOOD_BEVERAGE/financial_transactions.csv
FILE_FORMAT = (FORMAT_NAME = 'CSV_FORMAT')
ON_ERROR = 'CONTINUE';

-- 4. promotions_data
COPY INTO BRONZE.PROMOTIONS_DATA
FROM @S3_FOOD_BEVERAGE/promotions-data.csv
FILE_FORMAT = (FORMAT_NAME = 'CSV_FORMAT')
ON_ERROR = 'CONTINUE';

-- 5. marketing_campaigns
COPY INTO BRONZE.MARKETING_CAMPAIGNS
FROM @S3_FOOD_BEVERAGE/marketing_campaigns.csv
FILE_FORMAT = (FORMAT_NAME = 'CSV_FORMAT')
ON_ERROR = 'CONTINUE';

-- 6. product_reviews
COPY INTO BRONZE.PRODUCT_REVIEWS
FROM @S3_FOOD_BEVERAGE/product_reviews.csv
FILE_FORMAT = (FORMAT_NAME = 'CSV_FORMAT')
ON_ERROR = 'CONTINUE';

-- 7. logistics_and_shipping
COPY INTO BRONZE.LOGISTICS_AND_SHIPPING
FROM @S3_FOOD_BEVERAGE/logistics_and_shipping.csv
FILE_FORMAT = (FORMAT_NAME = 'CSV_FORMAT')
ON_ERROR = 'CONTINUE';

-- 8. supplier_information
COPY INTO BRONZE.SUPPLIER_INFORMATION
FROM @S3_FOOD_BEVERAGE/supplier_information.csv
FILE_FORMAT = (FORMAT_NAME = 'CSV_FORMAT')
ON_ERROR = 'CONTINUE';

-- 9. employee_records
COPY INTO BRONZE.EMPLOYEE_RECORDS
FROM @S3_FOOD_BEVERAGE/employee_records.csv
FILE_FORMAT = (FORMAT_NAME = 'CSV_FORMAT')
ON_ERROR = 'CONTINUE';

-- 10. inventory (JSON)
COPY INTO BRONZE.INVENTORY_RAW (raw_json)
FROM @S3_FOOD_BEVERAGE/inventory.json
FILE_FORMAT = (FORMAT_NAME = 'JSON_FORMAT')
ON_ERROR = 'CONTINUE';

-- 11. store_locations
COPY INTO BRONZE.STORE_LOCATIONS_RAW (raw_json)
FROM @S3_FOOD_BEVERAGE/store_locations.json
FILE_FORMAT = (FORMAT_NAME = 'JSON_FORMAT')
ON_ERROR = 'CONTINUE';

-- Aplatir les JSON en tables relationnelles
CREATE OR REPLACE TABLE BRONZE.INVENTORY AS
SELECT
    raw_json:"product_id"::VARCHAR        AS product_id,
    raw_json:"product_category"::VARCHAR  AS product_category,
    raw_json:"region"::VARCHAR            AS region,
    raw_json:"country"::VARCHAR           AS country,
    raw_json:"warehouse"::VARCHAR         AS warehouse,
    raw_json:"current_stock"::VARCHAR     AS current_stock,
    raw_json:"reorder_point"::VARCHAR     AS reorder_point,
    raw_json:"lead_time"::VARCHAR         AS lead_time,
    raw_json:"last_restock_date"::VARCHAR AS last_restock_date
FROM BRONZE.INVENTORY_RAW;

CREATE OR REPLACE TABLE BRONZE.STORE_LOCATIONS AS
SELECT
    raw_json:"store_id"::VARCHAR       AS store_id,
    raw_json:"store_name"::VARCHAR     AS store_name,
    raw_json:"store_type"::VARCHAR     AS store_type,
    raw_json:"region"::VARCHAR         AS region,
    raw_json:"country"::VARCHAR        AS country,
    raw_json:"city"::VARCHAR           AS city,
    raw_json:"address"::VARCHAR        AS address,
    raw_json:"postal_code"::VARCHAR    AS postal_code,
    raw_json:"square_footage"::VARCHAR AS square_footage,
    raw_json:"employee_count"::VARCHAR AS employee_count
FROM BRONZE.STORE_LOCATIONS_RAW;

-- ÉTAPE 5 – VÉRIFICATIONS

SELECT 'CUSTOMER_DEMOGRAPHICS'        AS table_name, COUNT(*) AS nb_rows FROM BRONZE.CUSTOMER_DEMOGRAPHICS        UNION ALL
SELECT 'CUSTOMER_SERVICE_INTERACTIONS',               COUNT(*) FROM BRONZE.CUSTOMER_SERVICE_INTERACTIONS        UNION ALL
SELECT 'FINANCIAL_TRANSACTIONS',                      COUNT(*) FROM BRONZE.FINANCIAL_TRANSACTIONS               UNION ALL
SELECT 'PROMOTIONS_DATA',                             COUNT(*) FROM BRONZE.PROMOTIONS_DATA                      UNION ALL
SELECT 'MARKETING_CAMPAIGNS',                         COUNT(*) FROM BRONZE.MARKETING_CAMPAIGNS                  UNION ALL
SELECT 'PRODUCT_REVIEWS',                             COUNT(*) FROM BRONZE.PRODUCT_REVIEWS                      UNION ALL
SELECT 'LOGISTICS_AND_SHIPPING',                      COUNT(*) FROM BRONZE.LOGISTICS_AND_SHIPPING               UNION ALL
SELECT 'SUPPLIER_INFORMATION',                        COUNT(*) FROM BRONZE.SUPPLIER_INFORMATION                 UNION ALL
SELECT 'EMPLOYEE_RECORDS',                            COUNT(*) FROM BRONZE.EMPLOYEE_RECORDS                     UNION ALL
SELECT 'INVENTORY',                                   COUNT(*) FROM BRONZE.INVENTORY                            UNION ALL
SELECT 'STORE_LOCATIONS',                             COUNT(*) FROM BRONZE.STORE_LOCATIONS;


-- Échantillon rapide

SELECT * FROM BRONZE.FINANCIAL_TRANSACTIONS LIMIT 10;
SELECT * FROM BRONZE.MARKETING_CAMPAIGNS    LIMIT 10;
SELECT * FROM BRONZE.PROMOTIONS_DATA        LIMIT 10;
