from db.queries import get_entries
from pipeline.ai_pipeline import get_gemini_model


def get_help_text() -> str:
    return """🤖 **NeuroCore Personal OS**

Here are the available commands:
• `/start` - Initialize bot and user profile
• `/ask [question]` - Query your stored knowledge using Gemini AI
• `/summary` - Get an AI-generated summary of recent entries
• `/status` - Show sync status, pending events, and next due reminder
• `/help` - Show this reference card

You can also send natural language messages, voice notes, or photos!
Example: *"Remind me to submit the project report Friday at 2pm"*
"""


def answer_query(question: str) -> str:
    if not question or question.strip() == "/ask":
        return "❓ Please provide a question after `/ask`. Example: `/ask What did I log about health this week?`"

    entries = get_entries(limit=50)
    if not entries:
        return "📂 Your knowledge base is currently empty. Start logging notes or tasks first!"

    context_lines = []
    for e in entries:
        context_lines.append(f"[{e['created_at'][:10]}] ({e['domain']}) {e['content']}")
    context_str = "\n".join(context_lines)

    model = get_gemini_model()
    if not model:
        # Fallback local search if Gemini is not configured
        matching = [e['content'] for e in entries if any(w.lower() in e['content'].lower() for w in question.split() if len(w) > 3)]
        if matching:
            return f"🔍 **Local Knowledge Search Results**:\n• " + "\n• ".join(matching[:5])
        return "🔍 No matching entries found in local search (Gemini AI API key not configured for semantic analysis)."

    try:
        prompt = f"""You are NeuroCore AI assistant answering a user query based ONLY on their logged personal entries.
        
User Stored Entries:
{context_str}

User Question: {question}

Provide a concise, helpful, human-readable answer based on the stored entries above. If the information isn't in the logs, state that clearly."""
        response = model.generate_content(prompt)
        return f"💡 **NeuroCore Answer**:\n\n{response.text.strip()}"
    except Exception as e:
        return f"❌ Error synthesizing answer via Gemini: {e}"
