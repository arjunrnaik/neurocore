import os
import logging
import threading
from http.server import HTTPServer, BaseHTTPRequestHandler
from db.connection import init_db
from bot.telegram_bot import create_app
from scheduler.jobs import start_scheduler

logging.basicConfig(format="%(asctime)s - %(name)s - %(levelname)s - %(message)s", level=logging.INFO)
logger = logging.getLogger("neurocore")


class HealthHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.end_headers()
        self.wfile.write(b"NeuroCore Personal OS is running online 24/7!")
    
    def log_message(self, format, *args):
        pass  # Suppress health check access logging to keep console clean


def start_health_server():
    port = int(os.getenv("PORT", 8080))
    server = HTTPServer(("0.0.0.0", port), HealthHandler)
    logger.info(f"Starting HTTP health check server on port {port} for Google Cloud Run...")
    threading.Thread(target=server.serve_forever, daemon=True).start()


def main():
    print("Hello NeuroCore")
    start_health_server()
    logger.info("Initializing database migrations...")
    init_db()

    logger.info("Setting up Telegram bot application...")
    app = create_app()

    logger.info("Starting background scheduler...")
    scheduler = start_scheduler(app)

    try:
        if app:
            logger.info("Launching Telegram bot polling loop...")
            app.run_polling()
        else:
            logger.warning("Bot application not created due to missing token. Scheduler is running in background.")
            # Keep process alive if only scheduler is running
            import time
            while True:
                time.sleep(1)
    except (KeyboardInterrupt, SystemExit):
        logger.info("Shutting down NeuroCore...")
        scheduler.shutdown()


if __name__ == "__main__":
    main()
