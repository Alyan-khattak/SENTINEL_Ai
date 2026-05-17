"""
SENTINEL Conflict Resolver Agent (Module 5)
Canon: idea.md Module 5, planning.md Hour 9
"""

import json
from datetime import datetime, timezone
from typing import Optional

from models.insight import Insight, Contradiction, ConflictResolution
from models.source import Source
from utils.credibility import compute_credibility
from utils.llm_client import LLMClient, extract_json
from utils.logger import logger


async def run_conflict_resolver(
    insights: list[Insight],
    sources: list[Source],
    scenario: str = "inventory_shortage",
    llm_client: Optional[LLMClient] = None,
    run_id: str = "",
) -> ConflictResolution:
    logger.info(f"[{run_id}] Conflict Resolver starting with {len(insights)} insights")
    now = datetime.now(timezone.utc)

    # Build source credibility map
    source_map = {s.source_id: s for s in sources}
    cred_map = {s.source_id: compute_credibility(s, now) for s in sources}

    if llm_client:
        try:
            from prompts.conflict import CONFLICT_PROMPT
            insights_json = json.dumps([i.model_dump() for i in insights], indent=2)
            credibility_json = json.dumps(cred_map, indent=2)
            prompt = CONFLICT_PROMPT.format(
                scenario=scenario,
                insights_json=insights_json,
                credibility_json=credibility_json
            )
            
            response_text = await llm_client.call(prompt, run_id=run_id)
            conflict_data = extract_json(response_text)
            
            result = ConflictResolution(**conflict_data)
            logger.info(f"[{run_id}] Conflicts: {len(result.contradictions)} detected via LLM, type={result.resolution_type}")
            return result
        except Exception as e:
            logger.warning(f"[{run_id}] Conflict Resolver LLM failed: {e}. Falling back to deterministic resolution.")

    # Group insights by metric
    metric_groups: dict[str, list[Insight]] = {}
    for ins in insights:
        key = ins.metric
        metric_groups.setdefault(key, []).append(ins)

    contradictions = []
    for metric, group in metric_groups.items():
        if len(group) < 2:
            continue
        # Check if values differ
        values = set()
        for ins in group:
            values.add(str(ins.value))
        if len(values) <= 1:
            continue

        # Build conflicting values
        conflicting = []
        for ins in group:
            for sid in ins.source_ids:
                conflicting.append({
                    "source_id": sid,
                    "value": str(ins.value),
                    "credibility": cred_map.get(sid, 5),
                })

        # Determine winner by credibility
        if conflicting:
            sorted_cv = sorted(conflicting, key=lambda x: x["credibility"], reverse=True)
            top = sorted_cv[0]["credibility"]
            second = sorted_cv[1]["credibility"] if len(sorted_cv) > 1 else 0
            winner = sorted_cv[0]["source_id"] if (top - second) > 2 else None
            reasoning = (
                f"Source {winner} has higher credibility ({top} vs {second})"
                if winner else
                f"Sources have similar credibility ({top} vs {second}), investigation needed"
            )
            contradictions.append(Contradiction(
                metric=metric,
                conflicting_values=conflicting,
                winner_source_id=winner,
                reasoning=reasoning,
            ))

    if not contradictions:
        return ConflictResolution(
            contradictions=[], resolution_type="resolved",
            investigation_actions=[], confidence=1.0,
        )

    all_resolved = all(c.winner_source_id is not None for c in contradictions)
    res_type = "resolved" if all_resolved else "investigation_required"
    inv_actions = []
    if not all_resolved:
        inv_actions = [
            "Query supplier API directly for latest stock data",
            "Wait for next scheduled warehouse data refresh",
            "Cross-reference with shipping manifests",
        ]

    confidence = 0.85 if all_resolved else 0.55
    result = ConflictResolution(
        contradictions=contradictions,
        resolution_type=res_type,
        investigation_actions=inv_actions,
        confidence=confidence,
    )
    logger.info(f"[{run_id}] Conflicts: {len(contradictions)} detected deterministically, type={res_type}")
    return result
