-- AnyCompany Food & Beverage – Phase 3 : Data Product
-- Description : Création des tables analytiques consolidées dans le schéma ANALYTICS (couche Gold)

USE DATABASE MY_GRP_LAB;
USE SCHEMA ANALYTICS;
USE WAREHOUSE MY_GRP_WH;

-- TABLE 1 : ANALYTICS.SALES_ENRICHED (ventes enrichies avec infos promotions et campagnes)

CREATE OR REPLACE TABLE ANALYTICS.SALES_ENRICHED AS
WITH promo_at_sale AS (
    -- Pour chaque transaction, retrouve la promotion active (si existante)
    SELECT
        t.transaction_id,
        MAX(p.promotion_id)          AS promo_id,
        MAX(p.product_category)      AS promo_category,
        MAX(p.promotion_type)        AS promotion_type,
        MAX(p.discount_pct_display)  AS discount_pct,
        TRUE                         AS has_promo
    FROM SILVER.FINANCIAL_TRANSACTIONS_CLEAN t
    JOIN SILVER.PROMOTIONS_CLEAN p
      ON p.region = t.region
     AND t.transaction_date BETWEEN p.start_date AND p.end_date
    GROUP BY t.transaction_id
),
campaign_at_sale AS (
    -- Pour chaque transaction, retrouve la campagne active (si existante)
    SELECT
        t.transaction_id,
        MAX(c.campaign_id)           AS campaign_id,
        MAX(c.campaign_name)         AS campaign_name,
        MAX(c.campaign_type)         AS campaign_type,
        MAX(c.product_category)      AS campaign_category,
        MAX(c.target_audience)       AS target_audience,
        MAX(c.budget)                AS campaign_budget,
        MAX(c.conversion_rate)       AS campaign_conversion_rate,
        TRUE                         AS has_campaign
    FROM SILVER.FINANCIAL_TRANSACTIONS_CLEAN t
    JOIN SILVER.MARKETING_CAMPAIGNS_CLEAN c
      ON c.region = t.region
     AND t.transaction_date BETWEEN c.start_date AND c.end_date
    GROUP BY t.transaction_id
)
SELECT
    -- Clés
    t.transaction_id,
    t.transaction_date,
    t.transaction_year,
    t.transaction_month,
    t.transaction_month_dt,
    -- Données ventes
    t.transaction_type,
    t.amount,
    t.payment_method,
    t.entity,
    t.region,
    t.account_code,
    -- Données promotions
    COALESCE(ps.has_promo, FALSE)    AS has_promotion,
    ps.promo_id,
    ps.promotion_type,
    ps.discount_pct,
    -- Données campagnes
    COALESCE(cs.has_campaign, FALSE) AS has_campaign,
    cs.campaign_id,
    cs.campaign_name,
    cs.campaign_type,
    cs.campaign_category,
    cs.target_audience,
    cs.campaign_budget,
    cs.campaign_conversion_rate,
    -- Métriques dérivées
    IFF(COALESCE(ps.has_promo, FALSE), t.amount * (1 - COALESCE(ps.discount_pct, 0) / 100), t.amount) AS estimated_net_revenue,
    IFF(COALESCE(ps.has_promo, FALSE) OR COALESCE(cs.has_campaign, FALSE), TRUE, FALSE) AS has_marketing_action
FROM SILVER.FINANCIAL_TRANSACTIONS_CLEAN t
LEFT JOIN promo_at_sale    ps ON t.transaction_id = ps.transaction_id
LEFT JOIN campaign_at_sale cs ON t.transaction_id = cs.transaction_id
WHERE t.transaction_type = 'Sale';

-- Documentation
COMMENT ON TABLE ANALYTICS.SALES_ENRICHED IS
'Table analytique Gold : ventes enrichies avec contexte promotionnel et campagne marketing.
Granularité : 1 ligne par transaction de vente.
Sources : SILVER.FINANCIAL_TRANSACTIONS_CLEAN + SILVER.PROMOTIONS_CLEAN + SILVER.MARKETING_CAMPAIGNS_CLEAN.
Champs clés : transaction_id, transaction_date, amount, region, has_promotion, has_campaign.';

SELECT 'ANALYTICS.SALES_ENRICHED' AS table_name, COUNT(*) AS nb_rows FROM ANALYTICS.SALES_ENRICHED;

-- TABLE 2 : ANALYTICS.ACTIVE_PROMOTIONS_SUMMARY (promotions actives avec KPIs agrégés)


