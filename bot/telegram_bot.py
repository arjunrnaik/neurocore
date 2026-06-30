import os
import logging
from telegram import Update
from telegram.ext import ApplicationBuilder, CommandHandler, MessageHandler, filters, ContextTypes
from bot.handlers import handle_text, handle_voice, handle_image
from commands.ask import get_help_text, answer_query
from commands.summary import get_summary_text
from commands.status import get_status_text

logger = logging.getLogger(__name__)


async def cmd_start_help(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if update.effective_chat:
        from db.queries import update_user_profile
        update_user_profile("chat_id", str(update.effective_chat.id))
    await update.message.reply_text(get_help_text(), parse_mode="Markdown")


async def cmd_ask(update: Update, context: ContextTypes.DEFAULT_TYPE):
    query = " ".join(context.args) if context.args else ""
    if not query:
        await update.message.reply_text("❓ Please provide a question. Example: `/ask What tasks are pending?`", parse_mode="Markdown")
        return
    await update.message.reply_chat_action(action="typing")
    reply = answer_query(query)
    await update.message.reply_text(reply, parse_mode="Markdown")


async def cmd_summary(update: Update, context: ContextTypes.DEFAULT_TYPE):
    await update.message.reply_chat_action(action="typing")
    reply = get_summary_text()
    await update.message.reply_text(reply, parse_mode="Markdown")


async def cmd_status(update: Update, context: ContextTypes.DEFAULT_TYPE):
    reply = get_status_text()
    await update.message.reply_text(reply, parse_mode="Markdown")


def create_app():
    token = os.getenv("TELEGRAM_BOT_TOKEN")
    if not token or token.startswith("test_") or token == "your_telegram_bot_token_here":
        logger.warning("TELEGRAM_BOT_TOKEN not configured or is placeholder. Bot cannot start polling.")
        return None

    app = ApplicationBuilder().token(token).build()

    # Commands
    app.add_handler(CommandHandler(["start", "help"], cmd_start_help))
    app.add_handler(CommandHandler("ask", cmd_ask))
    app.add_handler(CommandHandler("summary", cmd_summary))
    app.add_handler(CommandHandler("status", cmd_status))

    # Message handlers
    app.add_handler(MessageHandler(filters.TEXT & ~filters.COMMAND, handle_text))
    app.add_handler(MessageHandler(filters.VOICE, handle_voice))
    app.add_handler(MessageHandler(filters.PHOTO, handle_image))

    return app


def run_bot():
    logging.basicConfig(format="%(asctime)s - %(name)s - %(levelname)s - %(message)s", level=logging.INFO)
    app = create_app()
    if app:
        logger.info("Starting NeuroCore Telegram Bot polling...")
        app.run_polling()
    else:
        print("Error: Please set a valid TELEGRAM_BOT_TOKEN in .env to run live Telegram polling.")
