import time
import threading
import logging
import requests
from datetime import datetime
from services.market_service import market_provider
from services.notification_service import notification_service
from services.settings_service import settings_service

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class AlertMonitorService:
    def __init__(self):
        self._stop_event = threading.Event()
        self._thread = None

    def start(self):
        """Starts the background monitoring thread."""
        if self._thread and self._thread.is_alive():
            logger.info("Alert Monitor already running.")
            return

        self._stop_event.clear()
        self._thread = threading.Thread(target=self._monitor_loop, daemon=True)
        self._thread.start()
        logger.info("Alert Monitor Service started (Supabase Mode).")

    def stop(self):
        """Stops the background monitoring thread."""
        self._stop_event.set()
        if self._thread:
            self._thread.join()
        logger.info("Alert Monitor Service stopped.")

    def _monitor_loop(self):
        while not self._stop_event.is_set():
            try:
                # 1. Check if monitoring is enabled in settings
                is_enabled = settings_service.get_value("ALERT_MONITOR_ENABLED", "1") == "1"
                interval = int(settings_service.get_value("ALERT_MONITOR_INTERVAL_SEC", "60"))

                if is_enabled:
                    self._check_supabase_alerts()

                # Sleep until next check
                self._stop_event.wait(interval)
            except Exception as e:
                logger.error(f"Error in Alert Monitor Loop: {e}")
                time.sleep(10) # Wait a bit before retry on error

    def _get_supabase_config(self):
        url = settings_service.get_value("SUPABASE_URL")
        key = settings_service.get_value("SUPABASE_SERVICE_ROLE_KEY")
        return url, key

    def _check_supabase_alerts(self):
        url, key = self._get_supabase_config()
        if not url or not key:
            logger.warning("Supabase URL or Service Role Key is missing. Monitor skipped.")
            return

        headers = {
            "apikey": key,
            "Authorization": f"Bearer {key}",
            "Content-Type": "application/json"
        }

        # Fetch active alerts from Supabase
        try:
            # query params: is_active=eq.true
            response = requests.get(f"{url}/rest/v1/price_alerts?is_active=eq.true", headers=headers, timeout=10)
            if response.status_code != 200:
                logger.error(f"Failed to fetch alerts from Supabase: {response.text}")
                return
            
            alerts = response.json()
            if not alerts:
                return

            logger.info(f"Checking {len(alerts)} active price alerts from Supabase...")
            
            price_cache = {}

            for alert in alerts:
                symbol = alert["symbol"]
                
                if symbol not in price_cache:
                    asset_data = market_provider.get_asset_detail(symbol)
                    price_cache[symbol] = asset_data.get("price", 0)

                current_price = price_cache[symbol]
                if current_price <= 0:
                    continue

                target_price = float(alert["target_price"])
                is_above = bool(alert["is_above"])
                
                triggered = (is_above and current_price >= target_price) or (not is_above and current_price <= target_price)

                if triggered:
                    self._trigger_supabase_alert(alert, current_price, url, headers)

        except Exception as e:
            logger.error(f"Error fetching alerts from Supabase: {e}")

    def _trigger_supabase_alert(self, alert, current_price, url, headers):
        alert_id = alert["id"]
        user_id = alert["user_id"]
        symbol = alert["symbol"]
        target_price = float(alert["target_price"])
        is_above = bool(alert["is_above"])

        direction = "üstüne çıktı" if is_above else "altına düştü"
        title = f"🎯 {symbol} Hedef Fiyata Ulaştı!"
        message = f"{symbol} şu an ${current_price:.2f} seviyesinde. Hedefiniz olan ${target_price:.2f} {direction}."

        logger.info(f"Triggering alert {alert_id} for user {user_id} on {symbol}")

        # Send push notification
        _, _ = notification_service.send_push(
            title=title,
            message=message,
            segment=f"user_{user_id}" 
        )

        # Update Supabase: Mark as inactive and record trigger time
        try:
            payload = {
                "is_active": False,
                "last_triggered_at": datetime.now().isoformat()
            }
            resp = requests.patch(f"{url}/rest/v1/price_alerts?id=eq.{alert_id}", headers=headers, json=payload, timeout=10)
            if resp.status_code not in [200, 201, 204]:
                logger.error(f"Failed to update alert in Supabase: {resp.text}")
        except Exception as e:
            logger.error(f"Error updating alert in Supabase: {e}")

alert_monitor_service = AlertMonitorService()
