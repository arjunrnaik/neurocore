from dataclasses import dataclass, field
from typing import Dict, Any


@dataclass
class Intent:
    input_type: str  # "text" | "voice" | "image"
    domain: str  # "health" | "finance" | "task" | "note" | "reminder" | "general" | ...
    action: str  # "store" | "query" | "remind" | "summarize"
    confidence: float  # 0.0 - 1.0
    raw_content: str  # original user message
    extracted_data: Dict[str, Any] = field(default_factory=dict)  # structured payload from Gemini

    def to_dict(self) -> Dict[str, Any]:
        return {
            "input_type": self.input_type,
            "domain": self.domain,
            "action": self.action,
            "confidence": self.confidence,
            "raw_content": self.raw_content,
            "extracted_data": self.extracted_data,
        }

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> "Intent":
        return cls(
            input_type=data.get("input_type", "text"),
            domain=data.get("domain", "general"),
            action=data.get("action", "store"),
            confidence=float(data.get("confidence", 0.0)),
            raw_content=data.get("raw_content", ""),
            extracted_data=data.get("extracted_data", {}),
        )
