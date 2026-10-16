"""Optional CNGPulse wait-time estimation service.
This baseline uses a transparent heuristic. Replace with a trained model once real,
consented historical queue observations are available; do not treat it as live sensor data.
"""
from fastapi import FastAPI
from pydantic import BaseModel, Field

app = FastAPI(title="CNGPulse AI Service", version="0.1.0")

class WaitRequest(BaseModel):
    queue_count: int = Field(ge=0, le=10000)
    average_service_minutes: float = Field(default=4.0, gt=0, le=60)
    active_pumps: int = Field(default=1, ge=1, le=100)
    data_is_operator_reported: bool = True

@app.get("/health")
def health():
    return {"status": "ok", "mode": "baseline-estimate"}

@app.post("/predict-wait")
def predict_wait(body: WaitRequest):
    estimate = round(body.queue_count * body.average_service_minutes / body.active_pumps)
    return {
        "estimated_wait_minutes": estimate,
        "confidence": "low",
        "source": "operator-reported queue plus configured service-rate heuristic",
        "warning": "Estimate only; not a live measurement. Confidence improves with validated historical data."
    }
