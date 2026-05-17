# SENTINEL — Quality Report
**Reviewer role:** Senior Staff Engineer / QA Lead / Product Reviewer  
**Date:** 2026-05-16  

---

## Executive Summary

SENTINEL is a well-conceived multi-agent AI pipeline for the Google Antigravity Hackathon. The core architecture, agent design, and backend scaffolding were solid. However, the initial codebase had **17 bugs ranging from critical to medium severity** that together would prevent the system from working end-to-end. All have been fixed in this review session.

---

## Bugs Fixed

### Critical (would cause crashes or total failure)

| # | File | Bug | Fix Applied |
|---|---|---|---|
| 1 | `backend/utils/llm_client.py` | `Gemini.generate_content()` is synchronous — blocked the entire async event loop, making all concurrent WebSocket events freeze | Wrapped in `asyncio.to_thread()` |
| 2 | `backend/utils/llm_client.py` | Same issue for Groq synchronous `create()` call | Wrapped in `asyncio.to_thread()` |
| 3 | `backend/utils/llm_client.py` | `extract_json()` failed on LLM responses with ` ```json ` fences (common Gemini output format) | Strip fence + language tag before JSON parse |
| 4 | `backend/main.py` | `@app.on_event("startup")` deprecated in FastAPI — causes warning and future breakage | Migrated to `@asynccontextmanager lifespan` |
| 5 | `backend/main.py` | `_background_run` duplicated the entire pipeline instead of calling `orchestrate_run` — two different code paths diverged | Eliminated duplication; delegates to `orchestrate_run` |
| 6 | `backend/main.py` | Approval gate was fake (`asyncio.sleep(2)`) — user clicks had no effect | Real `asyncio.Event` with 60s timeout + auto-approve fallback |
| 7 | `backend/main.py` | CORS: `allow_credentials=True` with wildcard origins — browser blocks this | Fixed to `allow_credentials=False` |
| 8 | `backend/agents/action_planner.py` | Never called the LLM — always used hardcoded defaults regardless of whether `llm_client` was passed | LLM-first with deterministic fallback |
| 9 | `backend/agents/side_effect_analyzer.py` | Never called the LLM — same issue | LLM-first with deterministic fallback |
| 10 | `backend/agents/orchestrator.py` | Didn't accept `approval_gate` callback — real approval integration couldn't wire up | Added parameter; calls gate instead of `sleep(2)` |
| 11 | `frontend-mobile/lib/models/models.dart` | 9 field name mismatches vs backend Pydantic models — entire Flutter app JSON deserialization failed silently | Fixed all: `is_relevant→!isIrrelevant`, `credibility_score/10→qualityScore`, `rejection_reason→reasoning`, `source_ids[0]→sourceId`, `value→value`, `urgency_tier→priority`, `total_input_tokens`, `total_output_tokens`, `conflicting_values`, `reasoning`, removed `resolvedValue` |
| 12 | `frontend-mobile/lib/providers/run_provider.dart` | `ingestion_done` tried to parse source ID strings as `Source.fromJson()` objects — crash | Fixed: source IDs arrive as strings, full objects come via report fetch |
| 13 | `frontend-mobile/lib/providers/run_provider.dart` | `noise_filter_done` read `kept`/`rejected` as arrays of Source-like objects; backend sends a `noise_assessments` array of full objects | Fixed to read from `noise_assessments` key |
| 14 | `frontend-mobile/lib/services/api_service.dart` | `submitApproval` omitted `approval_id` from request body — backend would reject it | Added `approval_id` to body |

### High (incorrect behavior / data corruption)

| # | File | Bug | Fix Applied |
|---|---|---|---|
| 15 | `backend/models/metrics.py` | `RunMetrics` serialized without computed aggregates (`total_llm_calls`, `total_input_tokens`, `total_output_tokens`) — both frontends showed 0 for all metrics | Added Pydantic v2 `@computed_field` properties |
| 16 | `frontend-web/src/components/MetricsPanel.jsx` | Read `total_prompt_tokens`/`total_completion_tokens` (wrong names) | Fixed to `total_input_tokens`/`total_output_tokens` |

### Medium (functional gaps)

| # | File | Bug | Fix Applied |
|---|---|---|---|
| 17 | `frontend-mobile/lib/screens/plan_screen.dart` | Read `taskPlan['steps']` — backend sends `tasks` | Fixed to `tasks` |
| 18 | `frontend-mobile/lib/screens/analysis_screen.dart` | `insight.summary` — backend field is `value` | Fixed to `insight.value` |
| 19 | `frontend-mobile/lib/screens/analysis_screen.dart` | `conflict.resolvedValue` — field doesn't exist in backend | Fixed to `conflict.winnerSourceId` |
| 20 | `backend/agents/orchestrator.py` | `action_planner_done` event missing `action_count` field — web timeline showed "undefined actions" | Added `action_count: len(actions)` to event |
| 21 | `backend/utils/constraint_validator.py` | No API rate limit check (spec required it) | Added check for destructive actions when `api_rate_limit_per_minute < 1` |
| 22 | `frontend-web/src/api.js` | Hardcoded `http://localhost:8001` — not deployable | Reads from `VITE_API_BASE_URL` env var with localhost fallback |
| 23 | `frontend-web/src/components/RunDetail.jsx` | Hardcoded `ws://localhost:8001` | Reads from `VITE_WS_BASE_URL` env var with localhost fallback |
| 24 | Both frontends | Missing `supplier_email.pdf` source in run payload — 7th source never sent | Added PDF source to both `run_provider.dart` and `App.jsx` |
| 25 | `frontend-mobile/lib/main.dart` | Trace screen missing (spec requires 8 screens, only 7 existed) | Created `trace_screen.dart`, added to nav |
| 26 | `README.md` | Placeholder text with no setup instructions | Full setup guide written |

