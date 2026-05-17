"""
SENTINEL Pydantic Models — State, WorkPlan, TaskPlan, ActionStep
Canon: idea.md §8.3
"""

from datetime import datetime
from typing import Literal, Optional

from pydantic import BaseModel


class WorkPlan(BaseModel):
    """High-level workplan produced by the Planner Agent."""
    high_level_steps: list[str]
    expected_duration_seconds: int
    estimated_llm_calls: int
    fallback_strategy: str


class TaskPlan(BaseModel):
    """Detailed task plan with dependencies."""
    tasks: list[dict]


class ActionStep(BaseModel):
    """Runtime state of a single action execution step."""
    step_number: int
    action_id: str
    action_name: str
    status: Literal["pending", "running", "success", "failed", "retrying", "rolled_back", "skipped"]
    started_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None
    retried: int = 0
    rolled_back: bool = False
    error: Optional[str] = None
    state_diff: dict = {}
