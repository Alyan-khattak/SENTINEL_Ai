"""
SENTINEL Action Planner Agent (Module 6)
Canon: idea.md Module 6, planning.md Hour 11
"""

import json
from typing import Optional
from uuid import uuid4

from models.action import Action, Constraints
from models.insight import Insight, ConflictResolution
from utils.constraint_validator import validate_action
from utils.llm_client import LLMClient, extract_json
from utils.logger import logger


def _generate_default_actions(scenario: str) -> list[Action]:
    """Generate deterministic default actions for known scenarios."""
    if scenario == "inventory_shortage":
        return [
            Action(
                action_id="act_001", name="validate_stock_levels",
                description="Verify current stock levels against warehouse system",
                depends_on=[], estimated_cost_pkr=0, estimated_duration_minutes=5,
                affected_resources=["warehouse_staff"], urgency_tier="critical",
                is_destructive=False,
            ),
            Action(
                action_id="act_002", name="notify_procurement_team",
                description="Send emergency stock alert to procurement team via email and SMS",
                depends_on=["act_001"], estimated_cost_pkr=500, estimated_duration_minutes=2,
                affected_resources=[], urgency_tier="critical",
                is_destructive=False,
            ),
            Action(
                action_id="act_003", name="place_emergency_order",
                description="Place emergency order of 8,000 units of SKU001 with primary supplier",
                depends_on=["act_002"], estimated_cost_pkr=800000, estimated_duration_minutes=30,
                affected_resources=["delivery_trucks"], urgency_tier="critical",
                is_destructive=True,
            ),
            Action(
                action_id="act_004", name="update_delivery_schedule",
                description="Update CRM delivery schedules to reflect emergency order timeline",
                depends_on=["act_003"], estimated_cost_pkr=0, estimated_duration_minutes=10,
                affected_resources=[], urgency_tier="high",
                is_destructive=False,
            ),
            Action(
                action_id="act_005", name="schedule_stock_monitoring",
                description="Set up automated stock level monitoring every 6 hours",
                depends_on=["act_004"], estimated_cost_pkr=0, estimated_duration_minutes=5,
                affected_resources=[], urgency_tier="medium",
                is_destructive=False,
            ),
        ]
    return []


async def run_action_planner(
    insights: list[Insight],
    conflicts: ConflictResolution,
    constraints: Constraints,
    scenario: str = "inventory_shortage",
    llm_client: Optional[LLMClient] = None,
    run_id: str = "",
) -> list[Action]:
    logger.info(f"[{run_id}] Action Planner starting")

    actions: list[Action] = []

    if llm_client:
        try:
            from prompts.action import ACTION_PROMPT
            prompt = ACTION_PROMPT.format(
                scenario=scenario,
                insights_json=json.dumps([i.model_dump() for i in insights], default=str),
                conflicts_json=json.dumps(conflicts.model_dump(), default=str),
                constraints_json=json.dumps(constraints.model_dump()),
            )
            raw = await llm_client.call(prompt, run_id=run_id)
            parsed = extract_json(raw)
            action_list = parsed if isinstance(parsed, list) else parsed.get("actions", [])
            for a in action_list:
                a.setdefault("action_id", f"act_{uuid4().hex[:6]}")
                a.setdefault("depends_on", [])
                a.setdefault("estimated_cost_pkr", 0)
                a.setdefault("estimated_duration_minutes", 30)
                a.setdefault("affected_resources", [])
                a.setdefault("urgency_tier", "medium")
                a.setdefault("is_destructive", False)
                actions.append(Action(**a))
            logger.info(f"[{run_id}] Action Planner: LLM returned {len(actions)} actions")
        except Exception as exc:
            logger.warning(f"[{run_id}] Action Planner LLM failed ({exc}), using defaults")

    if not actions:
        actions = _generate_default_actions(scenario)

    # Validate each action against constraints
    validated = []
    for action in actions:
        validated_action, violations = validate_action(action, constraints)
        if violations:
            logger.info(f"[{run_id}] Action {action.name}: {len(violations)} constraint violations")
        validated.append(validated_action)

    logger.info(f"[{run_id}] Action Planner produced {len(validated)} actions")
    return validated
