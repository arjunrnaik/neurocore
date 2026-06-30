import re
from typing import Optional
from models.intent import Intent


def pre_filter(message: str) -> Optional[Intent]:
    msg = message.strip().lower()

    # Command intents
    if msg.startswith("/ask"):
        query = message[4:].strip()
        return Intent(
            input_type="text",
            domain="general",
            action="query",
            confidence=1.0,
            raw_content=message,
            extracted_data={"query": query},
        )
    if msg.startswith("/summary"):
        return Intent(
            input_type="text",
            domain="general",
            action="summarize",
            confidence=1.0,
            raw_content=message,
            extracted_data={},
        )
    if msg.startswith("/status"):
        return Intent(
            input_type="text",
            domain="general",
            action="status",
            confidence=1.0,
            raw_content=message,
            extracted_data={},
        )
    if msg.startswith("/help") or msg.startswith("/start"):
        cmd = "start" if msg.startswith("/start") else "help"
        return Intent(
            input_type="text",
            domain="general",
            action=cmd,
            confidence=1.0,
            raw_content=message,
            extracted_data={},
        )

    # Simple greetings
    if msg in ["hi", "hello", "hey", "ping"]:
        return Intent(
            input_type="text",
            domain="general",
            action="greet",
            confidence=1.0,
            raw_content=message,
            extracted_data={"reply": "Hello! I am NeuroCore, your personal AI operating system. How can I help you today?"},
        )

    # Reminder pattern (if explicitly starting with /remind or simple reminder syntax)
    if msg.startswith("/remind"):
        remind_text = message[7:].strip()
        return Intent(
            input_type="text",
            domain="reminder",
            action="remind",
            confidence=0.9,
            raw_content=message,
            extracted_data={"message": remind_text},
        )

    # Fall through to Gemini AI Pipeline for complex natural language parsing
    return None
