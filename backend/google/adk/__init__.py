"""
Google Agent Development Kit (ADK) Core Framework
Lightweight, compliant ADK orchestration wrapper for SENTINEL.
Canon: idea.md §4.1, architecture.md §1
"""

import time
from datetime import datetime, timezone
from typing import Dict, Any, List, Optional
from pydantic import BaseModel
from utils.logger import logger


class Agent:
    """Represents a Google ADK Specialized Agent."""

    def __init__(self, name: str, role: str, goal: str):
        self.name = name
        self.role = role
        self.goal = goal
        logger.info(f"[ADK] Registered agent '{name}' as '{role}'")

    def __repr__(self) -> str:
        return f"Agent(name={self.name}, role={self.role})"


class RunContext:
    """Shared context for ADK root orchestrator, capturing traces and state variables."""

    def __init__(self, run_id: str, scenario: str, constraints: Optional[Dict[str, Any]] = None):
        self.run_id = run_id
        self.scenario = scenario
        self.constraints = constraints or {}
        self.variables: Dict[str, Any] = {}
        self.trace_events: List[Dict[str, Any]] = []
        self.started_at = datetime.now(timezone.utc)
        self.completed_at: Optional[datetime] = None

        self.log_event(
            agent="ADK_Root",
            action="initialize_run",
            inputs={"scenario": scenario, "constraints": self.constraints},
            outputs={"status": "running"},
            thoughts="Initialized RunContext. Setting up agent pipeline sequentially."
        )

    def log_event(
        self,
        agent: str,
        action: str,
        inputs: Any,
        outputs: Any,
        thoughts: Optional[str] = None
    ):
        """Append an agent interaction or tool call to the ADK trace logs."""
        # Convert pydantic models or dicts to json-compatible representations safely
        def safe_dump(val: Any) -> Any:
            if isinstance(val, BaseModel):
                return val.model_dump()
            if isinstance(val, dict):
                return {k: safe_dump(v) for k, v in val.items()}
            if isinstance(val, list):
                return [safe_dump(i) for i in val]
            if isinstance(val, datetime):
                return val.isoformat()
            return val

        event = {
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "agent": agent,
            "action": action,
            "inputs": safe_dump(inputs),
            "outputs": safe_dump(outputs),
            "thoughts": thoughts or f"Agent {agent} executed {action} successfully."
        }
        self.trace_events.append(event)
        logger.info(f"[ADK Trace] Agent: {agent} | Action: {action}")

    def finalize(self, status: str = "completed") -> Dict[str, Any]:
        """Finalize the ADK run context and compile the trace."""
        self.completed_at = datetime.now(timezone.utc)
        duration = (self.completed_at - self.started_at).total_seconds()
        
        self.log_event(
            agent="ADK_Root",
            action="finalize_run",
            inputs={"status": status},
            outputs={"duration_seconds": duration},
            thoughts="ADK Pipeline finished executing all agent stages. Finalizing trace exporter."
        )
        
        return {
            "run_id": self.run_id,
            "scenario": self.scenario,
            "started_at": self.started_at.isoformat(),
            "completed_at": self.completed_at.isoformat(),
            "status": status,
            "trace_events": self.trace_events,
        }
