# SENTINEL — Signal-to-Action Autonomous Agent
> **Google Antigravity Hackathon — Challenge 1**  
> **Team Submission by AI Seekho**  
> *Powering Autonomous Organizational Logic via Google ADK, LangGraph, and Gemini 2.0 Flash*

---

## 1. Project Overview

**SENTINEL** is a production-grade **autonomous signal-to-action agent** built on Google Antigravity (ADK). Unlike simple chatbots or document summarizers, SENTINEL is a stateful multi-agent system that ingests multi-format heterogeneous organizational signals (CSVs, JSON, PDFs, and Web feeds), filters duplicate/spam/stale noise, extracts deep insights, resolves conflicting data points using recency-weighted credibility logic, plans multi-step constraint-bound actions, analyzes downstream cashflow/warehouse side-effects, and executes those actions via a robust state machine—featuring a Human-in-the-Loop approval gate before executing any destructive operations.

```
                    Heterogeneous Signal Sources (CSV, JSON, PDF, Web)
                                             │
                                             ▼
  Planner Agent ──► Ingestion Agent ──► Noise Filter ──► Insight Agent
                                                              │
                                                              ▼
                                                     Conflict Resolver
                                                              │
                                                              ▼
                                                     Action Planner ──► Side-Effect Analyzer
                                                                               │
                                                                   ┌───────────┴───────────┐
                                                                   │ Approval Gate (Human) │
                                                                   └───────────▼───────────┘
                                                                               │
                                                                    Execution (LangGraph)
```

---

## 2. Technical Stack & Languages

SENTINEL is built with a modern, high-performance, and entirely free-tier tech stack:

*   **Programming Languages:**
    *   **Python 3.11** (FastAPI backend, core agent logic, data ingestion, SQLite interactions)
    *   **Dart 3.x** (Flutter mobile client, state management, layouts, charts)
    *   **JavaScript (React/JSX/ES6)** (Web-based trace visualizer and dashboard)
    *   **SQL** (Local data schemas in SQLite)
*   **Core Frameworks:**
    *   **Google ADK (Antigravity):** Pipeline orchestration, agent transitions, and JSON trace generation.
    *   **LangGraph:** Stateful action execution graph with nodes for each task and conditional retry/rollback edges.
    *   **FastAPI:** High-performance async REST endpoints and native WebSockets for streaming execution.
    *   **Flutter:** Cross-platform mobile layouts utilizing `Provider` for state management and `fl_chart` for visual graphs.
    *   **React 18 + Vite + Tailwind CSS:** SPAs for detailed run reports and collapsible trace tree timelines.
*   **LLM Integration & Services:**
    *   **Gemini 2.0 Flash:** Primary LLM for planners, noise filters, insights, and conflict resolution.
    *   **Groq (Llama 3.3 70B):** High-speed fallback LLM automatically utilized during Gemini rate-limits or outages.
    *   **SQLite:** Local persistent relational database with 8 tables tracking runs, events, approvals, and token costs.
    *   **pdfplumber & pandas:** Robust local extraction tools for supplier invoices and stock inventory sheets.

---

## 3. Core Design Philosophy

SENTINEL's architecture is guided by five primary engineering principles:

*   **Antigravity-Central, Not Antigravity-Adjacent:** Google ADK (Antigravity) is the core brain stem. Every reasoning cycle, agent handoff, and tool execution runs through the ADK and is stored in chronological trace logs.
*   **Plan Before Act:** Before any signal is analyzed, the **Planner Agent** designs a clear, readable workplan and task plan. Users see the agents' intentions before the pipeline begins execution, eliminating the "AI black-box" problem.
*   **Contradiction-First, Conclusion-Second:** When data sources conflict, the system does not pick randomly. It scores credibility, weights recency, and either resolves the contradiction with explicit logic or builds a dynamic investigation path.
*   **Constraint-Bound Execution:** All proposed actions are checked against real-world constraints (e.g., budget limits, timelines, resource counts, API rate limits). If a constraint is violated, the Action Planner automatically modifies or rejects the action and displays why.
*   **Stateful, Recoverable Action Chains:** Plan execution runs on a stateful **LangGraph** state machine. Each step writes a state snapshot. If a step fails, the system executes exponential backoff retries, rolls back to safe states, and executes fallback nodes, streaming the timeline live to the user.

---

## 4. Complete System Architecture & Flow Diagrams

### 4.1 High-Level System Architecture
This diagram illustrates the complete architectural blueprint, showcasing the flow of data from clients through the API gateway, ADK orchestration core, stateful LangGraph executor, and the dual-model LLM tier.

