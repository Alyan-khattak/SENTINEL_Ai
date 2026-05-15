# SENTINEL — Master Development Plan
> **Signal-to-Action Autonomous Agent**
> 3-Day | 30-Hour Hackathon Sprint | Task-Level Breakdown

---

## Legend
| Symbol | Meaning |
|--------|---------|
| `T0` | Pre-requisites — installs, API keys, file creation, repo pull |
| `T1–Tn` | Implementation tasks in order |
| `TEST` | Smoke test to verify before committing |
| `PUSH` | Git commit + push protocol |

**Hourly Workflow:** Plan → T0 → T1…Tn → TEST → PUSH

---

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# DAY 1 — Agent Brain & Pipeline Core
# Hours 1–10
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

---

## HOUR 1 — Dev Environment + Repository Setup

**Goal:** Project scaffold live on GitHub. Cloneable and runnable from a fresh machine.

### T0 — Prerequisites
- [ ] Install Python 3.11 from python.org (verify `python --version`)
- [ ] Install Flutter 3.x from flutter.dev (verify `flutter doctor`)
- [ ] Install Node.js 20 LTS (verify `node --version`)
- [ ] Install Git for Windows / Linux; configure `git config --global user.name` and `user.email`
- [ ] Create GitHub repo `sentinel-hackathon` (public, add README, .gitignore Python+Node)
- [ ] Clone repo locally: `git clone https://github.com/<username>/sentinel-hackathon.git`
- [ ] Get Gemini API key from `aistudio.google.com`
- [ ] Get Groq API key from `console.groq.com`

### T1 — Create Top-Level Folder Structure
```
sentinel-hackathon/
├── README.md
├── .gitignore
├── idea.md
├── architecture.md
├── planning.md
├── docs/
├── mock-data/
├── backend/
├── frontend-mobile/
├── frontend-web/
└── demo/
```

### T2 — Initialize Python Backend
```bash
cd backend
python -m venv venv
source venv/bin/activate    # Linux/macOS
venv\Scripts\activate       # Windows
```

### T3 — Create `.env.example` and `.env`
```
GEMINI_API_KEY=your_gemini_key_here
GROQ_API_KEY=your_groq_key_here
ENV=dev
DATABASE_URL=sqlite:///./app.db
LOG_LEVEL=INFO
BUDGET_LIMIT_PKR=500000
NOTIFICATION_DEADLINE_HOURS=2
SUPPLIER_LEAD_TIME_HOURS=48
```
- Copy `.env.example` → `.env`, fill real values
- Add `.env` to `.gitignore` (never commit secrets)

### T4 — Create `requirements.txt` with Pinned Versions
```
fastapi==0.111.0
uvicorn[standard]==0.29.0
python-dotenv==1.0.1
pydantic==2.7.1
httpx==0.27.0
google-adk==1.0.0
google-generativeai==0.5.4
langgraph==0.0.55
groq==0.8.0
pdfplumber==0.11.0
pandas==2.2.2
beautifulsoup4==4.12.3
requests==2.31.0
tenacity==8.2.3
websockets==12.0
```

### T5 — Install Backend Dependencies
```bash
pip install -r requirements.txt
pip freeze > requirements.lock.txt
```

### TEST
- [ ] `python -c "import fastapi, google.adk, langgraph, google.generativeai; print('ok')"` returns `ok`
- [ ] `.env` not in `git status` output

### PUSH
```bash
git add .
git commit -m "chore: initial project scaffold + Python backend setup"
git push origin main
```

---

## HOUR 2 — Mock Data Generation

**Goal:** Seven mock source files with deliberate contradictions and noise samples ready for the agent pipeline.

### T1 — Create `mock-data/warehouse_stock_7days.csv` (7-day declining stock)
```csv
sku,name,quantity,recorded_at
SKU001,Cooking Oil 5L,8500,2026-05-08T08:00:00
SKU001,Cooking Oil 5L,7800,2026-05-09T08:00:00
SKU001,Cooking Oil 5L,7100,2026-05-10T08:00:00
SKU001,Cooking Oil 5L,6300,2026-05-11T08:00:00
SKU001,Cooking Oil 5L,5500,2026-05-12T08:00:00
SKU001,Cooking Oil 5L,4400,2026-05-13T08:00:00
SKU001,Cooking Oil 5L,3200,2026-05-14T08:00:00
SKU002,Rice 25kg,4200,2026-05-08T08:00:00
SKU002,Rice 25kg,4100,2026-05-14T08:00:00
```
**Note:** The CSV's "last_updated" field will be `2026-05-12` in metadata to deliberately make it appear 3 days stale relative to other sources.

### T2 — Create `mock-data/supplier_email.pdf`
Write content in a Word doc, export to PDF:
```
From: ahmed@karachisupplies.pk
To: procurement@yourcompany.pk
Date: 2026-05-15
Subject: URGENT — Stock Depletion Warning for SKU001

Dear Procurement Team,

Based on current dispatch rates analyzed from your warehouse data and our
delivery schedules, your SKU001 (Cooking Oil 5L) inventory will be fully
depleted within 48 hours. We strongly recommend placing an emergency order
of at least 8,000 units immediately to avoid stockout.

Our standard lead time is 24 hours for emergency orders if confirmed before
6:00 PM today. Transport conditions in Sindh remain affected by the ongoing
strike, which may add 6-12 hours to delivery.

Please confirm at your earliest convenience.

Regards,
Ahmed Khan
Karachi Supplies Pvt Ltd
```

