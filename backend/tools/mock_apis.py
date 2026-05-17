"""
SENTINEL Mock Tool APIs (Module 10)
Simulate external systems for action chain execution.
Canon: idea.md Module 10, planning.md Hour 15

Each tool simulates realistic latency and returns mock responses.
The supplier tool occasionally returns 503 for demo failure scenario.
"""

import asyncio
import random
import time
from datetime import datetime, timezone
from uuid import uuid4


async def mock_validate_stock(sku: str = "SKU001") -> dict:
    """Simulate stock validation against warehouse system."""
    await asyncio.sleep(random.uniform(0.3, 0.6))
    return {
        "tool": "stock_validation",
        "status": "success",
        "sku": sku,
        "current_quantity": 3200,
        "validated_at": datetime.now(timezone.utc).isoformat(),
        "warehouse_id": "WH-KHI-01",
    }


async def mock_notify_procurement(message: str = "Emergency stock alert") -> dict:
    """Simulate sending notification to procurement team."""
    await asyncio.sleep(random.uniform(0.2, 0.5))
    return {
        "tool": "notification",
        "status": "success",
        "message_id": f"msg_{uuid4().hex[:8]}",
        "channel": "email+sms",
        "recipients": ["procurement@company.pk", "+923001234567"],
        "sent_at": datetime.now(timezone.utc).isoformat(),
    }


async def mock_emergency_order(
    sku: str = "SKU001",
    quantity: int = 8000,
    should_fail: bool = False,
) -> dict:
    """
    Simulate placing emergency order with supplier.
    Deliberately fails on first call (should_fail=True) for demo recovery.
    """
    await asyncio.sleep(random.uniform(0.5, 0.8))

    if should_fail:
        return {
            "tool": "supplier_order",
            "status": "error",
            "error_code": 503,
            "error_message": "Supplier API temporarily unavailable — service overloaded",
            "timestamp": datetime.now(timezone.utc).isoformat(),
        }

    return {
        "tool": "supplier_order",
        "status": "success",
        "order_id": f"ORD-{uuid4().hex[:6].upper()}",
        "sku": sku,
        "quantity": quantity,
        "estimated_delivery_hours": 24,
        "total_cost_pkr": quantity * 62,  # ~62 PKR per unit
        "confirmed_at": datetime.now(timezone.utc).isoformat(),
    }


async def mock_update_crm(update_type: str = "delivery_schedule") -> dict:
    """Simulate updating CRM/delivery schedule."""
    await asyncio.sleep(random.uniform(0.3, 0.5))
    return {
        "tool": "crm_update",
        "status": "success",
        "update_id": f"upd_{uuid4().hex[:8]}",
        "type": update_type,
        "updated_at": datetime.now(timezone.utc).isoformat(),
    }


async def mock_schedule_monitoring(sku: str = "SKU001", interval_hours: int = 6) -> dict:
    """Simulate setting up automated monitoring schedule."""
    await asyncio.sleep(random.uniform(0.2, 0.4))
    return {
        "tool": "monitoring",
        "status": "success",
        "monitor_id": f"mon_{uuid4().hex[:8]}",
        "sku": sku,
        "check_interval_hours": interval_hours,
        "next_check_at": datetime.now(timezone.utc).isoformat(),
        "alerts_configured": True,
    }
