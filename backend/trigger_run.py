import urllib.request
import json
import time

url = "http://127.0.0.1:8001/api/v1/runs"
payload = {
    "scenario": "inventory_shortage",
    "sources": [
        {
            "type": "csv",
            "path": "mock-data/warehouse_stock_7days.csv"
        }
    ],
    "constraints": {
        "budget_limit_pkr": 500000,
        "notification_deadline_hours": 2,
        "supplier_lead_time_hours": 48
    }
}

headers = {"Content-Type": "application/json"}
req = urllib.request.Request(url, data=json.dumps(payload).encode(), headers=headers, method="POST")

try:
    with urllib.request.urlopen(req) as response:
        res_data = json.loads(response.read().decode())
        run_id = res_data["run_id"]
        print("RUN STARTED:", run_id)
        
        # Poll for completion
        for _ in range(30):
            time.sleep(2)
            status_req = urllib.request.Request(f"http://127.0.0.1:8001/api/v1/runs/{run_id}")
            try:
                with urllib.request.urlopen(status_req) as status_res:
                    status_data = json.loads(status_res.read().decode())
                    print("STATUS:", status_data["status"])
                    if status_data["status"] == "completed":
                        print("METRICS:", status_data["metrics"])
                        break
            except Exception as pe:
                print("Polling exception:", pe)
except Exception as e:
    print("ERROR starting run:", e)
