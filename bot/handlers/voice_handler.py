import os
import tempfile
from telegram import Update
from telegram.ext import ContextTypes
from pipeline.ai_pipeline import transcribe_voice
from bot.router import route_message


async def handle_voice(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if not update.message or not update.message.voice:
        return

    await update.message.reply_chat_action(action="typing")
    
    # Download voice note to a temporary file
    voice_file = await update.message.voice.get_file()
    with tempfile.NamedTemporaryFile(suffix=".ogg", delete=False) as tf:
        temp_path = tf.name
        
    try:
        await voice_file.download_to_drive(temp_path)
        transcription = transcribe_voice(temp_path)
    finally:
        if os.path.exists(temp_path):
            os.remove(temp_path)

    reply = route_message(transcription, input_type="voice")
    await update.message.reply_text(f"🎤 *Transcribed*: \"{transcription}\"\n\n{reply}", parse_mode="Markdown")
