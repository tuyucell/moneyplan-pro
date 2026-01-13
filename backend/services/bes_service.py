import requests
import json
from datetime import datetime, timedelta
from utils.cache import cache
from utils.network import SafeRequest

class BesService:
    def get_top_pension_funds(self):
        """
        BES (Bireysel Emeklilik) fonlarını çeker.
        Şu an için BİST verileri ve bilinen büyük emeklilik fonlarını simüle ediyoruz,
        zira BEFAS doğrudan API sağlamamaktadır ve scraping oldukça karışıktır.
        """
        cached = cache.get("bes_top_funds")
        if cached:
            return cached

        try:
            # Gerçek bir BES veri sağlayıcısı simülasyonu (Veya ileride eklenecek scraping kodu)
            # Normalde buradan BEFAS veya EGM verileri parse edilmelidir.
            
            # Örnek Gerçek Fon Kodları ve Verileri
            funds = [
                {"code": "VEH", "title": "Vakıf Emeklilik Altın Katılım EYF", "daily_return": 1.25, "weekly_return": 4.10, "monthly_return": 12.50},
                {"code": "AEA", "title": "Anadolu Hayat Emeklilik Altın EYF", "daily_return": 1.20, "weekly_return": 4.05, "monthly_return": 12.30},
                {"code": "AH5", "title": "Anadolu Hayat Emeklilik Hisse Senedi EYF", "daily_return": 2.45, "weekly_return": 5.20, "monthly_return": 15.10},
                {"code": "AVP", "title": "AgeSA Hayat Emeklilik Hisse Senedi EYF", "daily_return": 2.10, "weekly_return": 4.80, "monthly_return": 14.20},
                {"code": "VHE", "title": "Vakıf Emeklilik Hisse Senedi EYF", "daily_return": 2.30, "weekly_return": 5.15, "monthly_return": 14.80},
                {"code": "CHH", "title": "Cigna Sağlık Hayat Hisse Senedi EYF", "daily_return": 1.95, "weekly_return": 4.60, "monthly_return": 13.90},
                {"code": "GHL", "title": "Garanti Emeklilik Hisse Senedi EYF", "daily_return": 2.40, "weekly_return": 5.10, "monthly_return": 15.50},
                {"code": "FPH", "title": "Fiba Emeklilik Hisse Senedi EYF", "daily_return": 2.15, "weekly_return": 4.75, "monthly_return": 14.30},
                {"code": "BNR", "title": "BNP Paribas Cardif Emeklilik Hisse Senedi EYF", "daily_return": 2.05, "weekly_return": 4.90, "monthly_return": 14.00},
                {"code": "AER", "title": "Allianz Hayat Emeklilik Hisse Senedi EYF", "daily_return": 2.25, "weekly_return": 5.05, "monthly_return": 15.20},
            ]
            
            # Gerçek hayatta burada requests.post('https://www.befas.gov.tr/api/v1/Comparison/GetComparisonData', ...) yapılır.
            
            cache.set("bes_top_funds", funds, ttl_seconds=3600)
            return funds
            
        except Exception as e:
            print(f"BES Error: {e}")
            return []

bes_service = BesService()
