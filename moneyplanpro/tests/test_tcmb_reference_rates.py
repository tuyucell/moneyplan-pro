from datetime import datetime
from zoneinfo import ZoneInfo

from services.tcmb_service import TcmbService


SAMPLE_XML = b"""<?xml version="1.0" encoding="UTF-8"?>
<Tarih_Date Tarih="15.08.2026" Date="08/15/2026">
  <Currency CrossOrder="0" Kod="USD" CurrencyCode="USD">
    <Unit>1</Unit><ForexBuying>40.0000</ForexBuying><ForexSelling>40.1000</ForexSelling>
  </Currency>
  <Currency CrossOrder="1" Kod="JPY" CurrencyCode="JPY">
    <Unit>100</Unit><ForexBuying>26.0000</ForexBuying><ForexSelling>26.2000</ForexSelling>
  </Currency>
</Tarih_Date>
"""


class FakeResponse:
    def __init__(self, content=SAMPLE_XML, error=None):
        self.content = content
        self.error = error

    def raise_for_status(self):
        if self.error:
            raise self.error


class FakeSession:
    def __init__(self):
        self.calls = 0
        self.error = None

    def get(self, _url, **_kwargs):
        self.calls += 1
        return FakeResponse(error=self.error)


def test_reference_rates_refresh_once_per_morning_and_evening(tmp_path):
    session = FakeSession()
    service = TcmbService(
        cache_path=tmp_path / "tcmb.json",
        session=session,
    )
    timezone = ZoneInfo("Europe/Istanbul")

    morning = service.get_reference_rates(
        now=datetime(2026, 8, 15, 9, tzinfo=timezone)
    )
    same_slot = service.get_reference_rates(
        now=datetime(2026, 8, 15, 12, tzinfo=timezone)
    )
    evening = service.get_reference_rates(
        now=datetime(2026, 8, 15, 17, tzinfo=timezone)
    )

    assert session.calls == 2
    assert morning["refresh_slot"] == "2026-08-15-morning"
    assert same_slot["refresh_slot"] == morning["refresh_slot"]
    assert evening["refresh_slot"] == "2026-08-15-evening"
    assert evening["rate_date"] == "2026-08-15"
    rates = {item["code"]: item for item in evening["rates"]}
    assert rates["USD"]["rate_to_try"] == 40.1
    assert rates["JPY"]["rate_to_try"] == 0.262


def test_reference_rates_keep_last_verified_value_on_refresh_error(tmp_path):
    session = FakeSession()
    service = TcmbService(
        cache_path=tmp_path / "tcmb.json",
        session=session,
    )
    timezone = ZoneInfo("Europe/Istanbul")
    service.get_reference_rates(now=datetime(2026, 8, 15, 9, tzinfo=timezone))

    session.error = RuntimeError("temporary network error")
    result = service.get_reference_rates(
        now=datetime(2026, 8, 15, 17, tzinfo=timezone)
    )

    assert result["stale"] is True
    assert result["refresh_slot"] == "2026-08-15-morning"
    assert "temporary network error" in result["refresh_error"]
    assert any(item["code"] == "USD" for item in result["rates"])
