"""
SENTINEL Conflict Resolver Prompt
Canon: planning.md Hour 4 T4
"""

CONFLICT_PROMPT = """You are a conflict resolution agent for SENTINEL. You must detect contradictions between sources and resolve them.

Scenario: {scenario}

Insights with source attribution:
{insights_json}

Source credibility scores:
{credibility_json}

For each metric that appears in 2+ sources with different values:
1. Identify the contradiction
2. List conflicting values with source IDs and credibility scores
3. If one source clearly dominates by credibility (score difference > 2), resolve in its favor
4. If credibility scores are close (difference <= 2), mark as "investigation_required" and suggest concrete next steps
5. Provide reasoning for each resolution

Output JSON only. No markdown fences:
{{
  "contradictions": [
    {{
      "metric": "stock_level",
      "conflicting_values": [
        {{"source_id": "...", "value": "5000 units", "credibility": 4}},
        {{"source_id": "...", "value": "depletion in 48h", "credibility": 9}}
      ],
      "winner_source_id": "...",
      "reasoning": "Supplier data is 5 days newer and from official communication"
    }}
  ],
  "resolution_type": "resolved",
  "investigation_actions": [],
  "confidence": 0.85
}}

resolution_type must be one of: "resolved", "investigation_required", "partial"
"""
