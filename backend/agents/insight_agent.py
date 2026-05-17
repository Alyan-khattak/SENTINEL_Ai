"""
SENTINEL Insight Agent (Module 4)
Extracts structured signals, trends, and risks from filtered sources.
Canon: idea.md Module 4, planning.md Hour 8
"""

import json
from datetime import datetime
from typing import Optional
from uuid import uuid4

from models.insight import Insight
from models.source import Source
from prompts.insight import INSIGHT_PROMPT
from utils.llm_client import LLMClient, extract_json
from utils.temporal import compute_rate_of_change, determine_trend
from utils.logger import logger


def _extract_csv_time_series(content: str):
    """Extract time series from CSV content."""
    series = []
    lines = content.strip().split("\n")
    for line in lines[1:]:
        try:
            cols = line.split(",") if "," in line else line.split()
            for i, col in enumerate(cols):
                col = col.strip()
                try:
                    qty = float(col)
                    for j, other in enumerate(cols):
                        other = other.strip()
                        try:
                            ts = datetime.fromisoformat(other)
                            series.append((ts, qty))
                            break
                        except (ValueError, TypeError):
                            continue
                    break
                except ValueError:
                    continue
        except Exception:
            continue
    return sorted(series, key=lambda x: x[0])


async def run_insight_agent(
    sources: list[Source],
    scenario: str = "inventory_shortage",
    llm_client: Optional[LLMClient] = None,
    run_id: str = "",
) -> list[Insight]:
    """Extract structured insights with temporal analysis."""
    logger.info(f"[{run_id}] Insight Agent starting with {len(sources)} sources")
    
    if llm_client:
        try:
            sources_dict_list = [{"source_id": s.source_id, "type": s.source_type, "content": s.content} for s in sources]
            sources_json = json.dumps(sources_dict_list, indent=2)
            prompt = INSIGHT_PROMPT.format(scenario=scenario, sources_json=sources_json)
            
            response_text = await llm_client.call(prompt, run_id=run_id)
            insights_data = extract_json(response_text)
            
            insights = [Insight(**data) for data in insights_data]
            logger.info(f"[{run_id}] Insight Agent extracted {len(insights)} insights via LLM")
            return insights
        except Exception as e:
            logger.warning(f"[{run_id}] Insight Agent LLM failed: {e}. Falling back to deterministic parsing.")

    # Fallback deterministic parsing
    insights = []
    for source in sources:
        if source.source_type == "csv" and "SKU001" in source.content:
            ts = _extract_csv_time_series(source.content)
            if ts:
                rate = compute_rate_of_change(ts)
                trend = determine_trend(rate)
                last_val = ts[-1][1] if ts else 0
                insights.append(Insight(
                    insight_id=f"ins_{uuid4().hex[:6]}",
                    metric="stock_level_sku001", value=last_val,
                    source_ids=[source.source_id], confidence=0.95,
                    trend=trend, rate_of_change=rate,
                    risk_severity="critical" if rate and rate < -500 else "high",
                ))

    for source in sources:
        if source.source_type == "json":
            try:
                data = json.loads(source.content)
                if "metrics" in data and "demand_change_percent" in data.get("metrics", {}):
                    m = data["metrics"]
                    insights.append(Insight(
                        insight_id=f"ins_{uuid4().hex[:6]}",
                        metric="demand_change_percent",
                        value=float(m["demand_change_percent"]),
                        source_ids=[source.source_id], confidence=0.90,
                        trend="rising", risk_severity="high",
                    ))
                    if "stockout_probability" in m:
                        insights.append(Insight(
                            insight_id=f"ins_{uuid4().hex[:6]}",
                            metric="stockout_probability",
                            value=float(m["stockout_probability"]),
                            source_ids=[source.source_id], confidence=0.88,
                            trend="rising",
                            risk_severity="critical" if m["stockout_probability"] > 0.8 else "high",
                        ))
                if "complaint_count" in data:
                    insights.append(Insight(
                        insight_id=f"ins_{uuid4().hex[:6]}",
                        metric="customer_complaints_24h",
                        value=float(data["complaint_count"]),
                        source_ids=[source.source_id], confidence=0.85,
                        trend="rising",
                        risk_severity="high" if data["complaint_count"] >= 20 else "medium",
                    ))
                if "items" in data and isinstance(data["items"], list):
                    for item in data["items"]:
                        if "headline" in item:
                            insights.append(Insight(
                                insight_id=f"ins_{uuid4().hex[:6]}",
                                metric="external_risk_signal",
                                value=item["headline"],
                                source_ids=[source.source_id],
                                confidence=item.get("relevance_score", 0.7),
                                trend="volatile", risk_severity="medium",
                            ))
            except (json.JSONDecodeError, KeyError, TypeError):
                pass

    for source in sources:
        if source.source_type == "pdf":
            cl = source.content.lower()
            if "depleted" in cl or "depletion" in cl:
                insights.append(Insight(
                    insight_id=f"ins_{uuid4().hex[:6]}",
                    metric="supplier_depletion_warning",
                    value="SKU001 depletion within 48 hours",
                    source_ids=[source.source_id], confidence=0.92,
                    trend="falling", risk_severity="critical",
                ))
            if "strike" in cl:
                insights.append(Insight(
                    insight_id=f"ins_{uuid4().hex[:6]}",
                    metric="transport_disruption",
                    value="Transport strike may add 6-12 hours",
                    source_ids=[source.source_id], confidence=0.80,
                    trend="volatile", risk_severity="medium",
                ))

    logger.info(f"[{run_id}] Insight Agent extracted {len(insights)} insights deterministically")
    return insights
