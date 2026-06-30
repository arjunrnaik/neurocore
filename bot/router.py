from datetime import datetime, timedelta
from typing import Dict, Any, Optional
from models.intent import Intent
from events import publish, MESSAGE_RECEIVED, ENTRY_STORED, REMINDER_SET
from pipeline import pre_filter, extract_intent, validate_intent
from db.queries import insert_entry, insert_reminder


def route_message(message: str, input_type: str = "text", extra_data: Optional[Dict[str, Any]] = None) -> str:
    """Route incoming message through pre-filter, AI extraction, validation, event bus, and database."""
    extra_data = extra_data or {}
    
    # 1. Publish raw message received event
    publish(MESSAGE_RECEIVED, {
        "content": message,
        "input_type": input_type,
        "timestamp": datetime.now().isoformat(),
        "extra_data": extra_data,
    })

    # 2. Pre-filter fast path
    intent = pre_filter(message) if input_type == "text" else None

    # 3. AI extraction if pre-filter didn't match
    if not intent:
        intent = extract_intent(message, input_type=input_type)
        if extra_data:
            intent.extracted_data.update(extra_data)

    # 4. Validate schema
    validate_intent(intent)

    # 5. Handle based on action / domain
    if intent.action == "greet":
        return intent.extracted_data.get("reply", "Hello! I am NeuroCore.")

    if intent.action in ("help", "start"):
        from commands.ask import get_help_text
        return get_help_text()

    if intent.action == "status":
        from commands.status import get_status_text
        return get_status_text()

    if intent.action == "summarize":
        from commands.summary import get_summary_text
        return get_summary_text()

    if intent.action == "query":
        from commands.ask import answer_query
        query_text = intent.extracted_data.get("query", message)
        return answer_query(query_text)

    if intent.action == "remind" or intent.domain == "reminder":
        entities = intent.extracted_data.get("entities", {})
        if not isinstance(entities, dict):
            entities = {}
            
        remind_msg = entities.get("message") or intent.extracted_data.get("message") or message
        due_at = entities.get("due_at")
        
        # Default reminder to 1 hour in the future if time wasn't cleanly extracted
        if not due_at:
            due_at = (datetime.now() + timedelta(hours=1)).isoformat()
            
        rem_id = insert_reminder(remind_msg, due_at)
        insert_entry("reminder", "remind", remind_msg, {"reminder_id": rem_id, "due_at": due_at})
        
        publish(REMINDER_SET, {"reminder_id": rem_id, "message": remind_msg, "due_at": due_at})
        return f"⏰ Reminder set (ID #{rem_id}) for {due_at[:16].replace('T', ' ')}:\n'{remind_msg}'"

    # Default action: store entry
    entry_id = insert_entry(intent.domain, intent.action, intent.raw_content, intent.extracted_data)
    publish(ENTRY_STORED, {"entry_id": entry_id, "domain": intent.domain, "action": intent.action})
    
    return f"📝 Logged in [{intent.domain.upper()}] (Entry #{entry_id})"
