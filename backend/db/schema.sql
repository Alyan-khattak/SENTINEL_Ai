-- SENTINEL SQLite Schema
-- Canon: idea.md §9, architecture.md §9

CREATE TABLE IF NOT EXISTS Runs (
    run_id TEXT PRIMARY KEY,
    scenario TEXT NOT NULL,
    started_at DATETIME,
    completed_at DATETIME,
    status TEXT DEFAULT 'queued',
    constraints_json TEXT,
    total_llm_calls INTEGER DEFAULT 0,
    total_tokens_in INTEGER DEFAULT 0,
    total_tokens_out INTEGER DEFAULT 0,
    total_cost_usd REAL DEFAULT 0.0,
    total_duration_seconds REAL DEFAULT 0.0
);

CREATE TABLE IF NOT EXISTS Sources (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    run_id TEXT REFERENCES Runs(run_id),
    source_id TEXT,
    source_type TEXT,
    content TEXT,
    metadata_json TEXT,
    recorded_at DATETIME,
    ingested_at DATETIME
);

CREATE TABLE IF NOT EXISTS NoiseAssessments (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    run_id TEXT REFERENCES Runs(run_id),
    source_id TEXT,
    is_duplicate INTEGER DEFAULT 0,
    is_spam INTEGER DEFAULT 0,
    is_stale INTEGER DEFAULT 0,
    credibility_score INTEGER DEFAULT 5,
    keep_for_analysis INTEGER DEFAULT 1,
    rejection_reason TEXT
);

CREATE TABLE IF NOT EXISTS Insights (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    run_id TEXT REFERENCES Runs(run_id),
    metric TEXT,
    value TEXT,
    confidence REAL,
    trend TEXT,
    rate_of_change REAL,
    risk_severity TEXT
);

CREATE TABLE IF NOT EXISTS Conflicts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    run_id TEXT REFERENCES Runs(run_id),
    metric_in_conflict TEXT,
    resolution_type TEXT,
    confidence REAL,
    resolution_json TEXT
);

CREATE TABLE IF NOT EXISTS Actions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    run_id TEXT REFERENCES Runs(run_id),
    action_id TEXT,
    name TEXT,
    estimated_cost_pkr INTEGER,
    estimated_duration_minutes INTEGER,
    urgency_tier TEXT,
    is_destructive INTEGER DEFAULT 0,
    modification_applied TEXT
);

CREATE TABLE IF NOT EXISTS ActionSteps (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    run_id TEXT REFERENCES Runs(run_id),
    step_number INTEGER,
    action_id TEXT,
    status TEXT,
    started_at DATETIME,
    completed_at DATETIME,
    retried INTEGER DEFAULT 0,
    rolled_back INTEGER DEFAULT 0,
    error TEXT
);

CREATE TABLE IF NOT EXISTS Approvals (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    run_id TEXT REFERENCES Runs(run_id),
    approval_id TEXT,
    action_id TEXT,
    decision TEXT,
    modification TEXT,
    decided_at DATETIME
);

CREATE TABLE IF NOT EXISTS Metrics (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    run_id TEXT REFERENCES Runs(run_id),
    llm_provider TEXT,
    input_tokens INTEGER,
    output_tokens INTEGER,
    latency_ms INTEGER,
    estimated_cost_usd REAL,
    called_at DATETIME
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_runs_started ON Runs(started_at);
CREATE INDEX IF NOT EXISTS idx_steps_run ON ActionSteps(run_id, step_number);
CREATE INDEX IF NOT EXISTS idx_metrics_run ON Metrics(run_id, called_at);
