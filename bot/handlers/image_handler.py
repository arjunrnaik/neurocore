import os
import tempfile
from telegram import Update
from telegram.ext import ContextTypes
from pipeline.ai_pipeline import analyze_image
from bot.router import route_message


async def handle_image(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if not update.message or not update.message.photo:
        return

    await update.message.reply_chat_action(action="typing")
    
    # Get highest resolution photo
    photo = update.message.photo[-1]
    photo_file = await photo.get_file()
    caption = update.message.caption or ""
    
    with tempfile.NamedTemporaryFile(suffix=".jpg", delete=False) as tf:
        temp_path = tf.name

    try:
        await photo_file.download_to_drive(temp_path)
        intent = analyze_image(temp_path, caption)
    finally:
        if os.path.exists(temp_path):
            os.remove(temp_path)

    # Pass pre-extracted multimodal data to router
    reply = route_message(
        message=caption or "[Image Note]",
        input_type="image",
        extra_data=intent.extracted_data
    )
    await update.message.reply_text(f"🖼️ *Image processed*\n\n{reply}", parse_mode="Markdown")