### T3 — Create `mock-data/sales_dashboard.json`
```json
{
  "report_date": "2026-05-15",
  "period": "last_7_days",
  "metrics": {
    "demand_change_percent": 42,
    "skus_at_risk": ["SKU001", "SKU002"],
    "stockout_probability": 0.91,
    "daily_units_sold": [620, 680, 720, 800, 880, 1050, 1200]
  },
  "trend": "rapidly_rising"
}
```

### T4 — Create `mock-data/complaints.json`
```json
{
  "captured_at": "2026-05-15T10:00:00",
  "period_hours": 24,
  "complaint_count": 23,
  "topics": ["cooking oil unavailable", "delivery delays", "out of stock"],
  "sentiment_score": -0.7,
  "affected_skus": ["SKU001"]
}
```

### T5 — Create `mock-data/news_feed.json`
```json
{
  "feed_timestamp": "2026-05-15T09:30:00",
  "items": [
    {
      "headline": "Transport strike in Sindh enters day 3",
      "source": "Dawn News",
      "published_at": "2026-05-15T07:00:00",
      "relevance_score": 0.85
    },
    {
      "headline": "Fuel prices push delivery costs up 15%",
      "source": "Business Recorder",
      "published_at": "2026-05-14T18:00:00",
      "relevance_score": 0.70
    }
  ]
}
```

### T6 — Create `mock-data/duplicate_spam_source.json` (Noise filter test)
```json
{
  "report_date": "2026-05-15",
  "summary": "DAILY SALES SUMMARY - PROMOTIONAL OFFERS INSIDE",
  "data": {
    "demand_change": "42%",
    "at_risk": ["SKU001", "SKU002"]
  },
  "promotional_message": "Click here for 50% off all subscriptions"
}
```
**Why noise:** Duplicates the sales dashboard content and includes spam-like promotional content.

### T7 — Create `mock-data/stale_irrelevant_source.json` (Noise filter test)
```json
{
  "report_date": "2025-11-08",
  "category": "office_supplies_inventory",
  "items": [
    { "name": "A4 Paper", "quantity": 12000 },
    { "name": "Stapler Pins", "quantity": 8000 }
  ]
}
```
**Why noise:** 6+ months stale AND irrelevant to inventory crisis scenario.

### TEST
- [ ] All 7 files exist in `mock-data/`
- [ ] PDF opens correctly
- [ ] JSON files validate via `python -m json.tool < file.json`
- [ ] CSV has 9 rows

### PUSH
```bash
git add mock-data/
git commit -m "feat: add 7 mock data sources with deliberate contradictions and noise"
git push origin main
```

---

## HOUR 3 — LLM Client + Metrics Tracker

**Goal:** Centralized LLM client with Gemini → Groq fallback, retry, caching, and metrics recording.

### T1 — Create `backend/utils/logger.py`
Simple JSON logger with run_id correlation.

### T2 — Create `backend/utils/cache.py`
In-memory dict keyed by `hashlib.md5(prompt).hexdigest()`. Cache is per-run, cleared between runs.

### T3 — Create `backend/models/metrics.py`
```python
class LLMCallRecord(BaseModel):
    provider: Literal["gemini", "groq"]
    input_tokens: int
    output_tokens: int
    latency_ms: int
    estimated_cost_usd: float
    called_at: datetime
    cached: bool
    fallback_used: bool

class RunMetrics(BaseModel):
    run_id: str
    llm_calls: list[LLMCallRecord]
    total_duration_seconds: float
    
    def summary(self) -> dict: ...
```

### T4 — Create `backend/utils/metrics_tracker.py`
Singleton-per-run tracker. Wraps all LLM client calls.

### T5 — Create `backend/utils/llm_client.py`
Logic:
1. Hash prompt → check cache → return if hit
2. Try Gemini with `tenacity` retry (3 attempts, exponential backoff)
3. On Gemini failure, try Groq with same retry
4. On success, record metrics, cache response, return
5. On total failure, raise `LLMUnavailableError`

### TEST
- [ ] Create `scripts/test_llm.py` that calls `llm_client.call("Say hello in JSON")`
- [ ] Verify response is valid JSON
- [ ] Verify metrics recorded
- [ ] Verify cache hit on second identical call

### PUSH
```bash
git add backend/utils/ backend/models/metrics.py
git commit -m "feat: LLM client with Gemini/Groq fallback + metrics tracking"
git push
```

---

## HOUR 4 — Centralized Prompts

**Goal:** All agent prompts in one place for easy iteration.

### T1 — Create `backend/prompts/planner.py`
```python
PLANNER_PROMPT = """You are a senior agent orchestration planner.

Given the scenario "{scenario}" and these {n_sources} input sources:
{source_summaries}

Produce a structured plan with:
1. work_plan.high_level_steps: ordered list of 5-7 phases
2. work_plan.expected_duration_seconds: integer estimate
3. work_plan.estimated_llm_calls: integer
4. work_plan.fallback_strategy: 1-2 sentences
5. task_plan.tasks: array of {task_id, description, depends_on, agent_assigned, expected_output_schema}

Output JSON only. No markdown fences. No commentary.
"""
```

### T2 — Create `backend/prompts/noise_filter.py`
Prompts Gemini to classify each source as duplicate, spam, stale, or relevant.

