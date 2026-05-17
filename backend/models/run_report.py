"""
SENTINEL Pydantic Models — RunReport (final response) and API request/response models
Canon: idea.md §8.3
"""

from datetime import datetime
from typing import Literal, Optional

from pydantic import BaseModel

from .source import Source, NoiseAssessment, SourceInput
from .insight import Insight, ConflictResolution
from .action import Action, Constraints, SideEffectAnalysis
from .state import WorkPlan, TaskPlan, ActionStep
from .metrics import RunMetrics, BaselineComparison


class AnalysisRequest(BaseModel):
    """Request body for POST /api/v1/runs."""
    scenario: str
    sources: list[SourceInput]
    constraints: Constraints = Constraints()


class RunStartResponse(BaseModel):
    """Response for POST /api/v1/runs (202 Accepted)."""
    run_id: str
    status: str = "queued"
    websocket_url: str


class ApprovalDecision(BaseModel):
    """Request body for POST /api/v1/runs/{run_id}/approvals."""
    approval_id: str
    decision: Literal["approve", "reject", "modify"]
    modification: Optional[str] = None


class RunReport(BaseModel):
    """Complete run report returned by GET /api/v1/runs/{run_id}."""
    run_id: str
    scenario: str
    work_plan: Optional[WorkPlan] = None
    task_plan: Optional[TaskPlan] = None
    sources: list[Source] = []
    noise_assessments: list[NoiseAssessment] = []
    insights: list[Insight] = []
    conflicts: Optional[ConflictResolution] = None
    actions: list[Action] = []
    side_effects: list[SideEffectAnalysis] = []
    execution_log: list[ActionStep] = []
    before_state: dict = {}
    after_state: dict = {}
    metric_descriptions: dict = {}
    summary: str = ""
    metrics: Optional[RunMetrics] = None
    baseline_comparison: Optional[BaselineComparison] = None
    started_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None
    status: Literal["queued", "running", "completed", "failed", "partial"] = "queued"


class RunListItem(BaseModel):
    """Single item in the runs list response."""
    run_id: str
    scenario: str
    started_at: Optional[datetime] = None
    status: str


class RunListResponse(BaseModel):
    """Response for GET /api/v1/runs."""
    runs: list[RunListItem] = []
    total: int = 0