CREATE OR REPLACE TABLE ANALYTICS.ACTIVE_PROMOTIONS_SUMMARY AS
WITH months AS (
    SELECT DATEADD('month', SEQ4(), '2015-01-01'::DATE) AS month_start
    FROM TABLE(GENERATOR(ROWCOUNT => 120))
)
SELECT
    p.promotion_id,
    p.product_category,
    p.promotion_type,
    p.discount_pct_display,
    p.duration_days,
    p.region,
    p.start_date,
    p.end_date,
    m.month_start AS active_month,
    TO_CHAR(m.month_start, 'YYYY-MM') AS active_month_label,
    -- Ventes générées pendant la promotion dans la même région
    (
        SELECT ROUND(SUM(t.amount), 2)
        FROM SILVER.FINANCIAL_TRANSACTIONS_CLEAN t
        WHERE t.region = p.region
          AND t.transaction_type = 'Sale'
          AND t.transaction_date BETWEEN p.start_date AND p.end_date
    ) AS total_sales_during_promo
FROM SILVER.PROMOTIONS_CLEAN p
JOIN months m
  ON m.month_start BETWEEN DATE_TRUNC('month', p.start_date)
                       AND DATE_TRUNC('month', p.end_date);

COMMENT ON TABLE ANALYTICS.ACTIVE_PROMOTIONS_SUMMARY IS
'Table analytique Gold : résumé mensuel des promotions actives avec ventes associées.
Granularité : 1 ligne par promotion × mois actif.
Sources : SILVER.PROMOTIONS_CLEAN + SILVER.FINANCIAL_TRANSACTIONS_CLEAN.';

SELECT 'ANALYTICS.ACTIVE_PROMOTIONS_SUMMARY' AS table_name, COUNT(*) AS nb_rows FROM ANALYTICS.ACTIVE_PROMOTIONS_SUMMARY;

-- TABLE 3 : ANALYTICS.CUSTOMER_ENRICHED (démographie + historique service client)


CREATE OR REPLACE TABLE ANALYTICS.CUSTOMER_ENRICHED AS
WITH service_stats AS (
    SELECT
        customer_id,
        COUNT(*)                                                                    AS nb_interactions,
        ROUND(AVG(customer_satisfaction), 2)                                       AS avg_satisfaction,
        ROUND(AVG(duration_minutes), 1)                                            AS avg_call_duration,
        SUM(CASE WHEN resolution_status = 'Resolved'  THEN 1 ELSE 0 END)           AS nb_resolved,
        SUM(CASE WHEN resolution_status = 'Escalated' THEN 1 ELSE 0 END)           AS nb_escalated,
        SUM(CASE WHEN follow_up_required = 'YES'       THEN 1 ELSE 0 END)          AS nb_follow_ups,
        SUM(CASE WHEN issue_category = 'Complaints'    THEN 1 ELSE 0 END)          AS nb_complaints,
        MIN(interaction_date)                                                       AS first_interaction,
        MAX(interaction_date)                                                       AS last_interaction
    FROM SILVER.CUSTOMER_SERVICE_INTERACTIONS_CLEAN
    GROUP BY customer_id
)
SELECT
    d.customer_id,
    d.name,
    d.date_of_birth,
    d.age,
    d.gender,
    d.region,
    d.country,
    d.city,
    d.marital_status,
    d.annual_income,
    -- Segment de revenu
    CASE
        WHEN d.annual_income < 30000  THEN 'Low'
        WHEN d.annual_income < 60000  THEN 'Lower-Mid'
        WHEN d.annual_income < 100000 THEN 'Mid'
        WHEN d.annual_income < 150000 THEN 'Upper-Mid'
        ELSE 'High'
    END AS income_segment,
    -- Segment d'âge
    CASE
        WHEN d.age < 25  THEN 'Gen Z'
        WHEN d.age < 40  THEN 'Millennial'
        WHEN d.age < 55  THEN 'Gen X'
        WHEN d.age < 70  THEN 'Boomer'
        ELSE 'Senior'
    END AS age_segment,
    -- Service client
    COALESCE(s.nb_interactions, 0)     AS nb_interactions,
    COALESCE(s.avg_satisfaction, NULL) AS avg_satisfaction,
    COALESCE(s.avg_call_duration, 0)   AS avg_call_duration,
    COALESCE(s.nb_resolved, 0)         AS nb_resolved,
    COALESCE(s.nb_escalated, 0)        AS nb_escalated,
    COALESCE(s.nb_follow_ups, 0)       AS nb_follow_ups,
    COALESCE(s.nb_complaints, 0)       AS nb_complaints,
    s.first_interaction,
    s.last_interaction,
    -- Score de risque churn simplifié
    CASE
        WHEN COALESCE(s.avg_satisfaction, 3) < 2 OR COALESCE(s.nb_complaints, 0) > 3 THEN 'High'
        WHEN COALESCE(s.avg_satisfaction, 3) < 3 OR COALESCE(s.nb_complaints, 0) > 1 THEN 'Medium'
        ELSE 'Low'
    END AS churn_risk
