"""
SENTINEL Constraint Validator
Deterministic validation of actions against constraints.
Canon: planning.md Hour 11 T2
"""

from typing import Optional
from models.action import Action, Constraints


def validate_action(action: Action, constraints: Constraints) -> tuple[Action, list[str]]:
    """
    Validate a single action against the constraint set.
    Returns (possibly modified action, list of violation descriptions).
    """
    violations = []

    # Budget check
    if action.estimated_cost_pkr > constraints.budget_pkr_max:
        violations.append(
            f"Cost PKR {action.estimated_cost_pkr:,} exceeds budget cap PKR {constraints.budget_pkr_max:,}"
        )

    # Time check
    if action.estimated_duration_minutes / 60 > constraints.time_to_resolution_hours_max:
        violations.append(
            f"Duration {action.estimated_duration_minutes}min exceeds time-to-resolution limit "
            f"of {constraints.time_to_resolution_hours_max}h"
        )

    # API rate limit check (applies to actions that call external APIs)
    if action.is_destructive and constraints.api_rate_limit_per_minute < 1:
        violations.append(
            f"API rate limit is 0 req/min — cannot execute destructive action '{action.name}'"
        )

    # Resource check
    for resource in action.affected_resources:
        if resource in constraints.resource_constraints:
            available = constraints.resource_constraints[resource]
            if available <= 0:
                violations.append(f"Resource '{resource}' is not available (count: {available})")

    if violations:
        action = attempt_modification(action, violations, constraints)

    return action, violations


def attempt_modification(action: Action, violations: list[str], constraints: Constraints) -> Action:
    """
    Attempt to modify an action to satisfy constraints.
    Returns modified action with modification_applied set.
    """
    modified = action.model_copy()
    modifications = []

    # Budget modification: split into smaller batch
    if any("budget" in v.lower() for v in violations):
        if modified.estimated_cost_pkr > constraints.budget_pkr_max:
            # Split into two batches at half cost each
            original_cost = modified.estimated_cost_pkr
            modified.estimated_cost_pkr = constraints.budget_pkr_max
            modifications.append(
                f"Split order from PKR {original_cost:,} into batch of PKR {constraints.budget_pkr_max:,} "
                f"(remaining PKR {original_cost - constraints.budget_pkr_max:,} deferred to next cycle)"
            )

    # Time modification: flag as parallelizable
    if any("time-to-resolution" in v.lower() or "duration" in v.lower() for v in violations):
        modifications.append(
            f"Marked for parallel execution to meet {constraints.time_to_resolution_hours_max}h deadline"
        )

    # Resource unavailable: cannot fix, reject
    if any("not available" in v.lower() for v in violations):
        modifications.append("Action requires unavailable resources — flagged for rejection")

    modified.constraint_violations = violations
    modified.modification_applied = "; ".join(modifications) if modifications else "No modification possible"
    return modified
