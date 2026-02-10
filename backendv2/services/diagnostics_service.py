import os
import requests
from services.settings_service import settings_service

class DiagnosticsService:
    def check_all(self):
        results = {
            "binance": self.check_binance(),
            "onesignal": self.check_onesignal(),
            "supabase": self.check_supabase(),
            "fmp": self.check_fmp(),
            "twelve_data": self.check_twelve_data()
        }
        return results

    def check_binance(self):
        key = settings_service.get_value("BINANCE_API_KEY")
        if not key: return {"status": "missing", "message": "Key not found in ENV or DB"}
        
        try:
            # Check account status (requires key) or just a simple weighted request
            url = "https://api.binance.com/api/v3/account"
            headers = {"X-MBX-APIKEY": key}
            # Note: This might fail if the key doesn't have permissions, 
            # but it confirms if the key is 'accepted' as a format.
            # Alternately, use a public one with the key to check rate limit headers
            resp = requests.get("https://api.binance.com/api/v3/ping", headers=headers, timeout=5)
            if resp.status_code == 200:
                return {"status": "ok", "message": "Connection successful"}
            return {"status": "error", "message": f"Status {resp.status_code}"}
        except Exception as e:
            return {"status": "error", "message": str(e)}

    def check_onesignal(self):
        app_id = settings_service.get_value("ONESIGNAL_APP_ID")
        api_key = settings_service.get_value("ONESIGNAL_REST_API_KEY")
        if not app_id or not api_key: return {"status": "missing", "message": "Keys missing"}
        
        try:
            url = f"https://onesignal.com/api/v1/apps/{app_id}"
            headers = {"Authorization": f"Basic {api_key}"}
            resp = requests.get(url, headers=headers, timeout=5)
            if resp.status_code == 200:
                return {"status": "ok", "message": "App verified"}
            return {"status": "error", "message": f"Status {resp.status_code}: {resp.text[:50]}"}
        except Exception as e:
            return {"status": "error", "message": str(e)}

    def check_supabase(self):
        url = settings_service.get_value("SUPABASE_URL")
        key = settings_service.get_value("SUPABASE_SERVICE_ROLE_KEY")
        if not url or not key: return {"status": "missing", "message": "Config missing"}
        
        try:
            # Try to list users (requires service_role)
            check_url = f"{url}/auth/v1/admin/users"
            headers = {"apikey": key, "Authorization": f"Bearer {key}"}
            resp = requests.get(check_url, headers=headers, timeout=5)
            if resp.status_code == 200:
                return {"status": "ok", "message": "Admin access verified"}
            return {"status": "error", "message": f"Status {resp.status_code}"}
        except Exception as e:
            return {"status": "error", "message": str(e)}

    def check_fmp(self):
        key = settings_service.get_value("FMP_API_KEY")
        if not key: return {"status": "missing"}
        try:
            resp = requests.get(f"https://financialmodelingprep.com/api/v3/quote/AAPL?apikey={key}", timeout=5)
            if resp.status_code == 200: return {"status": "ok"}
            return {"status": "error"}
        except: return {"status": "error"}

    def check_twelve_data(self):
        key = settings_service.get_value("TWELVEAPI_TOKEN")
        if not key: return {"status": "missing"}
        try:
            resp = requests.get(f"https://api.twelvedata.com/quote?symbol=AAPL&apikey={key}", timeout=5)
            if resp.status_code == 200: return {"status": "ok"}
            return {"status": "error"}
        except: return {"status": "error"}

diagnostics_service = DiagnosticsService()