### T3 — Create `backend/prompts/insight.py`
Demands structured signals + temporal trends + rates of change.

### T4 — Create `backend/prompts/conflict.py`
Demands contradictions list + credibility-weighted resolution OR investigation path.

### T5 — Create `backend/prompts/action.py`
Demands 3-5 actions with cost, duration, dependencies, urgency.

### T6 — Create `backend/prompts/side_effect.py`
Demands impact predictions per business area + alternative path if severe.

### TEST
- [ ] Run a quick script that imports each prompt and asserts non-empty string
- [ ] Verify all prompts demand JSON output explicitly

### PUSH
```bash
git add backend/prompts/
git commit -m "feat: centralized agent prompts with structured output schemas"
git push
```

---

## HOUR 5 — Pydantic Models

**Goal:** Every agent input/output is a strongly-typed Pydantic model.

### T1 — Create `backend/models/source.py`
```python
class Source(BaseModel):
    source_id: str
    source_type: Literal["pdf", "csv", "json", "web", "realtime_feed"]
    content: str
    metadata: dict
    recorded_at: datetime
    ingested_at: datetime

class NoiseAssessment(BaseModel):
    source_id: str
    is_duplicate: bool
    duplicate_of: Optional[str] = None
    is_spam: bool
    is_stale: bool
    staleness_days: int
    is_relevant: bool
    credibility_score: int  # 1-10
    keep_for_analysis: bool
    rejection_reason: Optional[str] = None
```

### T2 — Create `backend/models/insight.py`
```python
class Insight(BaseModel):
    insight_id: str
    metric: str
    value: Union[float, str]
    source_ids: list[str]
    confidence: float
    trend: Optional[Literal["rising", "falling", "stable", "volatile"]] = None
    rate_of_change: Optional[float] = None
    risk_severity: Optional[Literal["low", "medium", "high", "critical"]] = None

class Contradiction(BaseModel):
    metric: str
    conflicting_values: list[dict]  # [{source_id, value, credibility}]
    winner_source_id: Optional[str]
    reasoning: str

class ConflictResolution(BaseModel):
    contradictions: list[Contradiction]
    resolution_type: Literal["resolved", "investigation_required", "partial"]
    investigation_actions: list[str]
    confidence: float
```

### T3 — Create `backend/models/action.py`
```python
class Constraints(BaseModel):
    budget_pkr_max: int = 500_000
    time_to_resolution_hours_max: int = 48
    notification_deadline_hours_max: int = 2
    api_rate_limit_per_minute: int = 10
    resource_constraints: dict[str, int] = {}

class Action(BaseModel):
    action_id: str
    name: str
    description: str
    depends_on: list[str]
    estimated_cost_pkr: int
    estimated_duration_minutes: int
    affected_resources: list[str]
    urgency_tier: Literal["low", "medium", "high", "critical"]
    is_destructive: bool
    constraint_violations: list[str] = []
    modification_applied: Optional[str] = None

class SideEffectImpact(BaseModel):
    area: str
    direction: Literal["positive", "negative", "neutral"]
    magnitude: Literal["low", "medium", "high"]
    explanation: str
    mitigation: str
```

### T4 — Create `backend/models/state.py`
```python
class ActionStep(BaseModel):
    step_number: int
    action_id: str
    action_name: str
    status: Literal["pending", "running", "success", "failed", "retrying", "rolled_back", "skipped"]
    started_at: Optional[datetime]
    completed_at: Optional[datetime]
    retried: int = 0
    rolled_back: bool = False
    error: Optional[str] = None
    state_diff: dict = {}

class WorkPlan(BaseModel):
    high_level_steps: list[str]
    expected_duration_seconds: int
    estimated_llm_calls: int
    fallback_strategy: str

class TaskPlan(BaseModel):
    tasks: list[dict]
```

### T5 — Create `backend/models/run_report.py`
Final `RunReport` schema combining all of the above.

### TEST
- [ ] Import every model in a test script
- [ ] Construct each with sample data — no validation errors

### PUSH
```bash
git add backend/models/
git commit -m "feat: complete Pydantic schema for all agent inputs and outputs"
git push
```

---

## HOUR 6 — Planner Agent + Ingestion Agent

**Goal:** First two modules of the pipeline are working in isolation.

### T1 — Create `backend/agents/planner_agent.py`
Single function `async def run_planner(scenario, sources) -> tuple[WorkPlan, TaskPlan]`. Calls `llm_client` with the planner prompt. Validates response via Pydantic.

### T2 — Create `backend/tools/pdf_parser.py`, `csv_parser.py`, `json_parser.py`
Each exposes `parse(file_path) -> str` returning normalized text content.

### T3 — Create `backend/tools/web_fetcher.py`
Uses `requests` + `BeautifulSoup` to fetch and clean HTML pages. (For hackathon, this will mostly hit local files.)

### T4 — Create `backend/agents/ingestion_agent.py`
```python
async def run_ingestion(source_paths: list[dict]) -> list[Source]:
    sources = []
    for src in source_paths:
        if src["type"] == "pdf":
            content = pdf_parser.parse(src["path"])
        elif src["type"] == "csv":
            content = csv_parser.parse(src["path"])
        elif src["type"] == "json":
            content = json_parser.parse(src["path"])
        # ... etc
        sources.append(Source(
            source_id=f"src_{uuid4().hex[:8]}",
            source_type=src["type"],
            content=content,
            metadata=extract_metadata(content),
            recorded_at=extract_timestamp(content),
            ingested_at=datetime.utcnow()
        ))
    return sources
```

