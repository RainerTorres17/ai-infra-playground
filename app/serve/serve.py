import os
from pathlib import Path
from typing import List

import mlflow
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from prometheus_fastapi_instrumentator import Instrumentator

from mlflow.tracking import MlflowClient

# Set or derive MODEL_URI before API call
MODEL_URI = os.getenv("MODEL_URI", "").strip()
if not MODEL_URI:
    model_name = os.getenv("MODEL_NAME", "ForecastModel").strip()
    client = MlflowClient()
    try:
        prod_version = client.get_model_version_by_alias(model_name, "prod")
    except Exception:
        prod_version = None

    if prod_version:
        MODEL_URI = f"models:/{model_name}@prod"
    else:
        all_versions = client.search_model_versions(f"name='{model_name}'")
        if all_versions:
            latest_version = max(all_versions, key=lambda v: int(v.version))
            MODEL_URI = f"models:/{model_name}/{latest_version.version}"
        else:
            raise RuntimeError(f"No registered versions found for model '{model_name}'. "
                               "Please set MODEL_URI environment variable to a valid model URI.")

# Config via env/ConfigMap
tracking_uri = os.getenv("MLFLOW_TRACKING_URI", "").strip()
if tracking_uri:
  mlflow.set_tracking_uri(tracking_uri)
else:
  default_mlruns = f"file://{(Path.cwd() / 'mlruns').resolve()}"
  mlflow.set_tracking_uri(default_mlruns)
  tracking_uri = default_mlruns

try:
  model = mlflow.pyfunc.load_model(MODEL_URI)
except Exception as e:
  raise RuntimeError(f"Failed to load model from '{MODEL_URI}'. "
                     f"Underlying error: {e}")

app = FastAPI(title="Forecast Serving API")

Instrumentator().instrument(app).expose(app)

class PredictIn(BaseModel):
  n_periods: int

class PredictOut(BaseModel):
  predictions: List[float]

@app.get("/healthz")
def healthz():
  return {
    "status": "ok",
    "model_uri": MODEL_URI,
    "tracking_uri": tracking_uri,
  }

@app.post("/predict", response_model=PredictOut)
def predict(body: PredictIn):
  # Validate input
  try:
    n = int(body.n_periods)
    if n <= 0:
      raise ValueError
  except Exception:
    raise HTTPException(status_code=400, detail="'n_periods' must be a positive integer.")

  # Call model
  try:
    preds = model.predict({"n_periods": n})
  except Exception as e:
    raise HTTPException(status_code=400, detail=f"Model failed to predict with n_periods={n}: {e}")

  # Output predictions
  try:
    col0 = preds.iloc[:, 0]
    vals = col0.values.tolist() if hasattr(col0, "values") else list(col0)
  except Exception:
    vals = preds.values.ravel().tolist() if hasattr(preds, "values") else list(preds)
  return PredictOut(predictions=[float(x) for x in vals])