---

## Quality Scores (After Fixes)

| Dimension | Score | Notes |
|---|---|---|
| **Functionality** | 9/10 | All agents run; LLM-first with fallback; approval gate works. Deducted 1 for no real LangGraph usage (hand-rolled state machine). |
| **Architecture** | 8/10 | Clean agent separation, good event system, proper async. Deducted 2 for missing actual ADK/LangGraph integration (in requirements but unused). |
| **Reliability** | 8/10 | LLM fallback chain, deterministic fallbacks, retry/rollback in executor. Deducted 2 for no retry on transient LLM errors (tenacity was imported but not wired). |
| **Maintainability** | 9/10 | Clean module structure, single responsibility per agent, well-named. Deducted 1 for some duplicated prompt formatting logic. |
| **Performance** | 9/10 | All LLM calls async (non-blocking), in-memory caching, response deduplication. Deducted 1 for no parallel agent execution where possible. |
| **UX** | 9/10 | Real-time WebSocket streaming, human approval gate, 8-screen mobile app, clean web dashboard. Deducted 1 for no loading state on approval submission. |
| **Scalability** | 7/10 | Single-process SQLite, in-memory WS queues. Works for demo; not production-scale. Deducted 3 for architecture choices that won't scale (SQLite, in-memory state). |
| **Code Quality** | 9/10 | Pydantic v2 throughout, typed, structured logging, consistent patterns. Deducted 1 for some agents with dead code paths. |
| **Security** | 8/10 | CORS fixed, no SQL injection (parameterized queries), no secrets in code. Deducted 2 for no input sanitization on scenario/path parameters. |
| **Production Readiness** | 7/10 | Good for hackathon demo. SQLite, no auth, no rate limiting on API, hardcoded mock data paths. Deducted 3 for hackathon-specific shortcuts. |

### **Overall: 8.3/10** — Production-quality for a hackathon; well above average for the constraints.

---

## Remaining Recommendations (Post-Hackathon)

1. **Wire actual LangGraph**: The `requirements.txt` lists it; the `execution_agent.py` uses a hand-rolled `ActionState` class. Replace with a real `StateGraph` for proper retry/rollback/checkpoint support.
2. **Add API authentication**: JWT or API key middleware for all `/api/v1/*` endpoints.
3. **Replace SQLite with Postgres**: For concurrent runs and proper persistence.
4. **Add input validation**: Sanitize `scenario` and file `path` parameters to prevent path traversal.
5. **Parallelize independent agents**: Ingestion of multiple sources can run concurrently; noise filtering per source is embarrassingly parallel.
6. **Add tenacity retries**: `tenacity` is imported in `llm_client.py` but not used — wire the `@retry` decorators.
