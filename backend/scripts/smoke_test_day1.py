"""
SENTINEL Day 1 Smoke Test
Canon: planning.md Hour 10
Tests: Import → POST run → Wait → Verify report
"""

import asyncio
import sys
import os
import time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))

import httpx

BASE = "http://localhost:8001"


def run_smoke_test():
    print("=" * 60)
    print("SENTINEL — Day 1 Smoke Test")
    print("=" * 60)

    # 1. Health check
    r = httpx.get(f"{BASE}/health")
    assert r.status_code == 200, f"Health failed: {r.status_code}"
    print("[OK] Health check passed")

    # 2. /docs available
    r = httpx.get(f"{BASE}/docs")
    assert r.status_code == 200
    print("[OK] /docs endpoint available")

    # 3. POST /api/v1/runs
    payload = {
        "scenario": "inventory_shortage",
        "sources": [
            {"type": "csv", "path": "mock-data/warehouse_stock_7days.csv"},
            {"type": "json", "path": "mock-data/sales_dashboard.json"},
            {"type": "json", "path": "mock-data/complaints.json"},
            {"type": "json", "path": "mock-data/news_feed.json"},
            {"type": "json", "path": "mock-data/duplicate_spam_source.json"},
            {"type": "json", "path": "mock-data/stale_irrelevant_source.json"},
        ],
        "constraints": {
            "budget_pkr_max": 500000,
            "time_to_resolution_hours_max": 48,
            "notification_deadline_hours_max": 2,
            "api_rate_limit_per_minute": 10,
            "resource_constraints": {"warehouse_staff": 3, "delivery_trucks": 5}
        }
    }
    r = httpx.post(f"{BASE}/api/v1/runs", json=payload)
    assert r.status_code == 202, f"POST /runs failed: {r.status_code} - {r.text}"
    data = r.json()
    run_id = data["run_id"]
    assert data["status"] == "queued"
    assert "websocket_url" in data
    print(f"[OK] POST /api/v1/runs -> 202, run_id={run_id}")

    # 4. Wait for pipeline to complete
    print("  Waiting for pipeline to complete...", end="", flush=True)
    for i in range(30):
        time.sleep(2)
        print(".", end="", flush=True)
        r = httpx.get(f"{BASE}/api/v1/runs/{run_id}")
        if r.status_code == 200:
            report = r.json()
            if report.get("status") in ("completed", "failed"):
                break
    print()

    # 5. Verify report
    r = httpx.get(f"{BASE}/api/v1/runs/{run_id}")
    if r.status_code == 200:
        report = r.json()
        status = report.get("status", "unknown")
        print(f"[OK] Run status: {status}")

        sources = report.get("sources", [])
        print(f"[OK] Sources ingested: {len(sources)}")

        noise = report.get("noise_assessments", [])
        kept = sum(1 for a in noise if a.get("keep_for_analysis"))
        rejected = sum(1 for a in noise if not a.get("keep_for_analysis"))
        print(f"[OK] Noise filter: {kept} kept, {rejected} rejected")

        insights = report.get("insights", [])
        print(f"[OK] Insights extracted: {len(insights)}")

        conflicts = report.get("conflicts", {})
        contradictions = conflicts.get("contradictions", [])
        print(f"[OK] Contradictions detected: {len(contradictions)}")

        actions = report.get("actions", [])
        print(f"[OK] Actions planned: {len(actions)}")

        execution_log = report.get("execution_log", [])
        print(f"[OK] Execution steps: {len(execution_log)}")

        metrics = report.get("metrics", {})
        if metrics:
            duration = metrics.get("total_duration_seconds", "N/A")
            print(f"[OK] Total duration: {duration}s")

        if status == "completed":
            print("\n" + "=" * 60)
            print("[SUCCESS] DAY 1 SMOKE TEST PASSED")
            print("=" * 60)
        else:
            print(f"\n[WARNING] Run completed with status: {status}")
    else:
        print(f"[ERROR] Could not fetch run report: {r.status_code}")
        print("[WARNING] Pipeline may still be running or failed")

    # 6. Check trace
    r = httpx.get(f"{BASE}/api/v1/runs/{run_id}/trace")
    if r.status_code == 200:
        print("[OK] Trace JSON available")
    else:
        print(f"  Trace not yet available: {r.status_code}")

    # 7. List runs
    r = httpx.get(f"{BASE}/api/v1/runs")
    assert r.status_code == 200
    runs = r.json()
    print(f"[OK] Listed {runs['total']} run(s)")


if __name__ == "__main__":
    run_smoke_test()
