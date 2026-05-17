"""
SENTINEL Action Planner Prompt
Canon: planning.md Hour 4 T5
"""

ACTION_PROMPT = """You are an action planning agent for SENTINEL. Generate a 3-5 step interconnected action chain.

Scenario: {scenario}

Resolved insights:
{insights_json}

Conflict resolution:
{conflicts_json}

User constraints:
{constraints_json}

Generate 3-5 dependent actions. Each action must include:
- action_id: unique identifier (e.g., "act_001")
- name: short descriptive name
- description: what this action does
- depends_on: list of action_ids this depends on (empty for first action)
- estimated_cost_pkr: integer cost estimate in PKR
- estimated_duration_minutes: integer time estimate
- affected_resources: list of resources affected
- urgency_tier: one of "low", "medium", "high", "critical"
- is_destructive: true if action modifies external systems (e.g., placing orders)

For the inventory_shortage scenario, typical actions include:
1. Validate current stock levels
2. Notify procurement team
3. Place emergency supplier order
4. Update delivery schedules
5. Set up monitoring

Output JSON only. No markdown fences. Return an array:
[
  {{
    "action_id": "act_001",
    "name": "validate_stock_levels",
    "description": "...",
    "depends_on": [],
    "estimated_cost_pkr": 0,
    "estimated_duration_minutes": 5,
    "affected_resources": ["warehouse_staff"],
    "urgency_tier": "critical",
    "is_destructive": false
  }}
]
"""