### TEST
- [ ] `scripts/test_planner.py` runs planner with inventory scenario → outputs valid WorkPlan + TaskPlan
- [ ] `scripts/test_ingestion.py` parses all 7 mock files → returns 7 Source objects

### PUSH
```bash
git add backend/agents/planner_agent.py backend/agents/ingestion_agent.py backend/tools/
git commit -m "feat: planner + ingestion agents complete"
git push
```

---

## HOUR 7 — Noise Filter Agent

**Goal:** Reject duplicate, spam, stale, and irrelevant sources with explanations.

### T1 — Create `backend/agents/noise_filter_agent.py`
Logic:
1. Compute content hash similarity using simple character-level overlap for each pair
2. Check timestamp delta vs. `freshness_threshold_days` (e.g., 7 days for inventory)
3. Send remaining sources to Gemini with noise filter prompt for spam + relevance check
4. Aggregate into `list[NoiseAssessment]`

### T2 — Rule-based pre-filter for obvious cases
- If `is_stale` and `staleness_days > 30` → reject without calling LLM
- If `content_hash` matches another source → mark as duplicate

### TEST
- [ ] Run noise filter on 7 mock sources
- [ ] Verify `duplicate_spam_source.json` flagged as duplicate
- [ ] Verify `stale_irrelevant_source.json` flagged as stale + irrelevant
- [ ] Verify 5 main sources pass through

### PUSH
```bash
git add backend/agents/noise_filter_agent.py
git commit -m "feat: noise filter agent with duplicate, spam, stale, relevance detection"
git push
```

---

## HOUR 8 — Insight Agent with Temporal Analysis

**Goal:** Extract structured signals + trends + rates of change.

### T1 — Create `backend/agents/insight_agent.py`
1. Group sources by metric type
2. For each CSV/JSON with multi-day data, compute rate of change locally
3. Send all kept sources to Gemini with insight prompt
4. Validate JSON output → list of `Insight` objects

### T2 — Temporal pre-processor in `backend/utils/temporal.py`
```python
def compute_rate_of_change(time_series: list[tuple[datetime, float]]) -> float:
    """Returns units/day rate of change using linear regression slope."""
```

### TEST
- [ ] Run insight agent on filtered sources
- [ ] Verify at least one insight has `trend == "falling"` and `rate_of_change` is a negative number
- [ ] Verify `risk_severity` is set on critical insights

### PUSH
```bash
git add backend/agents/insight_agent.py backend/utils/temporal.py
git commit -m "feat: insight agent with temporal analysis and trend computation"
git push
```

---

## HOUR 9 — Conflict Resolver with Investigation Path

**Goal:** Detect contradictions, resolve via credibility weighting, generate investigation path when unresolvable.

### T1 — Create `backend/agents/conflict_resolver.py`
1. Group insights by `metric` field
2. Where same metric appears in multiple sources with different values, mark as contradiction
3. Compute credibility weight per source: `weight = recency_score * 0.5 + type_score * 0.3 + consistency_score * 0.2`
4. Send contradictions + weights to Gemini for resolution reasoning
5. If max credibility - min credibility < 0.2 threshold → `investigation_required` branch

### T2 — Credibility weighting function in `backend/utils/credibility.py`
```python
SOURCE_TYPE_WEIGHTS = {
    "pdf": 8,        # official documents
    "csv": 7,        # warehouse records
    "json": 7,       # internal dashboards
    "web": 5,        # external news
    "realtime_feed": 6
}

def compute_credibility(source: Source, now: datetime) -> int:
    recency = max(0, 10 - (now - source.recorded_at).days)
    type_score = SOURCE_TYPE_WEIGHTS.get(source.source_type, 5)
    return round((recency * 0.5 + type_score * 0.5))
```

### TEST
- [ ] Run conflict resolver on insights
- [ ] Verify stock contradiction detected between warehouse_stock (5000) and supplier_email (depletion in 48h)
- [ ] Verify supplier wins on credibility (newer)
- [ ] Force-test with equally credible sources → verify `investigation_required` branch

### PUSH
```bash
git add backend/agents/conflict_resolver.py backend/utils/credibility.py
git commit -m "feat: conflict resolver with credibility scoring and investigation path"
git push
```

---

## HOUR 10 — Day 1 Integration & Smoke Test

**Goal:** Run planner → ingestion → noise filter → insight → conflict end-to-end. Commit working pipeline.

### T1 — Create `backend/scripts/smoke_test_day1.py`
```python
async def smoke_day1():
    scenario = "inventory_shortage"
    source_paths = [
        {"type": "csv",  "path": "../mock-data/warehouse_stock_7days.csv"},
        {"type": "pdf",  "path": "../mock-data/supplier_email.pdf"},
        {"type": "json", "path": "../mock-data/sales_dashboard.json"},
        {"type": "json", "path": "../mock-data/complaints.json"},
        {"type": "json", "path": "../mock-data/news_feed.json"},
        {"type": "json", "path": "../mock-data/duplicate_spam_source.json"},
        {"type": "json", "path": "../mock-data/stale_irrelevant_source.json"},
    ]
    
    plan, task_plan = await run_planner(scenario, source_paths)
    print(f"✓ Plan: {len(plan.high_level_steps)} steps")
    
    sources = await run_ingestion(source_paths)
    print(f"✓ Ingested: {len(sources)} sources")
    
    noise = await run_noise_filter(sources)
    kept = [a for a in noise if a.keep_for_analysis]
    rejected = [a for a in noise if not a.keep_for_analysis]
    print(f"✓ Noise filter: {len(kept)} kept, {len(rejected)} rejected")
    
    insights = await run_insight_agent([s for s in sources if any(a.source_id == s.source_id and a.keep_for_analysis for a in noise)])
    print(f"✓ Insights: {len(insights)}")
    
    conflicts = await run_conflict_resolver(insights, sources)
    print(f"✓ Conflicts: {len(conflicts.contradictions)} detected, resolution: {conflicts.resolution_type}")
    
    print("\n✅ DAY 1 SMOKE TEST PASSED")
```

