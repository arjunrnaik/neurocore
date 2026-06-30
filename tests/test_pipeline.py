from models.intent import Intent
from pipeline.pre_filter import pre_filter
from pipeline.validator import validate_intent


def test_intent_serialization():
    intent = Intent(
        input_type="text",
        domain="task",
        action="store",
        confidence=0.95,
        raw_content="Buy groceries",
        extracted_data={"item": "groceries"}
    )
    data = intent.to_dict()
    restored = Intent.from_dict(data)
    assert restored.domain == "task"
    assert restored.confidence == 0.95


def test_pre_filter_commands():
    ask_intent = pre_filter("/ask what did I log yesterday?")
    assert ask_intent is not None
    assert ask_intent.action == "query"
    assert ask_intent.extracted_data["query"] == "what did I log yesterday?"

    sum_intent = pre_filter("/summary")
    assert sum_intent is not None
    assert sum_intent.action == "summarize"


def test_pre_filter_greetings():
    greet_intent = pre_filter("hello")
    assert greet_intent is not None
    assert greet_intent.action == "greet"


def test_validator():
    intent = Intent(
        input_type="text",
        domain="UNKNOWN_DOMAIN",
        action="INVALID_ACTION",
        confidence=1.5,
        raw_content="Test message"
    )
    is_valid, msg = validate_intent(intent)
    assert is_valid is True
    assert intent.domain == "general"  # Clamped/fallback
    assert intent.action == "store"
    assert intent.confidence == 1.0  # Clamped to max 1.0
