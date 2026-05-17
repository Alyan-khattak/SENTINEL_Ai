"""
SENTINEL Execution Agent (Module 8) — LangGraph State Machine
Canon: idea.md Module 8, planning.md Hours 13-14
"""

import asyncio
import json
from copy import deepcopy
from datetime import datetime, timezone
from typing import Callable, Optional

from models.state import ActionStep
from models.action import Action
from tools.mock_apis import (
    mock_validate_stock, mock_notify_procurement,
    mock_emergency_order, mock_update_crm, mock_schedule_monitoring,
)
from utils.logger import logger


class ActionState:
    """Shared mutable state for LangGraph-style execution."""
    def __init__(self, run_id: str, actions: list[Action], ws_emit: Optional[Callable] = None):
        self.run_id = run_id
        self.actions = actions
        self.current_step = 0
        self.state_snapshot: dict = {}
        self.state_history: list[dict] = []
        self.logs: list[dict] = []
        self.failed_count = 0
        self.execution_log: list[ActionStep] = []
        self.ws_emit = ws_emit or (lambda event, data: asyncio.sleep(0))

    async def emit(self, event: str, data: dict):
        try:
            await self.ws_emit(event, data)
        except Exception as e:
            logger.warning(f"WebSocket emit failed: {e}")


async def _execute_step(state: ActionState, step_num: int, name: str, tool_fn, **kwargs) -> bool:
    """Execute a single action step with the mock tool."""
    step = ActionStep(
        step_number=step_num, action_id=f"act_{step_num:03d}",
        action_name=name, status="running",
        started_at=datetime.now(timezone.utc),
    )
    state.execution_log.append(step)
    await state.emit("step_started", {
        "step_number": step_num, "action_name": name, "depends_on": [],
    })

    try:
        result = await tool_fn(**kwargs)
        if result.get("status") == "error":
            raise Exception(result.get("error_message", "Tool returned error"))

        step.status = "success"
        step.completed_at = datetime.now(timezone.utc)
        state.state_snapshot[name] = result
        state.state_history.append(deepcopy(state.state_snapshot))
        step.state_diff = {name: "completed"}

        duration_ms = int((step.completed_at - step.started_at).total_seconds() * 1000)
        await state.emit("step_completed", {
            "step_number": step_num, "action_name": name,
            "duration_ms": duration_ms, "state_diff": step.state_diff,
        })
        return True

    except Exception as e:
        step.status = "failed"
        step.error = str(e)
        step.completed_at = datetime.now(timezone.utc)
        await state.emit("step_failed", {
            "step_number": step_num, "action_name": name,
            "error": str(e), "retry_will_run": state.failed_count < 2,
        })
        return False


async def run_execution_agent(
    actions: list[Action],
    run_id: str = "",
    ws_emit: Optional[Callable] = None,
) -> list[ActionStep]:
    """
    Execute the action chain with retry, rollback, and state tracking.
    emergency_order deliberately fails on first attempt for demo.
    """
    logger.info(f"[{run_id}] Execution Agent starting with {len(actions)} actions")
    state = ActionState(run_id=run_id, actions=actions, ws_emit=ws_emit)

    # Step 1: Validate Stock
    await _execute_step(state, 1, "validate_stock", mock_validate_stock)

    # Step 2: Notify Procurement
    await _execute_step(state, 2, "notify_procurement", mock_notify_procurement)

    # Step 3: Emergency Order — deliberate failure on first try
    step3_success = await _execute_step(
        state, 3, "emergency_order", mock_emergency_order,
        should_fail=True,
    )

    if not step3_success:
        state.failed_count = 1
        # Retry
        await state.emit("step_retrying", {
            "step_number": 3, "retry_count": 1, "backoff_ms": 1000,
        })
        await asyncio.sleep(1.0)  # Exponential backoff

        retry_step = ActionStep(
            step_number=3, action_id="act_003",
            action_name="emergency_order", status="retrying",
            started_at=datetime.now(timezone.utc), retried=1,
        )
        state.execution_log.append(retry_step)

        step3_success = await _execute_step(
            state, 3, "emergency_order", mock_emergency_order,
            should_fail=False,
        )

        if not step3_success:
            # Rollback
            await state.emit("step_rolled_back", {
                "step_number": 3, "rollback_target_step": 2,
            })
            rollback_step = ActionStep(
                step_number=3, action_id="act_003",
                action_name="emergency_order", status="rolled_back",
                started_at=datetime.now(timezone.utc),
                completed_at=datetime.now(timezone.utc),
                rolled_back=True,
            )
            state.execution_log.append(rollback_step)

    # Step 4: Update Delivery
    await _execute_step(state, 4, "update_delivery", mock_update_crm)

    # Step 5: Schedule Monitoring
    await _execute_step(state, 5, "schedule_monitoring", mock_schedule_monitoring)

    logger.info(f"[{run_id}] Execution complete: {len(state.execution_log)} steps logged")
    return state.execution_log
