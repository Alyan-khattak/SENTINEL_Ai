# SENTINEL — Assumptions

## Data Assumptions
1. **Mock data is realistic**: The 7 mock sources use values (stock levels, demand rates, complaint counts) calibrated to represent a real inventory crisis scenario for a mid-size Pakistani FMCG distributor.
2. **Timestamps**: All mock data timestamps are relative to run time. The stale source is intentionally set 189 days in the past to trigger the noise filter.
3. **PDF content**: `supplier_email.pdf` contains structured text that `pdfplumber` can extract cleanly. Scanned PDFs (image-only) are not supported.
4. **CSV format**: The warehouse CSV has headers in row 1 and 7 rows of daily data. Other CSV schemas will parse but may produce fewer insights.

## System Assumptions
5. **Single-run demo**: SENTINEL is designed for one concurrent run per backend instance. Multiple simultaneous runs share the in-memory WebSocket queue.
6. **Backend is trusted**: No authentication on API endpoints. All callers are treated as authorized operators.
7. **LLM JSON output**: Gemini and Groq are expected to output valid JSON when prompted. The `extract_json` utility handles markdown fences and leading text; it retries once on malformed output.
8. **Approval timeout**: If the user does not respond to the approval gate within 60 seconds, the action is auto-approved. This is intentional for demo flow.

## Scenario Assumptions
9. **Inventory Shortage**: The demo scenario assumes SKU001 is a high-velocity item (cooking oil) with a 48-hour depletion window. Budget cap of PKR 500,000 is intentionally set below the unconstrained order cost to trigger the constraint modification demo.
10. **Supplier lead time**: Assumed to be 24 hours for demo purposes. The side-effect analyzer uses this value when projecting cashflow impact.

## Infrastructure Assumptions
11. **Free tier**: All LLM providers, hosting platforms, and databases are used within their free tiers. No billing card is required for the hackathon demo.
12. **SQLite persistence**: Only the `Runs` table is fully populated in the current implementation. The other 7 tables (Sources, NoiseAssessments, Insights, etc.) are reserved for future persistence — the current system uses in-memory state during a run and saves the full trace to JSON.