### TEST
- [ ] `python scripts/smoke_test_day1.py` prints all 5 checkmarks
- [ ] Total duration under 30 seconds
- [ ] No exceptions raised

### PUSH
```bash
git add .
git commit -m "feat: Day 1 complete — full pipeline through conflict resolution"
git push
git tag day1-complete
git push --tags
```

---

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# DAY 2 — Execution Engine + FastAPI + Mobile App
# Hours 11–20
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

---

## HOUR 11 — Action Planner with Multi-Constraint Engine

**Goal:** Generate 3-5 step action chain that enforces budget, time, resource, urgency, and API rate-limit constraints.

### T1 — Create `backend/agents/action_planner.py`
1. Build prompt with resolved insights + constraints object
2. Call Gemini → parse list of `Action` objects
3. Pass each action through `constraint_validator.py`
4. For violations, attempt modification; if not possible, reject with reason

### T2 — Create `backend/utils/constraint_validator.py`
```python
def validate_action(action: Action, constraints: Constraints) -> tuple[Action, list[str]]:
    violations = []
    if action.estimated_cost_pkr > constraints.budget_pkr_max:
        violations.append(f"Cost {action.estimated_cost_pkr} exceeds budget {constraints.budget_pkr_max}")
    if action.estimated_duration_minutes / 60 > constraints.time_to_resolution_hours_max:
        violations.append(f"Duration exceeds time-to-resolution limit")
    # ... etc
    
    if violations:
        action = attempt_modification(action, violations, constraints)
    return action, violations
```

### T3 — Modification strategies
- Budget over → split into 2 smaller orders
- Time over → parallelize independent steps
- Rate limit over → add `throttle_delay_ms` field
- Resource shortage → reject

### TEST
- [ ] Action planner generates 5 actions for inventory scenario
- [ ] Force a budget violation (e.g., 800k action with 500k budget) → verify modification applied
- [ ] Verify `modification_applied` field shows reasoning

### PUSH
```bash
git add backend/agents/action_planner.py backend/utils/constraint_validator.py
git commit -m "feat: action planner with multi-constraint enforcement"
git push
```

---

## HOUR 12 — Side-Effect Analyzer with What-If Branch

**Goal:** Predict downstream impacts and trigger alternative path when severe.

### T1 — Create `backend/agents/side_effect_analyzer.py`
1. For each action in the chain, prompt Gemini with action + business context
2. Parse list of `SideEffectImpact` objects
3. If any `magnitude == "high"` AND `direction == "negative"`:
   - Set `requires_approval = True`
   - Generate alternative action path via second Gemini call
4. Return `SideEffectAnalysis` per action + optional `AlternativePath`

### T2 — Update `Action` model
Add `side_effects: list[SideEffectImpact]` and `alternative_path: Optional[list[Action]]` fields.

### TEST
- [ ] Side-effect analyzer runs on 5-action chain
- [ ] Verify emergency_order action shows cashflow impact
- [ ] Verify alternative path generated (e.g., split over 3 days)

### PUSH
```bash
git add backend/agents/side_effect_analyzer.py
git commit -m "feat: side-effect analyzer with what-if alternative paths"
git push
```

---

## HOUR 13–14 — LangGraph Execution Engine

**Goal:** Stateful action chain executor with retry, rollback, fallback, and WebSocket streaming.

### T1 — Create `backend/agents/execution_agent.py`
```python
from langgraph.graph import StateGraph, END
from typing import TypedDict

class ActionState(TypedDict):
    run_id: str
    actions: list[Action]
    current_step: int
    state_snapshot: dict
    state_history: list[dict]
    logs: list[dict]
    failed_count: int
    websocket_emit: Callable

async def validate_stock_node(state: ActionState) -> ActionState:
    await state["websocket_emit"]("step_started", {"step_number": 1, "action_name": "validate_stock"})
    # ... mock API call
    state["state_snapshot"]["stock_validated"] = True
    state["state_history"].append(deepcopy(state["state_snapshot"]))
    await state["websocket_emit"]("step_completed", {...})
    return state

# Similarly for: notify_procurement_node, emergency_order_node, update_delivery_node, schedule_monitoring_node

# Conditional edge for emergency_order
def should_retry_or_proceed(state: ActionState) -> str:
    last_log = state["logs"][-1]
    if last_log["status"] == "failed" and state["failed_count"] < 2:
        return "retry_emergency_order"
    elif last_log["status"] == "failed":
        return "rollback"
    else:
        return "update_delivery"

graph = StateGraph(ActionState)
graph.add_node("validate_stock", validate_stock_node)
# ... add all nodes
graph.add_conditional_edges("emergency_order", should_retry_or_proceed)
graph.set_entry_point("validate_stock")
action_chain = graph.compile()
```

