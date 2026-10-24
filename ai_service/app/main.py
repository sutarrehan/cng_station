"""CNGPulse optional estimates API. Keep this service off unless deployed separately."""
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field
from app.waiting_time.predictor import estimate_wait_minutes
from app.best_time.recommender import recommend_best_hour

app = FastAPI(title="CNGPulse AI Service", version="1.0.0", description="Rule-based estimates; not trained ML predictions.")

class WaitRequest(BaseModel):
    queue_count: int = Field(ge=0, le=10000)
    average_service_minutes: float = Field(default=4.0, gt=0, le=60)
    active_pumps: int = Field(default=1, ge=1, le=100)
    data_is_operator_reported: bool = True

class BestTimeRequest(BaseModel):
    hourly_counts: list[int] = Field(min_length=24, max_length=24)

@app.get("/health")
def health():
    return {"status": "ok", "mode": "rule-based-estimates", "ml_model_loaded": False}

@app.post("/predict-wait")
def predict_wait(body: WaitRequest):
    try:
        estimate = estimate_wait_minutes(body.queue_count, body.average_service_minutes, body.active_pumps)
    except ValueError as exc:
        raise HTTPException(status_code=422, detail=str(exc)) from exc
    return {"estimated_wait_minutes": estimate, "confidence": "low", "source": "operator-reported queue plus configured service-rate heuristic", "warning": "Estimate only; not a live measurement. Validate with real historical data."}

@app.post("/recommend-best-time")
def recommend_time(body: BestTimeRequest):
    try:
        return recommend_best_hour(body.hourly_counts)
    except ValueError as exc:
        raise HTTPException(status_code=422, detail=str(exc)) from exc
