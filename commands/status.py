from db.queries import get_status_metrics


def get_status_text() -> str:
    metrics = get_status_metrics()
    
    error_line = f"\n⚠️ **Last Sync Error**: `{metrics['last_sync_error']}`" if metrics["last_sync_error"] else ""
    rem_line = metrics['next_reminder_due']
    if metrics['next_reminder_message']:
        rem_line += f" ('{metrics['next_reminder_message']}')"

    return f"""⚙️ **NeuroCore System Status**

🔄 **Google Sheets Sync**:
• Status: `{metrics['last_sync_status']}`
• Last Synced: `{metrics['last_synced_at']}`
• Unsynced Entries Pending: `{metrics['unsynced_entries']}`{error_line}

📨 **Event Bus Queue**:
• Pending Events: `{metrics['pending_events']}`

⏰ **Reminders**:
• Next Due: `{rem_line}`
"""
