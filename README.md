# Architecture Big Data — ESG MBA 2026

**Équipe** : El Mansouri Nada · Laifa Djazira · Abakhchouch Basma  
**Stack** : Snowflake · Streamlit · Python · Snowpark · XGBoost

---

## Structure du projet

```
anycompany-analytics/
├── sql/                        ← Projet 1 : SQL ETL + Analyses
│   ├── Load_data.sql           
│   ├── clean_data.sql          
│   ├── sales_trends.sql        
│   ├── promotion_impact.sql    
│   ├── campaign_performance.sql
│   └── analytics_data_product.sql
├── streamlit/                  ← Projet 1 : Dashboards
│   ├── sales_dashboard.py      
│   ├── promotion_analysis.py   
│   └── marketing_roi.py        
├── notebook/                   ← Projet 2 : ML Pipeline
│   └── house_price_ml_pipeline.ipynb
├── streamlit_app.py            ← Projet 2 : App Streamlit
├── README.md
└── business_insights.md
```

---

## Projet 1 – AnyCompany Marketing Analytics

Analyse data-driven des ventes, promotions et campagnes marketing d'AnyCompany Food & Beverage sur Snowflake.

**Architecture** : `S3 → BRONZE → SILVER → ANALYTICS`

| Membre | Tâche |
|--------|-------|
| Nada | Load_data.sql · campaign_performance.sql · Dashboards Streamlit |
| Djaz | clean_data.sql |
| Basma | sales_trends.sql · promotion_impact.sql |

---

## Projet 2 – House Price Prediction (ML)

Pipeline ML complet dans Snowflake pour prédire le prix d'une maison.

**Pipeline** : `S3 → Ingestion → EDA → Features → ML → Registry → Streamlit`

| Membre | Tâche |
|--------|-------|
| Nada | Configuration · Ingestion · Registry · Streamlit |
| Djaz | Exploration · Préparation des données |
| Basma | Entraînement · Évaluation · Optimisation |

---

## Accès Snowflake

**URL** : `https://VTB83829.snowflakecomputing.com`  
**Database** : `MY_GRP_LAB` · **Warehouse** : `MY_GRP_WH`

| Membre | Login |
|--------|-------|
| Nada | `NELMANSOURI` |
| Djaz | `djaz` |
| Basma | `basma` |
