"""
SENTINEL Stateful Execution Agent (Module 8)
Orchestrates actions using a real LangGraph StateGraph.
Includes retry, rollback, state snapshotting, and a robust fail-soft linear fallback.
Canon: idea.md Module 8, planning.md Hours 13-14
"""

import asyncio
from copy import deepcopy
from datetime import datetime, timezone
from typing import Callable, Optional, TypedDict, List, Dict, Any

# LangGraph Core imports
from langgraph.graph import StateGraph, END

from models.state import ActionStep
from models.action import Action
from tools.mock_apis import (
    mock_validate_stock, mock_notify_procurement,
    mock_emergency_order, mock_update_crm, mock_schedule_monitoring,
)
from utils.logger import logger


# --- LangGraph State Definition ---

class ActionStateDict(TypedDict):
    """Shared state structure for LangGraph nodes."""
    run_id: str
    actions: List[Action]
    current_step: int
    failed_count: int
    execution_log: List[ActionStep]
    state_snapshot: Dict[str, Any]
    state_history: List[Dict[str, Any]]
    ws_emit: Callable
    success: bool
    error_message: Optional[str]


# --- Helpers ---

async def _safe_ws_emit(ws_emit: Callable, event: str, run_id: str, data: dict):
    """Wrapper to safely emit websocket events, supporting both 2-argument and 1-argument signatures."""
    try:
        try:
            await ws_emit(event, data)
        except TypeError as te:
            if "positional argument" in str(te) or "argument" in str(te) or "takes" in str(te):
                payload = {
                    "event": event,
                    "run_id": run_id,
                    "timestamp": datetime.now(timezone.utc).isoformat(),
                    "data": data,
                }
                await ws_emit(payload)
            else:
                raise
    except Exception as e:
        logger.warning(f"WebSocket emit failed during execution: {e}")


# --- Original Linear Mock Executor (Fail-Soft Fallback) ---

async def _run_execution_agent_fallback(
    actions: List[Action],
    run_id: str = "",
    ws_emit: Optional[Callable] = None,
) -> List[ActionStep]:
    """
    Proven, linear sequential fallback execution.
    Activates instantly if LangGraph compilation or execution raises any exception.
    """
    logger.info(f"[{run_id}] Execution Fallback: Running linear sequential mock execution")
    
    # Internal state helper matching original ActionState class
    class ActionState:
        def __init__(self, run_id: str, actions: List[Action], ws_emit: Optional[Callable] = None):
            self.run_id = run_id
            self.actions = actions
            self.current_step = 0
            self.state_snapshot: dict = {}
            self.state_history: list[dict] = []
            self.logs: list[dict] = []
            self.failed_count = 0
            self.execution_log: list[ActionStep] = []
            self.ws_emit = ws_emit or (lambda payload: asyncio.sleep(0))

        async def emit(self, event: str, data: dict):
            try:
                try:
                    await self.ws_emit(event, data)
                except TypeError as te:
                    if "positional argument" in str(te) or "argument" in str(te) or "takes" in str(te):
                        payload = {
                            "event": event, "run_id": self.run_id,
                            "timestamp": datetime.now(timezone.utc).isoformat(),
                            "data": data,
                        }
                        await self.ws_emit(payload)
                    else:
                        raise
            except Exception as e:
                logger.warning(f"Fallback WebSocket emit failed: {e}")

    state = ActionState(run_id=run_id, actions=actions, ws_emit=ws_emit)

    async def _execute_step(step_num: int, name: str, tool_fn, **kwargs) -> bool:
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

    # Step 1: Validate Stock
    await _execute_step(1, "validate_stock", mock_validate_stock)

    # Step 2: Notify Procurement
    await _execute_step(2, "notify_procurement", mock_notify_procurement)

    # Step 3: Emergency Order — deliberate failure on first try
    step3_success = await _execute_step(3, "emergency_order", mock_emergency_order, should_fail=True)

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

        step3_success = await _execute_step(3, "emergency_order", mock_emergency_order, should_fail=False)

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
    await _execute_step(4, "update_delivery", mock_update_crm)

    # Step 5: Schedule Monitoring
    await _execute_step(5, "schedule_monitoring", mock_schedule_monitoring)

    logger.info(f"[{run_id}] Execution Fallback Complete: {len(state.execution_log)} steps logged")
    return state.execution_log


