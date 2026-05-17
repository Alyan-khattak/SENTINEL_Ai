"""
SENTINEL Side-Effect Analyzer Agent (Module 7)
Canon: idea.md Module 7, planning.md Hour 12
"""

import json
from typing import Optional
from uuid import uuid4

from models.action import Action, SideEffectImpact, SideEffectAnalysis
from utils.llm_client import LLMClient, extract_json
from utils.logger import logger


def _analyze_side_effects_deterministic(action: Action) -> SideEffectAnalysis:
    """Deterministic side-effect prediction for known action types."""
    impacts = []
    requires_approval = False
    alternative_path = None

    # Robust approval check: trigger if it is an order/purchase, costly (>10k PKR), or pre-flagged as destructive
    is_procurement = any(kw in action.name.lower() for kw in ["order", "purchase", "buy", "procure", "replenish", "shift", "change"])
    if is_procurement or action.is_destructive or action.estimated_cost_pkr > 10000:
        impacts = [
            SideEffectImpact(
                area="cashflow", direction="negative", magnitude="high",
                explanation=f"Emergency order of PKR {action.estimated_cost_pkr:,} reduces available cash by ~18%",
                mitigation="Split order into 2 batches spaced 3 days apart",
            ),
            SideEffectImpact(
                area="warehouse_capacity", direction="positive", magnitude="medium",
                explanation="Replenished stock restores warehouse utilization to target levels",
                mitigation="No mitigation needed — positive impact",
            ),
            SideEffectImpact(
                area="supplier_relationships", direction="negative", magnitude="low",
                explanation="Emergency orders may strain supplier capacity",
                mitigation="Communicate transparently and offer premium on future orders",
            ),
            SideEffectImpact(
                area="customer_satisfaction", direction="positive", magnitude="high",
                explanation="Restocking prevents customer-facing stockouts",
                mitigation="No mitigation needed — positive impact",
            ),
        ]
        requires_approval = True
        alternative_path = [
            {
                "name": "staggered_order",
                "description": "Split emergency order into 3 smaller batches over 3 days (avoids cashflow spikes)",
                "estimated_cost_pkr": action.estimated_cost_pkr,
                "estimated_duration_minutes": 4320,
            },
            {
                "name": "regional_supplier_shift",
                "description": "Karachi Bypass: Order 40% stock from local Karachi supplier (evades transport strikes)",
                "estimated_cost_pkr": int(action.estimated_cost_pkr * 0.9),
                "estimated_duration_minutes": 1440,
            }
        ]

    elif "notify" in action.name.lower():
        impacts = [
            SideEffectImpact(
                area="customer_satisfaction", direction="positive", magnitude="low",
                explanation="Proactive notification builds trust with stakeholders",
                mitigation="No mitigation needed",
            ),
        ]

    elif "validate" in action.name.lower():
        impacts = [
            SideEffectImpact(
                area="warehouse_capacity", direction="neutral", magnitude="low",
                explanation="Stock validation is a read-only operation",
                mitigation="No mitigation needed",
            ),
        ]

    elif "monitor" in action.name.lower():
        impacts = [
            SideEffectImpact(
                area="delivery_logistics", direction="positive", magnitude="medium",
                explanation="Monitoring enables early detection of future shortages",
                mitigation="No mitigation needed",
            ),
        ]

    else:
        impacts = [
            SideEffectImpact(
                area="general", direction="neutral", magnitude="low",
                explanation=f"Action '{action.name}' has minimal predicted side effects",
                mitigation="Standard monitoring recommended",
            ),
        ]

    return SideEffectAnalysis(
        action_id=action.action_id,
        impacts=impacts,
        requires_approval=requires_approval,
        alternative_path=alternative_path,
    )


async def run_side_effect_analyzer(
    actions: list[Action],
    scenario: str = "inventory_shortage",
    llm_client: Optional[LLMClient] = None,
    run_id: str = "",
) -> list[SideEffectAnalysis]:
    logger.info(f"[{run_id}] Side-Effect Analyzer starting with {len(actions)} actions")

    analyses: list[SideEffectAnalysis] = []

    if llm_client and actions:
        try:
            from prompts.side_effect import SIDE_EFFECT_PROMPT
            context = {"scenario": scenario, "action_count": len(actions)}
            prompt = SIDE_EFFECT_PROMPT.format(
                scenario=scenario,
                actions_json=json.dumps([a.model_dump() for a in actions], default=str),
                context_json=json.dumps(context),
            )
            raw = await llm_client.call(prompt, run_id=run_id)
            parsed = extract_json(raw)
            result_list = parsed if isinstance(parsed, list) else parsed.get("analyses", [])
            for item in result_list:
                impacts = [SideEffectImpact(**imp) for imp in item.get("impacts", [])]
                analyses.append(SideEffectAnalysis(
                    action_id=item.get("action_id", f"act_{uuid4().hex[:6]}"),
                    impacts=impacts,
                    requires_approval=item.get("requires_approval", False),
                    alternative_path=item.get("alternative_path"),
                ))
            logger.info(f"[{run_id}] Side-Effect: LLM analyzed {len(analyses)} actions")
        except Exception as exc:
            logger.warning(f"[{run_id}] Side-Effect Analyzer LLM failed ({exc}), using defaults")
            analyses = []

    if not analyses:
        analyses = [_analyze_side_effects_deterministic(action) for action in actions]

    approval_needed = sum(1 for a in analyses if a.requires_approval)
    logger.info(f"[{run_id}] Side-Effect analysis complete: {approval_needed} actions need approval")
    return analyses
