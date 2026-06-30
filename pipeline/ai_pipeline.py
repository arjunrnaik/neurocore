import os
import json
from datetime import datetime
from typing import Dict, Any
from dotenv import load_dotenv
import google.generativeai as genai
from models.intent import Intent

load_dotenv()

SYSTEM_PROMPT = """
You are an intent extraction engine for NeuroCore personal AI operating system. Given a user message and current timestamp, return ONLY a valid JSON object matching this exact schema:
{
  "domain": "health|finance|task|note|reminder|general",
  "action": "store|query|remind|summarize",
  "entities": {
    "key": "value"
  },
  "sentiment": "positive|neutral|negative",
  "confidence": 0.0-1.0
}
Rules:
1. If action is "remind" or domain is "reminder", try to include "message" and "due_at" (in ISO 8601 YYYY-MM-DDTHH:MM:SS format based on current time) in "entities".
2. No preamble. No explanation. Return JSON only.
"""


def get_gemini_model():
    api_key = os.getenv("GEMINI_API_KEY")
    if not api_key or api_key.startswith("test_") or api_key == "your_gemini_api_key_here":
        return None
    genai.configure(api_key=api_key)
    model_name = os.getenv("GEMINI_MODEL", "gemini-2.5-flash")
    return genai.GenerativeModel(model_name)


def extract_intent(message: str, input_type: str = "text") -> Intent:
    model = get_gemini_model()
    
    # Fallback if API key is not configured or in unit testing
    if not model:
        return Intent(
            input_type=input_type,
            domain="note",
            action="store",
            confidence=0.8,
            raw_content=message,
            extracted_data={"entities": {"text": message}, "sentiment": "neutral"},
        )

    try:
        current_time = datetime.now().isoformat()
        prompt = f"{SYSTEM_PROMPT}\nCurrent Time: {current_time}\nUser Message: {message}"
        response = model.generate_content(prompt)
        text = response.text.strip()
        
        # Clean markdown code blocks if Gemini wrapped response in ```json ... ```
        if text.startswith("```json"):
            text = text[7:]
        if text.startswith("```"):
            text = text[3:]
        if text.endswith("```"):
            text = text[:-3]
        text = text.strip()

        data = json.loads(text)
        return Intent(
            input_type=input_type,
            domain=data.get("domain", "general"),
            action=data.get("action", "store"),
            confidence=float(data.get("confidence", 0.9)),
            raw_content=message,
            extracted_data=data,
        )
    except Exception as e:
        # Graceful degradation on API or parsing errors
        return Intent(
            input_type=input_type,
            domain="general",
            action="store",
            confidence=0.5,
            raw_content=message,
            extracted_data={"error": str(e), "entities": {"text": message}},
        )


def transcribe_voice(file_path: str) -> str:
    """Convert voice message audio file to text using Groq Whisper API."""
    api_key = os.getenv("GROQ_API_KEY")
    if not api_key or api_key.startswith("test_") or api_key == "your_groq_api_key_here":
        return "[Simulated voice transcription: reminder to check email]"

    try:
        from groq import Groq
        client = Groq(api_key=api_key)
        with open(file_path, "rb") as file:
            transcription = client.audio.transcriptions.create(
                file=(os.path.basename(file_path), file.read()),
                model="whisper-large-v3",
            )
        return transcription.text
    except Exception as e:
        return f"[Voice transcription failed: {e}]"


def analyze_image(image_path: str, caption: str = "") -> Intent:
    """Analyze image input using Gemini Multimodal vision capabilities."""
    model = get_gemini_model()
    if not model:
        return Intent(
            input_type="image",
            domain="note",
            action="store",
            confidence=0.8,
            raw_content=caption or "[Image logged]",
            extracted_data={"entities": {"image_path": image_path, "caption": caption}},
        )

    try:
        import PIL.Image
        img = PIL.Image.open(image_path)
        prompt = f"{SYSTEM_PROMPT}\nAnalyze this image. User caption: {caption}"
        response = model.generate_content([prompt, img])
        text = response.text.strip()
        if text.startswith("```json"):
            text = text[7:-3].strip()
        elif text.startswith("```"):
            text = text[3:-3].strip()
        data = json.loads(text)
        return Intent(
            input_type="image",
            domain=data.get("domain", "note"),
            action=data.get("action", "store"),
            confidence=float(data.get("confidence", 0.9)),
            raw_content=caption or "[Image logged]",
            extracted_data=data,
        )
    except Exception as e:
        return Intent(
            input_type="image",
            domain="note",
            action="store",
            confidence=0.5,
            raw_content=caption or "[Image logged]",
            extracted_data={"error": str(e), "entities": {"image_path": image_path}},
        )