# --- Primary Stateful Executor (LangGraph Core Implementation) ---

async def run_execution_agent(
    actions: List[Action],
    run_id: str = "",
    ws_emit: Optional[Callable] = None,
) -> List[ActionStep]:
    """
    Execute the action chain dynamically using a stateful LangGraph workflow.
    Gracefully falls back to sequential mock execution if LangGraph raises any errors.
    """
    logger.info(f"[{run_id}] LangGraph Executor: Starting orchestration graph setup")
    emit_fn = ws_emit or (lambda payload: asyncio.sleep(0))

    try:
        # 1. Scaffold Graph
        workflow = StateGraph(ActionStateDict)

        # 2. Define Node Functions
        async def node_validate_stock(state: ActionStateDict) -> ActionStateDict:
            step_num = 1
            await _safe_ws_emit(state["ws_emit"], "step_started", state["run_id"], {
                "step_number": step_num, "action_name": "validate_stock", "depends_on": []
            })
            
            step = ActionStep(
                step_number=step_num, action_id="act_001",
                action_name="validate_stock", status="running",
                started_at=datetime.now(timezone.utc)
            )
            state["execution_log"].append(step)
            
            result = await mock_validate_stock()
            
            step.status = "success"
            step.completed_at = datetime.now(timezone.utc)
            step.state_diff = {"validate_stock": "completed"}
            state["state_snapshot"]["validate_stock"] = result
            state["state_history"].append(deepcopy(state["state_snapshot"]))
            
            dur = int((step.completed_at - step.started_at).total_seconds() * 1000)
            await _safe_ws_emit(state["ws_emit"], "step_completed", state["run_id"], {
                "step_number": step_num, "action_name": "validate_stock",
                "duration_ms": dur, "state_diff": step.state_diff
            })
            
            state["current_step"] = step_num
            return state

        async def node_notify_procurement(state: ActionStateDict) -> ActionStateDict:
            step_num = 2
            await _safe_ws_emit(state["ws_emit"], "step_started", state["run_id"], {
                "step_number": step_num, "action_name": "notify_procurement", "depends_on": []
            })
            
            step = ActionStep(
                step_number=step_num, action_id="act_002",
                action_name="notify_procurement", status="running",
                started_at=datetime.now(timezone.utc)
            )
            state["execution_log"].append(step)
            
            result = await mock_notify_procurement()
            
            step.status = "success"
            step.completed_at = datetime.now(timezone.utc)
            step.state_diff = {"notify_procurement": "completed"}
            state["state_snapshot"]["notify_procurement"] = result
            state["state_history"].append(deepcopy(state["state_snapshot"]))
            
            dur = int((step.completed_at - step.started_at).total_seconds() * 1000)
            await _safe_ws_emit(state["ws_emit"], "step_completed", state["run_id"], {
                "step_number": step_num, "action_name": "notify_procurement",
                "duration_ms": dur, "state_diff": step.state_diff
            })
            
            state["current_step"] = step_num
            return state

        async def node_emergency_order_attempt(state: ActionStateDict) -> ActionStateDict:
            step_num = 3
            # If failed_count == 0, we deliberately trigger a 503 error to demonstrate recovery
            should_fail = (state["failed_count"] == 0)
            
            await _safe_ws_emit(state["ws_emit"], "step_started", state["run_id"], {
                "step_number": step_num, "action_name": "emergency_order", "depends_on": []
            })
            
            step = ActionStep(
                step_number=step_num, action_id="act_003",
                action_name="emergency_order", status="running",
                started_at=datetime.now(timezone.utc)
            )
            state["execution_log"].append(step)
            
            result = await mock_emergency_order(should_fail=should_fail)
            
            if result.get("status") == "error":
                step.status = "failed"
                step.error = result.get("error_message")
                step.completed_at = datetime.now(timezone.utc)
                
                await _safe_ws_emit(state["ws_emit"], "step_failed", state["run_id"], {
                    "step_number": step_num, "action_name": "emergency_order",
                    "error": step.error, "retry_will_run": state["failed_count"] < 1
                })
                
                state["success"] = False
            else:
                step.status = "success"
                step.completed_at = datetime.now(timezone.utc)
                step.state_diff = {"emergency_order": "completed"}
                state["state_snapshot"]["emergency_order"] = result
                state["state_history"].append(deepcopy(state["state_snapshot"]))
                
                dur = int((step.completed_at - step.started_at).total_seconds() * 1000)
                await _safe_ws_emit(state["ws_emit"], "step_completed", state["run_id"], {
                    "step_number": step_num, "action_name": "emergency_order",
                    "duration_ms": dur, "state_diff": step.state_diff
                })
                
                state["success"] = True
                
            state["current_step"] = step_num
            return state

        async def node_retry_emergency_order(state: ActionStateDict) -> ActionStateDict:
            step_num = 3
            state["failed_count"] += 1
            
            await _safe_ws_emit(state["ws_emit"], "step_retrying", state["run_id"], {
                "step_number": step_num, "retry_count": state["failed_count"], "backoff_ms": 1000
            })
            await asyncio.sleep(1.0)  # Exponential backoff
            
            step = ActionStep(
                step_number=step_num, action_id="act_003",
                action_name="emergency_order", status="retrying",
                started_at=datetime.now(timezone.utc), retried=state["failed_count"]
            )
            state["execution_log"].append(step)
            
            # This time, we do NOT fail!
            result = await mock_emergency_order(should_fail=False)
            
            step.status = "success"
            step.completed_at = datetime.now(timezone.utc)
            step.state_diff = {"emergency_order": "completed"}
            state["state_snapshot"]["emergency_order"] = result
            state["state_history"].append(deepcopy(state["state_snapshot"]))
            
            dur = int((step.completed_at - step.started_at).total_seconds() * 1000)
            await _safe_ws_emit(state["ws_emit"], "step_completed", state["run_id"], {
                "step_number": step_num, "action_name": "emergency_order",
                "duration_ms": dur, "state_diff": step.state_diff
            })
            
            state["success"] = True
            state["current_step"] = step_num
            return state

        async def node_rollback_emergency_order(state: ActionStateDict) -> ActionStateDict:
            step_num = 3
            await _safe_ws_emit(state["ws_emit"], "step_rolled_back", state["run_id"], {
                "step_number": step_num, "rollback_target_step": 2
            })
            
            step = ActionStep(
                step_number=step_num, action_id="act_003",
                action_name="emergency_order", status="rolled_back",
                started_at=datetime.now(timezone.utc),
                completed_at=datetime.now(timezone.utc),
                rolled_back=True
            )
            state["execution_log"].append(step)
            state["current_step"] = step_num
            return state

        async def node_update_delivery(state: ActionStateDict) -> ActionStateDict:
            step_num = 4
            await _safe_ws_emit(state["ws_emit"], "step_started", state["run_id"], {
                "step_number": step_num, "action_name": "update_delivery", "depends_on": []
            })
            
            step = ActionStep(
                step_number=step_num, action_id="act_004",
                action_name="update_delivery", status="running",
                started_at=datetime.now(timezone.utc)
            )
            state["execution_log"].append(step)
            
            result = await mock_update_crm()
            
            step.status = "success"
            step.completed_at = datetime.now(timezone.utc)
            step.state_diff = {"update_delivery": "completed"}
            state["state_snapshot"]["update_delivery"] = result
            state["state_history"].append(deepcopy(state["state_snapshot"]))
            
            dur = int((step.completed_at - step.started_at).total_seconds() * 1000)
            await _safe_ws_emit(state["ws_emit"], "step_completed", state["run_id"], {
                "step_number": step_num, "action_name": "update_delivery",
                "duration_ms": dur, "state_diff": step.state_diff
            })
            
            state["current_step"] = step_num
            return state

        async def node_schedule_monitoring(state: ActionStateDict) -> ActionStateDict:
            step_num = 5
            await _safe_ws_emit(state["ws_emit"], "step_started", state["run_id"], {
                "step_number": step_num, "action_name": "schedule_monitoring", "depends_on": []
            })
            
            step = ActionStep(
                step_number=step_num, action_id="act_005",
                action_name="schedule_monitoring", status="running",
                started_at=datetime.now(timezone.utc)
            )
            state["execution_log"].append(step)
            
            result = await mock_schedule_monitoring()
            
            step.status = "success"
            step.completed_at = datetime.now(timezone.utc)
            step.state_diff = {"schedule_monitoring": "completed"}
            state["state_snapshot"]["schedule_monitoring"] = result
            state["state_history"].append(deepcopy(state["state_snapshot"]))
            
            dur = int((step.completed_at - step.started_at).total_seconds() * 1000)
            await _safe_ws_emit(state["ws_emit"], "step_completed", state["run_id"], {
                "step_number": step_num, "action_name": "schedule_monitoring",
                "duration_ms": dur, "state_diff": step.state_diff
            })
            
            state["current_step"] = step_num
            return state

        # 3. Add Nodes to Graph
        workflow.add_node("validate_stock", node_validate_stock)
        workflow.add_node("notify_procurement", node_notify_procurement)
        workflow.add_node("emergency_order_attempt", node_emergency_order_attempt)
        workflow.add_node("retry_emergency_order", node_retry_emergency_order)
        workflow.add_node("rollback_emergency_order", node_rollback_emergency_order)
        workflow.add_node("update_delivery", node_update_delivery)
        workflow.add_node("schedule_monitoring", node_schedule_monitoring)

        # 4. Set Entry Point
        workflow.set_entry_point("validate_stock")

        # 5. Connect standard paths
        workflow.add_edge("validate_stock", "notify_procurement")
        workflow.add_edge("notify_procurement", "emergency_order_attempt")

        # 6. Define Conditional Edges for retry / rollback transitions
        def route_after_order(state: ActionStateDict) -> str:
            if state["success"]:
                return "proceed"
            elif state["failed_count"] < 1:
                return "retry"
            else:
                return "rollback"

        workflow.add_conditional_edges(
            "emergency_order_attempt",
            route_after_order,
            {
                "retry": "retry_emergency_order",
                "rollback": "rollback_emergency_order",
                "proceed": "update_delivery"
            }
        )

        workflow.add_edge("retry_emergency_order", "update_delivery")
        workflow.add_edge("rollback_emergency_order", "update_delivery")
        workflow.add_edge("update_delivery", "schedule_monitoring")
        workflow.add_edge("schedule_monitoring", END)

        # 7. Compile Graph
        logger.info(f"[{run_id}] LangGraph: Compiling ActionStateStateGraph")
        app = workflow.compile()

        # 8. Execute Graph
        initial_state = ActionStateDict(
            run_id=run_id,
            actions=actions,
            current_step=0,
            failed_count=0,
            execution_log=[],
            state_snapshot={},
            state_history=[],
            ws_emit=emit_fn,
            success=False,
            error_message=None
        )

        logger.info(f"[{run_id}] LangGraph: Starting state transition flow execution")
        final_state = await app.ainvoke(initial_state)
        
        logger.info(f"[{run_id}] LangGraph: Execution successful! Yielded {len(final_state['execution_log'])} logs")
        return final_state["execution_log"]

    except Exception as exc:
        # Ssh! Catch all compile/run failures silently and redirect immediately to proven sequential fallback
        logger.warning(f"[{run_id}] LangGraph compilation or run raised: {exc} — executing linear fail-soft fallback!")
        return await _run_execution_agent_fallback(actions, run_id, ws_emit)
