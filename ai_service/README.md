# CNGPulse optional AI estimates service

This is an optional FastAPI service. It is **not required to run the Flutter app** and is not a trained ML system. Both endpoints use transparent rule-based heuristics.

## Local run

```bash
python -m venv .venv
# Windows: .venv\Scripts\activate
# macOS/Linux: source .venv/bin/activate
pip install -r requirements.txt
uvicorn main:app --host 127.0.0.1 --port 8000 --reload
```

- `GET /health`
- `POST /predict-wait` with `{"queue_count": 5, "average_service_minutes": 4, "active_pumps": 1}`
- `POST /recommend-best-time` with `{"hourly_counts": [ ... exactly 24 non-negative integers ... ]}`

Do not expose this unauthenticated service publicly without adding authentication, rate limiting, logging controls and deployment hardening. Estimates must not be presented as live measurements.
