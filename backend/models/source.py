"""
SENTINEL Pydantic Models — Source and Noise Assessment
Canon: idea.md §8.3
"""

from datetime import datetime
from typing import Literal, Optional

from pydantic import BaseModel


class SourceInput(BaseModel):
    """Source input from the API request."""
    type: Literal["pdf", "csv", "json", "web", "realtime_feed"]
    path: str
    raw_content: Optional[str] = None


class Source(BaseModel):
    """Unified internal representation of an ingested source."""
    source_id: str
    source_type: Literal["pdf", "csv", "json", "web", "realtime_feed"]
    content: str
    metadata: dict
    recorded_at: datetime
    ingested_at: datetime


class NoiseAssessment(BaseModel):
    """Result of noise filtering for a single source."""
    source_id: str
    is_duplicate: bool
    duplicate_of: Optional[str] = None
    is_spam: bool
    is_stale: bool
    staleness_days: int = 0
    is_relevant: bool
    credibility_score: int  # 1-10
    keep_for_analysis: bool
    rejection_reason: Optional[str] = None