```mermaid
flowchart TD
    subgraph CLIENT["Client Layer"]
        MOB["Flutter Mobile App<br/>Android APK"]
        WEB["React Web Dashboard<br/>Trace Viewer"]
    end

    subgraph API["API Gateway — FastAPI"]
        HTTP["HTTP REST<br/>/api/v1/*"]
        WS["WebSocket<br/>/ws/runs/&lt;run_id&gt;"]
        APPR["Approval Endpoint<br/>/approvals"]
    end

    subgraph ORCH["Antigravity Orchestration Core"]
        ROOT["ADK Root Agent<br/>Orchestrator"]
        PLAN["Planner Agent<br/>Module 1"]
        ING["Ingestion Agent<br/>Module 2"]
        NOISE["Noise Filter<br/>Module 3"]
        INS["Insight Agent<br/>Module 4"]
        CONF["Conflict Resolver<br/>Module 5"]
        ACT["Action Planner<br/>Module 6"]
        SIDE["Side-Effect Analyzer<br/>Module 7"]
    end

    subgraph EXEC["Execution Layer"]
        LG["LangGraph Executor<br/>Module 8"]
        TOOLS["Mock Tools<br/>Module 10"]
        APPRV["Approval Gate<br/>Module 11"]
    end

    subgraph LLM["LLM Layer"]
        CLIENT_LLM["llm_client.py<br/>Cache + Fallback + Retry"]
        GEM["Gemini 2.0 Flash<br/>Primary"]
        GROQ["Groq Llama 3.3<br/>Fallback"]
    end

    subgraph PERSIST["Persistence Layer"]
        SQL["SQLite<br/>app.db"]
        TRACE["JSON Trace Logs<br/>/traces/"]
        METRICS["Metrics Tracker<br/>Module 9"]
    end

    MOB -->|POST| HTTP
    MOB -->|stream| WS
    MOB -->|decision| APPR
    WEB -->|GET| HTTP

    HTTP --> ROOT
    WS --> ROOT
    APPR --> APPRV

    ROOT --> PLAN
    PLAN --> ING
    ING --> NOISE
    NOISE --> INS
    INS --> CONF
    CONF --> ACT
    ACT --> SIDE
    SIDE --> LG
    LG --> TOOLS
    LG --> APPRV

    PLAN -.-> CLIENT_LLM
    INS -.-> CLIENT_LLM
    CONF -.-> CLIENT_LLM
    ACT -.-> CLIENT_LLM
    SIDE -.-> CLIENT_LLM
    CLIENT_LLM --> GEM
    CLIENT_LLM -.fallback.-> GROQ

    ROOT --> TRACE
    LG --> SQL
    CLIENT_LLM --> METRICS
    LG --> METRICS
```

---

### 4.2 Sequential Agent Pipeline
Every Sentinel run progresses chronologically through eight specialized agent modules:

```mermaid
flowchart LR
    START([Client POST<br/>/api/v1/runs]) --> P1
    P1[Planner Agent] --> P2
    P2[Ingestion Agent] --> P3
    P3[Noise Filter Agent] --> P4
    P4[Insight Agent] --> P5
    P5[Conflict Resolver]
    P5 -->|resolved| P6
    P5 -->|investigate| INV[Investigation Path]
    P6[Action Planner] --> P7
    P7[Side-Effect Analyzer]
    P7 -->|no major impact| P8
    P7 -->|major impact| WIF[What-If Branch]
    WIF --> P8
    P8[Execution Agent<br/>LangGraph] --> RESULT([Run Report])
    INV --> RESULT
```

---

### 4.3 LangGraph Execution State Machine
The Action Execution Layer runs on a stateful state machine utilizing LangGraph. If any high-impact destructive action fails, the engine retries with backoff, rolls back state snapshots, and activates fallback nodes.

```mermaid
stateDiagram-v2
    [*] --> ValidateStock
    ValidateStock --> NotifyProcurement: success
    ValidateStock --> Failed: error
    
    NotifyProcurement --> EmergencyOrder: success
    NotifyProcurement --> Failed: error
    
    EmergencyOrder --> UpdateDelivery: success
    EmergencyOrder --> Retry: failure (count < 2)
    EmergencyOrder --> Rollback: failure (count >= 2)
    
    Retry --> EmergencyOrder: retry
    
    Rollback --> Fallback: rollback success
    Rollback --> Failed: rollback failed
    
    Fallback --> UpdateDelivery: success
    Fallback --> Failed: error
    
    UpdateDelivery --> ScheduleMonitoring: success
    UpdateDelivery --> Failed: error
    
    ScheduleMonitoring --> Completed: success
    ScheduleMonitoring --> Failed: error
    
    Completed --> [*]
    Failed --> [*]
```

---

### 4.4 Failure Recovery Flow chart
This charts how the executor manages errors during action execution, trying automatic retries and falling back to a safe rollback state on consecutive failures.

```mermaid
flowchart TD
    EXEC[Execute Action Step] --> RESULT{Result?}
    RESULT -->|Success| NEXT[Next step]
    RESULT -->|Failure| RETRY_CHECK{Retry count < 2?}
    
    RETRY_CHECK -->|Yes| BACKOFF[Wait exponential backoff<br/>1s, 2s, 4s]
    BACKOFF --> EXEC
    
    RETRY_CHECK -->|No| ROLLBACK[Rollback to last snapshot]
    ROLLBACK --> RB_RESULT{Rollback success?}
    
    RB_RESULT -->|Yes| FALLBACK[Execute fallback action]
    RB_RESULT -->|No| TERMINATE[Terminate run<br/>emit run_failed]
    
    FALLBACK --> FB_RESULT{Fallback success?}
    FB_RESULT -->|Yes| NEXT
    FB_RESULT -->|No| TERMINATE
```

