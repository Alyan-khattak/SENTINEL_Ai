"""
SENTINEL Temporal Analysis Utility
Computes rate of change from time-series data.
Canon: planning.md Hour 8 T2
"""

from datetime import datetime
from typing import Optional


def compute_rate_of_change(time_series: list[tuple[datetime, float]]) -> Optional[float]:
    """
    Returns units/day rate of change using linear regression slope.
    Input: list of (datetime, value) tuples, sorted by time ascending.
    Output: float representing daily change rate. Negative = declining.
    """
    if len(time_series) < 2:
        return None

    # Convert datetimes to day offsets
    base_time = time_series[0][0]
    x = [(t - base_time).total_seconds() / 86400.0 for t, _ in time_series]
    y = [v for _, v in time_series]

    n = len(x)
    sum_x = sum(x)
    sum_y = sum(y)
    sum_xy = sum(xi * yi for xi, yi in zip(x, y))
    sum_x2 = sum(xi * xi for xi in x)

    denominator = n * sum_x2 - sum_x * sum_x
    if denominator == 0:
        return 0.0

    slope = (n * sum_xy - sum_x * sum_y) / denominator
    return round(slope, 2)


def determine_trend(rate: Optional[float]) -> str:
    """Determine trend direction from rate of change."""
    if rate is None:
        return "stable"
    if rate > 50:
        return "rising"
    elif rate < -50:
        return "falling"
    elif abs(rate) > 10:
        return "volatile"
    else:
        return "stable"
