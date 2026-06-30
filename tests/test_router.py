import os
import tempfile
import pytest
from db.connection import init_db
from events import publish, consume_pending, MESSAGE_RECEIVED
from bot.router import route_message
from db.queries import get_entries


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


def test_event_bus():
    ev_id = publish(MESSAGE_RECEIVED, {"text": "hello world"})
    assert ev_id > 0

    pending = consume_pending()
    assert len(pending) == 1
    assert pending[0]["type"] == MESSAGE_RECEIVED
    assert pending[0]["payload"]["text"] == "hello world"

    # Second consume should return empty since it was marked processed
    pending_after = consume_pending()
    assert len(pending_after) == 0


def test_route_message_logging():
    reply = route_message("Bought a coffee for $5", input_type="text")
    assert "Logged in" in reply or "Entry #" in reply

    entries = get_entries()
    assert len(entries) >= 1
    assert entries[0]["content"] == "Bought a coffee for $5"


def test_route_message_commands():
    reply = route_message("/status", input_type="text")
    assert "NeuroCore System Status" in reply
