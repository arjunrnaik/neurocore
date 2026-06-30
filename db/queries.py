import json
from datetime import datetime, timedelta
from typing import List, Dict, Any, Optional
from db.connection import get_connection


# Entries CRUD
def insert_entry(domain: str, action: str, content: str, metadata: Dict[str, Any] = None) -> int:
    meta_str = json.dumps(metadata or {})
    with get_connection() as conn:
        cursor = conn.execute(
            "INSERT INTO entries (domain, action, content, metadata) VALUES (?, ?, ?, ?)",
            (domain, action, content, meta_str),
        )
        return cursor.lastrowid


def get_entries(domain: Optional[str] = None, limit: int = 50, unsynced_only: bool = False) -> List[Dict[str, Any]]:
    query = "SELECT id, domain, action, content, metadata, created_at, synced FROM entries WHERE 1=1"
    params = []
    if domain:
        query += " AND domain = ?"
        params.append(domain)
    if unsynced_only:
        query += " AND synced = 0"
    query += " ORDER BY id DESC LIMIT ?"
    params.append(limit)

    with get_connection() as conn:
        rows = conn.execute(query, params).fetchall()
        return [
            {
                "id": r["id"],
                "domain": r["domain"],
                "action": r["action"],
                "content": r["content"],
                "metadata": json.loads(r["metadata"]) if r["metadata"] else {},
                "created_at": r["created_at"],
                "synced": bool(r["synced"]),
            }
            for r in rows
        ]


def get_recent_entries(days: int = 7) -> List[Dict[str, Any]]:
    cutoff = (datetime.now() - timedelta(days=days)).isoformat()
    with get_connection() as conn:
        rows = conn.execute(
            "SELECT id, domain, action, content, metadata, created_at FROM entries WHERE created_at >= ? ORDER BY id DESC",
            (cutoff,),
        ).fetchall()
        return [
            {
                "id": r["id"],
                "domain": r["domain"],
                "action": r["action"],
                "content": r["content"],
                "metadata": json.loads(r["metadata"]) if r["metadata"] else {},
                "created_at": r["created_at"],
            }
            for r in rows
        ]


def mark_entries_synced(entry_ids: List[int]):
    if not entry_ids:
        return
    placeholders = ",".join("?" * len(entry_ids))
    with get_connection() as conn:
        conn.execute(f"UPDATE entries SET synced = 1 WHERE id IN ({placeholders})", entry_ids)


# Reminders CRUD
def insert_reminder(message: str, due_at: str) -> int:
    with get_connection() as conn:
        cursor = conn.execute(
            "INSERT INTO reminders (message, due_at) VALUES (?, ?)",
            (message, due_at),
        )
        return cursor.lastrowid


def get_due_reminders() -> List[Dict[str, Any]]:
    now_iso = datetime.now().isoformat()
    with get_connection() as conn:
        rows = conn.execute(
            "SELECT id, message, due_at, status, created_at FROM reminders WHERE status = 'pending' AND due_at <= ?",
            (now_iso,),
        ).fetchall()
        return [dict(r) for r in rows]


def get_next_reminder() -> Optional[Dict[str, Any]]:
    with get_connection() as conn:
        row = conn.execute(
            "SELECT id, message, due_at FROM reminders WHERE status = 'pending' ORDER BY due_at ASC LIMIT 1"
        ).fetchone()
        return dict(row) if row else None


def mark_reminder_status(reminder_id: int, status: str):
    with get_connection() as conn:
        conn.execute("UPDATE reminders SET status = ? WHERE id = ?", (status, reminder_id))


# Sync Log CRUD
def log_sync(rows_synced: int, status: str, error: str = "") -> int:
    with get_connection() as conn:
        cursor = conn.execute(
            "INSERT INTO sync_log (rows_synced, status, error) VALUES (?, ?, ?)",
            (rows_synced, status, error),
        )
        return cursor.lastrowid


def get_last_sync_log() -> Optional[Dict[str, Any]]:
    with get_connection() as conn:
        row = conn.execute("SELECT id, synced_at, rows_synced, status, error FROM sync_log ORDER BY id DESC LIMIT 1").fetchone()
        return dict(row) if row else None


# User Profile CRUD
def get_user_profile(key: str) -> Optional[str]:
    with get_connection() as conn:
        row = conn.execute("SELECT value FROM user_profile WHERE key = ?", (key,)).fetchone()
        return row["value"] if row else None


def get_full_user_profile() -> Dict[str, str]:
    with get_connection() as conn:
        rows = conn.execute("SELECT key, value FROM user_profile").fetchall()
        return {r["key"]: r["value"] for r in rows}


def update_user_profile(key: str, value: str):
    now_iso = datetime.now().isoformat()
    with get_connection() as conn:
        conn.execute(
            "INSERT INTO user_profile (key, value, updated_at) VALUES (?, ?, ?) ON CONFLICT(key) DO UPDATE SET value=excluded.value, updated_at=excluded.updated_at",
            (key, value, now_iso),
        )


# Metrics for /status
def get_status_metrics() -> Dict[str, Any]:
    with get_connection() as conn:
        pending_events = conn.execute("SELECT COUNT(*) as cnt FROM events WHERE status = 'pending'").fetchone()["cnt"]
        unsynced = conn.execute("SELECT COUNT(*) as cnt FROM entries WHERE synced = 0").fetchone()["cnt"]
        
    last_sync = get_last_sync_log()
    next_rem = get_next_reminder()
    
    return {
        "pending_events": pending_events,
        "unsynced_entries": unsynced,
        "last_synced_at": last_sync["synced_at"] if last_sync else "Never",
        "last_sync_status": last_sync["status"] if last_sync else "N/A",
        "last_sync_error": last_sync["error"] if last_sync else "",
        "next_reminder_due": next_rem["due_at"] if next_rem else "None scheduled",
        "next_reminder_message": next_rem["message"] if next_rem else "",
    }
