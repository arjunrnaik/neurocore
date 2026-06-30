import logging
import asyncio
from apscheduler.schedulers.background import BackgroundScheduler
from db.queries import get_due_reminders, mark_reminder_status, get_user_profile
from commands.summary import get_summary_text
from sync.sheets_sync import sync_to_sheets
from events import publish, REMINDER_SET

logger = logging.getLogger(__name__)


def check_reminders(bot_app=None):
    """Poll for due reminders and send notifications via Telegram."""
    try:
        due = get_due_reminders()
        if not due:
            return

        chat_id = get_user_profile("chat_id")
        for rem in due:
            rem_id = rem["id"]
            msg = rem["message"]
            mark_reminder_status(rem_id, "sent")
            logger.info(f"Reminder due (#{rem_id}): {msg}")

            if bot_app and chat_id:
                try:
                    asyncio.run_coroutine_threadsafe(
                        bot_app.bot.send_message(
                            chat_id=int(chat_id),
                            text=f"⏰ **REMINDER**\n\n{msg}",
                            parse_mode="Markdown"
                        ),
                        bot_app.loop
                    )
                except Exception as e:
                    logger.error(f"Failed to send Telegram reminder: {e}")
    except Exception as e:
        logger.error(f"Error checking reminders: {e}")


def run_weekly_summary(bot_app=None):
    """Generate weekly summary and send to user."""
    try:
        logger.info("Running weekly summary job...")
        summary = get_summary_text()
        chat_id = get_user_profile("chat_id")
        if bot_app and chat_id:
            try:
                asyncio.run_coroutine_threadsafe(
                    bot_app.bot.send_message(
                        chat_id=int(chat_id),
                        text=summary,
                        parse_mode="Markdown"
                    ),
                    bot_app.loop
                )
            except Exception as e:
                logger.error(f"Failed to send weekly summary: {e}")
    except Exception as e:
        logger.error(f"Error running weekly summary: {e}")


def start_scheduler(bot_app=None) -> BackgroundScheduler:
    scheduler = BackgroundScheduler()
    
    # Check reminders every 30 seconds
    scheduler.add_job(check_reminders, "interval", seconds=30, args=[bot_app], id="check_reminders")
    
    # Run sync to Google Sheets every 15 minutes
    scheduler.add_job(sync_to_sheets, "interval", minutes=15, id="sync_sheets")
    
    # Weekly summary every Sunday at 9:00 AM
    scheduler.add_job(run_weekly_summary, "cron", day_of_week="sun", hour=9, minute=0, args=[bot_app], id="weekly_summary")
    
    scheduler.start()
    logger.info("APScheduler background scheduler started.")
    return scheduler
