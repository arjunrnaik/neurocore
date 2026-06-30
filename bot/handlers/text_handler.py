from telegram import Update
from telegram.ext import ContextTypes
from bot.router import route_message


async def handle_text(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if not update.message or not update.message.text:
        return

    text = update.message.text
    reply = route_message(text, input_type="text")
    await update.message.reply_text(reply, parse_mode="Markdown")
