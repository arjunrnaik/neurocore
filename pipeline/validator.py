from typing import Tuple
from models.intent import Intent

VALID_DOMAINS = {"health", "finance", "task", "note", "reminder", "general"}
VALID_ACTIONS = {"store", "query", "remind", "summarize", "status", "help", "start", "greet"}


def validate_intent(intent: Intent) -> Tuple[bool, str]:
    """Validate Intent extracted data against schema rules."""
    if not isinstance(intent, Intent):
        return False, "Input must be an Intent instance."

    if intent.confidence < 0.0 or intent.confidence > 1.0:
        # Clamp confidence to valid range rather than completely rejecting
        intent.confidence = max(0.0, min(1.0, intent.confidence))

    # Normalize domain and action
    domain_clean = intent.domain.lower().strip()
    action_clean = intent.action.lower().strip()

    if domain_clean not in VALID_DOMAINS:
        # Fallback unknown domain to general or note
        intent.domain = "general"
    else:
        intent.domain = domain_clean

    if action_clean not in VALID_ACTIONS:
        intent.action = "store"
    else:
        intent.action = action_clean

    if not isinstance(intent.extracted_data, dict):
        intent.extracted_data = {"raw": str(intent.extracted_data)}

    return True, "Valid"
