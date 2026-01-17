import sqlite3
import os
from datetime import datetime

DB_PATH = os.path.join(os.path.dirname(__file__), "invest_guide.db")

def init_db():
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    # Ekonomik Takvim Tablosu
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS calendar_events (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            event_id TEXT,
            date_time TEXT, -- ISO format: YYYY-MM-DD HH:MM:SS
            country_id INTEGER,
            currency TEXT,
            title TEXT,
            impact TEXT, -- Low, Medium, High
            actual TEXT DEFAULT '-',
            forecast TEXT DEFAULT '-',
            previous TEXT DEFAULT '-',
            unit TEXT DEFAULT '',
            category TEXT,
            description TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    """)
    
    conn.commit()
    conn.close()

def get_db_connection():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn

# Uygulama başladığında DB'yi hazırla
init_db()
