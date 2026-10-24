"""Rule-based low-confidence recommendation from operator-reported hourly counts."""
def recommend_best_hour(hourly_counts: list[int]) -> dict:
    if len(hourly_counts) != 24:
        raise ValueError("hourly_counts must contain exactly 24 values")
    if any(isinstance(v, bool) or not isinstance(v, int) or v < 0 for v in hourly_counts):
        raise ValueError("hourly_counts must contain non-negative integers")
    best_hour = min(range(24), key=lambda hour: hourly_counts[hour])
    return {
        "recommended_hour": best_hour,
        "reported_queue_count": hourly_counts[best_hour],
        "confidence": "low",
        "source": "operator-reported historical hourly counts",
        "warning": "Rule-based suggestion, not a live prediction."
    }
