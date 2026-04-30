import streamlit as st
import pandas as pd
import plotly.express as px
import plotly.graph_objects as go
import snowflake.connector

st.set_page_config(
    page_title="AnyCompany | Marketing ROI",
    page_icon="🚀",
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

st.title("🚀 AnyCompany – Marketing ROI & Performance Campagnes")
st.caption("Données : ANALYTICS.CAMPAIGN_ROI · SILVER.MARKETING_CAMPAIGNS_CLEAN")

kpi_q = """
SELECT
    COUNT(*) AS nb_campaigns,
    ROUND(SUM(BUDGET), 2) AS total_budget,
    SUM(REACH) AS total_reach,
    SUM(ESTIMATED_CONVERSIONS) AS total_conversions,
    ROUND(AVG(CONVERSION_RATE)*100, 3) AS avg_conversion_pct,
    ROUND(AVG(ESTIMATED_ROI_RATIO), 2) AS avg_roi
FROM ANALYTICS.CAMPAIGN_ROI
"""
kpi = run_query(kpi_q).iloc[0]

c1, c2, c3, c4, c5 = st.columns(5)
c1.metric("📣 Campagnes",            f"{int(kpi['NB_CAMPAIGNS']):,}")
c2.metric("💰 Budget total",         f"${kpi['TOTAL_BUDGET']:,.0f}")
c3.metric("👁️ Portée totale",       f"{int(kpi['TOTAL_REACH']):,}")
c4.metric("✅ Conversions estimées",  f"{int(kpi['TOTAL_CONVERSIONS']):,}")
c5.metric("📈 Taux de conv. moy.",   f"{kpi['AVG_CONVERSION_PCT']:.2f}%")

st.divider()

with st.sidebar:
    st.header("Filtres")
    years = run_query("SELECT DISTINCT CAMPAIGN_YEAR FROM ANALYTICS.CAMPAIGN_ROI ORDER BY CAMPAIGN_YEAR")
    sel_years = st.multiselect("Année(s)", years["CAMPAIGN_YEAR"].tolist(),
                               default=years["CAMPAIGN_YEAR"].tolist())
    types = run_query("SELECT DISTINCT CAMPAIGN_TYPE FROM ANALYTICS.CAMPAIGN_ROI ORDER BY CAMPAIGN_TYPE")
    sel_types = st.multiselect("Type de campagne", types["CAMPAIGN_TYPE"].tolist(),
                               default=types["CAMPAIGN_TYPE"].tolist())

year_f = tuple(sel_years) if sel_years else (0,)
type_f = tuple(sel_types) if sel_types else ("__NONE__",)

col_l, col_r = st.columns(2)

with col_l:
    st.subheader("Taux de conversion par type de campagne")
    type_q = f"""
    SELECT
        CAMPAIGN_TYPE,
        COUNT(*) AS nb_campaigns,
        ROUND(AVG(CONVERSION_RATE)*100, 3) AS avg_conversion_pct,
        ROUND(SUM(BUDGET), 0) AS total_budget,
        SUM(ESTIMATED_CONVERSIONS) AS total_conversions
    FROM ANALYTICS.CAMPAIGN_ROI
    WHERE CAMPAIGN_YEAR IN {year_f}
      AND CAMPAIGN_TYPE IN {type_f}
    GROUP BY CAMPAIGN_TYPE
    ORDER BY avg_conversion_pct DESC
    """
    df_type = run_query(type_q)
    fig = px.bar(
        df_type, x="CAMPAIGN_TYPE", y="AVG_CONVERSION_PCT",
        color="CAMPAIGN_TYPE",
        text="AVG_CONVERSION_PCT",
        labels={"CAMPAIGN_TYPE": "Type", "AVG_CONVERSION_PCT": "Conv. rate (%)"},
        color_discrete_sequence=px.colors.qualitative.Set2,
    )
    fig.update_traces(texttemplate="%{text:.2f}%", textposition="outside")
    fig.update_layout(showlegend=False, margin=dict(t=10, b=10))
    st.plotly_chart(fig, use_container_width=True)

with col_r:
    st.subheader("Budget investi vs Conversions (par catégorie)")
    cat_q = f"""
    SELECT
        PRODUCT_CATEGORY,
        ROUND(SUM(BUDGET), 0) AS total_budget,
        SUM(ESTIMATED_CONVERSIONS) AS total_conversions,
        ROUND(AVG(CONVERSION_RATE)*100, 3) AS avg_conv_pct
    FROM ANALYTICS.CAMPAIGN_ROI
    WHERE CAMPAIGN_YEAR IN {year_f}
      AND CAMPAIGN_TYPE IN {type_f}
    GROUP BY PRODUCT_CATEGORY
    """
    df_cat = run_query(cat_q)
    fig2 = px.scatter(
        df_cat,
        x="TOTAL_BUDGET", y="TOTAL_CONVERSIONS",
        size="AVG_CONV_PCT", color="PRODUCT_CATEGORY",
        text="PRODUCT_CATEGORY",
        labels={"TOTAL_BUDGET": "Budget ($)", "TOTAL_CONVERSIONS": "Conversions"},
    )
    fig2.update_traces(textposition="top center")
    fig2.update_layout(showlegend=False, margin=dict(t=10, b=10))
    st.plotly_chart(fig2, use_container_width=True)

col_l2, col_r2 = st.columns(2)

with col_l2:
    st.subheader("ROI estimé par région")
    roi_q = f"""
    SELECT
        REGION,
        ROUND(AVG(ESTIMATED_ROI_RATIO), 2) AS avg_roi,
        COUNT(*) AS nb_campaigns,
        ROUND(SUM(BUDGET), 0) AS total_budget
    FROM ANALYTICS.CAMPAIGN_ROI
    WHERE CAMPAIGN_YEAR IN {year_f}
      AND CAMPAIGN_TYPE IN {type_f}
      AND REGION IS NOT NULL
    GROUP BY REGION
    ORDER BY avg_roi DESC
    """
    df_roi = run_query(roi_q)
    fig3 = px.bar(
        df_roi, x="AVG_ROI", y="REGION", orientation="h",
        color="AVG_ROI", color_continuous_scale="RdYlGn",
        labels={"AVG_ROI": "ROI moyen (x)", "REGION": "Région"},
        text="AVG_ROI",
    )
    fig3.update_traces(texttemplate="%{text:.2f}x", textposition="outside")
    fig3.update_layout(margin=dict(t=10, b=10))
    st.plotly_chart(fig3, use_container_width=True)

with col_r2:
    st.subheader("Évolution annuelle : budget vs conversions")
    yearly_q = f"""
    SELECT
        CAMPAIGN_YEAR AS year,
        ROUND(SUM(BUDGET), 0) AS total_budget,
        SUM(ESTIMATED_CONVERSIONS) AS total_conversions,
        COUNT(*) AS nb_campaigns
    FROM ANALYTICS.CAMPAIGN_ROI
    WHERE CAMPAIGN_YEAR IN {year_f}
    GROUP BY CAMPAIGN_YEAR
    ORDER BY CAMPAIGN_YEAR
    """
    df_yearly = run_query(yearly_q)
    fig4 = go.Figure()
    fig4.add_bar(x=df_yearly["YEAR"], y=df_yearly["TOTAL_BUDGET"],
                 name="Budget ($)", marker_color="#3498db", opacity=0.8)
    fig4.add_scatter(x=df_yearly["YEAR"], y=df_yearly["TOTAL_CONVERSIONS"],
                     mode="lines+markers", name="Conversions",
                     yaxis="y2", marker_color="#e74c3c", line_width=2)
    fig4.update_layout(
        yaxis=dict(title="Budget ($)"),
        yaxis2=dict(title="Conversions", overlaying="y", side="right"),
        legend=dict(x=0, y=1.1, orientation="h"),
        margin=dict(t=30, b=10),
    )
    st.plotly_chart(fig4, use_container_width=True)

col_l3, col_r3 = st.columns(2)

with col_l3:
    st.subheader("Top 10 campagnes par taux de conversion")
    top_q = f"""
    SELECT
        CAMPAIGN_NAME, CAMPAIGN_TYPE, PRODUCT_CATEGORY, REGION,
        ROUND(CONVERSION_RATE*100, 3) AS conversion_pct,
        ROUND(BUDGET, 0) AS budget,
        ESTIMATED_CONVERSIONS
    FROM ANALYTICS.CAMPAIGN_ROI
    WHERE CAMPAIGN_YEAR IN {year_f}
      AND CAMPAIGN_TYPE IN {type_f}
    ORDER BY CONVERSION_RATE DESC
    LIMIT 10
    """
    df_top = run_query(top_q)
    fig5 = px.bar(
        df_top, x="CONVERSION_PCT", y="CAMPAIGN_NAME", orientation="h",
        color="CAMPAIGN_TYPE",
        labels={"CONVERSION_PCT": "Conv. rate (%)", "CAMPAIGN_NAME": ""},
        text="CONVERSION_PCT",
    )
    fig5.update_traces(texttemplate="%{text:.2f}%", textposition="outside")
    fig5.update_layout(height=400, margin=dict(t=10, b=10))
    st.plotly_chart(fig5, use_container_width=True)

with col_r3:
    st.subheader("Performance par audience cible")
    aud_q = f"""
    SELECT
        TARGET_AUDIENCE,
        COUNT(*) AS nb_campaigns,
        ROUND(AVG(CONVERSION_RATE)*100, 3) AS avg_conversion_pct,
        ROUND(SUM(BUDGET)/NULLIF(SUM(ESTIMATED_CONVERSIONS),0), 2) AS cost_per_conversion
    FROM ANALYTICS.CAMPAIGN_ROI
    WHERE CAMPAIGN_YEAR IN {year_f}
      AND CAMPAIGN_TYPE IN {type_f}
      AND TARGET_AUDIENCE IS NOT NULL
    GROUP BY TARGET_AUDIENCE
    ORDER BY avg_conversion_pct DESC
    """
    df_aud = run_query(aud_q)
    fig6 = px.scatter(
        df_aud,
        x="COST_PER_CONVERSION", y="AVG_CONVERSION_PCT",
        size="NB_CAMPAIGNS", color="TARGET_AUDIENCE",
        text="TARGET_AUDIENCE",
        labels={
            "COST_PER_CONVERSION": "Coût / conversion ($)",
            "AVG_CONVERSION_PCT": "Taux de conversion (%)",
        },
    )
    fig6.update_traces(textposition="top center")
    fig6.update_layout(showlegend=False, height=400, margin=dict(t=10, b=10))
    st.plotly_chart(fig6, use_container_width=True)

with st.expander("📋 Détail complet des campagnes"):
    full_q = f"""
    SELECT
        CAMPAIGN_ID, CAMPAIGN_NAME, CAMPAIGN_TYPE, PRODUCT_CATEGORY,
        TARGET_AUDIENCE, REGION, CAMPAIGN_YEAR,
        ROUND(BUDGET, 0) AS budget,
        REACH, ESTIMATED_CONVERSIONS,
        ROUND(CONVERSION_RATE*100, 3) AS conversion_pct,
        ROUND(ESTIMATED_ROI_RATIO, 2) AS roi_ratio
    FROM ANALYTICS.CAMPAIGN_ROI
    WHERE CAMPAIGN_YEAR IN {year_f}
      AND CAMPAIGN_TYPE IN {type_f}
    ORDER BY conversion_pct DESC
    """
    df_full = run_query(full_q)
    st.dataframe(df_full, use_container_width=True)
    st.download_button(
        "⬇️ Télécharger CSV",
        df_full.to_csv(index=False).encode("utf-8"),
        "campaigns.csv", "text/csv",
    )
