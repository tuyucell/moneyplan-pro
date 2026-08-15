import json
import os
import threading
from datetime import datetime, time as datetime_time, timedelta
from pathlib import Path
from zoneinfo import ZoneInfo
import xml.etree.ElementTree as ET

import requests


class TcmbService:
    """Official TCMB reference rates with a durable twice-daily cache.

    TCMB's public ``today.xml`` is a daily reference-rate document, not a
    real-time feed. We check it once in the morning and once after the usual
    afternoon publication window. Endpoint requests also perform a lazy
    refresh so the design still works when a Hugging Face Space wakes from
    sleep after a scheduled time.
    """

    SOURCE_URL = "https://www.tcmb.gov.tr/kurlar/today.xml"
    TIMEZONE = ZoneInfo("Europe/Istanbul")
    MORNING_REFRESH = datetime_time(hour=8)
    EVENING_REFRESH = datetime_time(hour=16, minute=45)
    CHECK_INTERVAL_SECONDS = 5 * 60

    def __init__(self, cache_path=None, session=None):
        self.kurlar_url = self.SOURCE_URL
        self._session = session or requests.Session()
        self._cache_path = Path(cache_path or self._default_cache_path())
        self._lock = threading.Lock()
        self._stop_event = threading.Event()
        self._scheduler_thread = None

    @staticmethod
    def _default_cache_path():
        persistent_root = Path("/data")
        if persistent_root.is_dir() and os.access(persistent_root, os.W_OK):
            return persistent_root / "tcmb_reference_rates.json"
        return (
            Path(__file__).resolve().parent.parent
            / "data"
            / "tcmb_reference_rates.json"
        )

    @classmethod
    def _refresh_slot(cls, now):
        local_now = now.astimezone(cls.TIMEZONE)
        local_time = local_now.time().replace(tzinfo=None)
        if local_time < cls.MORNING_REFRESH:
            slot_date = (local_now - timedelta(days=1)).date()
            slot_name = "evening"
        elif local_time < cls.EVENING_REFRESH:
            slot_date = local_now.date()
            slot_name = "morning"
        else:
            slot_date = local_now.date()
            slot_name = "evening"
        return f"{slot_date.isoformat()}-{slot_name}"

    @classmethod
    def _next_refresh_at(cls, now):
        local_now = now.astimezone(cls.TIMEZONE)
        morning = datetime.combine(
            local_now.date(), cls.MORNING_REFRESH, tzinfo=cls.TIMEZONE
        )
        evening = datetime.combine(
            local_now.date(), cls.EVENING_REFRESH, tzinfo=cls.TIMEZONE
        )
        if local_now < morning:
            return morning
        if local_now < evening:
            return evening
        return morning + timedelta(days=1)

    def _load_cache(self):
        try:
            with self._cache_path.open("r", encoding="utf-8") as cache_file:
                payload = json.load(cache_file)
            return payload if isinstance(payload, dict) else None
        except (OSError, ValueError, TypeError):
            return None

    def _save_cache(self, payload):
        self._cache_path.parent.mkdir(parents=True, exist_ok=True)
        temporary_path = self._cache_path.with_suffix(".tmp")
        with temporary_path.open("w", encoding="utf-8") as cache_file:
            json.dump(payload, cache_file, ensure_ascii=False, indent=2)
        os.replace(temporary_path, self._cache_path)

    @staticmethod
    def _parse_rate_date(root):
        raw_date = root.attrib.get("Tarih") or root.attrib.get("Date")
        if not raw_date:
            return None
        for date_format in ("%d.%m.%Y", "%m/%d/%Y", "%Y-%m-%d"):
            try:
                return datetime.strptime(raw_date, date_format).date().isoformat()
            except ValueError:
                continue
        return raw_date

    def _fetch(self, now, refresh_slot):
        response = self._session.get(
            self.kurlar_url,
            timeout=10,
            headers={"User-Agent": "MoneyPlanPro/1.0 (+https://moneyplan.pro)"},
        )
        response.raise_for_status()
        root = ET.fromstring(response.content)
        rates = []

        for currency in root.findall("Currency"):
            code = currency.get("Kod") or currency.get("CurrencyCode")
            if not code:
                continue
            unit_text = currency.findtext("Unit") or "1"
            buying_text = currency.findtext("ForexBuying")
            selling_text = currency.findtext("ForexSelling")
            try:
                unit = max(float(unit_text), 1.0)
                buying = float(buying_text) / unit if buying_text else None
                selling = float(selling_text) / unit if selling_text else None
            except (TypeError, ValueError):
                continue
            if buying is None and selling is None:
                continue
            # Selling is the conservative reference for a foreign-currency
            # expense. Users can still enter the actual bank charge.
            rate_to_try = selling if selling is not None else buying
            rates.append(
                {
                    "code": code,
                    "symbol": code,
                    "buying": buying,
                    "selling": selling,
                    "rate_to_try": rate_to_try,
                    "unit": 1,
                }
            )

        if not rates:
            raise ValueError("TCMB response did not contain usable rates")

        rates.insert(
            0,
            {
                "code": "TRY",
                "symbol": "TRY",
                "buying": 1.0,
                "selling": 1.0,
                "rate_to_try": 1.0,
                "unit": 1,
            },
        )
        return {
            "source": "TCMB",
            "source_url": self.kurlar_url,
            "rate_type": "official_indicative_forex_selling",
            "rate_date": self._parse_rate_date(root),
            "fetched_at": now.astimezone(self.TIMEZONE).isoformat(),
            "refresh_slot": refresh_slot,
            "stale": False,
            "rates": rates,
        }

    def get_reference_rates(self, force_refresh=False, now=None):
        current_time = now or datetime.now(self.TIMEZONE)
        if current_time.tzinfo is None:
            current_time = current_time.replace(tzinfo=self.TIMEZONE)
        current_slot = self._refresh_slot(current_time)

        with self._lock:
            cached = self._load_cache()
            should_refresh = (
                force_refresh
                or not cached
                or cached.get("refresh_slot") != current_slot
            )
            error_message = None
            if should_refresh:
                try:
                    cached = self._fetch(current_time, current_slot)
                    self._save_cache(cached)
                except Exception as error:  # Keep the last verified rate offline.
                    error_message = str(error)

            if not cached:
                return None

            result = dict(cached)
            result["stale"] = bool(error_message)
            if error_message:
                result["refresh_error"] = error_message
            result["next_refresh_at"] = self._next_refresh_at(
                current_time
            ).isoformat()
            return result

    def get_exchange_rates(self):
        """Backward-compatible map used by older backend callers."""
        payload = self.get_reference_rates()
        if not payload:
            return None
        return {
            item["code"]: {
                "buying": item.get("buying"),
                "selling": item.get("selling"),
                "change": 0.0,
            }
            for item in payload["rates"]
            if item["code"] != "TRY"
        }

    def start_scheduler(self):
        if self._scheduler_thread and self._scheduler_thread.is_alive():
            return
        self._stop_event.clear()

        def run():
            while not self._stop_event.is_set():
                self.get_reference_rates()
                self._stop_event.wait(self.CHECK_INTERVAL_SECONDS)

        self._scheduler_thread = threading.Thread(
            target=run,
            name="tcmb-reference-rate-refresh",
            daemon=True,
        )
        self._scheduler_thread.start()

    def stop_scheduler(self):
        self._stop_event.set()
        if self._scheduler_thread and self._scheduler_thread.is_alive():
            self._scheduler_thread.join(timeout=2)


tcmb_service = TcmbService()
