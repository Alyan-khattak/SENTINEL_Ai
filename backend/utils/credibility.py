"""
SENTINEL Credibility Scoring Utility
Computes credibility weight per source for conflict resolution.
Canon: planning.md Hour 9 T2
"""

from datetime import datetime, timezone

from models.source import Source


SOURCE_TYPE_WEIGHTS = {
    "pdf": 8,            # official documents
    "csv": 7,            # warehouse records
    "json": 7,           # internal dashboards
    "web": 5,            # external news
    "realtime_feed": 6,  # streaming feeds
}


def compute_credibility(source: Source, now: datetime = None) -> int:
    """
    Compute credibility score (1-10) for a source.
    Formula: round(recency * 0.5 + type_score * 0.5)

    Args:
        source: The Source to score.
        now: Current datetime for recency calculation.

    Returns:
        Integer credibility score from 1-10.
    """
    if now is None:
        now = datetime.now(timezone.utc)

    # Recency score: 10 if today, decreasing by 1 per day, min 0
    if source.recorded_at.tzinfo is None:
        recorded = source.recorded_at.replace(tzinfo=timezone.utc)
    else:
        recorded = source.recorded_at
    days_old = max(0, (now - recorded).days)
    recency_score = max(0, 10 - days_old)

    # Source type score
    type_score = SOURCE_TYPE_WEIGHTS.get(source.source_type, 5)

    # Weighted combination
    score = round(recency_score * 0.5 + type_score * 0.5)
    return max(1, min(10, score))
