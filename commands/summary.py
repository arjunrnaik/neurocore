from collections import Counter
from db.queries import get_recent_entries
from pipeline.ai_pipeline import get_gemini_model


def get_summary_text() -> str:
    entries = get_recent_entries(days=7)
    if not entries:
        return "📊 No entries recorded in the past 7 days to summarize."

    domain_counts = Counter(e["domain"] for e in entries)
    total_count = len(entries)

    model = get_gemini_model()
    if not model:
        # Fallback local summary breakdown
        breakdown = "\n".join(f"• **{dom.capitalize()}**: {cnt} entries" for dom, cnt in domain_counts.items())
        return f"📊 **Weekly Activity Summary (Local)**\nTotal Entries Logged: {total_count}\n\n**Domain Breakdown**:\n{breakdown}"

    context_lines = [f"[{e['created_at'][:10]}] ({e['domain']}) {e['content']}" for e in entries]
    context_str = "\n".join(context_lines)

    try:
        prompt = f"""You are NeuroCore AI analyzing the user's logged entries from the past 7 days.
        
Entries:
{context_str}

Provide a well-structured, motivating weekly review formatted in Markdown. Include:
1. 🌟 **Key Themes & Highlights**
2. 🔥 **Activity Breakdown** (mention active domains)
3. 💡 **Personalized Insights/Recommendations** based on their notes and tasks."""
        response = model.generate_content(prompt)
        return f"📊 **NeuroCore Weekly Review**\n\n{response.text.strip()}"
    except Exception as e:
        return f"❌ Error generating summary via Gemini: {e}"
