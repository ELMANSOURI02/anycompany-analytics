import streamlit as st
import pandas as pd
import plotly.express as px
import plotly.graph_objects as go
import snowflake.connector

st.set_page_config(
    page_title="AnyCompany | Promotion Analysis",
    page_icon="🎯",
    layout="wide",
)

@st.cache_resource
def get_connection():
    return snowflake.connector.connect(
        user=st.secrets["snowflake"]["user"],
        password=st.secrets["snowflake"]["password"],
        account=st.secrets["snowflake"]["account"],
        warehouse="MY_GRP_WH",
        database="MY_GRP_LAB",
        schema="ANALYTICS",
    )

@st.cache_data(ttl=600)
def run_query(sql: str) -> pd.DataFrame:
    return pd.read_sql(sql, get_connection())

st.title("🎯 AnyCompany – Analyse des Promotions")
st.caption("Données : SILVER.PROMOTIONS_CLEAN · ANALYTICS.SALES_ENRICHED")

kpi_q = """
SELECT
    COUNT(*) AS nb_promotions,
    ROUND(AVG(DISCOUNT_PCT_DISPLAY), 1) AS avg_discount,
    ROUND(AVG(DURATION_DAYS), 1) AS avg_duration,
    COUNT(DISTINCT PRODUCT_CATEGORY) AS nb_categories,
    COUNT(DISTINCT REGION) AS nb_regions
FROM SILVER.PROMOTIONS_CLEAN
"""
kpi = run_query(kpi_q).iloc[0]

c1, c2, c3, c4, c5 = st.columns(5)
c1.metric("📦 Promotions totales",    f"{int(kpi['NB_PROMOTIONS']):,}")
c2.metric("💸 Remise moyenne",        f"{kpi['AVG_DISCOUNT']:.1f}%")
c3.metric("📅 Durée moyenne",         f"{kpi['AVG_DURATION']:.1f} j")
c4.metric("🏷️ Catégories couvertes", f"{int(kpi['NB_CATEGORIES'])}")
c5.metric("🌍 Régions couvertes",     f"{int(kpi['NB_REGIONS'])}")

st.divider()

col_l, col_r = st.columns(2)

with col_l:
    st.subheader("Ventes : avec vs sans promotion")
    comp_q = """
    SELECT
        CASE WHEN HAS_PROMOTION THEN 'Avec promotion' ELSE 'Sans promotion' END AS type,
        COUNT(*) AS nb_transactions,
        ROUND(SUM(AMOUNT), 2) AS total_revenue,
        ROUND(AVG(AMOUNT), 2) AS avg_basket
    FROM ANALYTICS.SALES_ENRICHED
    GROUP BY HAS_PROMOTION
    """
    df_comp = run_query(comp_q)
    fig = px.bar(
        df_comp, x="TYPE", y="TOTAL_REVENUE", text="AVG_BASKET",
        color="TYPE",
        color_discrete_map={
            "Avec promotion": "#2ecc71",
            "Sans promotion": "#3498db",
        },
        labels={"TYPE": "", "TOTAL_REVENUE": "Revenus ($)"},
    )
    fig.update_traces(texttemplate="Panier moy: $%{text:.0f}", textposition="outside")
    fig.update_layout(showlegend=False, margin=dict(t=10, b=10))
    st.plotly_chart(fig, use_container_width=True)

with col_r:
    st.subheader("Uplift promotionnel par région")
    uplift_q = """
    SELECT
        REGION,
        ROUND(AVG(CASE WHEN HAS_PROMOTION THEN AMOUNT END), 2) AS avg_with_promo,
        ROUND(AVG(CASE WHEN NOT HAS_PROMOTION THEN AMOUNT END), 2) AS avg_without_promo,
        ROUND(
            (AVG(CASE WHEN HAS_PROMOTION THEN AMOUNT END)
           - AVG(CASE WHEN NOT HAS_PROMOTION THEN AMOUNT END))
           / NULLIF(AVG(CASE WHEN NOT HAS_PROMOTION THEN AMOUNT END), 0) * 100,
        2) AS uplift_pct
    FROM ANALYTICS.SALES_ENRICHED
    WHERE REGION IS NOT NULL
    GROUP BY REGION
    HAVING avg_with_promo IS NOT NULL AND avg_without_promo IS NOT NULL
    ORDER BY uplift_pct DESC
    """
    df_uplift = run_query(uplift_q)
    df_uplift["COLOR"] = df_uplift["UPLIFT_PCT"].apply(
        lambda x: "positive" if x > 0 else "negative"
    )
    fig2 = px.bar(
        df_uplift, x="UPLIFT_PCT", y="REGION", orientation="h",
        color="COLOR",
        color_discrete_map={"positive": "#2ecc71", "negative": "#e74c3c"},
        labels={"UPLIFT_PCT": "Uplift (%)", "REGION": "Région"},
    )
    fig2.update_layout(showlegend=False, margin=dict(t=10, b=10))
    st.plotly_chart(fig2, use_container_width=True)

