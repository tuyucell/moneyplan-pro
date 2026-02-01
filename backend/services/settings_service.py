import json
import logging
from database import get_db_connection

logger = logging.getLogger(__name__)

class SettingsService:
    def __init__(self):
        self._cache = {}
        self._init_table()
        self._load_cache()

    def _init_table(self):
        try:
            conn = get_db_connection()
            conn.execute("""
                CREATE TABLE IF NOT EXISTS app_settings (
                    key TEXT PRIMARY KEY,
                    value TEXT,
                    description TEXT,
                    category TEXT,
                    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            """)
            # Seed default settings if empty
            defaults = [
                ("BINANCE_API_KEY", "", "Binance API Key for Crypto Data", "api_keys"),
                ("NEWS_SOURCES", json.dumps([
                    {"name": "Bloomberg HT", "url": "https://www.bloomberght.com/rss"},
                    {"name": "Habertürk", "url": "https://www.haberturk.com/rss/ekonomi.xml"},
                    {"name": "Investing", "url": "https://tr.investing.com/rss/news.rss"}
                ]), "Active RSS News Sources", "content"),
                ("ENABLE_FEAR_GREED", "true", "Toggle Crypto Fear & Greed Index", "features"),
                ("ONESIGNAL_APP_ID", "", "OneSignal Application ID", "api_keys"),
                ("ONESIGNAL_REST_API_KEY", "", "OneSignal Rest API Key", "api_keys"),
                ("SUPABASE_URL", "https://gbncnwinlmniohafhnqf.supabase.co", "Supabase API URL", "api_keys"),
                ("SUPABASE_SERVICE_ROLE_KEY", "", "Supabase Service Role Key (CRITICAL: Private)", "api_keys"),
                ("ALERT_MONITOR_ENABLED", "1", "Enable/Disable Price Alert Monitoring", "features"),
                ("ALERT_MONITOR_INTERVAL_SEC", "60", "Monitoring check interval in seconds", "performance")
            ]
            
            cursor = conn.cursor()
            for key, val, desc, cat in defaults:
                cursor.execute("INSERT OR IGNORE INTO app_settings (key, value, description, category) VALUES (?, ?, ?, ?)", (key, val, desc, cat))
            
            conn.commit()
            conn.close()
        except Exception as e:
            logger.error(f"Error initializing settings table: {e}")

    def _load_cache(self):
        try:
            conn = get_db_connection()
            rows = conn.execute("SELECT key, value FROM app_settings").fetchall()
            conn.close()
            self._cache = {row["key"]: row["value"] for row in rows}
        except Exception as e:
            logger.error(f"Error loading settings cache: {e}")

    def get_all(self):
        conn = get_db_connection()
        rows = conn.execute("SELECT * FROM app_settings").fetchall()
        conn.close()
        return [dict(r) for r in rows]

    def update(self, key, value):
        try:
            conn = get_db_connection()
            conn.execute("UPDATE app_settings SET value = ?, updated_at = CURRENT_TIMESTAMP WHERE key = ?", (value, key))
            conn.commit()
            conn.close()
            self._cache[key] = value # Update cache
            return True
        except Exception as e:
            logger.error(f"Error updating setting {key}: {e}")
            return False

    def get_value(self, key, default=None):
        # Always check cache first
        if key in self._cache:
            return self._cache[key]
        
        # Fallback to DB if not found (shouldn't happen often if loaded at init)
        conn = get_db_connection()
        row = conn.execute("SELECT value FROM app_settings WHERE key = ?", (key,)).fetchone()
        conn.close()
        if row:
            self._cache[key] = row["value"]
            return row["value"]
        return default

settings_service = SettingsService()
