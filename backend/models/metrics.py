"""
SENTINEL Pydantic Models — Metrics (Module 9)
Canon: idea.md §8.3, planning.md Hour 3
"""

from datetime import datetime
from typing import Literal

from pydantic import BaseModel, computed_field


class LLMCallRecord(BaseModel):
    """Record of a single LLM API call."""
    provider: Literal["gemini", "groq"]
    input_tokens: int
    output_tokens: int
    latency_ms: int
    estimated_cost_usd: float
    called_at: datetime
    cached: bool = False
    fallback_used: bool = False


class RunMetrics(BaseModel):
    """Aggregated metrics for an entire run."""
    run_id: str
    llm_calls: list[LLMCallRecord] = []
    total_duration_seconds: float = 0.0

    @computed_field
    @property
    def total_llm_calls(self) -> int:
        return len(self.llm_calls)

    @computed_field
    @property
    def total_input_tokens(self) -> int:
        return sum(c.input_tokens for c in self.llm_calls)

    @computed_field
    @property
    def total_output_tokens(self) -> int:
        return sum(c.output_tokens for c in self.llm_calls)

    def summary(self) -> dict:
        """Compute aggregated summary statistics."""
        total_input = sum(c.input_tokens for c in self.llm_calls)
        total_output = sum(c.output_tokens for c in self.llm_calls)
        total_cost = sum(c.estimated_cost_usd for c in self.llm_calls)
        avg_latency = (
            sum(c.latency_ms for c in self.llm_calls) / len(self.llm_calls)
            if self.llm_calls else 0
        )
        fallback_count = sum(1 for c in self.llm_calls if c.fallback_used)
        cache_hits = sum(1 for c in self.llm_calls if c.cached)

        return {
            "total_llm_calls": len(self.llm_calls),
            "total_input_tokens": total_input,
            "total_output_tokens": total_output,
            "total_cost_usd": round(total_cost, 6),
            "average_latency_ms": round(avg_latency, 1),
            "fallback_calls": fallback_count,
            "cache_hits": cache_hits,
            "total_duration_seconds": round(self.total_duration_seconds, 2),
        }


class BaselineComparison(BaseModel):
    """Comparison of SENTINEL vs baseline approaches."""
    naive_approach: dict = {}
    rule_based_approach: dict = {}
    sentinel_approach: dict = {}
