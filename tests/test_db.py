import os
import tempfile
import pytest
from db.connection import init_db, get_connection
from db.queries import (
    insert_entry, get_entries, mark_entries_synced,
    insert_reminder, get_due_reminders, mark_reminder_status,
    update_user_profile, get_user_profile
)


@pytest.fixture(autouse=True)
def setup_test_db():
    with tempfile.NamedTemporaryFile(suffix=".db", delete=False) as tf:
        db_path = tf.name
    os.environ["DB_PATH"] = db_path
    init_db()
    yield
    if os.path.exists(db_path):
        try:
            os.remove(db_path)
        except Exception:
            pass


def test_init_db():
    with get_connection() as conn:
        tables = conn.execute("SELECT name FROM sqlite_master WHERE type='table'").fetchall()
        table_names = {t["name"] for t in tables}
        assert {"events", "entries", "reminders", "sync_log", "user_profile"}.issubset(table_names)
        
        # Verify seeding
        tz = get_user_profile("timezone")
        assert tz == "UTC"


def test_entries_crud():
    entry_id = insert_entry("health", "store", "Drank 2L of water", {"tags": ["hydration"]})
    assert entry_id > 0

    entries = get_entries(domain="health")
    assert len(entries) == 1
    assert entries[0]["content"] == "Drank 2L of water"
    assert entries[0]["synced"] is False

    mark_entries_synced([entry_id])
    unsynced = get_entries(unsynced_only=True)
    assert len(unsynced) == 0


def test_reminders_crud():
    due_at = "2020-01-01T12:00:00"  # Past date so it is due immediately
    rem_id = insert_reminder("Call mom", due_at)
    assert rem_id > 0

    due = get_due_reminders()
    assert len(due) == 1
    assert due[0]["message"] == "Call mom"

    mark_reminder_status(rem_id, "sent")
    due_after = get_due_reminders()
    assert len(due_after) == 0
