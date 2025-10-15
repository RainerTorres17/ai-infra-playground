import os
import argparse
import sys

import pandas as pd
import mlflow
from mlflow.models import ModelSignature
from mlflow.types import Schema, ColSpec
from mlflow.tracking import MlflowClient

import pmdarima
from pmdarima.metrics import smape


def infer_freq_and_seasonality(dates: pd.Series):
    freq = pd.infer_freq(dates)
    if freq is None:
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
        m = 7
    seasonal = m not in (0, 1)
    return freq, m, seasonal


def main():
    parser = argparse.ArgumentParser(description="Batch train ARIMA model and log to MLflow")
    parser.add_argument("--csv", required=True, help="Path or URL to CSV with columns 'ds' (date) and 'y' (numeric)")
    parser.add_argument("--horizon", type=int, default=30, help="Forecast horizon (steps)")
    parser.add_argument("--experiment", default=os.getenv("EXPERIMENT_NAME", "forecast-demo"), help="MLflow experiment name")
    parser.add_argument("--model-name", default=os.getenv("MODEL_NAME"), help="MLflow Registry model name")
    parser.add_argument("--no-promote", action="store_true", help="If set, do not promote to Production")
    args = parser.parse_args()

    # Configure MLflow tracking URI if provided via env
    mlflow_uri_env = os.getenv("MLFLOW_TRACKING_URI")
    if mlflow_uri_env:
        mlflow.set_tracking_uri(mlflow_uri_env)
    effective_uri = mlflow.get_tracking_uri()

    # Set experiment (create if missing)
    mlflow.set_experiment(args.experiment)

    print(f"[info] Tracking URI: {effective_uri}")
    print(f"[info] Experiment: {args.experiment}")
    if args.model_name:
        print(f"[info] Model Registry name: {args.model_name}")

    # Load and clean data
    print(f"[info] Loading data from: {args.csv}")
    sales_data = pd.read_csv(args.csv, parse_dates=["ds"]).sort_values("ds").dropna(subset=["ds", "y"]).copy()
    sales_data.rename(columns={"y": "sales", "ds": "date"}, inplace=True)
    sales_data["sales"] = sales_data["sales"].astype(float)

    # Infer frequency & seasonality
    freq, m, seasonal = infer_freq_and_seasonality(sales_data["date"]) 
    print(f"[info] Detected frequency: {freq} -> seasonal={seasonal}, m={m}")

    # Train/test split
    train_size = int(0.8 * len(sales_data))
    train = sales_data.iloc[:train_size]
    test = sales_data.iloc[train_size:]

    with mlflow.start_run() as run:
        # Train ARIMA
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
            enforce_invertibility=False,
        )

        # Calculate SMAPE
        prediction = model.predict(n_periods=len(test))
        score = float(smape(test["sales"], prediction))
        mlflow.log_metrics({"smape": score})
        print(f"[info] SMAPE: {score:.4f}")

        # Log model with explicit signature
        signature = ModelSignature(
            inputs=Schema([ColSpec("long", "n_periods")]),
            outputs=Schema([ColSpec("double")]),
        )
        model_info = mlflow.pmdarima.log_model(
            model,
            artifact_path="model",
            signature=signature,
        )

    #Register & conditional promote to Production based on SMAPE
    if args.model_name and not args.no_promote:
        try:

            c = MlflowClient()

            # Ensure registry entry exists or create if missing
            try:
                c.get_registered_model(args.model_name)
            except Exception:
                c.create_registered_model(args.model_name)

            # Create a new model version from this run
            mv = c.create_model_version(
                name=args.model_name,
                source=model_info.model_uri,
                run_id=model_info.run_id,
                description="Auto-registered by train.py",
            )

            new_version = mv.version

            # Find current Production version if any and its SMAPE
            versions = c.search_model_versions(f"name='{args.model_name}'")
            prod_versions = [v for v in versions if "prod" in (v.aliases or [])]

            new_smape = score

            if not prod_versions:
                c.set_registered_model_alias(name=args.model_name, alias="prod", version=new_version)
            else:
                prod_version = sorted(prod_versions, key=lambda v: int(v.version))[-1]
                prod_run = c.get_run(prod_version.run_id)
                prod_smape = prod_run.data.metrics.get("smape")

                if new_smape < prod_smape:
                    c.set_registered_model_alias(name=args.model_name, alias="prod", version=new_version)
                    print(f"[info] Promoted ForecastModel v{new_version} to prod.")
                else:
                    print(f"[info] Skipped promotion — worse SMAPE ({new_smape:.4f} ≥ {prod_smape:.4f}).")

            

        except Exception as e:
            print(f"[warn] Model Registry step failed or unavailable: {e}")


if __name__ == "__main__":
    main()