### T2 — Deliberate failure injection in `emergency_order_node`
```python
async def emergency_order_node(state):
    if state["failed_count"] == 0:
        # First call: fail
        await state["websocket_emit"]("step_failed", {...})
        state["failed_count"] = 1
        state["logs"].append({"step": 3, "status": "failed", "error": "Supplier API 503"})
        return state
    
    # Retry: succeed
    state["state_snapshot"]["emergency_order_placed"] = True
    state["state_history"].append(deepcopy(state["state_snapshot"]))
    await state["websocket_emit"]("step_completed", {...})
    return state
```

### T3 — Rollback logic
```python
async def rollback_node(state):
    # Restore previous snapshot
    state["state_snapshot"] = state["state_history"][-2] if len(state["state_history"]) > 1 else {}
    await state["websocket_emit"]("step_rolled_back", {"rollback_target_step": state["current_step"] - 1})
    return state
```

### TEST
- [ ] Standalone execution test runs the full chain
- [ ] Verify step 3 fails on first attempt then succeeds on retry
- [ ] Verify all 5 steps complete eventually
- [ ] Verify state_history has 5 snapshots

### PUSH
```bash
git add backend/agents/execution_agent.py
git commit -m "feat: LangGraph executor with retry, rollback, fallback"
git push
```

---

## HOUR 15 — FastAPI Routes + WebSocket Streaming

**Goal:** Wire all agents behind a clean REST + WebSocket API.

### T1 — Create `backend/main.py`
```python
from fastapi import FastAPI, WebSocket
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(title="SENTINEL API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.post("/api/v1/runs", status_code=202)
async def start_run(req: AnalysisRequest, background_tasks: BackgroundTasks):
    run_id = generate_run_id()
    background_tasks.add_task(orchestrate_run, run_id, req)
    return {"run_id": run_id, "status": "queued", "websocket_url": f"/ws/runs/{run_id}"}

@app.get("/api/v1/runs/{run_id}")
async def get_run(run_id: str):
    return await fetch_run_report(run_id)

@app.get("/api/v1/runs/{run_id}/trace")
async def get_trace(run_id: str):
    return load_trace_json(run_id)

@app.post("/api/v1/runs/{run_id}/approvals")
async def submit_approval(run_id: str, decision: ApprovalDecision):
    await deliver_approval(run_id, decision)
    return {"status": "delivered"}

@app.websocket("/ws/runs/{run_id}")
async def websocket_run(websocket: WebSocket, run_id: str):
    await websocket.accept()
    queue = register_websocket(run_id, websocket)
    try:
        while True:
            event = await queue.get()
            await websocket.send_json(event)
            if event["event"] in ["run_completed", "run_failed"]:
                break
    finally:
        await websocket.close()
```

### T2 — Create `backend/agents/orchestrator.py`
ADK root agent that runs all 8 agents sequentially, emits WebSocket events at each phase, and persists to SQLite.

### TEST
- [ ] Start server: `uvicorn main:app --reload`
- [ ] Hit `/docs` → all endpoints listed
- [ ] `curl POST /api/v1/runs` with sample payload → returns 202 + run_id
- [ ] Connect to WebSocket via Postman/wscat → events stream in

### PUSH
```bash
git add backend/main.py backend/agents/orchestrator.py
git commit -m "feat: FastAPI + WebSocket + ADK orchestrator wired"
git push
```

---

## HOUR 16 — Flutter Project Setup

**Goal:** Flutter project initialized with dependencies and theme.

### T1 — Initialize Flutter project
```bash
cd frontend-mobile
flutter create . --org com.sentinel --project-name sentinel
```

### T2 — Add dependencies to `pubspec.yaml`
```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.2.0
  web_socket_channel: ^3.0.0
  provider: ^6.1.2
  fl_chart: ^0.68.0
  intl: ^0.19.0
```
Run `flutter pub get`.

### T3 — Create `lib/theme/app_theme.dart`
Dark theme with SENTINEL brand colors (deep navy, electric cyan, warning amber).

### T4 — Create `lib/config.dart`
```dart
class AppConfig {
  static const String baseUrl = "https://sentinel-api.onrender.com";
  static const String wsUrl = "wss://sentinel-api.onrender.com";
  // Dev: "http://localhost:8000" and "ws://localhost:8000"
}
```

### TEST
- [ ] `flutter run` opens default app
- [ ] No build errors

### PUSH
```bash
git add frontend-mobile/
git commit -m "feat: Flutter project scaffold with dependencies and theme"
git push
```

---

## HOUR 17 — Flutter Service Layer + Models

### T1 — Create `lib/models/`
Dart equivalents of the Pydantic models (use `json_serializable` or hand-written `fromJson`).

### T2 — Create `lib/services/api_service.dart`
```dart
class ApiService {
  Future<RunStartResponse> startRun(AnalysisRequest req) async { ... }
  Future<RunReport> getRun(String runId) async { ... }
  Stream<RunEvent> connectWebSocket(String runId) { ... }
  Future<void> submitApproval(String runId, ApprovalDecision decision) async { ... }
}
```

### TEST
- [ ] Manual `flutter run` with hardcoded run → verify start_run succeeds against local backend

### PUSH
```bash
git commit -am "feat: Flutter API service and models"
git push
```

---

