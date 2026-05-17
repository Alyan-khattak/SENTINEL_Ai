"""
SENTINEL Planner Agent (Module 1)
Produces WorkPlan + TaskPlan before any execution.
Canon: idea.md Module 1, planning.md Hour 6 T1
"""

import json
from models.state import WorkPlan, TaskPlan
from prompts.planner import PLANNER_PROMPT
from utils.llm_client import LLMClient, extract_json
from utils.logger import logger


async def run_planner(
    scenario: str,
    source_paths: list[dict],
    llm_client: LLMClient,
    run_id: str = "",
) -> tuple[WorkPlan, TaskPlan]:
    """
    Generate a structured workplan and task plan for the given scenario.

    Args:
        scenario: The scenario name (e.g., "inventory_shortage")
        source_paths: List of source path dicts with type and path
        llm_client: Configured LLM client instance
        run_id: Current run ID for logging

    Returns:
        Tuple of (WorkPlan, TaskPlan)
    """
    logger.info(f"[{run_id}] Planner Agent starting for scenario: {scenario}")

    # Build source summaries for the prompt
    source_summaries = "\n".join(
        f"- {s['type']}: {s['path']}" for s in source_paths
    )

    prompt = PLANNER_PROMPT.format(
        scenario=scenario,
        n_sources=len(source_paths),
        source_summaries=source_summaries,
    )

    try:
        response = await llm_client.call(prompt, run_id=run_id)
        data = extract_json(response)

        work_plan = WorkPlan(**data["work_plan"])
        task_plan = TaskPlan(**data["task_plan"])

        logger.info(
            f"[{run_id}] Planner produced {len(work_plan.high_level_steps)} steps, "
            f"est. {work_plan.estimated_llm_calls} LLM calls"
        )
        return work_plan, task_plan

    except Exception as e:
        logger.warning(f"[{run_id}] Planner LLM call failed: {e}, using fallback plan")
        # Fallback: deterministic plan
        work_plan = WorkPlan(
            high_level_steps=[
                "Ingest and parse all source files",
                "Filter noise: remove duplicates, spam, and stale sources",
                "Extract structured insights with temporal analysis",
                "Detect and resolve contradictions across sources",
                "Plan constraint-bound action chain",
                "Analyze side effects and generate alternatives",
                "Execute action chain with failure recovery",
            ],
            expected_duration_seconds=30,
            estimated_llm_calls=7,
            fallback_strategy="Use deterministic rules if LLM is unavailable; "
                              "skip insight extraction and use raw source data directly.",
        )
        task_plan = TaskPlan(
            tasks=[
                {"task_id": "T1", "description": "Parse all input sources", "depends_on": [], "agent_assigned": "ingestion", "expected_output_schema": "List[Source]"},
                {"task_id": "T2", "description": "Filter noise and duplicates", "depends_on": ["T1"], "agent_assigned": "noise_filter", "expected_output_schema": "List[NoiseAssessment]"},
                {"task_id": "T3", "description": "Extract insights with temporal trends", "depends_on": ["T2"], "agent_assigned": "insight", "expected_output_schema": "List[Insight]"},
                {"task_id": "T4", "description": "Resolve contradictions", "depends_on": ["T3"], "agent_assigned": "conflict_resolver", "expected_output_schema": "ConflictResolution"},
                {"task_id": "T5", "description": "Plan actions with constraint checks", "depends_on": ["T4"], "agent_assigned": "action_planner", "expected_output_schema": "List[Action]"},
                {"task_id": "T6", "description": "Analyze side effects", "depends_on": ["T5"], "agent_assigned": "side_effect", "expected_output_schema": "List[SideEffectAnalysis]"},
                {"task_id": "T7", "description": "Execute action chain", "depends_on": ["T6"], "agent_assigned": "executor", "expected_output_schema": "List[ActionStep]"},
            ]
        )
        return work_plan, task_plan