---

### 4.5 LLM Client Decision Flow
All LLM prompts run through a unified wrapper that caches duplicate calls, enforces exponential backoff, and shifts from Gemini to Groq if API quotas are exceeded.

```mermaid
flowchart TD
    REQ[LLM Call Requested] --> CACHE{In Cache?}
    CACHE -->|Yes| RETURN_CACHE[Return Cached Response]
    CACHE -->|No| GEM_TRY[Try Gemini 2.0 Flash]
    
    GEM_TRY --> GEM_OK{Success?}
    GEM_OK -->|Yes| RECORD_GEM[Record Metrics + Cache]
    GEM_OK -->|Rate limit / 5xx| GROQ_TRY[Try Groq Llama 3.3]
    
    GROQ_TRY --> GROQ_OK{Success?}
    GROQ_OK -->|Yes| RECORD_GROQ[Record Metrics<br/>Mark as Fallback]
    GROQ_OK -->|No| RETRY{Retry < 3?}
    
    RETRY -->|Yes| BACKOFF[Exponential Backoff]
    BACKOFF --> GEM_TRY
    RETRY -->|No| FAIL[Raise Exception<br/>Trigger run_failed]
    
    RECORD_GEM --> DONE[Return Response]
    RECORD_GROQ --> DONE
    RETURN_CACHE --> DONE
```

---

### 4.6 WebSocket Event Stream Timeline
Shows the sequential message exchange between the mobile client and the FastAPI gateway throughout the agent pipeline runtime.

```mermaid
sequenceDiagram
    participant App as Flutter App
    participant API as FastAPI
    participant ADK as ADK Orchestrator
    participant LG as LangGraph Executor
    participant LLM as Gemini API
    
    App->>API: POST /api/v1/runs
    API-->>App: 202 + run_id + websocket_url
    App->>API: WS connect /ws/runs/<run_id>
    API-->>App: run_started event
    
    API->>ADK: Start pipeline
    ADK->>LLM: Planner prompt
    LLM-->>ADK: WorkPlan + TaskPlan
    ADK-->>App: planner_done event
    
    ADK->>ADK: Ingestion (local file parsing)
    ADK-->>App: ingestion_done event
    
    ADK->>LLM: Noise filter analysis
    LLM-->>ADK: NoiseAssessments
    ADK-->>App: noise_filter_done event
    
    ADK->>LLM: Insight extraction
    LLM-->>ADK: Insights with temporal data
    ADK-->>App: insight_done event
    
    ADK->>LLM: Conflict resolution
    LLM-->>ADK: ConflictResolution
    ADK-->>App: conflict_done event
    
    ADK->>LLM: Action planning
    LLM-->>ADK: Action chain
    ADK->>ADK: Apply constraint checks
    ADK-->>App: action_planner_done event
    
    ADK->>LLM: Side-effect prediction
    LLM-->>ADK: SideEffectAnalysis
    ADK-->>App: side_effect_done event
    
    ADK->>LG: Hand off action chain
    LG-->>App: approval_required
    App-->>LG: POST approval decision
    
    loop For each action step
        LG-->>App: step_started
        LG->>LG: Execute node
        alt Step succeeds
            LG-->>App: step_completed
        else Step fails (first try)
            LG-->>App: step_failed
            LG-->>App: step_retrying
            LG->>LG: Retry node
            LG-->>App: step_completed
        end
    end
    
    LG-->>App: run_completed event
    LG->>ADK: Final state
    ADK->>API: Persist trace + report
```

---

### 4.7 Approval Gate Flow
Illustrates the user checkpoint sequence before a destructive or highly negative step executes.

```mermaid
sequenceDiagram
    participant User
    participant App as Flutter App
    participant WS as WebSocket
    participant LG as LangGraph
    participant Action as Destructive Action
    
    LG->>LG: Reach is_destructive=true step
    LG->>WS: emit approval_required event
    WS->>App: approval_required payload
    App->>User: Show approval modal
    
    alt User taps Approve
        User->>App: Approve
        App->>WS: POST /approvals (decision=approve)
        WS->>LG: Resume with approval=true
        LG->>Action: Execute as planned
    else User taps Reject
        User->>App: Reject
        App->>WS: POST /approvals (decision=reject)
        WS->>LG: Resume with approval=false
        LG->>LG: Skip action, mark as rejected
    else User taps Modify
        User->>App: Modify (provides changes)
        App->>WS: POST /approvals (decision=modify, modification)
        WS->>LG: Resume with modification
        LG->>Action: Execute with modified params
    end
```

---

### 4.8 Constraint Enforcement Flow
Shows the validation logic executed for each planned action to ensure it respects PKR budgets and timelines.