col_l2, col_r2 = st.columns(2)

with col_l2:
    st.subheader("Nombre de promotions par catégorie")
    cat_q = """
    SELECT
        PRODUCT_CATEGORY,
        COUNT(*) AS nb_promotions,
        ROUND(AVG(DISCOUNT_PCT_DISPLAY), 1) AS avg_discount,
        ROUND(AVG(DURATION_DAYS), 1) AS avg_duration
    FROM SILVER.PROMOTIONS_CLEAN
    GROUP BY PRODUCT_CATEGORY
    ORDER BY nb_promotions DESC
    """
    df_cat = run_query(cat_q)
    fig3 = px.bar(
        df_cat, x="NB_PROMOTIONS", y="PRODUCT_CATEGORY",
        orientation="h", color="AVG_DISCOUNT",
        color_continuous_scale="Blues",
        labels={
            "NB_PROMOTIONS": "Nb promotions",
            "PRODUCT_CATEGORY": "Catégorie",
            "AVG_DISCOUNT": "Remise moy (%)",
        },
    )
    fig3.update_layout(margin=dict(t=10, b=10))
    st.plotly_chart(fig3, use_container_width=True)

with col_r2:
    st.subheader("Remise (%) vs Durée (jours)")
    scatter_q = """
    SELECT
        PROMOTION_ID, PRODUCT_CATEGORY, PROMOTION_TYPE,
        DISCOUNT_PCT_DISPLAY, DURATION_DAYS, REGION
    FROM SILVER.PROMOTIONS_CLEAN
    """
    df_scatter = run_query(scatter_q)
    fig4 = px.scatter(
        df_scatter,
        x="DURATION_DAYS", y="DISCOUNT_PCT_DISPLAY",
        color="PRODUCT_CATEGORY", symbol="REGION",
        hover_data=["PROMOTION_TYPE", "PROMOTION_ID"],
        labels={
            "DURATION_DAYS": "Durée (jours)",
            "DISCOUNT_PCT_DISPLAY": "Remise (%)",
        },
        opacity=0.7,
    )
    fig4.update_layout(margin=dict(t=10, b=10), legend_title="Catégorie")
    st.plotly_chart(fig4, use_container_width=True)

st.subheader("Heatmap : intensité promotionnelle (catégorie × région)")

heat_q = """
SELECT
    PRODUCT_CATEGORY,
    REGION,
    COUNT(*) AS nb_promotions,
    ROUND(AVG(DISCOUNT_PCT_DISPLAY), 1) AS avg_discount
FROM SILVER.PROMOTIONS_CLEAN
GROUP BY PRODUCT_CATEGORY, REGION
"""
df_heat = run_query(heat_q)
pivot = df_heat.pivot_table(
    index="PRODUCT_CATEGORY", columns="REGION",
    values="NB_PROMOTIONS", fill_value=0
)
fig5 = px.imshow(
    pivot,
    aspect="auto",
    color_continuous_scale="YlOrRd",
    labels=dict(x="Région", y="Catégorie", color="Nb promotions"),
)
fig5.update_layout(margin=dict(t=10, b=10))
st.plotly_chart(fig5, use_container_width=True)

st.subheader("Timeline des promotions (Gantt)")
gantt_q = """
SELECT
    PROMOTION_ID, PRODUCT_CATEGORY, PROMOTION_TYPE,
    DISCOUNT_PCT_DISPLAY, START_DATE, END_DATE, REGION
FROM SILVER.PROMOTIONS_CLEAN
ORDER BY START_DATE
LIMIT 50
"""
df_gantt = run_query(gantt_q)
df_gantt["START_DATE"] = pd.to_datetime(df_gantt["START_DATE"])
df_gantt["END_DATE"]   = pd.to_datetime(df_gantt["END_DATE"])

fig6 = px.timeline(
    df_gantt,
    x_start="START_DATE", x_end="END_DATE",
    y="PROMOTION_ID", color="PRODUCT_CATEGORY",
    hover_data=["PROMOTION_TYPE", "DISCOUNT_PCT_DISPLAY", "REGION"],
    labels={"PROMOTION_ID": "Promotion"},
)
fig6.update_yaxes(autorange="reversed")
fig6.update_layout(height=500, margin=dict(t=10, b=10))
st.plotly_chart(fig6, use_container_width=True)
