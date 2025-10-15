import os
import json
import requests
import pandas as pd
import streamlit as st
import matplotlib.pyplot as plt

# Config
SERVE_BASE_URL = os.getenv("SERVE_BASE_URL", "http://localhost:8000")
DEFAULT_N_PERIODS = int(os.getenv("N_PERIODS", "12"))

st.set_page_config(page_title="Serve API Tester", layout="centered")
st.title("🧪 Forecast Serve API Tester")
st.caption(f"Target server: {SERVE_BASE_URL}")

# Health check
with st.expander("Health check", expanded=True):
    try:
        r = requests.get(f"{SERVE_BASE_URL}/healthz", timeout=5)
        r.raise_for_status()
        st.success("/healthz OK")
        st.json(r.json())
    except Exception as e:
        st.error(f"/healthz failed: {e}")

st.divider()

# Prediction form
st.subheader("Make a prediction")
col1, col2 = st.columns(2)
with col1:
    n_periods = st.number_input("n_periods", min_value=1, max_value=365, value=DEFAULT_N_PERIODS)
with col2:
    raw_mode = st.toggle("Show raw JSON", value=False)

if st.button("Call /predict"):
    try:
        payload = {"n_periods": int(n_periods)}
        resp = requests.post(
            f"{SERVE_BASE_URL}/predict",
            headers={"Content-Type": "application/json"},
            data=json.dumps(payload),
            timeout=30,
        )
        resp.raise_for_status()
        data = resp.json()

        if raw_mode:
            st.code(json.dumps(data, indent=2), language="json")

        df = None
        if isinstance(data, dict) and "predictions" in data:
            preds = data["predictions"]
            df = pd.DataFrame({"step": list(range(1, len(preds)+1)), "yhat": preds})
        elif isinstance(data, dict) and "forecast" in data and isinstance(data["forecast"], list):
            rows = data["forecast"]

            norm = []
            for r in rows:
                if isinstance(r, dict) and "prediction" in r:
                    norm.append({"date": r.get("date"), "yhat": r["prediction"]})
                elif isinstance(r, (list, tuple)) and len(r) >= 2:
                    norm.append({"date": r[0], "yhat": r[1]})
            df = pd.DataFrame(norm)
        else:
            st.warning("Unexpected response shape; showing raw JSON below.")
            st.code(json.dumps(data, indent=2), language="json")

        if df is not None and not df.empty:
            st.success("Prediction received ✅")
            st.dataframe(df, use_container_width=True)

            # Simple plot
            fig, ax = plt.subplots(figsize=(8, 3.5))
            if "date" in df.columns:
                ax.plot(pd.to_datetime(df["date"]), df["yhat"], label="forecast")
                ax.set_xlabel("date")
            else:
                ax.plot(df["step"], df["yhat"], label="forecast")
                ax.set_xlabel("step")
            ax.set_ylabel("prediction")
            ax.legend()
            st.pyplot(fig)

    except requests.HTTPError as he:
        try:
            st.error(f"HTTP {resp.status_code}: {resp.text}")
        except Exception:
            st.error(f"HTTP error: {he}")
    except Exception as e:
        st.error(f"Call failed: {e}")

st.info("Tip: set SERVE_BASE_URL env var to point at a remote service")