FROM SILVER.CUSTOMER_DEMOGRAPHICS_CLEAN d
LEFT JOIN service_stats s ON d.customer_id = s.customer_id;

COMMENT ON TABLE ANALYTICS.CUSTOMER_ENRICHED IS
'Table analytique Gold : profil client complet avec démographie et historique service.
Granularité : 1 ligne par client unique.
Sources : SILVER.CUSTOMER_DEMOGRAPHICS_CLEAN + SILVER.CUSTOMER_SERVICE_INTERACTIONS_CLEAN.
Champs clés : customer_id, income_segment, age_segment, churn_risk.';

SELECT 'ANALYTICS.CUSTOMER_ENRICHED' AS table_name, COUNT(*) AS nb_rows FROM ANALYTICS.CUSTOMER_ENRICHED;

-- TABLE 4 : ANALYTICS.CAMPAIGN_ROI (KPIs ROI par campagne avec ventes associées)


CREATE OR REPLACE TABLE ANALYTICS.CAMPAIGN_ROI AS
SELECT
    c.campaign_id,
    c.campaign_name,
    c.campaign_type,
    c.product_category,
    c.target_audience,
    c.start_date,
    c.end_date,
    c.campaign_year,
    c.duration_days,
    c.region,
    c.budget,
    c.reach,
    c.conversion_rate,
    c.estimated_conversions,
    c.cost_per_person,
    -- Ventes de la région pendant la campagne
    (
        SELECT ROUND(SUM(t.amount), 2)
        FROM SILVER.FINANCIAL_TRANSACTIONS_CLEAN t
        WHERE t.region = c.region
          AND t.transaction_type = 'Sale'
          AND t.transaction_date BETWEEN c.start_date AND c.end_date
    ) AS sales_during_campaign,
    -- ROI estimé
    ROUND(
        (
            SELECT SUM(t.amount)
            FROM SILVER.FINANCIAL_TRANSACTIONS_CLEAN t
            WHERE t.region = c.region
              AND t.transaction_type = 'Sale'
              AND t.transaction_date BETWEEN c.start_date AND c.end_date
        ) / NULLIF(c.budget, 0),
    2) AS estimated_roi_ratio,
    -- Efficacité : conversions pour 1000 $ de budget
    ROUND(c.estimated_conversions / NULLIF(c.budget, 0) * 1000, 2) AS conversions_per_1k
FROM SILVER.MARKETING_CAMPAIGNS_CLEAN c;

COMMENT ON TABLE ANALYTICS.CAMPAIGN_ROI IS
'Table analytique Gold : ROI des campagnes marketing avec ventes associées par région et période.
Granularité : 1 ligne par campagne.
Sources : SILVER.MARKETING_CAMPAIGNS_CLEAN + SILVER.FINANCIAL_TRANSACTIONS_CLEAN.';

SELECT 'ANALYTICS.CAMPAIGN_ROI' AS table_name, COUNT(*) AS nb_rows FROM ANALYTICS.CAMPAIGN_ROI;

-- RÉCAPITULATIF ANALYTICS

SELECT 'SALES_ENRICHED'             AS table_name, COUNT(*) AS nb_rows FROM ANALYTICS.SALES_ENRICHED             UNION ALL
SELECT 'ACTIVE_PROMOTIONS_SUMMARY',                COUNT(*) FROM ANALYTICS.ACTIVE_PROMOTIONS_SUMMARY             UNION ALL
SELECT 'CUSTOMER_ENRICHED',                        COUNT(*) FROM ANALYTICS.CUSTOMER_ENRICHED                     UNION ALL
SELECT 'CAMPAIGN_ROI',                             COUNT(*) FROM ANALYTICS.CAMPAIGN_ROI;
