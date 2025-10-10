import os
import pandas as pd
import mlflow
from mlflow.models import ModelSignature
from mlflow.types import Schema, ColSpec
import pmdarima
from pmdarima.metrics import smape
import streamlit as st
import matplotlib.pyplot as plt
from pathlib import Path

# Config via env/ConfigMap
EXPERIMENT = os.getenv("EXPERIMENT_NAME", "forecast-demo")
MLRUNS_DIR = os.getenv("MLRUNS_DIR", str((Path.cwd() / "mlruns").resolve()))
DEFAULT_MLRUNS_DIR = Path(MLRUNS_DIR)
DEFAULT_MLRUNS_DIR.mkdir(parents=True, exist_ok=True)
MLFLOW_URI = os.getenv("MLFLOW_TRACKING_URI", f"file://{DEFAULT_MLRUNS_DIR}")

mlflow.set_tracking_uri(MLFLOW_URI)
mlflow.set_experiment(EXPERIMENT)

st.set_page_config(page_title="Forecast", layout="centered")
st.title("🧭 Forecast with ARIMA & MLflow")
st.caption(f"Tracking to: {MLFLOW_URI}")

st.write("Upload a CSV with two columns: **ds** (date) and **y** (number).")
uploaded = st.file_uploader("CSV file", type=["csv"])
horizon = st.number_input("Forecast horizon (steps)", min_value=1, max_value=365, value=30)

if st.button("Train, Log to MLflow, and Forecast") and uploaded:
    try:

        # Read data and rename columns
        sales_data = pd.read_csv(uploaded, parse_dates=["ds"]).sort_values("ds").dropna(subset=["ds","y"])
        sales_data.rename(columns={"y": "sales", "ds": "date"}, inplace=True)

        # Convert to float
        sales_data["sales"] = sales_data["sales"].astype(float)

        # Infer frequency/seasonality
        freq = pd.infer_freq(sales_data["date"])
        if freq is None: # fallback to daily
            freq = "D" 
        if freq.startswith("M"):   # monthly
            m = 12
        elif freq.startswith("W"): # weekly
            m = 52
        elif freq.startswith("D"): # daily
            m = 7
        elif freq.startswith("H"): # hourly
            m = 24
        else:
            m = 7  # default
        seasonal = m not in (0, 1)
        st.caption(f"Detected frequency: **{freq}** → using seasonal={seasonal} with m={m}")

        # Spliting data into train/test
        train_size = int(0.8 * len(sales_data))
        train = sales_data[:train_size]
        test = sales_data[train_size:]

        with mlflow.start_run():
            # Create the model
            model = pmdarima.auto_arima(
                train["sales"],
                seasonal=seasonal,
                m=m,
                d=None, D=None, 
                start_p=1, start_q=1,
                start_P=0, start_Q=0,
                max_p=5, max_q=5, max_P=2, max_Q=2,
                information_criterion="aic",
                stepwise=True,
                error_action="ignore",
                suppress_warnings=True,
                enforce_stationarity=False,
                enforce_invertibility=False
            )

            # Calculate metrics
            prediction = model.predict(n_periods=len(test))
            metrics = {"smape": smape(test["sales"], prediction)}
            mlflow.log_metrics(metrics)

            # Explicit schema
            signature = ModelSignature(
                inputs=Schema([ColSpec("long", "n_periods")]),
                outputs=Schema([ColSpec("double")])
            )
            
            model_info = mlflow.pmdarima.log_model(
                model,
                artifact_path="model",
                signature=signature
            )
        
        st.code(f"Model URI: {model_info.model_uri}", language="text")

        # Forecast the selected horizon for visual confirmation that model works as expected
        loaded_model = mlflow.pmdarima.load_model(model_info.model_uri)
        future_vals = loaded_model.predict(n_periods=horizon)

        # Start from the last observed date to generate DataFrame for new predicted values
        last_date = sales_data["date"].max()
        future_dates = pd.date_range(start=pd.to_datetime(last_date), periods=horizon + 1, freq=freq)[1:]

        forecast_df = pd.DataFrame({"date": future_dates, "yhat": future_vals})

        st.info(f"Horizon = {horizon} step(s) at frequency **{freq}** (e.g., monthly data → {horizon} months).")

        st.subheader("Forecast")
        st.dataframe(forecast_df)

        # Plot graph of history and forecast
        fig, ax = plt.subplots(figsize=(8,4))
        ax.plot(sales_data["date"], sales_data["sales"], label="actual")
        ax.plot(forecast_df["date"], forecast_df["yhat"], label="forecast")
        ax.set_xlabel(f"date ({freq})"); ax.set_ylabel("sales"); ax.legend()
        st.pyplot(fig)

        # Show run id
        run_id = mlflow.active_run().info.run_id if mlflow.active_run() else None
        if run_id:
            st.success(f"Logged run_id: {run_id}")
    except Exception as e:
        st.error(f"An error occurred: {e}")
elif not uploaded:
    st.info("Upload a small CSV to try it out. Example:\n\nds,y\n2024-01-01,100\n2024-01-02,102\n…")
