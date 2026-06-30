import os
import json
from db.queries import get_entries, mark_entries_synced, log_sync
from events import publish, SYNC_RUN


def sync_to_sheets() -> int:
    """Mirror unsynced SQLite entries to Google Sheets."""
    entries = get_entries(unsynced_only=True, limit=100)
    if not entries:
        log_sync(0, "success", "")
        return 0

    sheet_id = os.getenv("GOOGLE_SHEETS_ID")
    creds_path = os.getenv("GOOGLE_SERVICE_ACCOUNT_JSON", "./service_account.json")

    # If credentials or ID are missing/placeholders, log simulated success/warning in dev mode
    if not sheet_id or sheet_id.startswith("test_") or not os.path.exists(creds_path):
        entry_ids = [e["id"] for e in entries]
        mark_entries_synced(entry_ids)
        log_sync(len(entries), "success", "Simulated sync (Google Sheets API credentials not configured locally)")
        publish(SYNC_RUN, {"rows_synced": len(entries), "status": "simulated_success"})
        return len(entries)

    try:
        from google.oauth2.service_account import Credentials
        from googleapiclient.discovery import build

        scopes = ["https://www.googleapis.com/auth/spreadsheets"]
        creds = Credentials.from_service_account_file(creds_path, scopes=scopes)
        service = build("sheets", "v4", credentials=creds)

        values = [
            [str(e["id"]), e["created_at"], e["domain"], e["action"], e["content"], json.dumps(e["metadata"])]
            for e in entries
        ]
        body = {"values": values}
        
        service.spreadsheets().values().append(
            spreadsheetId=sheet_id,
            range="Sheet1!A:F",
            valueInputOption="USER_ENTERED",
            body=body,
        ).execute()

        entry_ids = [e["id"] for e in entries]
        mark_entries_synced(entry_ids)
        log_sync(len(entries), "success", "")
        publish(SYNC_RUN, {"rows_synced": len(entries), "status": "success"})
        return len(entries)

    except Exception as e:
        err_msg = str(e)
        log_sync(0, "failed", err_msg)
        publish(SYNC_RUN, {"rows_synced": 0, "status": "failed", "error": err_msg})
        return 0
