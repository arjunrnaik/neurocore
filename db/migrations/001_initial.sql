-- NeuroCore v1 Database Migration

-- Persistent event bus
CREATE TABLE IF NOT EXISTS events (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    event_type TEXT NOT NULL,
    payload TEXT NOT NULL, -- JSON blob
    status TEXT DEFAULT 'pending', -- pending|processed|failed
    created_at TEXT DEFAULT (datetime('now')),
    processed_at TEXT
);

-- User-submitted information entries
CREATE TABLE IF NOT EXISTS entries (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    domain TEXT NOT NULL, -- health|finance|task|note|...
    action TEXT NOT NULL, -- store|remind|query
    content TEXT NOT NULL,
    metadata TEXT, -- JSON: entities, tags, sentiment
    created_at TEXT DEFAULT (datetime('now')),
    synced INTEGER DEFAULT 0
);

-- Scheduled reminders and follow-ups
CREATE TABLE IF NOT EXISTS reminders (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    message TEXT NOT NULL,
    due_at TEXT NOT NULL,
    status TEXT DEFAULT 'pending', -- pending|sent|cancelled
    created_at TEXT DEFAULT (datetime('now'))
);

-- Google Sheets sync audit trail
CREATE TABLE IF NOT EXISTS sync_log (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    synced_at TEXT DEFAULT (datetime('now')),
    rows_synced INTEGER,
    status TEXT, -- success|failed
    error TEXT
);

-- User preferences and personalisation data
CREATE TABLE IF NOT EXISTS user_profile (
    key TEXT PRIMARY KEY, -- timezone|name|active_domains|...
    value TEXT,
    updated_at TEXT DEFAULT (datetime('now'))
);
