"""
SENTINEL Database — SQLite persistence
Canon: idea.md §9, architecture.md §9
"""

import json
import os
import sqlite3
from datetime import datetime
from typing import Optional

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
    finally:
        conn.close()


def update_run_status(run_id: str, status: str, completed_at: Optional[str] = None,
                      total_llm_calls: int = 0, total_duration: float = 0.0):
    """Update run status and metrics."""
    conn = get_connection()
    try:
        conn.execute(
            "UPDATE Runs SET status=?, completed_at=?, total_llm_calls=?, total_duration_seconds=? WHERE run_id=?",
            (status, completed_at or datetime.utcnow().isoformat(), total_llm_calls, total_duration, run_id),
        )
        conn.commit()
    finally:
        conn.close()


def get_run(run_id: str) -> Optional[dict]:
    """Fetch a run by ID."""
    conn = get_connection()
    try:
        row = conn.execute("SELECT * FROM Runs WHERE run_id=?", (run_id,)).fetchone()
        return dict(row) if row else None
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
    finally:
        conn.close()
