"""
SENTINEL LLM Client — Gemini primary, Groq fallback, retry, caching, metrics.
Canon: idea.md §6.4, planning.md Hour 3 T5, architecture.md §4

Logic:
1. Hash prompt → check cache → return if hit
2. Try Gemini with tenacity retry (3 attempts, exponential backoff)
3. On Gemini failure, try Groq with same retry
4. On success, record metrics, cache response, return
5. On total failure, raise LLMUnavailableError
"""

import json
import time
from typing import Optional

import google.generativeai as genai
from groq import Groq
from tenacity import retry, stop_after_attempt, wait_exponential, retry_if_exception_type

from config import settings
from utils.cache import RunCache
from utils.logger import logger
from utils.metrics_tracker import MetricsTracker


class LLMUnavailableError(Exception):
    """Raised when both Gemini and Groq fail after all retries."""
    pass


class LLMClient:
    """Centralized LLM client with Gemini→Groq fallback, caching, and metrics."""

    def __init__(self, metrics_tracker: Optional[MetricsTracker] = None):
        self.cache = RunCache()
        self.metrics = metrics_tracker

        # Configure Gemini
        if settings.GEMINI_API_KEY and settings.GEMINI_API_KEY != "your_gemini_key_here":
            genai.configure(api_key=settings.GEMINI_API_KEY)
            self._gemini_model = genai.GenerativeModel("gemini-2.0-flash")
            self._gemini_available = True
        else:
            self._gemini_available = False
            logger.warning("Gemini API key not set — Gemini calls will be skipped")

        # Configure Groq
        if settings.GROQ_API_KEY and settings.GROQ_API_KEY != "your_groq_key_here":
            self._groq_client = Groq(api_key=settings.GROQ_API_KEY)
            self._groq_available = True
        else:
            self._groq_available = False
            logger.warning("Groq API key not set — Groq fallback will be unavailable")

    async def call(self, prompt: str, run_id: str = "", expect_json: bool = True) -> str:
        """
        Call LLM with fallback chain: cache → Gemini → Groq.
        Returns raw text response.
        """
        # 1. Check cache
        cached = self.cache.get(prompt)
        if cached is not None:
            if self.metrics:
                self.metrics.record_llm_call(
                    provider="gemini", input_tokens=0, output_tokens=0,
                    latency_ms=0, cached=True
                )
            logger.info(f"Cache hit for prompt (run={run_id})")
            return cached

        # 2. Try Gemini
        if self._gemini_available:
            try:
                response = await self._call_gemini(prompt)
                self.cache.set(prompt, response)
                return response
            except Exception as e:
                logger.warning(f"Gemini failed: {e} — falling back to Groq")

        # 3. Try Groq
        if self._groq_available:
            try:
                response = await self._call_groq(prompt)
                self.cache.set(prompt, response)
                return response
            except Exception as e:
                logger.error(f"Groq also failed: {e}")

        raise LLMUnavailableError(
            "Both Gemini and Groq are unavailable. Check API keys in backend/.env"
        )

    async def _call_gemini(self, prompt: str) -> str:
        """Call Gemini with tenacity retry and metrics recording."""
        import asyncio
        from tenacity import AsyncRetrying, stop_after_attempt, wait_exponential

        start = time.time()
        last_exc = None
        async for attempt in AsyncRetrying(
            stop=stop_after_attempt(3),
            wait=wait_exponential(multiplier=1, min=2, max=10),
            reraise=True,
        ):
            with attempt:
                response = await asyncio.to_thread(self._gemini_model.generate_content, prompt)
                latency_ms = int((time.time() - start) * 1000)

                text = response.text
                usage_meta = getattr(response, 'usage_metadata', None)
                in_tok = getattr(usage_meta, 'prompt_token_count', len(prompt) // 4) if usage_meta else len(prompt) // 4
                out_tok = getattr(usage_meta, 'candidates_token_count', len(text) // 4) if usage_meta else len(text) // 4

                if self.metrics:
                    self.metrics.record_llm_call(
                        provider="gemini",
                        input_tokens=in_tok,
                        output_tokens=out_tok,
                        latency_ms=latency_ms,
                    )
                return text

    async def _call_groq(self, prompt: str) -> str:
        """Call Groq with tenacity retry and metrics recording."""
        import asyncio
        from tenacity import AsyncRetrying, stop_after_attempt, wait_exponential

        start = time.time()
        async for attempt in AsyncRetrying(
            stop=stop_after_attempt(3),
            wait=wait_exponential(multiplier=1, min=2, max=10),
            reraise=True,
        ):
            with attempt:
                response = await asyncio.to_thread(
                    self._groq_client.chat.completions.create,
                    model="llama-3.1-8b-instant",

                    messages=[{"role": "user", "content": prompt}],
                    temperature=0.1,
                    max_tokens=4096,
                )
                latency_ms = int((time.time() - start) * 1000)

                text = response.choices[0].message.content
                usage = response.usage
                in_tok = usage.prompt_tokens if usage else len(prompt) // 4
                out_tok = usage.completion_tokens if usage else len(text) // 4

                if self.metrics:
                    self.metrics.record_llm_call(
                        provider="groq",
                        input_tokens=in_tok,
                        output_tokens=out_tok,
                        latency_ms=latency_ms,
                        fallback_used=True,
                    )
                return text

    def clear_cache(self):
        """Clear the per-run cache."""
        self.cache.clear()


def extract_json(text: str) -> dict:
    """Extract JSON from LLM response text, handling markdown fences, trailing commentary, and tags."""
    text = text.strip()
    if text.startswith("```"):
        lines = text.split("\n")
        lines = lines[1:]
        while lines and lines[-1].strip() in ("```", ""):
            lines.pop()
        text = "\n".join(lines).strip()

    start_char = None
    start_idx = -1
    for char in ("{", "["):
        idx = text.find(char)
        if idx != -1:
            if start_idx == -1 or idx < start_idx:
                start_idx = idx
                start_char = char

    if start_idx != -1:
        text = text[start_idx:]
        end_char = "}" if start_char == "{" else "]"
        end_idx = text.rfind(end_char)
        if end_idx != -1:
            text = text[:end_idx + 1]

    return json.loads(text)
