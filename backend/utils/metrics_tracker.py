"""
SENTINEL Metrics Tracker (Module 9)
Singleton-per-run tracker wrapping all LLM client calls.
Canon: planning.md Hour 3 T4, idea.md Module 9
"""

from datetime import datetime, timezone
from typing import Optional

from models.metrics import LLMCallRecord, RunMetrics


class MetricsTracker:
    """Tracks LLM call metrics for a single run."""

    def __init__(self, run_id: str):
        self.run_id = run_id
        self._metrics = RunMetrics(run_id=run_id)
        self._start_time: Optional[datetime] = None

    def start(self):
        """Mark the run start time."""
        self._start_time = datetime.now(timezone.utc)

    def record_llm_call(
        self,
        provider: str,
        input_tokens: int,
        output_tokens: int,
        latency_ms: int,
        cached: bool = False,
        fallback_used: bool = False,
    ):
        """Record a single LLM API call."""
        # Cost estimation (Gemini Flash free tier, Groq free tier)
        if provider == "gemini":
            cost = (input_tokens * 0.000000075) + (output_tokens * 0.0000003)
        else:
            cost = (input_tokens * 0.00000005) + (output_tokens * 0.00000008)

        record = LLMCallRecord(
            provider=provider,
            input_tokens=input_tokens,
            output_tokens=output_tokens,
            latency_ms=latency_ms,
            estimated_cost_usd=round(cost, 8),
            called_at=datetime.now(timezone.utc),
            cached=cached,
            fallback_used=fallback_used,
        )
        self._metrics.llm_calls.append(record)

    def finish(self):
        """Mark the run end and compute total duration."""
        if self._start_time:
            elapsed = (datetime.now(timezone.utc) - self._start_time).total_seconds()
            self._metrics.total_duration_seconds = elapsed

    def get_metrics(self) -> RunMetrics:
        """Return the current metrics state."""
        return self._metrics

    def get_summary(self) -> dict:
        """Return aggregated summary dict."""
        return self._metrics.summary()
