"""
SENTINEL Database — SQLite persistence.
Fully populated database queries for all schema.sql tables.
Canon: idea.md §9, architecture.md §9
"""

import os
import json
import sqlite3
from datetime import datetime
from typing import Optional, List, Dict, Any

from config import settings
from utils.logger import logger


def get_connection() -> sqlite3.Connection:
    """Get a SQLite connection, creating the database if needed."""
    os.makedirs(os.path.dirname(settings.DB_PATH), exist_ok=True)
    conn = sqlite3.connect(settings.DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn


def init_db():
    """Initialize the database schema."""
    schema_path = os.path.join(os.path.dirname(settings.DB_PATH), "schema.sql")
    conn = get_connection()
    try:
        with open(schema_path, "r") as f:
            conn.executescript(f.read())
        conn.commit()
        logger.info("Database initialized successfully")
    except Exception as e:
        logger.error(f"Database init failed: {e}")
    finally:
        conn.close()


def save_run(run_id: str, scenario: str, constraints_json: str, status: str = "queued"):
    """Insert a new run record."""
    conn = get_connection()
    try:
        conn.execute(
            "INSERT OR REPLACE INTO Runs (run_id, scenario, started_at, status, constraints_json) VALUES (?, ?, ?, ?, ?)",
            (run_id, scenario, datetime.utcnow().isoformat(), status, constraints_json),
        )
        conn.commit()
    except Exception as e:
        logger.warning(f"Database save_run failed: {e}")
    finally:
        conn.close()


def update_run_status(run_id: str, status: str, completed_at: Optional[str] = None,
                      total_llm_calls: int = 0, total_duration: float = 0.0,
                      total_tokens_in: int = 0, total_tokens_out: int = 0):
    """Update run status, metrics, and token counts."""
    conn = get_connection()
    try:
        conn.execute(
            "UPDATE Runs SET status=?, completed_at=?, total_llm_calls=?, total_duration_seconds=?, total_tokens_in=?, total_tokens_out=? WHERE run_id=?",
            (status, completed_at or datetime.utcnow().isoformat(), total_llm_calls, total_duration, total_tokens_in, total_tokens_out, run_id),
        )
        conn.commit()
    except Exception as e:
        logger.warning(f"Database update_run_status failed: {e}")
    finally:
        conn.close()


def save_sources(run_id: str, sources: List[Any]):
    """Save all ingested sources into the database."""
    conn = get_connection()
    try:
        for src in sources:
            meta = src.metadata if hasattr(src, "metadata") else {}
            conn.execute(
                "INSERT INTO Sources (run_id, source_id, source_type, content, metadata_json, recorded_at, ingested_at) VALUES (?, ?, ?, ?, ?, ?, ?)",
                (
                    run_id,
                    getattr(src, "source_id", ""),
                    getattr(src, "source_type", ""),
                    getattr(src, "content", ""),
                    json.dumps(meta),
                    getattr(src, "recorded_at", datetime.utcnow()).isoformat() if isinstance(getattr(src, "recorded_at", None), datetime) else str(getattr(src, "recorded_at", "")),
                    getattr(src, "ingested_at", datetime.utcnow()).isoformat() if isinstance(getattr(src, "ingested_at", None), datetime) else str(getattr(src, "ingested_at", "")),
                )
            )
        conn.commit()
        logger.info(f"Persisted {len(sources)} sources to SQLite database")
    except Exception as e:
        logger.warning(f"Failed to persist sources: {e}")
    finally:
        conn.close()


def save_noise_assessments(run_id: str, assessments: List[Any]):
    """Save all noise assessments into the database."""
    conn = get_connection()
    try:
        for ass in assessments:
            conn.execute(
                "INSERT INTO NoiseAssessments (run_id, source_id, is_duplicate, is_spam, is_stale, credibility_score, keep_for_analysis, rejection_reason) VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
                (
                    run_id,
                    getattr(ass, "source_id", ""),
                    1 if getattr(ass, "is_duplicate", False) else 0,
                    1 if getattr(ass, "is_spam", False) else 0,
                    1 if getattr(ass, "is_stale", False) else 0,
                    getattr(ass, "credibility_score", 5),
                    1 if getattr(ass, "keep_for_analysis", True) else 0,
                    getattr(ass, "rejection_reason", None)
                )
            )
        conn.commit()
        logger.info(f"Persisted {len(assessments)} noise assessments to SQLite database")
    except Exception as e:
        logger.warning(f"Failed to persist noise assessments: {e}")
    finally:
        conn.close()


def save_insights(run_id: str, insights: List[Any]):
    """Save all extracted insights into the database."""
    conn = get_connection()
    try:
        for ins in insights:
            conn.execute(
                "INSERT INTO Insights (run_id, metric, value, confidence, trend, rate_of_change, risk_severity) VALUES (?, ?, ?, ?, ?, ?, ?)",
                (
                    run_id,
                    getattr(ins, "metric", ""),
                    str(getattr(ins, "value", "")),
                    getattr(ins, "confidence", 1.0),
                    getattr(ins, "trend", "stable"),
                    getattr(ins, "rate_of_change", 0.0),
                    getattr(ins, "risk_severity", "low")
                )
            )
        conn.commit()
        logger.info(f"Persisted {len(insights)} insights to SQLite database")
    except Exception as e:
        logger.warning(f"Failed to persist insights: {e}")
    finally:
        conn.close()


def save_conflicts(run_id: str, conflicts: Any):
    """Save detected contradictions and resolved outcomes into the database."""
    conn = get_connection()
    try:
        contradictions = getattr(conflicts, "contradictions", [])
        res_type = getattr(conflicts, "resolution_type", "resolved")
        conf = getattr(conflicts, "confidence", 1.0)
        
        for cont in contradictions:
            vals = getattr(cont, "conflicting_values", [])
            conn.execute(
                "INSERT INTO Conflicts (run_id, metric_in_conflict, resolution_type, confidence, resolution_json) VALUES (?, ?, ?, ?, ?)",
                (
                    run_id,
                    getattr(cont, "metric", ""),
                    res_type,
                    conf,
                    json.dumps({
                        "conflicting_values": vals,
                        "winner_source_id": getattr(cont, "winner_source_id", ""),
                        "reasoning": getattr(cont, "reasoning", "")
                    })
                )
            )
        conn.commit()
        logger.info(f"Persisted conflict resolutions to SQLite database")
    except Exception as e:
        logger.warning(f"Failed to persist conflicts: {e}")
    finally:
        conn.close()


def save_actions(run_id: str, actions: List[Any]):
    """Save planned action plans into the database."""
    conn = get_connection()
    try:
        for act in actions:
            conn.execute(
                "INSERT INTO Actions (run_id, action_id, name, estimated_cost_pkr, estimated_duration_minutes, urgency_tier, is_destructive, modification_applied) VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
                (
                    run_id,
                    getattr(act, "action_id", ""),
                    getattr(act, "name", ""),
                    getattr(act, "estimated_cost_pkr", 0),
                    getattr(act, "estimated_duration_minutes", 0),
                    getattr(act, "urgency_tier", "medium"),
                    1 if getattr(act, "is_destructive", False) else 0,
                    getattr(act, "modification_applied", None)
                )
            )
        conn.commit()
        logger.info(f"Persisted {len(actions)} actions to SQLite database")
    except Exception as e:
        logger.warning(f"Failed to persist actions: {e}")
    finally:
        conn.close()


def save_action_steps(run_id: str, steps: List[Any]):
    """Save execution steps (retries, rollbacks, status updates) into the database."""
    conn = get_connection()
    try:
        for step in steps:
            conn.execute(
                "INSERT INTO ActionSteps (run_id, step_number, action_id, status, started_at, completed_at, retried, rolled_back, error) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
                (
                    run_id,
                    getattr(step, "step_number", 0),
                    getattr(step, "action_id", ""),
                    getattr(step, "status", "pending"),
                    getattr(step, "started_at", datetime.utcnow()).isoformat() if isinstance(getattr(step, "started_at", None), datetime) else str(getattr(step, "started_at", "")),
                    getattr(step, "completed_at", datetime.utcnow()).isoformat() if isinstance(getattr(step, "completed_at", None), datetime) else str(getattr(step, "completed_at", "")),
                    getattr(step, "retried", 0),
                    1 if getattr(step, "rolled_back", False) else 0,
                    getattr(step, "error", None)
                )
            )
        conn.commit()
        logger.info(f"Persisted {len(steps)} action execution steps to SQLite database")
    except Exception as e:
        logger.warning(f"Failed to persist action steps: {e}")
    finally:
        conn.close()


def save_approval(run_id: str, approval_id: str, action_id: str, decision: str, modification: str):
    """Save human-in-the-loop approval logs."""
    conn = get_connection()
    try:
        conn.execute(
            "INSERT INTO Approvals (run_id, approval_id, action_id, decision, modification, decided_at) VALUES (?, ?, ?, ?, ?, ?)",
            (run_id, approval_id, action_id, decision, modification, datetime.utcnow().isoformat())
        )
        conn.commit()
        logger.info(f"Persisted human approval decision to SQLite database")
    except Exception as e:
        logger.warning(f"Failed to persist approval: {e}")
    finally:
        conn.close()


def get_run(run_id: str) -> Optional[dict]:
    """Fetch a run by ID."""
    conn = get_connection()
    try:
        row = conn.execute("SELECT * FROM Runs WHERE run_id=?", (run_id,)).fetchone()
        return dict(row) if row else None
    except Exception as e:
        logger.warning(f"Failed to get_run: {e}")
        return None
    finally:
        conn.close()


def list_runs(limit: int = 20) -> list[dict]:
    """List recent runs."""
    conn = get_connection()
    try:
        rows = conn.execute(
            "SELECT run_id, scenario, started_at, status FROM Runs ORDER BY started_at DESC LIMIT ?",
            (limit,),
        ).fetchall()
        return [dict(row) for row in rows]
    except Exception as e:
        logger.warning(f"Failed to list_runs: {e}")
        return []
    finally:
        conn.close()
