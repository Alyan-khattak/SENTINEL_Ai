"""
SENTINEL FastAPI Backend — Main Entry Point
Canon: idea.md §8, planning.md Hour 15
"""

import asyncio
import json
import os
import sys
from contextlib import asynccontextmanager
from datetime import datetime, timezone
from uuid import uuid4
from typing import Optional

from fastapi import FastAPI, WebSocket, WebSocketDisconnect, BackgroundTasks, HTTPException
from fastapi.middleware.cors import CORSMiddleware

# Ensure backend dir is in path for local imports
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from models import (
    AnalysisRequest, RunStartResponse, ApprovalDecision,
    RunReport, RunListResponse, RunListItem,
    BaselineComparison,
)
from database import init_db, save_run, update_run_status, get_run, list_runs
from config import settings
from utils.logger import logger


# --- Lifespan (replaces deprecated on_event) ---
@asynccontextmanager
async def lifespan(app: FastAPI):
    init_db()
    os.makedirs(settings.TRACES_DIR, exist_ok=True)
    logger.info("SENTINEL API started")
    yield


# --- App Setup ---
app = FastAPI(
    title="SENTINEL API",
    description="Signal-to-Action Autonomous Agent — Google Antigravity Hackathon",
    version="1.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

# In-memory stores for active runs and WebSocket queues
_run_reports: dict[str, RunReport] = {}
_ws_queues: dict[str, list[asyncio.Queue]] = {}
_approval_events: dict[str, asyncio.Event] = {}
_approval_decisions: dict[str, dict] = {}


# --- Helpers ---
def generate_run_id() -> str:
    """Generate a run ID in format run_YYYY_MM_DD_6hex."""
    now = datetime.now(timezone.utc)
    hex_part = uuid4().hex[:6]
    return f"run_{now.year}_{now.month:02d}_{now.day:02d}_{hex_part}"


async def _make_emit(run_id: str):
    """Create a WebSocket emit coroutine for a specific run."""
    async def emit(payload: dict):
        if run_id in _ws_queues:
            for queue in _ws_queues[run_id]:
                await queue.put(payload)
    return emit


async def _background_run(run_id: str, request: AnalysisRequest):
    """Background task: runs the full SENTINEL pipeline via the orchestrator."""
    # Import here to avoid circular imports and to pick up path correctly
    from agents.orchestrator import orchestrate_run

    emit_fn = await _make_emit(run_id)
    save_run(run_id, request.scenario, request.constraints.model_dump_json())

    # Register approval event so the orchestrator can pause for user input
    _approval_events[run_id] = asyncio.Event()

    async def ws_emit(payload: dict):
        await emit_fn(payload)

    async def approval_gate(approval_id: str) -> dict:
        """Wait for user approval decision, timeout after 60s and auto-approve."""
        _approval_events[run_id].clear()
        try:
            await asyncio.wait_for(_approval_events[run_id].wait(), timeout=60.0)
            return _approval_decisions.get(run_id, {"decision": "approve"})
        except asyncio.TimeoutError:
            logger.warning(f"[{run_id}] Approval timeout — auto-approving")
            return {"decision": "approve"}

    try:
        report = await orchestrate_run(
            run_id=run_id,
            request=request,
            ws_emit=ws_emit,
            approval_gate=approval_gate,
        )
    except Exception as e:
        logger.error(f"[{run_id}] Orchestrator raised: {e}")
        import traceback
        traceback.print_exc()
        report = RunReport(
            run_id=run_id, scenario=request.scenario,
            status="failed", started_at=datetime.now(timezone.utc),
            completed_at=datetime.now(timezone.utc),
        )

    _run_reports[run_id] = report

    # Clean up approval state
    _approval_events.pop(run_id, None)
    _approval_decisions.pop(run_id, None)

    summary = report.metrics.summary() if report.metrics else {}
    update_run_status(
        run_id, report.status,
        completed_at=report.completed_at.isoformat() if report.completed_at else None,
        total_llm_calls=summary.get("total_llm_calls", 0),
        total_duration=summary.get("total_duration_seconds", 0.0),
    )


# --- REST Endpoints ---

@app.post("/api/v1/runs", status_code=202, response_model=RunStartResponse)
async def start_run(req: AnalysisRequest, background_tasks: BackgroundTasks):
    """Start a new analysis run. Returns immediately with run_id."""
    run_id = generate_run_id()
    ws_url = f"/ws/runs/{run_id}"

    _ws_queues[run_id] = []
    background_tasks.add_task(_background_run, run_id, req)

    logger.info(f"Run {run_id} queued for scenario: {req.scenario}")
    return RunStartResponse(run_id=run_id, status="queued", websocket_url=ws_url)


@app.get("/api/v1/runs/{run_id}", response_model=RunReport)
async def get_run_report(run_id: str):
    """Fetch the full run report."""
    if run_id in _run_reports:
        return _run_reports[run_id]

    # Check for persisted trace file
    trace_path = os.path.join(settings.TRACES_DIR, run_id, "trace.json")
    if os.path.exists(trace_path):
        with open(trace_path, "r") as f:
            return RunReport(**json.load(f))

    db_run = get_run(run_id)
    if not db_run:
        raise HTTPException(status_code=404, detail=f"No run exists for run_id={run_id}")

    raise HTTPException(status_code=404, detail=f"Run report not yet available for run_id={run_id}")


@app.get("/api/v1/runs/{run_id}/trace")
async def get_trace(run_id: str):
    """Fetch the full ADK trace JSON."""
    trace_path = os.path.join(settings.TRACES_DIR, run_id, "trace.json")
    if os.path.exists(trace_path):
        with open(trace_path, "r") as f:
            return json.load(f)
    raise HTTPException(status_code=404, detail=f"No trace found for run_id={run_id}")


@app.get("/api/v1/runs", response_model=RunListResponse)
async def list_all_runs():
    """List recent runs."""
    runs = list_runs()
    items = [
        RunListItem(
            run_id=r["run_id"], scenario=r["scenario"],
            started_at=r.get("started_at"), status=r.get("status", "unknown"),
        )
        for r in runs
    ]
    return RunListResponse(runs=items, total=len(items))


@app.post("/api/v1/runs/{run_id}/approvals")
async def submit_approval(run_id: str, decision: ApprovalDecision):
    """Submit an approval decision for a paused destructive action."""
    _approval_decisions[run_id] = {
        "approval_id": decision.approval_id,
        "decision": decision.decision,
        "modification": decision.modification,
    }
    if run_id in _approval_events:
        _approval_events[run_id].set()
    return {"status": "delivered", "run_id": run_id}


# --- WebSocket ---

@app.websocket("/ws/runs/{run_id}")
async def websocket_run(websocket: WebSocket, run_id: str):
    """Stream run events until run_completed or run_failed."""
    await websocket.accept()
    queue: asyncio.Queue = asyncio.Queue()

    if run_id not in _ws_queues:
        _ws_queues[run_id] = []
    _ws_queues[run_id].append(queue)

    # If there's already a completed report, send it immediately
    if run_id in _run_reports:
        report = _run_reports[run_id]
        if report.status in ("completed", "failed"):
            final_event = {
                "event": "run_completed" if report.status == "completed" else "run_failed",
                "run_id": run_id,
                "timestamp": datetime.now(timezone.utc).isoformat(),
                "data": {"status": report.status},
            }
            try:
                await websocket.send_json(final_event)
            except Exception:
                pass
            finally:
                if run_id in _ws_queues and queue in _ws_queues[run_id]:
                    _ws_queues[run_id].remove(queue)
                try:
                    await websocket.close()
                except Exception:
                    pass
            return

    try:
        while True:
            try:
                event = await asyncio.wait_for(queue.get(), timeout=120.0)
            except asyncio.TimeoutError:
                # Send ping to keep connection alive
                try:
                    await websocket.send_json({"event": "ping", "run_id": run_id})
                except Exception:
                    break
                continue

            await websocket.send_json(event)
            if event.get("event") in ("run_completed", "run_failed"):
                break
    except WebSocketDisconnect:
        logger.info(f"WebSocket disconnected for run {run_id}")
    finally:
        if run_id in _ws_queues and queue in _ws_queues[run_id]:
            _ws_queues[run_id].remove(queue)
        try:
            await websocket.close()
        except Exception:
            pass


# --- Health ---
@app.get("/health")
async def health():
    return {"status": "ok", "service": "sentinel", "version": "1.0.0"}
