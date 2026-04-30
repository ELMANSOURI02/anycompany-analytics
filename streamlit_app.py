# AnyCompany – House Price Prediction

import streamlit as st
import pandas as pd
import numpy as np
from snowflake.snowpark.context import get_active_session
from snowflake.ml.registry import Registry

# ── Configuration ────────────────────────────────────────────
st.set_page_config(
    page_title="house Price Predictor",
    page_icon="🏠",
    layout="wide"
)

# ── Session Snowflake (automatique dans Snowflake Notebooks) ─
session = get_active_session()

# ── Charger le modèle depuis le Registry ────────────────────
@st.cache_resource
def load_model():
    registry = Registry(
        session=session,
        database_name='MY_GRP_LAB',
        schema_name='ML'
    )
    return registry.get_model('HOUSE_PRICE_PREDICTOR').version('V1')

model = load_model()

# ── En-tête ──────────────────────────────────────────────────
st.title("House Price Predictor")
st.caption("Modèle ML entraîné sur Snowflake – MBA ESG 2026")
st.markdown("Renseignez les caractéristiques de la maison pour obtenir une **estimation du prix** en temps réel.")

st.divider()

# ── Formulaire de saisie ─────────────────────────────────────
col1, col2, col3 = st.columns(3)

with col1:
    st.subheader("Surface & Structure")
    area      = st.number_input("Surface (m^2)",       min_value=50,  max_value=1000, value=150, step=10)
    bedrooms  = st.slider("Nombre de chambres",        min_value=1,   max_value=10,   value=3)
    bathrooms = st.slider("Nombre de salles de bain",  min_value=1,   max_value=5,    value=2)
    stories   = st.slider("Nombre d'étages",           min_value=1,   max_value=5,    value=2)
    parking   = st.slider("Places de parking",         min_value=0,   max_value=5,    value=1)

with col2:
    st.subheader("Équipements")
    mainroad       = st.selectbox("Route principale ?",      ["yes", "no"])
    guestroom      = st.selectbox("Chambre d'amis ?",        ["yes", "no"])
    basement       = st.selectbox("Sous-sol ?",              ["yes", "no"])
    hotwaterheating = st.selectbox("Chauffage eau chaude ?", ["yes", "no"])
    airconditioning = st.selectbox("Climatisation ?",        ["yes", "no"])

with col3:
    st.subheader("caractéristiques")
    prefarea         = st.selectbox("Zone privilégiée ?",    ["yes", "no"])
    furnishingstatus = st.selectbox("État d'ameublement",    ["furnished", "semi-furnished", "unfurnished"])

# ── Préparation des données ───────────────────────────────────
def encode_binary(val):
    return 1 if val == "yes" else 0

def encode_furnishing(val):
    mapping = {"furnished": 2, "semi-furnished": 1, "unfurnished": 0}
    return mapping[val]

input_data = pd.DataFrame([{
    "AREA":             area,
    "BEDROOMS":         bedrooms,
    "BATHROOMS":        bathrooms,
    "STORIES":          stories,
    "MAINROAD":         encode_binary(mainroad),
    "GUESTROOM":        encode_binary(guestroom),
    "BASEMENT":         encode_binary(basement),
    "HOTWATERHEATING":  encode_binary(hotwaterheating),
    "AIRCONDITIONING":  encode_binary(airconditioning),
    "PARKING":          parking,
    "PREFAREA":         encode_binary(prefarea),
    "FURNISHINGSTATUS": encode_furnishing(furnishingstatus),
}])

# ── Bouton de prédiction ──────────────────────────────────────
st.divider()

if st.button("estimer le prix", type="primary", use_container_width=True):
    with st.spinner("Calcul en cours..."):
        try:
            prediction = model.run(input_data, function_name='predict')
            price = float(prediction[0])

            # Affichage du résultat
            st.success("Estimation calculée !")

            col_res1, col_res2, col_res3 = st.columns(3)
            col_res1.metric("Prix estimé",    f"${price:,.0f}")
            col_res2.metric("Fourchette basse", f"${price * 0.90:,.0f}")
            col_res3.metric("fourchette haute", f"${price * 1.10:,.0f}")

            st.info("ℹla a fourchette représente ±10% autour de l'estimation centrale.")

            # Récapitulatif des caractéristiques
            st.subheader("Récapitulatif de la maison")
            recap = {
                "Surface":            f"{area} m²",
                "Chambres":           bedrooms,
                "Salles de bain":     bathrooms,
                "Étages":             stories,
                "Parking":            parking,
                "Route principale":   mainroad,
                "Climatisation":      airconditioning,
                "Zone privilégiée":   prefarea,
                "Ameublement":        furnishingstatus,
            }
            st.table(pd.DataFrame(recap.items(), columns=["Caractéristique", "Valeur"]))

        except Exception as e:
            st.error(f"erreur lors de la prédiction : {e}")

# ── Historique des prédictions ────────────────────────────────
st.divider()
with st.expander("voir l'historique des prédictions sauvegardées"):
    try:
        history = session.sql("""
            SELECT PRICE_REEL, PRICE_PREDIT, ERREUR_PCT
            FROM MY_GRP_LAB.ML.HOUSE_PRICE_PREDICTIONS
            ORDER BY ERREUR_PCT ASC
            LIMIT 20
        """).to_pandas()
        st.dataframe(history, use_container_width=True)
    except:
        st.info("Aucune prédiction sauvegardée pour l'instant.")
