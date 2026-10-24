"""Transparent queue wait-time baseline; not a trained ML model."""
def estimate_wait_minutes(queue_count: int, average_service_minutes: float = 4.0, active_pumps: int = 1) -> int:
    if isinstance(queue_count, bool) or queue_count < 0:
        raise ValueError("queue_count must be a non-negative integer")
    if average_service_minutes <= 0:
        raise ValueError("average_service_minutes must be greater than zero")
    if active_pumps < 1:
        raise ValueError("active_pumps must be at least one")
    return round(queue_count * average_service_minutes / active_pumps)
