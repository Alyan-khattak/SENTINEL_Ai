"""
SENTINEL Noise Filter Agent (Module 3)
Rejects duplicate, spam, stale, and irrelevant sources with explanations.
Canon: idea.md Module 3, planning.md Hour 7
"""

import hashlib
import json
from datetime import datetime, timezone
from typing import Optional

from models.source import Source, NoiseAssessment
from prompts.noise_filter import NOISE_FILTER_PROMPT
from utils.llm_client import LLMClient, extract_json
from utils.logger import logger


FRESHNESS_THRESHOLD_DAYS = 7
SPAM_KEYWORDS = ["click here", "subscribe", "promotional", "discount", "offer", "50% off"]


def _content_hash(content: str) -> str:
    """Compute hash for duplicate detection."""
    normalized = content.lower().strip()
    return hashlib.md5(normalized.encode()).hexdigest()


def _check_stale(source: Source, now: datetime) -> tuple[bool, int]:
    """Check if a source is stale based on its recorded_at timestamp."""
    if source.recorded_at.tzinfo is None:
        recorded = source.recorded_at.replace(tzinfo=timezone.utc)
    else:
        recorded = source.recorded_at
    days_old = (now - recorded).days
    return days_old > FRESHNESS_THRESHOLD_DAYS, days_old


def _check_spam(content: str) -> bool:
    """Check for spam/promotional patterns."""
    content_lower = content.lower()
    spam_count = sum(1 for keyword in SPAM_KEYWORDS if keyword in content_lower)
    return spam_count >= 2


def _content_similarity(content_a: str, content_b: str) -> float:
    """Simple word overlap similarity score."""
    words_a = set(content_a.lower().split())
    words_b = set(content_b.lower().split())
    if not words_a or not words_b:
        return 0.0
    intersection = words_a & words_b
    union = words_a | words_b
    return len(intersection) / len(union) if union else 0.0


async def run_noise_filter(
    sources: list[Source],
    scenario: str = "inventory_shortage",
    llm_client: Optional[LLMClient] = None,
    run_id: str = "",
) -> list[NoiseAssessment]:
    """
    Filter sources for noise: duplicates, spam, stale, irrelevant.
    Uses deterministic pre-filters before optional LLM classification.

    Args:
        sources: List of ingested Source objects
        scenario: Current scenario for relevance checking
        llm_client: Optional LLM client for relevance analysis
        run_id: Current run ID for logging

    Returns:
        List of NoiseAssessment objects
    """
    logger.info(f"[{run_id}] Noise Filter starting with {len(sources)} sources")
    now = datetime.now(timezone.utc)
    assessments = []
    content_hashes: dict[str, str] = {}  # hash -> source_id

    for source in sources:
        is_duplicate = False
        duplicate_of = None
        is_spam = False
        is_stale = False
        staleness_days = 0
        is_relevant = True
        rejection_reasons = []

        # 1. Duplicate detection via content hash
        content_hash = _content_hash(source.content)
        if content_hash in content_hashes:
            is_duplicate = True
            duplicate_of = content_hashes[content_hash]
            rejection_reasons.append(f"Duplicate of {duplicate_of}")
        else:
            # Check similarity with existing sources
            for other_source in sources:
                if other_source.source_id == source.source_id:
                    continue
                similarity = _content_similarity(source.content, other_source.content)
                if similarity > 0.6:
                    is_duplicate = True
                    duplicate_of = other_source.source_id
                    rejection_reasons.append(
                        f"High similarity ({similarity:.0%}) with {other_source.source_id}"
                    )
                    break

        content_hashes[content_hash] = source.source_id

        # 2. Staleness check
        is_stale, staleness_days = _check_stale(source, now)
        if staleness_days > 30:
            is_relevant = False
            rejection_reasons.append(f"Source is {staleness_days} days old (>30 days stale)")
        elif is_stale:
            rejection_reasons.append(f"Source is {staleness_days} days old (>{FRESHNESS_THRESHOLD_DAYS} days)")

        # 3. Spam check
        is_spam = _check_spam(source.content)
        if is_spam:
            rejection_reasons.append("Contains spam/promotional content")

        # 4. Relevance check (basic keyword matching)
        scenario_keywords = {
            "inventory_shortage": ["stock", "inventory", "sku", "warehouse", "supply", "order",
                                   "delivery", "shortage", "demand", "cooking oil", "depletion"],
        }
        keywords = scenario_keywords.get(scenario, [])
        if keywords:
            content_lower = source.content.lower()
            matches = sum(1 for k in keywords if k in content_lower)
            if matches == 0:
                is_relevant = False
                rejection_reasons.append("No relevant keywords found for scenario")

        # Compute credibility score
        from utils.credibility import compute_credibility
        credibility = compute_credibility(source, now)

        # Determine if kept
        keep = is_relevant and not is_duplicate and not is_spam
        if is_stale and staleness_days > 30:
            keep = False

        assessment = NoiseAssessment(
            source_id=source.source_id,
            is_duplicate=is_duplicate,
            duplicate_of=duplicate_of,
            is_spam=is_spam,
            is_stale=is_stale,
            staleness_days=staleness_days,
            is_relevant=is_relevant,
            credibility_score=credibility,
            keep_for_analysis=keep,
            rejection_reason="; ".join(rejection_reasons) if rejection_reasons else None,
        )
        assessments.append(assessment)

    # LLM pass: re-score ambiguous sources (not clearly spam/stale/duplicate)
    if llm_client:
        ambiguous = [
            (i, a) for i, a in enumerate(assessments)
            if a.keep_for_analysis and a.credibility_score in range(4, 8)
        ]
        if ambiguous:
            try:
                sources_json = json.dumps([
                    {
                        "source_id": sources[i].source_id,
                        "source_type": sources[i].source_type,
                        "content_preview": sources[i].content[:400],
                        "recorded_at": sources[i].recorded_at.isoformat(),
                        "current_credibility": assessments[i].credibility_score,
                    }
                    for i, _ in ambiguous
                ], default=str)

                prompt = NOISE_FILTER_PROMPT.format(
                    scenario=scenario, sources_json=sources_json
                )
                raw = await llm_client.call(prompt, run_id=run_id)
                llm_results = extract_json(raw)

                if isinstance(llm_results, list):
                    llm_by_id = {r["source_id"]: r for r in llm_results if isinstance(r, dict)}
                    for i, assessment in ambiguous:
                        sid = assessment.source_id
                        if sid in llm_by_id:
                            r = llm_by_id[sid]
                            assessment.credibility_score = int(r.get("credibility_score", assessment.credibility_score))
                            if not r.get("keep_for_analysis", True):
                                assessment.keep_for_analysis = False
                                reason = r.get("rejection_reason", "LLM: low relevance")
                                assessment.rejection_reason = (
                                    f"{assessment.rejection_reason}; {reason}"
                                    if assessment.rejection_reason else reason
                                )
            except Exception as e:
                logger.warning(f"[{run_id}] Noise filter LLM scoring failed (using deterministic): {e}")

    kept = sum(1 for a in assessments if a.keep_for_analysis)
    rejected = sum(1 for a in assessments if not a.keep_for_analysis)
    logger.info(f"[{run_id}] Noise Filter complete: {kept} kept, {rejected} rejected")

    return assessments
