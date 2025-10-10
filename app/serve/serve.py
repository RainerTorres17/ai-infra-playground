import os
from pathlib import Path
from typing import List

import mlflow
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

# Set local variable before API call
MODEL_URI = os.getenv("MODEL_URI", "").strip()
if not MODEL_URI:
  raise RuntimeError("MODEL_URI is required. Example: export MODEL_URI='runs:/<RUN_ID>/model'")

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

class PredictIn(BaseModel):
  n_periods: int

class PredictOut(BaseModel):
  predictions: List[float]

@app.get("/health")
def health():
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