```mermaid
flowchart TD
    ACT_GEN[Action Planner generates 5 actions] --> LOOP{For each action}
    
    LOOP --> CK1{Within<br/>budget?}
    CK1 -->|No| MOD_BUDGET[Modify: split or reduce]
    CK1 -->|Yes| CK2
    
    CK2{Within<br/>time deadline?}
    CK2 -->|No| MOD_TIME[Modify: parallelize]
    CK2 -->|Yes| CK3
    
    CK3{Within API<br/>rate limit?}
    CK3 -->|No| MOD_RATE[Add throttle/batch]
    CK3 -->|Yes| CK4
    
    CK4{Required<br/>resources<br/>available?}
    CK4 -->|No| REJECT[Reject with reason]
    CK4 -->|Yes| KEEP[Keep action unchanged]
    
    MOD_BUDGET --> RE_CHECK{Modification<br/>feasible?}
    MOD_TIME --> RE_CHECK
    MOD_RATE --> RE_CHECK
    
    RE_CHECK -->|Yes| KEEP_MOD[Keep modified action]
    RE_CHECK -->|No| REJECT
    
    KEEP --> NEXT
    KEEP_MOD --> NEXT
    REJECT --> NEXT
    NEXT[Next action] --> LOOP
    LOOP -->|Done| FINAL[Final action chain]
```

---

### 4.9 Contradiction Resolution Logic
Details how the agent groups and resolves metrics using recency-weighted scoring formulas.

```mermaid
flowchart TD
    INSIGHTS[All Insights with source attribution] --> GROUP[Group by metric]
    GROUP --> CHECK{Same metric in<br/>2+ sources?}
    CHECK -->|No| NO_CONFLICT[No conflict]
    CHECK -->|Yes| COMPARE[Compare values]
    
    COMPARE --> SAME{Values<br/>match?}
    SAME -->|Yes| CONFIRMED[Confirmed signal]
    SAME -->|No| WEIGHT[Weight each source]
    
    WEIGHT --> W1[Recency weight<br/>newer = higher]
    W1 --> W2[Source type weight<br/>official &gt; news &gt; social]
    W2 --> W3[Internal consistency check]
    W3 --> SCORE[Compute credibility score]
    
    SCORE --> DOMINANT{One source<br/>clearly dominant?}
    DOMINANT -->|Yes| RESOLVE[Resolution:<br/>trust winner, mark others stale]
    DOMINANT -->|No| INVESTIGATE[Investigation Path:<br/>generate next steps]
    
    RESOLVE --> OUT_RES[ConflictResolution<br/>type=resolved]
    INVESTIGATE --> OUT_INV[ConflictResolution<br/>type=investigation_required]
```

---

### 4.10 ERD Database Schema
Shows the SQL schema stored locally on SQLite to track the run timeline and logs.

```mermaid
erDiagram
    Runs {
        text run_id PK
        text scenario
        datetime started_at
        datetime completed_at
        text status
        text constraints_json
        int total_llm_calls
        int total_tokens_in
        int total_tokens_out
        real total_cost_usd
        real total_duration_seconds
    }
    Sources {
        int id PK
        text run_id FK
        text source_id
        text source_type
        text content
        text metadata_json
        datetime recorded_at
        datetime ingested_at
    }
    NoiseAssessments {
        int id PK
        text run_id FK
        text source_id
        int is_duplicate
        int is_spam
        int is_stale
        int credibility_score
        int keep_for_analysis
        text rejection_reason
    }
    Insights {
        int id PK
        text run_id FK
        text metric
        text value
        real confidence
        text trend
        real rate_of_change
        text risk_severity
    }
    Conflicts {
        int id PK
        text run_id FK
        text metric_in_conflict
        text resolution_type
        real confidence
        text resolution_json
    }
    Actions {
        int id PK
        text run_id FK
        text action_id
        text name
        int estimated_cost_pkr
        int estimated_duration_minutes
        text urgency_tier
        int is_destructive
        text modification_applied
    }
    ActionSteps {
        int id PK
        text run_id FK
        int step_number
        text action_id FK
        text status
        datetime started_at
        datetime completed_at
        int retried
        int rolled_back
        text error
    }
    Approvals {
        int id PK
        text run_id FK
        text approval_id
        text action_id
        text decision
        text modification
        datetime decided_at
    }
    Metrics {
        int id PK
        text run_id FK
        text llm_provider
        int input_tokens
        int output_tokens
        int latency_ms
        real estimated_cost_usd
        datetime called_at
    }

    Runs ||--o{ Sources : ""
    Runs ||--o{ NoiseAssessments : ""
    Runs ||--o{ Insights : ""
    Runs ||--o{ Conflicts : ""
    Runs ||--o{ Actions : ""
    Runs ||--o{ ActionSteps : ""
    Runs ||--o{ Approvals : ""
    Runs ||--o{ Metrics : ""
    Actions ||--o{ ActionSteps : "executed as"
    Actions ||--o{ Approvals : "approved via"
```

