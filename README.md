# SENTINEL — Signal-to-Action Autonomous Agent

**Google Antigravity Hackathon | AI Seekho**

SENTINEL is a multi-agent AI system that ingests heterogeneous data sources (CSV, JSON, PDF, web), filters noise, extracts insights, resolves contradictions, plans actions, analyzes side effects, and executes those actions — all with a human-in-the-loop approval gate before any destructive operation.

---

## Architecture

```
Signal Sources
     │
     ▼
Planner Agent → Ingestion Agent → Noise Filter → Insight Agent
                                                        │
                                                        ▼
                                               Conflict Resolver
                                                        │
                                                        ▼
                                               Action Planner → Side-Effect Analyzer
                                                                         │
                                                              ┌──────────┴────────────┐
                                                              │  Approval Gate (Human) │
                                                              └──────────┬────────────┘
                                                                         │
                                                               Execution Agent (LangGraph)
```

**LLMs:** Gemini 2.0 Flash (primary) → Groq Llama 3.3 70B (fallback)

**Stack:**
- Backend: FastAPI + Python 3.11 + SQLite + WebSocket streaming
- Web Dashboard: React 18 + Vite + Tailwind CSS
- Mobile: Flutter 3.x + Provider

---

## Quick Start

### 1. Backend

```bash
cd backend
python -m venv .venv
# Windows:
.venv\Scripts\activate
# macOS/Linux:
source .venv/bin/activate

pip install -r requirements.txt

# Copy and fill in your API keys
cp .env.example .env
# Edit .env: set GEMINI_API_KEY and GROQ_API_KEY

python main.py
# API available at http://localhost:8001
# Docs at http://localhost:8001/docs
```

### 2. Web Dashboard

```bash
cd frontend-web
npm install
npm run dev
# Open http://localhost:5173
```

### 3. Mobile App

```bash
cd frontend-mobile
flutter pub get
flutter run
# For web: flutter run -d chrome
```

---

## Environment Variables (`backend/.env`)

| Variable | Description |
|---|---|
| `GEMINI_API_KEY` | Google Gemini API key (get from aistudio.google.com) |
| `GROQ_API_KEY` | Groq API key (get from console.groq.com) |
| `DATABASE_URL` | SQLite path (default: `./sentinel.db`) |
| `TRACES_DIR` | Directory to store run traces (default: `./traces`) |
| `LOG_LEVEL` | Logging level (default: `INFO`) |

### Web Frontend Environment (optional)

Create `frontend-web/.env.local`:
```
VITE_API_BASE_URL=http://localhost:8001/api/v1
VITE_WS_BASE_URL=ws://localhost:8001
```

---

## Demo Scenario: Inventory Shortage

The default scenario ingests 7 mock data sources:
- `warehouse_stock_7days.csv` — 7-day stock trend
- `sales_dashboard.json` — real-time sales velocity
- `complaints.json` — customer complaints feed
- `news_feed.json` — supply chain news
- `duplicate_spam_source.json` — intentional noise (tested by Noise Filter)
- `stale_irrelevant_source.json` — intentional stale data (tested by Noise Filter)
- `supplier_email.pdf` — supplier communication

**Outcome:** SENTINEL recommends splitting an emergency order into 2 batches vs. a naive "buy everything now" approach — saving PKR 400,000 in wasted spend.

---

## API Reference

| Method | Endpoint | Description |
|---|---|---|
| `POST` | `/api/v1/runs` | Start a new analysis run |
| `GET` | `/api/v1/runs` | List recent runs |
| `GET` | `/api/v1/runs/{run_id}` | Fetch full run report |
| `POST` | `/api/v1/runs/{run_id}/approvals` | Submit approval decision |
| `WS` | `/ws/runs/{run_id}` | Live event stream |
| `GET` | `/api/v1/runs/{run_id}/trace` | Raw trace JSON |
| `GET` | `/health` | Health check |

---

## Mobile Screens

1. **Input** — Configure run, view sources
2. **Plan** — Agent task plan (pre-execution)
3. **Sources** — Noise filter results (kept vs rejected)
4. **Analysis** — Insights + conflict resolutions
5. **Constraints** — Budget, time, resource sliders
6. **Execution** — Real-time step timeline
7. **Outcome** — Metrics, baseline comparison
8. **Trace** — Full WebSocket event log

---

## Evaluation Criteria (Hackathon)

| Dimension | Score |
|---|---|
| Innovation | ADK orchestration of 8 specialized agents |
| Technical Depth | Gemini+Groq fallback, LangGraph execution, credibility-weighted conflict resolution |
| Impact | Demonstrated PKR 400K cost savings vs. naive approach |
| UX | Real-time WebSocket streaming, human approval gate, dual frontend |
