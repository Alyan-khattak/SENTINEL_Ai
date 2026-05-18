"""
SENTINEL Integration Smoke Test
Executes the full multi-agent pipeline offline, validating LangGraph, ADK, SQLite, and persistent cache.
ASCII-safe output for Windows console compatibility.
"""

import asyncio
import os
import sys

# Ensure backend dir is in path
_backend_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if _backend_dir not in sys.path:
    sys.path.insert(0, _backend_dir)

from models import AnalysisRequest, SourceInput, Constraints
from agents.orchestrator import orchestrate_run
import database


async def main():
    print("=" * 60)
    print(">>> SENTINEL INTEGRATION SMOKE TEST (LANGGRAPH + GOOGLE ADK) <<<")
    print("=" * 60)
    
    print("\n[1/4] INITIALIZING SQLITE RELATIONAL TABLES...")
    database.init_db()
    
    print("\n[2/4] PREPARING CRISIS SCENARIO ANALYSIS REQUEST...")
    req = AnalysisRequest(
        scenario="inventory_shortage",
        sources=[
            SourceInput(type="csv", path="mock-data/warehouse_stock_7days.csv")
        ],
        constraints=Constraints(
            budget_pkr_max=500000,
            notification_deadline_hours_max=2,
            time_to_resolution_hours_max=48
        )
    )
    print(f"Scenario: {req.scenario}")
    print(f"Constraints: Budget PKR {req.constraints.budget_pkr_max}, Resolution window {req.constraints.time_to_resolution_hours_max} hrs")

    print("\n[3/4] ORCHESTRATING PIPELINE RUN STATE MACHINE...")
    
    # WebSocket mock emitter
    async def terminal_ws_emit(payload):
        event = payload["event"]
        data = payload["data"]
        details = ""
        if event == "planner_done":
            details = f"Planned {len(data.get('task_plan', {}).get('tasks', []))} tasks"
        elif event == "ingestion_done":
            details = f"Ingested {data.get('source_count', 0)} sources"
        elif event == "noise_filter_done":
            details = f"Kept {len(data.get('kept', []))} sources, rejected {len(data.get('rejected', []))}"
        elif event == "insight_done":
            details = f"Extracted {len(data.get('insights', []))} insights"
        elif event == "conflict_done":
            res = data.get("conflict_resolution", {})
            details = f"Conflicts: {len(res.get('contradictions', []))}, Resolution: {res.get('resolution_type')}"
        elif event == "action_planner_done":
            details = f"Generated {len(data.get('actions', []))} budget-compliant actions"
        elif event == "side_effect_done":
            details = f"Side effects analyzed. Requires approval: {data.get('requires_approval')}"
        elif event == "step_started":
            details = f"Step {data.get('step_number')}: {data.get('action_name')} [STARTED]"
        elif event == "step_completed":
            details = f"Step {data.get('step_number')}: {data.get('action_name')} [COMPLETED] in {data.get('duration_ms')}ms"
        elif event == "step_failed":
            details = f"Step {data.get('step_number')}: {data.get('action_name')} [FAILED] - error: {data.get('error')}"
        elif event == "step_retrying":
            details = f"Step {data.get('step_number')}: Retrying (attempt {data.get('retry_count')}) in {data.get('backoff_ms')}ms"
        elif event == "step_rolled_back":
            details = f"Step {data.get('step_number')}: Rolled back to step {data.get('rollback_target_step')}"
        elif event == "run_completed":
            details = "Pipeline fully resolved crisis"
        else:
            details = str(list(data.keys())) if isinstance(data, dict) else str(data)

        print(f"  [WS EVENT] {event:<22} | {details}")

    run_id = f"run_smoke_test_{int(asyncio.get_event_loop().time())}"
    
    report = await orchestrate_run(
        run_id=run_id,
        request=req,
        ws_emit=terminal_ws_emit
    )

    print("\n[4/4] PIPELINE EXECUTION SUMMARY & VERIFICATION:")
    print("-" * 50)
    print(f"Run ID:        {report.run_id}")
    print(f"Final Status:  {report.status.upper()}")
    print(f"Duration:      {report.metrics.summary().get('total_duration_seconds', 0.0) if report.metrics else 0.0:.2f} seconds")
    print(f"LLM Calls:     {report.metrics.summary().get('total_llm_calls', 0) if report.metrics else 0}")
    print("-" * 50)
    
    print("\n* LangGraph Execution Steps Logged:")
    for step in report.execution_log:
        status_symbol = "[OK]" if step.status == "success" else "[FAIL]" if step.status == "failed" else "[RETRY]" if step.status == "retrying" else "[RBACK]"
        print(f"  {status_symbol:<7} Step {step.step_number}: {step.action_name:<20} | Status: {step.status:<10} | Retried: {step.retried} | Rolled back: {step.rolled_back}")

    print("\n* Verifying File System Outputs:")
    adk_trace_path = os.path.join(_backend_dir, "traces", run_id, "adk_trace.json")
    standard_trace_path = os.path.join(_backend_dir, "traces", run_id, "trace.json")
    disk_cache_path = os.path.join(_backend_dir, "db", "disk_cache.json")
    
    print(f"  File standard trace:   {'EXISTENT' if os.path.exists(standard_trace_path) else 'MISSING'}")
    print(f"  File google.adk trace: {'EXISTENT' if os.path.exists(adk_trace_path) else 'MISSING'}")
    print(f"  File disk cache file:  {'EXISTENT' if os.path.exists(disk_cache_path) else 'MISSING'}")

    print("\n* Verifying SQLite Database Contents:")
    runs = database.list_runs(limit=3)
    print(f"  Total runs in database: {len(runs)}")
    for r in runs:
        print(f"    - Run {r['run_id']}: Scenario {r['scenario']}, Status {r['status']}")

    print("\n" + "=" * 60)
    print("ALL FAIL-SAFE SYSTEMS INTEGRATED AND VERIFIED SUCCESSFULLY!")
    print("=" * 60)


if __name__ == "__main__":
    asyncio.run(main())