---

### 4.11 Side-Effect What-If Branch
Shows how downstream side-effects trigger an alternative path simulation.

```mermaid
flowchart TD
    ACTIONS[Action chain from Planner] --> ANALYZE[Side-Effect Analyzer]
    ANALYZE --> LLM_CALL[Gemini predicts<br/>downstream impacts]
    
    LLM_CALL --> IMPACTS[List of impacts<br/>per business area]
    IMPACTS --> SCORE{Any impact<br/>medium-high negative?}
    
    SCORE -->|No| PROCEED[Proceed with original chain]
    SCORE -->|Yes| ALT[Generate Alternative Path]
    
    ALT --> COMPARE[Compare paths side-by-side]
    COMPARE --> SHOW[Show both paths to user via approval gate]
    
    SHOW --> CHOOSE{User chooses}
    CHOOSE -->|Original| PROCEED
    CHOOSE -->|Alternative| EXEC_ALT[Execute alternative]
    CHOOSE -->|Reject both| ABORT[Abort run]
    
    PROCEED --> EXECUTOR[Hand off to LangGraph]
    EXEC_ALT --> EXECUTOR
```

---

### 4.12 Mobile App Screen Navigation
Shows the complete Dart navigation path across the 8 views of the Flutter mobile app.

```mermaid
flowchart LR
    INPUT[Input Screen] --> PLAN[Plan Screen]
    PLAN --> SOURCES[Sources Screen]
    SOURCES --> ANALYSIS[Analysis Screen]
    ANALYSIS --> CONSTRAINTS[Constraints Screen]
    CONSTRAINTS --> EXEC[Execution Screen]
    EXEC -.modal.-> APPROVAL[Approval Modal]
    APPROVAL -.resume.-> EXEC
    EXEC --> OUTCOME[Outcome Screen]
    OUTCOME --> TRACE[Trace Screen]
    TRACE -.back.-> INPUT
```

---

### 4.13 Deployment Architecture
Outlines where services are hosted and how they communicate in production.

```mermaid
flowchart TB
    subgraph LOCAL["Developer Machine"]
        FLUTTER_DEV[Flutter SDK]
        APK_BUILD[flutter build apk]
    end
    
    subgraph GITHUB["GitHub Repository"]
        REPO[Public Repo<br/>backend + frontend-web]
        RELEASE[Releases<br/>APK artifact]
    end
    
    subgraph RENDER["Render.com"]
        FAST_DEPLOY[FastAPI Container<br/>Free Tier 750 hrs]
        ENV[Env Vars<br/>GEMINI_API_KEY<br/>GROQ_API_KEY]
    end
    
    subgraph VERCEL["Vercel"]
        REACT_DEPLOY[React Build<br/>Edge CDN]
    end
    
    subgraph EXTERNAL["External APIs"]
        GEM_API[Google Gemini API]
        GROQ_API[Groq Cloud API]
    end
    
    subgraph USERS["End Users"]
        JUDGES_APK[Judges' Android Phone]
        JUDGES_WEB[Judges' Browser]
    end
    
    FLUTTER_DEV --> APK_BUILD
    APK_BUILD --> RELEASE
    REPO -->|auto-deploy| FAST_DEPLOY
    REPO -->|auto-deploy| REACT_DEPLOY
    
    JUDGES_APK -->|HTTPS| FAST_DEPLOY
    JUDGES_WEB --> REACT_DEPLOY
    REACT_DEPLOY -->|fetch API| FAST_DEPLOY
    
    FAST_DEPLOY --> GEM_API
    FAST_DEPLOY -.fallback.-> GROQ_API
    
    ENV --> FAST_DEPLOY
    RELEASE -->|download APK| JUDGES_APK
```

---

### 4.14 Component Interaction — Full Detail
Details the classes, files, and API endpoints interacting across layers.

