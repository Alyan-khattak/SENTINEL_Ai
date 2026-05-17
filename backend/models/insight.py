"""
SENTINEL Pydantic Models — Insight and Conflict Resolution
Canon: idea.md §8.3
"""

from typing import Literal, Optional, Union

from pydantic import BaseModel


class Insight(BaseModel):
    """Structured signal extracted from filtered sources."""
    insight_id: str
    metric: str
    value: Union[float, str]
    source_ids: list[str]
    confidence: float  # 0.0-1.0
    trend: Optional[Literal["rising", "falling", "stable", "volatile"]] = None
    rate_of_change: Optional[float] = None
    risk_severity: Optional[Literal["low", "medium", "high", "critical"]] = None


class Contradiction(BaseModel):
    """A detected contradiction between sources on a specific metric."""
    metric: str
    conflicting_values: list[dict]  # [{source_id, value, credibility}]
    winner_source_id: Optional[str] = None
    reasoning: str


class ConflictResolution(BaseModel):
    """Result of conflict resolution across all insights."""
    contradictions: list[Contradiction]
    resolution_type: Literal["resolved", "investigation_required", "partial"]
    investigation_actions: list[str] = []
    confidence: float