## HOUR 18–19 — Flutter Screens 1-8

**Goal:** All eight screens implemented with navigation.

### T1 — Input Screen
Scenario picker (single option: inventory_shortage), source file list (read-only display), "Run Analysis" button.

### T2 — Plan Screen
Renders workplan high-level steps as a vertical timeline, task plan as a dependency graph (simple list with depends_on indicators).

### T3 — Sources Screen
List of source cards. Rejected sources have strikethrough + red badge with rejection reason.

### T4 — Analysis Screen
Tabs: Insights (with rate-of-change chart via fl_chart), Contradictions (side-by-side credibility scores).

### T5 — Constraints Screen
Sliders for budget, time-to-resolution, notification deadline, API rate-limit. Defaults loaded from previous run.

### T6 — Execution Screen
Real-time stream of action steps. Each step is a card: pending (grey), running (cyan spinner), success (green check), failed (red X), retrying (yellow), rolled_back (orange).

### T7 — Approval Modal
Triggered by `approval_required` WebSocket event. Shows action + predicted side effects + alternative path. Three buttons: Approve, Reject, Modify.

### T8 — Outcome Screen
Before/after state diff (side-by-side cards), metrics panel (cost, latency, token count), baseline comparison table.

### TEST
- [ ] Navigate through all 8 screens
- [ ] Live WebSocket connection succeeds against local backend
- [ ] Approval modal triggers and resumes execution

### PUSH
```bash
git commit -am "feat: all 8 Flutter screens implemented"
git push
```

---

## HOUR 20 — Day 2 Integration Test

**Goal:** Full end-to-end pipeline works from mobile app.

### T1 — Run backend locally
```bash
cd backend
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

### T2 — Run Flutter on Android emulator or physical device
```bash
cd frontend-mobile
flutter run
```

### T3 — Execute full flow
1. Tap "Run Analysis"
2. View Plan Screen
3. View Sources Screen with rejections visible
4. View Analysis Screen with contradictions
5. Tap "Proceed to Execution"
6. Approve the destructive action in modal
7. Watch live execution with failure recovery
8. View Outcome Screen

### TEST
- [ ] All 6 wow moments visible in the demo flow
- [ ] No crashes
- [ ] WebSocket reconnects gracefully if interrupted

### PUSH
```bash
git tag day2-complete
git push --tags
git commit -am "feat: Day 2 complete — end-to-end pipeline working"
git push
```

---

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# DAY 3 — Web Dashboard, Deployment, Demo
# Hours 21–30
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

---

## HOUR 21–22 — React Web Dashboard

**Goal:** Polished trace viewer for judges.

### T1 — Initialize Vite + React + Tailwind
```bash
cd frontend-web
npm create vite@latest . -- --template react
npm install
npm install -D tailwindcss postcss autoprefixer
npx tailwindcss init -p
npm install recharts axios
```

### T2 — Create `src/api.js` with axios client.

### T3 — Build components:
- `TraceTimeline.jsx` — chronological agent transitions
- `AgentFlow.jsx` — Mermaid-style visual graph of which agent called what
- `ContradictionGraph.jsx` — bar chart of credibility scores per source per metric
- `StateDiff.jsx` — before/after side-by-side
- `MetricsPanel.jsx` — cards for cost, latency, tokens

### T4 — `RunDetail.jsx` page composing all components.

### TEST
- [ ] `npm run dev` opens dashboard
- [ ] Fetches recent run from local backend
- [ ] All visualizations render

### PUSH
```bash
git add frontend-web/
git commit -m "feat: React web dashboard with trace timeline and metrics"
git push
```

---

## HOUR 23 — Backend Deployment to Render

### T1 — Push backend to GitHub (already done)

### T2 — Create Render service
1. Sign up at render.com
2. New → Web Service → Connect GitHub repo
3. Root directory: `backend`
4. Build command: `pip install -r requirements.txt`
5. Start command: `uvicorn main:app --host 0.0.0.0 --port $PORT`
6. Add env vars: `GEMINI_API_KEY`, `GROQ_API_KEY`

### T3 — Wait for deploy → verify `/docs` page loads at `https://<service>.onrender.com/docs`

### TEST
- [ ] curl POST against deployed URL → returns run_id
- [ ] WebSocket connects from external client

### PUSH
- N/A (deployment only)

---

## HOUR 24 — Web Dashboard Deployment to Vercel

### T1 — Update `src/api.js` baseURL to deployed Render URL

### T2 — Deploy
```bash
cd frontend-web
npm install -g vercel
vercel
```
Follow prompts. Set framework to "Vite".

### T3 — Verify deployed URL loads dashboard and fetches from backend.

### PUSH
```bash
git commit -am "chore: web dashboard pointed to production backend"
git push
```

---

## HOUR 25 — Mobile App Build + Distribution

### T1 — Update `lib/config.dart` with production URLs.

### T2 — Build release APK
```bash
cd frontend-mobile
flutter build apk --release
```
Output: `build/app/outputs/flutter-apk/app-release.apk`

### T3 — Test APK on physical Android device
Side-load via USB or share via Google Drive link.

### T4 — Upload APK to GitHub Releases
```bash
gh release create v1.0 build/app/outputs/flutter-apk/app-release.apk --notes "Hackathon demo APK"
```

### TEST
- [ ] APK installs without errors
- [ ] Full flow works on physical device
- [ ] WebSocket stable

### PUSH
- N/A

---