```mermaid
flowchart TD
    subgraph FRONTEND["Frontend"]
        F1[Mobile Input Screen]
        F2[Mobile Plan Screen]
        F3[Mobile Sources Screen]
        F4[Mobile Analysis Screen]
        F5[Mobile Constraints Screen]
        F6[Mobile Execution Screen]
        F7[Mobile Outcome Screen]
        F8[Web Trace Viewer]
    end
    
    subgraph API_LAYER["API Layer"]
        EP_POST[POST /runs]
        EP_GET[GET /runs/&lt;id&gt;]
        EP_TRACE[GET /runs/&lt;id&gt;/trace]
        EP_APPRV[POST /approvals]
        EP_WS[WS /ws/runs/&lt;id&gt;]
    end
    
    subgraph AGENT_LAYER["Agent Layer"]
        A_ROOT[ADK Root Agent]
        A_PLAN[Planner Agent]
        A_ING[Ingestion Agent]
        A_NOISE[Noise Filter]
        A_INS[Insight Agent]
        A_CONF[Conflict Resolver]
        A_ACT[Action Planner]
        A_SIDE[Side-Effect Analyzer]
        A_EXEC[Execution Agent / LangGraph]
    end
    
    subgraph UTILS["Utilities"]
        U_LLM[llm_client.py]
        U_METRICS[metrics_tracker.py]
        U_CACHE[cache.py]
        U_LOG[logger.py]
    end
    
    subgraph STORAGE["Storage"]
        S_SQL[SQLite app.db]
        S_TRACE[JSON traces/]
        S_MOCK[Mock data files]
    end
    
    F1 --> EP_POST
    F1 --> EP_WS
    F2 --> EP_WS
    F3 --> EP_WS
    F4 --> EP_WS
    F5 --> EP_POST
    F6 --> EP_WS
    F6 --> EP_APPRV
    F7 --> EP_GET
    F8 --> EP_GET
    F8 --> EP_TRACE
    
    EP_POST --> A_ROOT
    EP_WS --> A_ROOT
    EP_APPRV --> A_EXEC
    
    A_ROOT --> A_PLAN --> A_ING --> A_NOISE --> A_INS --> A_CONF --> A_ACT --> A_SIDE --> A_EXEC
    
    A_PLAN --> U_LLM
    A_INS --> U_LLM
    A_NOISE --> U_LLM
    A_CONF --> U_LLM
    A_ACT --> U_LLM
    A_SIDE --> U_LLM
    
    A_ING --> S_MOCK
    
    A_EXEC --> S_SQL
    A_ROOT --> S_TRACE
    
    U_LLM --> U_METRICS
    U_LLM --> U_CACHE
    U_LLM --> U_LOG
```

---

### 4.15 API Gateway Overview
All REST and WebSocket endpoints exposed by SENTINEL are versioned under `/api/v1/`. The interactive Swagger UI at `/docs` lets you execute any call directly from your browser.

```mermaid
flowchart LR
    subgraph REST["REST Endpoints"]
        R1["POST /api/v1/runs"]
        R2["GET  /api/v1/runs"]
        R3["GET  /api/v1/runs/{run_id}"]
        R4["GET  /api/v1/runs/{run_id}/trace"]
        R5["POST /api/v1/runs/{run_id}/approvals"]
        R6["GET  /health"]
    end
    subgraph WS["WebSocket"]
        W1["WS /ws/runs/{run_id}"]
    end
    subgraph EVENTS["Emitted WS Events"]
        E1["run_started"]
        E2["planner_done"]
        E3["ingestion_done"]
        E4["noise_filter_done"]
        E5["insight_done"]
        E6["conflict_done"]
        E7["action_planner_done"]
        E8["side_effect_done"]
        E9["approval_required"]
        E10["step_started / step_completed / step_failed / step_retrying / step_rolled_back"]
        E11["run_completed / run_failed"]
    end
    W1 --> EVENTS
```

---

## 5. Detailed Walkthrough of System Structure

### 5.1 Project Folder Layout
The codebase is organized into modules, isolating backend, mobile app, web dashboard, and test datasets:

```
sentinel-hackathon/
│
├── README.md                              # Main documentation (this file)
├── idea.md                                # Canonical project reference
├── architecture.md                        # Compilation of mermaid text flows
├── planning.md                            # Granular sprint execution roadmap
├── railway.json                           # Railway deployment config
├── .gitignore                             # Git exclusion list
│
├── docs/                                  # Side documents
│   ├── assumptions.md                     # Assumptions on signals & APIs
│   ├── cost-latency-analysis.md           # Latency and API cost metrics
│   └── limitations.md                     # Constraints & future expansions
│
├── mock-data/                             # 7 Mock signals
│   ├── warehouse_stock_7days.csv          # 7-day declining stocks for SKU001
│   ├── supplier_email.pdf                 # PDF invoice warning of delays
│   ├── sales_dashboard.json               # JSON sales increase indicators
│   ├── complaints.json                    # Customer complaint tickets
│   ├── news_feed.json                     # Regional logistic transport alerts
│   ├── duplicate_spam_source.json         # Duplicate source for noise testing
│   └── stale_irrelevant_source.json       # Outdated sheet for noise testing
│
├── backend/                               # FastAPI Backend Application
│   ├── main.py                            # REST Router + WebSocket Server
│   ├── requirements.txt                   # Backend dependencies
│   ├── config.py                          # Env parsing and static limits
│   ├── db/                                # SQLite persistence database
│   ├── traces/                            # JSON output files generated by ADK
│   ├── models/                            # Pydantic schemas (Source, Action, etc)
│   ├── prompts/                           # Prompts (planner, noise, conflict)
│   ├── utils/                             # Helpers (llm_client, metrics)
│   ├── tools/                             # Local parsers (pdf, csv, web)
│   └── agents/                            # ADK modules and LangGraph execution
│       ├── orchestrator.py                # ADK Root Agent
│       ├── planner_agent.py               # Module 1 (Workplan configuration)
│       ├── ingestion_agent.py             # Module 2 (Signal parsing)
│       ├── noise_filter_agent.py          # Module 3 (Credibility filtering)
│       ├── insight_agent.py               # Module 4 (Trend analysis)
│       ├── conflict_resolver.py           # Module 5 (Conflict scoring)
│       ├── action_planner.py              # Module 6 (Constraint checks)
│       ├── side_effect_analyzer.py        # Module 7 (What-if branching)
│       └── execution_agent.py             # Module 8 (LangGraph state engine)
│
├── frontend-mobile/                       # Flutter Mobile Client (Module 15)
│   ├── pubspec.yaml                       # Dart package config
│   ├── lib/
│   │   ├── main.dart                      # App entry point
│   │   ├── config.dart                    # API base URLs
│   │   ├── theme/                         # Theme styles
│   │   ├── services/                      # API and WebSocket channels
│   │   ├── screens/                       # 8 UI Views (Input, Plan, etc)
│   │   └── widgets/                       # Components (ApprovalModal, etc)
│   └── android/                           # Build files for releases
│
└── frontend-web/                          # React Web Dashboard (Module 14)
    ├── package.json                       # JS package config
    ├── vite.config.js                     # Vite build config
    └── src/
        ├── main.jsx                       # React entry point
        ├── api.js                         # Axios endpoints
        ├── App.jsx                        # Layout and routing
        └── components/                    # Trace timelines and graphs
```

