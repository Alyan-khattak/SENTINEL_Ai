# SENTINEL — System Architecture Diagrams
> Signal-to-Action Autonomous Agent
> Visual Architecture Reference for Engineering & Demo

---

## 1. High-Level System Architecture

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

## 2. Sequential Agent Pipeline

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

## 3. LangGraph Execution State Machine

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

## 4. LLM Client Decision Flow

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

## 5. WebSocket Event Stream Timeline

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

## 6. Approval Gate Flow

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

## 7. Constraint Enforcement Flow

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

## 8. Contradiction Resolution Logic

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

## 9. Database Schema

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

## 10. Failure Recovery Flow

```mermaid
flowchart TD
    EXEC[Execute Action Step] --> RESULT{Result?}
    RESULT -->|Success| NEXT[Next step]
    RESULT -->|Failure| RETRY_CHECK{Retry count &lt; 2?}
    
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

## 11. Side-Effect What-If Branch

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

## 12. Mobile App Screen Navigation

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

## 13. Deployment Architecture

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

## 14. Component Interaction — Full Detail

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
    
    subgraph TOOLS_LAYER["Tools"]
        T_PDF[pdf_parser]
        T_CSV[csv_parser]
        T_JSON[json_parser]
        T_WEB[web_fetcher]
        T_MOCK[mock_apis]
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
    
    A_ING --> T_PDF
    A_ING --> T_CSV
    A_ING --> T_JSON
    A_ING --> T_WEB
    A_ING --> S_MOCK
    
    A_EXEC --> T_MOCK
    A_EXEC --> S_SQL
    A_ROOT --> S_TRACE
    
    U_LLM --> U_METRICS
    U_LLM --> U_CACHE
    U_LLM --> U_LOG
```

---

## 15. Demo Video Flow Map

```mermaid
flowchart LR
    M0[0:00-0:15<br/>Hook + 5 source files] --> M1
    M1[0:15-0:35<br/>Plan Reveal] --> M2
    M2[0:35-1:00<br/>Noise Rejection] --> M3
    M3[1:00-1:35<br/>Contradiction Resolution] --> M4
    M4[1:35-2:05<br/>Constraint Block] --> M5
    M5[2:05-2:50<br/>Failure Recovery] --> M6
    M6[2:50-3:15<br/>Side-Effect What-If] --> M7
    M7[3:15-3:45<br/>Outcome + Metrics] --> M8
    M8[3:45-4:00<br/>ADK Traces in Web Dashboard]
```
