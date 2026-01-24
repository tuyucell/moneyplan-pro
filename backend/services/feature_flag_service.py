from typing import Dict, Optional
from datetime import datetime, timedelta
from models.feature_flag import FeatureFlag, FeatureFlagsResponse
import json


class FeatureFlagService:
    """Service for managing feature flags"""
    
    # Default feature flags (fallback if DB is empty)
    DEFAULT_FLAGS = {
        "ai_analyst": {
            "id": "ai_analyst",
            "name": "AI Portföy Analisti",
            "description": "Yapay zeka ile portföy analizi ve öneriler",
            "is_pro": True,
            "is_enabled": True,
            "daily_free_limit": 1,
            "metadata": {"min_version": "1.0.0"}
        },
        "scenario_planner": {
            "id": "scenario_planner",
            "name": "Gelecek Simülasyonu",
            "description": "30 yıllık finansal projeksiyon",
            "is_pro": True,
            "is_enabled": True,
            "daily_free_limit": 1,
            "metadata": {"min_version": "1.0.0"}
        },
        "investment_wizard": {
            "id": "investment_wizard",
            "name": "Yatırım Asistanı",
            "description": "Risk ve getiri analizi",
            "is_pro": True,
            "is_enabled": True,
            "daily_free_limit": 1,
            "metadata": {"min_version": "1.0.0"}
        },
        "import_statement_ai": {
            "id": "import_statement_ai",
            "name": "AI Ekstre Okuma",
            "description": "Banka ekstresini AI ile otomatik işleme",
            "is_pro": True,
            "is_enabled": True,
            "daily_free_limit": 1,
            "metadata": {"min_version": "1.0.0"}
        },
        "email_automation": {
            "id": "email_automation",
            "name": "E-posta Otomasyonu",
            "description": "Gmail entegrasyonu ile otomatik işlem",
            "is_pro": True,
            "is_enabled": True,
            "daily_free_limit": 0,
            "metadata": {"min_version": "1.0.0"}
        },
        "export_csv": {
            "id": "export_csv",
            "name": "CSV Export",
            "description": "İşlemleri CSV olarak dışa aktar",
            "is_pro": False,
            "is_enabled": True,
            "daily_free_limit": 1,
            "metadata": {"show_ad": True}
        },
        "export_pdf": {
            "id": "export_pdf",
            "name": "PDF Export",
            "description": "İşlemleri PDF olarak dışa aktar",
            "is_pro": False,
            "is_enabled": True,
            "daily_free_limit": 1,
            "metadata": {"show_ad": True}
        },
        "compound_interest": {
            "id": "compound_interest",
            "name": "Bileşik Faiz Hesaplayıcı",
            "description": "Bileşik faiz ve yatırım hesaplaması",
            "is_pro": False,
            "is_enabled": True,
            "daily_free_limit": None,
            "metadata": {}
        },
        "loan_calculator": {
            "id": "loan_calculator",
            "name": "Kredi & Mevduat Hesaplayıcı",
            "description": "Kredi ve mevduat hesaplama araçları",
            "is_pro": False,
            "is_enabled": True,
            "daily_free_limit": None,
            "metadata": {}
        },
        "credit_card_assistant": {
            "id": "credit_card_assistant",
            "name": "Kredi Kartı Asistanı",
            "description": "Kredi kartı yönetimi ve öneriler",
            "is_pro": False,
            "is_enabled": True,
            "daily_free_limit": None,
            "metadata": {}
        }
    }
    
    @staticmethod
    async def get_all_flags() -> FeatureFlagsResponse:
        """Get all feature flags from database"""
        from database import get_db_connection
        db = get_db_connection()
        try:
            # Get from settings table
            result = db.execute(
                "SELECT value, updated_at FROM settings WHERE key = 'feature_flags'"
            ).fetchone()
            
            if result:
                flags_data = json.loads(result[0])
                # result[1] should be a datetime object now due to detect_types
                ts = result[1]
                if hasattr(ts, 'timestamp'):
                    version = int(ts.timestamp())
                elif isinstance(ts, str):
                    try:
                        # SQLite format YYYY-MM-DD HH:MM:SS
                        version = int(datetime.strptime(ts, "%Y-%m-%d %H:%M:%S").timestamp())
                    except (ValueError, TypeError):
                        version = int(datetime.now().timestamp())
                else:
                    version = int(datetime.now().timestamp())
            else:
                # Initialize with defaults
                await FeatureFlagService._initialize_defaults(db)
                flags_data = FeatureFlagService.DEFAULT_FLAGS
                version = int(datetime.now().timestamp())
            
            # Convert to FeatureFlag objects
            features = {}
            for flag_id, flag_data in flags_data.items():
                # Ensure created_at and updated_at exist
                if "created_at" not in flag_data:
                    flag_data["created_at"] = datetime.now()
                if "updated_at" not in flag_data:
                    flag_data["updated_at"] = datetime.now()
                    
                features[flag_id] = FeatureFlag(**flag_data)
            
            return FeatureFlagsResponse(
                features=features,
                version=version,
                cached_until=datetime.now() + timedelta(hours=1)  # Cache for 1 hour
            )
        finally:
            db.close()
    
    @staticmethod
    async def _initialize_defaults(db):
        """Initialize default feature flags in database"""
        now = datetime.now()
        flags_with_timestamps = {}
        
        for flag_id, flag_data in FeatureFlagService.DEFAULT_FLAGS.items():
            flags_with_timestamps[flag_id] = {
                **flag_data,
                "created_at": now.isoformat(),
                "updated_at": now.isoformat()
            }
        
        db.execute(
            "INSERT OR REPLACE INTO settings (key, value, updated_at) VALUES (?, ?, ?)",
            ("feature_flags", json.dumps(flags_with_timestamps), now)
        )
        db.commit()
    
    @staticmethod
    async def update_flag(flag_id: str, updates: dict) -> Optional[FeatureFlag]:
        """Update a specific feature flag"""
        from database import get_db_connection
        db = get_db_connection()
        try:
            # Get current flags
            result = db.execute(
                "SELECT value FROM settings WHERE key = 'feature_flags'"
            ).fetchone()
            
            if not result:
                await FeatureFlagService._initialize_defaults(db)
                result = db.execute(
                    "SELECT value FROM settings WHERE key = 'feature_flags'"
                ).fetchone()
            
            flags_data = json.loads(result[0])
            
            if flag_id not in flags_data:
                return None
            
            # Update the flag
            now = datetime.now()
            for key, value in updates.items():
                if value is not None:
                    flags_data[flag_id][key] = value
            
            flags_data[flag_id]["updated_at"] = now.isoformat()
            
            # Save back to database
            db.execute(
                "UPDATE settings SET value = ?, updated_at = ? WHERE key = 'feature_flags'",
                (json.dumps(flags_data), now)
            )
            db.commit()
            
            return FeatureFlag(
                **flags_data[flag_id],
                created_at=datetime.fromisoformat(flags_data[flag_id]["created_at"]),
                updated_at=now
            )
        finally:
            db.close()
    
    @staticmethod
    async def get_flag(flag_id: str) -> Optional[FeatureFlag]:
        """Get a specific feature flag"""
        flags_response = await FeatureFlagService.get_all_flags()
        return flags_response.features.get(flag_id)
    
    @staticmethod
    async def is_feature_available(flag_id: str, is_pro_user: bool) -> bool:
        """Check if a feature is available for a user"""
        flag = await FeatureFlagService.get_flag(flag_id)
        
        if not flag or not flag.is_enabled:
            return False
        
        # If feature is not PRO, it's available to everyone
        if not flag.is_pro:
            return True
        
        # If user is PRO, they have access
        if is_pro_user:
            return True
        
        # If feature has daily free limit > 0, it's available (usage tracking is separate)
        if flag.daily_free_limit and flag.daily_free_limit > 0:
            return True
        
        return False
