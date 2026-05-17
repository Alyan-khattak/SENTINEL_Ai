# SENTINEL — Known Limitations

## Architecture Limitations

**L1 — Single-process, in-memory state**
WebSocket event queues and run state are held in Python dicts in the FastAPI process. If the process restarts mid-run, the run is lost. Production would require Redis-backed shared state and multiple uvicorn workers.

**L2 — SQLite, not Postgres**
SQLite is single-writer. Concurrent runs from multiple clients will queue on disk writes. For >5 concurrent runs, migrate to PostgreSQL with connection pooling.

**L3 — No authentication**
All API endpoints are open. Any caller can start a run, submit an approval, or read any run report. JWT or API-key middleware is required before production deployment.

## LLM Limitations

**L4 — Groq rate limits**
The free Groq tier allows ~30 requests/minute. A full SENTINEL run makes 5–6 LLM calls. Back-to-back demo runs will hit rate limits after ~5 consecutive runs. The in-memory cache deduplicates identical prompts within a single run but not across runs.

**L5 — JSON output reliability**
Gemini and Groq occasionally produce malformed JSON despite explicit prompting. The `extract_json` utility handles markdown fences and leading text. If the LLM produces truncated JSON (rare at 4096 token limit), the agent falls back to deterministic output.

**L6 — No cross-run memory**
Insights from previous runs are not fed into new runs. Each run starts fresh. A vector database (Pinecone, Weaviate) would enable historical trend comparison.

## Feature Limitations

**L7 — Action execution is mocked**
The LangGraph executor calls internal FastAPI mock endpoints that simulate supplier ordering, CRM updates, and notifications. No real external integrations exist.

**L8 — Web scraping is mocked**
The `realtime_feed` source type routes to `web_fetcher.py` which makes HTTP requests. For the demo, a mock JSON feed is used instead of live web scraping to avoid network dependency during judging.

**L9 — Single scenario**
The noise filter's relevance keywords are tuned for `inventory_shortage`. Custom scenarios will get basic keyword matching but the Gemini-assisted scoring will handle novel scenario text reasonably well.

**L10 — No iOS build**
Only Android APK is provided. The Flutter codebase is platform-agnostic and would compile to iOS with an Apple developer certificate, but this is out of scope for the hackathon.