---

### 5.2 How Features Work Under the Hood

#### 1. Ingestion & Rule-Based Filtering
The **Ingestion Agent** receives files as byte paths, parsing them via native libraries (`pdfplumber` for PDF, `pandas` for CSV) to return a unified schema mapping. The **Noise Filter** inspects this stream: it computes similarity hashes (rejecting duplicate uploads), reads timestamps against a threshold (discarding stale logs), and checks keywords to flag spam. Clean signals are passed to the **Insight Agent**.

#### 2. Recency-Weighted Conflict Resolution
If multiple sources claim different values for the same metric (e.g. current inventory count), the **Conflict Resolver** scores each source using:
$$\text{Weight} = (\text{Recency} \times 0.5) + (\text{Source Type Score} \times 0.3) + (\text{Consistency} \times 0.2)$$
The source with the highest weight is trusted, and the contradiction is logged as resolved. If the weights are equal, the system builds an *Investigation Path* (an explicit plan requesting further data retrieval).

#### 3. Constraint-Bound Planning
The **Action Planner** drafts actions. The system validates them against constraints:
*   *Budget Cap:* Exceeding limits triggers an automatic split into smaller batches.
*   *Time Limits:* Slow actions are converted to run in parallel.
*   *API Limits:* Excessive API requests trigger automatic throttling.
Infeasible actions are rejected, and the reasoning is returned.

#### 4. Stateful Recovery and Rollbacks
The **LangGraph Executor** manages actions. Each action corresponds to a node in the state graph. Nodes are executed sequentially:
*   On success, the output state diff is broadcasted, and the graph moves to the next node.
*   On failure, the node retries with exponential backoff (1s, 2s, 4s).
*   If retries are exhausted, the graph rolls back to the last state snapshot.
*   Upon successful rollback, a fallback action node (e.g., placing an order with a local supplier) is run.

#### 5. Human-in-the-Loop Approval Gate
When the executor reaches a node marked `is_destructive=true` (such as completing an order payment), it broadcasts an `approval_required` WebSocket event and pauses the graph execution. The mobile app displays an overlay modal showing the proposed action and estimated budget. Once the user selects *Approve*, *Reject*, or *Modify*, the client posts the decision to the `/approvals` API, letting the execution graph resume or abort.

---

## 6. Step-by-Step Local Setup & Running Guide

### 6.1 Prerequisites
Ensure the following packages are installed globally on your machine:
*   Python 3.11+ (with `pip`)
*   Node.js v18+ (with `npm`)
*   Flutter SDK 3.x+ (with `flutter`)
*   An active Android Emulator or physical device with USB debugging enabled.

---

### 6.2 Step 1: Backend Setup (FastAPI)
1.  Navigate into the `backend` directory:
    ```bash
    cd backend
    ```
2.  Create and activate your virtual environment:
    ```bash
    python -m venv venv
    # On Windows (PowerShell):
    venv\Scripts\Activate.ps1
    # On macOS/Linux:
    source venv/bin/activate
    ```
3.  Install all backend dependencies:
    ```bash
    pip install -r requirements.txt
    ```
4.  Configure your environment variables:
    ```bash
    cp .env.example .env
    ```
    Open `backend/.env` in your text editor and input your API keys:
    ```env
    GEMINI_API_KEY=AIzaSy... (Obtain from Google AI Studio)
    GROQ_API_KEY=gsk_...     (Obtain from Groq Cloud Console)
    ```
5.  Launch the FastAPI server:
    ```bash
    python -m uvicorn main:app --host 127.0.0.1 --port 8001
    ```
    *   Interactive Swagger API docs will be active at: `http://localhost:8001/docs`
    *   System Health Check will be active at: `http://localhost:8001/health`

