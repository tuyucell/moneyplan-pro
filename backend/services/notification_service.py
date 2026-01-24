from database import get_db_connection
from services.settings_service import settings_service
import requests
import json
from datetime import datetime

class NotificationService:
    def get_history(self, limit=50):
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM notifications ORDER BY created_at DESC LIMIT ?", (limit,))
        rows = cursor.fetchall()
        history = [dict(row) for row in rows]
        conn.close()
        return history

    def send_push(self, title, message, image_url=None, action_url=None, segment="all"):
        """
        Sends push notification via OneSignal.
        Logs the attempt to the database.
        """
        app_id = settings_service.get_value("ONESIGNAL_APP_ID")
        api_key = settings_service.get_value("ONESIGNAL_REST_API_KEY")

        # Log to DB first as pending
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("""
            INSERT INTO notifications (title, message, image_url, action_url, target_segment, status)
            VALUES (?, ?, ?, ?, ?, 'sending')
        """, (title, message, image_url, action_url, segment))
        notification_id = cursor.lastrowid
        conn.commit()

        # If keys are missing, we just log as missed/failed but don't crash
        if not app_id or not api_key:
            cursor.execute("UPDATE notifications SET status = 'failed', message = message || ' (API Keys missing)' WHERE id = ?", (notification_id,))
            conn.commit()
            conn.close()
            return False, "OneSignal API keys are not configured."

        # OneSignal Payload
        header = {"Content-Type": "application/json; charset=utf-8",
                  "Authorization": f"Basic {api_key}"}

        payload = {
            "app_id": app_id,
            "contents": {"en": message, "tr": message}, # Added Turkish support
            "headings": {"en": title, "tr": title},
        }

        if segment == "all":
            payload["included_segments"] = ["Subscribed Users"]
        elif segment.startswith("user_"):
            # Target specific user by external ID (Supabase UID)
            user_id = segment.replace("user_", "")
            payload["include_external_user_ids"] = [user_id]
        else:
            payload["included_segments"] = [segment.capitalize()]

        if image_url:
            payload["big_picture"] = image_url
            payload["chrome_web_image"] = image_url
        
        if action_url:
            payload["url"] = action_url

        try:
            response = requests.post("https://onesignal.com/api/v1/notifications", 
                                   headers=header, 
                                   data=json.dumps(payload),
                                   timeout=10)
            
            res_data = response.json()
            if response.status_code == 200 and "id" in res_data:
                delivered = res_data.get("recipients", 0)
                cursor.execute("UPDATE notifications SET status = 'sent', delivered_count = ? WHERE id = ?", (delivered, notification_id))
                conn.commit()
                return True, f"Successfully sent to {delivered} users"
            else:
                error_msg = res_data.get("errors", ["Unknown error"])[0]
                cursor.execute("UPDATE notifications SET status = 'failed' WHERE id = ?", (notification_id,))
                conn.commit()
                return False, f"OneSignal Error: {error_msg}"

        except Exception as e:
            cursor.execute("UPDATE notifications SET status = 'failed' WHERE id = ?", (notification_id,))
            conn.commit()
            return False, f"Exception: {str(e)}"
        finally:
            conn.close()

notification_service = NotificationService()
