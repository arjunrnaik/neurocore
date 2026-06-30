import json
from datetime import datetime
from typing import List, Dict, Any
from db.connection import get_connection


def publish(event_type: str, payload: Dict[str, Any]) -> int:
    with get_connection() as conn:
        cursor = conn.execute(
            "INSERT INTO events (event_type, payload) VALUES (?, ?)",
            (event_type, json.dumps(payload)),
        )
        return cursor.lastrowid


def consume_pending() -> List[Dict[str, Any]]:
    with get_connection() as conn:
        rows = conn.execute(
            "SELECT id, event_type, payload FROM events WHERE status='pending'"
        ).fetchall()
        
        now_iso = datetime.now().isoformat()
        for row in rows:
            conn.execute(
                "UPDATE events SET status='processed', processed_at=? WHERE id=?",
                (now_iso, row["id"]),
            )
            
        return [
            {
                "id": r["id"],
                "type": r["event_type"],
                "payload": json.loads(r["payload"]) if r["payload"] else {},
            }
            for r in rows
        ]