## HOUR 26–27 — Demo Video Recording

**Goal:** 4-minute demo showcasing all 6 wow moments.

### T1 — Set up OBS Studio
Configure: 1080p, 30fps, mp4 output, screen capture region for phone mirror + browser tabs.

### T2 — Mirror Android phone to PC
Use `scrcpy` (free) or Android Studio's emulator screen.

### T3 — Record 8 segments per the demo script:
1. 0:00–0:15 — Hook + show 5 sources
2. 0:15–0:35 — Plan Reveal
3. 0:35–1:00 — Noise Rejection
4. 1:00–1:35 — Contradiction Resolution
5. 1:35–2:05 — Constraint Block
6. 2:05–2:50 — Failure Recovery
7. 2:50–3:15 — Side-Effect What-If
8. 3:15–4:00 — Outcome + ADK Traces in Web Dashboard

### T4 — Edit in OBS or free DaVinci Resolve
Stitch segments, add captions for each wow moment, fade in/out.

### T5 — Upload to YouTube unlisted
Get shareable link for README.

### TEST
- [ ] Video plays cleanly
- [ ] Total length 3:00 ≤ T ≤ 5:00
- [ ] All 6 wow moments visible

### PUSH
```bash
mv demo-video.mp4 demo/
git add demo/
git commit -m "docs: hackathon demo video"
git push
```

---

## HOUR 28 — README + Documentation

**Goal:** Complete README with all required sections.

### T1 — Write `README.md` sections:
- Project overview (1 paragraph)
- Architecture diagram (Excalidraw PNG)
- Quick start: clone, install, run locally
- Tech stack
- Data sources description (link to mock-data/)
- Tools/APIs used
- **Antigravity role and integration depth** (critical section)
- Assumptions
- Constraints documentation
- **Cost/latency analysis** with real numbers from a run
- **Baseline comparison** table (naive vs rule-based vs SENTINEL)
- Limitations and future work
- Demo video link
- Web dashboard URL
- APK download link

### T2 — Generate `docs/baseline-comparison.md`
| Approach | Decision | Stockout Risk After | Cost Wasted |
|---|---|---|---|
| Naive (latest source) | Order 50,000 units emergency | 8% | $400K |
| Rule-based (avg) | Order 25,000 units | 30% | $200K |
| SENTINEL | Order 8,000 units split in 2 batches | 18% | $0 |

### T3 — Generate `docs/cost-latency-analysis.md`
Capture metrics from a real run via the API → format table.

### T4 — Generate `docs/assumptions.md`, `docs/constraints.md`, `docs/limitations.md`

### TEST
- [ ] All required README sections present
- [ ] All links work
- [ ] Architecture diagram embedded

### PUSH
```bash
git add README.md docs/
git commit -m "docs: complete README and all required documentation"
git push
```

---

## HOUR 29 — Final Stress Testing

**Goal:** Verify all 5 stress-test scenarios pass.

### T1 — Run stress test scenarios
1. ✅ 3 sources with conflicting stock numbers → resolved by credibility
2. ✅ Action exceeds budget → modified (split)
3. ✅ Emergency order fails → retries → succeeds
4. ✅ Stale source flagged and downranked
5. ✅ Side-effect on cashflow → what-if alternative shown

### T2 — Capture screenshots of each scenario
Save to `demo/screenshots/`.

### T3 — Update `docs/stress-tests.md` with screenshots and verification.

### TEST
- [ ] All 5 scenarios documented
- [ ] Screenshots clear and legible

### PUSH
```bash
git add docs/stress-tests.md demo/screenshots/
git commit -m "docs: stress test verification with screenshots"
git push
```

---

## HOUR 30 — Submission

**Goal:** Final hackathon submission. No new code.

### Checklist
- [ ] GitHub repo public and committed
- [ ] README at root with all sections
- [ ] APK uploaded to GitHub Releases
- [ ] Web dashboard URL working
- [ ] Demo video uploaded and link in README
- [ ] ADK traces in `traces/` folder committed
- [ ] All API keys removed from code
- [ ] `.env` not in git

### Final actions
1. Run one final smoke test against production backend
2. Verify demo video plays
3. Verify APK installs on a clean device
4. Submit to hackathon portal with:
   - GitHub repo URL
   - Demo video URL
   - Web dashboard URL
   - APK download URL
5. Tag the final commit:
```bash
git tag final-submission
git push --tags
```

---

## Context.md Entry — planning.md

```
FILE: planning.md
ACTION: Created (new file)
LOCATION: Project root
CHANGE: Complete 3-day, 30-hour hackathon execution plan with hour-by-hour task
        breakdown. Covers Day 1 (agent brain — planner, ingestion, noise filter,
        insight, conflict resolver), Day 2 (action planner, side-effect analyzer,
        LangGraph executor, FastAPI + WebSocket, Flutter app with 8 screens),
        Day 3 (React web dashboard, deployment to Render and Vercel, mobile APK
        build, demo video recording, README + all required documentation,
        stress test verification, final submission). Each hour has T0 prereqs,
        T1-Tn tasks, TEST checklist, and PUSH protocol.
BEFORE: File did not exist
AFTER: Authoritative day-by-day execution roadmap for the SENTINEL hackathon build
REASON: Needed an hour-granular, task-level plan so the 3-day sprint stays on
        track and no required feature is missed. Each hour is independently
        committable and testable, enabling incremental progress with continuous
        verification.
```
