# NeuroCore

**AI-Powered Personal Operating System**

NeuroCore is an AI-powered personal operating system that learns from your daily interactions, remembers everything you tell it, and proactively helps you stay organized and productive. It accepts text, voice, and image input through Telegram and transforms natural language into structured, queryable knowledge — all stored locally in SQLite and mirrored to Google Sheets.

## Core Features

- **Stateful Memory**: Stores all interactions categorized by domain and action in SQLite.
- **Multimodal Inputs**: Accepts text, voice notes (transcribed via Groq Whisper), and images via Telegram.
- **Intelligent Processing**: Uses Google Gemini AI for intent classification, entity extraction, sentiment analysis, and answering semantic questions.
- **Google Sheets Mirror**: Automatically mirrors your logged entries to a Google Sheets dashboard.
- **Proactive Scheduling**: APScheduler powers periodic reminder checks and weekly AI-generated summaries.

## Quick Start

1. **Install Dependencies**:
   ```bash
   pip install -r requirements.txt
   ```

2. **Configure Environment**:
   Copy `.env.example` to `.env` and fill in your API keys:
   - `TELEGRAM_BOT_TOKEN` (from @BotFather)
   - `GEMINI_API_KEY` (from Google AI Studio)
   - `GROQ_API_KEY` (from Groq Console)
   - `GOOGLE_SHEETS_ID` & `GOOGLE_SERVICE_ACCOUNT_JSON`

3. **Run NeuroCore**:
   ```bash
   python main.py
   ```

## Available Commands

- `/start` - Initialize bot and set up user profile
- `/ask [question]` - Query your stored knowledge via Gemini RAG
- `/summary` - Get an AI-generated summary of recent entries
- `/status` - Show sync status, pending events, and next due reminder
- `/help` - List all available commands