---

### 6.3 Step 2: Web Dashboard Setup (React + Vite)
1.  Navigate into the `frontend-web` directory:
    ```bash
    cd frontend-web
    ```
2.  Install the JavaScript dependencies:
    ```bash
    npm install
    ```
3.  Launch the Vite development server:
    ```bash
    npm run dev
    ```
    *   Open your browser to: `http://localhost:5173`
    *   *Note: For local development, ensure `.env` values are configured to connect to your local backend (`http://localhost:8001/api/v1`).*

---

### 6.4 Step 3: Mobile App Setup (Flutter)
1.  Navigate into the `frontend-mobile` directory:
    ```bash
    cd frontend-mobile
    ```
2.  Restore the Flutter packages:
    ```bash
    flutter pub get
    ```
3.  Run the application:
    ```bash
    flutter run
    ```
    *Note: To connect the app to a local backend, open `lib/config.dart` and update the addresses to point to your computer's IP address (e.g. `http://10.0.2.2:8001` for Android Emulator).*

---

## 7. How to Verify Custom Scenarios Live

We have built two custom datasets in `mock-data/` to test the system's dynamic reasoning. You can trigger these scenarios from the mobile or web app:

### Test Scenario A: Wheat Supply Chain Spike (JSON + CSV)
*Tests dynamic wheat metrics and stock depletion calculations.*
1.  Go to the **Input Screen** and select **"Custom Input"**.
2.  Set the **SCENARIO** name to: `wheat_shortage`
3.  Add the following source logs:
    *   **Source 1 (Sales JSON):**
        ```json
        {
          "report_date": "2026-05-18",
          "period": "last_7_days",
          "metrics": {
            "demand_change_percent": 65,
            "skus_at_risk": ["SKU004"],
            "stockout_probability": 0.98,
            "daily_units_sold": [1200, 1400, 1600, 1900, 2200, 2500, 3100]
          },
          "trend": "exponential_growth"
        }
        ```
    *   **Source 2 (Warehouse CSV):**
        ```csv
        sku,name,quantity,recorded_at
        SKU004,Wheat Flour 10kg,15000,2026-05-12T08:00:00
        SKU004,Wheat Flour 10kg,8000,2026-05-15T08:00:00
        SKU004,Wheat Flour 10kg,1200,2026-05-18T08:00:00
        ```
4.  Run the pipeline and verify the **Outcome Screen** displays the simulated Wheat Flour safety stocks.

### Test Scenario B: Karachi Sugar Shortage (CSV + Text)
*Tests contradiction resolution and alternative logistics path routing.*
1.  Go to the **Input Screen** and select **"Custom Input"**.
2.  Set the **SCENARIO** name to: `sugar_shortage`
3.  Add the following source logs:
    *   **Source 1 (Warehouse CSV):**
        ```csv
        sku,name,quantity,recorded_at
        SKU003,Sugar 50kg,8000,2026-05-10T08:00:00
        SKU003,Sugar 50kg,600,2026-05-12T08:00:00
        SKU003,Sugar 50kg,3000,2026-05-14T08:00:00
        SKU003,Sugar 50kg,600,2026-05-16T08:00:00
        ```
    *   **Source 2 (Text Alert):**
        ```text
        CRITICAL DISRUPTIONS: All shipping container trucks routed through the Karachi Bypass are blocked due to an active logistics union strike. Deliveries of SKU003 Sugar will experience shipment delays of up to 72 hours. Regional alternative dispatch paths are clear but charge a transport rate premium of 25% on delivery.
        ```
4.  Run the pipeline and verify the **Side-Effect Analyzer** triggers the alternative transport dispatch path.

---

## 8. Evaluation Criteria Mapping

This section maps the hackathon evaluation categories directly to SENTINEL's core system modules:

| Criterion | Weight | SENTINEL Implementation |
|---|---|---|
| **Antigravity Integration** | 20% | Handled via Module 1 (Planner workplans), Module 13 (ADK Trace Exporter), and Module 14 (Web timeline visualization). |
| **Agentic Reasoning & Workflow** | 20% | Sequenced pipeline of 8 agents (Modules 1-8), conditional routing in LangGraph (Module 8), and What-If side-effect branching (Module 7). |
| **Insight Quality & Contradiction Handling** | 20% | Checked via Module 3 (Noise filter), Module 4 (Temporal trend insights), and Module 5 (Recency-weighted conflict resolution). |
| **Action Chain & Outcome Simulation** | 15% | Handled via Module 6 (5-step constraint validator) and Module 8 (LangGraph execution, backoff retries, state rollbacks, and before/after comparisons). |
| **Robustness, Scalability, Cost/Latency** | 15% | Monitored via Module 9 (Metrics tracker), `llm_client.py` (caching & Gemini-to-Groq fallback), and database WAL concurrency optimization. |
| **Innovation & UX** | 10% | Verified via Module 11 (Approval Gate modal), Module 12 (Adjustable constraint sliders), and the dark glassmorphic Flutter interfaces. |
