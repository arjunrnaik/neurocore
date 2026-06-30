import os
import sqlite3
from contextlib import contextmanager
from pathlib import Path
from dotenv import load_dotenv

load_dotenv()


def get_db_path() -> str:
    return os.getenv("DB_PATH", "./neurocore.db")


@contextmanager
def get_connection():
    db_path = get_db_path()
    # Ensure parent directory exists if path contains directories
    Path(db_path).parent.mkdir(parents=True, exist_ok=True)
    
    conn = sqlite3.connect(db_path)
    conn.row_factory = sqlite3.Row
    try:
        yield conn
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()


def init_db():
    """Run migration script and seed default user profile if needed."""
    migration_path = Path(__file__).parent / "migrations" / "001_initial.sql"
    if not migration_path.exists():
        raise FileNotFoundError(f"Migration file not found at {migration_path}")

    with get_connection() as conn:
        with open(migration_path, "r", encoding="utf-8") as f:
            sql_script = f.read()
        conn.executescript(sql_script)

        # Seed default user profile
        defaults = [
            ("timezone", "UTC"),
            ("name", "User"),
        ]
        for key, val in defaults:
            conn.execute(
                "INSERT OR IGNORE INTO user_profile (key, value) VALUES (?, ?)",
                (key, val)
            )
