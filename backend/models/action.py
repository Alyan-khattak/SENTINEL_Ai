"""
SENTINEL Pydantic Models — Action, Constraints, Side-Effect
Canon: idea.md §8.3
"""

from typing import Literal, Optional

from pydantic import BaseModel


class Constraints(BaseModel):
    """User-adjustable constraint set for action planning."""
    budget_pkr_max: int = 500_000
    time_to_resolution_hours_max: int = 48
    notification_deadline_hours_max: int = 2
    api_rate_limit_per_minute: int = 10
    resource_constraints: dict[str, int] = {}


class Action(BaseModel):
    """A single action in the planned action chain."""
    action_id: str
    name: str
    description: str
    depends_on: list[str] = []
    estimated_cost_pkr: int
    estimated_duration_minutes: int
    affected_resources: list[str] = []
    urgency_tier: Literal["low", "medium", "high", "critical"]
    is_destructive: bool = False
    constraint_violations: list[str] = []
    modification_applied: Optional[str] = None


class SideEffectImpact(BaseModel):
    """Predicted impact of an action on an adjacent business area."""
    area: str
    direction: Literal["positive", "negative", "neutral"]
    magnitude: Literal["low", "medium", "high"]
    explanation: str
    mitigation: str


class SideEffectAnalysis(BaseModel):
    """Side-effect analysis result for a single action."""
    action_id: str
    impacts: list[SideEffectImpact]
    requires_approval: bool = False
    alternative_path: Optional[list[dict]] = None
