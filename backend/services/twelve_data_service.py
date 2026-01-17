import os
import requests
import json
from utils.cache import cache
from dotenv import load_dotenv

load_dotenv()

class TwelveDataService:
    def __init__(self):
        self.api_key = os.getenv("TWELVEAPI_TOKEN")
        self.base_url = "https://api.twelvedata.com"
        self.TTL = 60 # 1 dakika cache
        self.master_list_path = "backend/data/twelve_symbols.json"
        
        # Ensure data directory exists
        os.makedirs("backend/data", exist_ok=True)

    def sync_symbols(self):
        """
        Günde bir kez veya manuel tetiklendiğinde sembol listelerini (BIST, US, Forex, Commodity) 
        Twelve Data'dan çekip yerele kaydeder.
        """
        if not self.api_key: return False
        
        try:
            # 1. Stocks (Turkey & US & Europe)
            symbols_data = {}
            countries = ["Turkey", "United States", "Germany", "United Kingdom"]
            
            for country in countries:
                print(f"Fetching stocks for {country}...")
                url = f"{self.base_url}/stocks?country={country}&apikey={self.api_key}"
                res = requests.get(url, timeout=60).json()
                if res.get("status") == "ok":
                    for item in res.get("data", []):
                        sym = item["symbol"]
                        symbols_data[sym] = {
                            "name": item["name"],
                            "currency": item["currency"],
                            "exchange": item["exchange"],
                            "mic_code": item["mic_code"],
                            "country": item["country"],
                            "type": item["type"]
                        }

            # 2. Forex Pairs
            print("Fetching Forex pairs...")
            url = f"{self.base_url}/forex_pairs?apikey={self.api_key}"
            res = requests.get(url, timeout=60).json()
            if res.get("status") == "ok":
                for item in res.get("data", []):
                    sym = item["symbol"]
                    symbols_data[sym] = {
                        "name": item["currency_base"],
                        "currency": item["currency_quote"],
                        "type": "Forex"
                    }

            # 3. Commodities
            print("Fetching Commodities...")
            url = f"{self.base_url}/commodities?apikey={self.api_key}"
            res = requests.get(url, timeout=60).json()
            if res.get("status") == "ok":
                for item in res.get("data", []):
                    sym = item["symbol"]
                    symbols_data[sym] = {
                        "name": item["name"],
                        "type": "Commodity"
                    }

            # Save to disk
            with open(self.master_list_path, "w", encoding="utf-8") as f:
                json.dump(symbols_data, f, ensure_ascii=False, indent=2)
            
            return True
        except Exception as e:
            print(f"Twelve Data Sync Error: {e}")
            return False

    def get_quotes(self, symbols: list):
        if not self.api_key: return {}

        # Sembolleri standart Twelve formatına çevir
        formatted_symbols = []
        sym_map = {}
        
        # Yerel master listeyi yükle
        master = {}
        if os.path.exists(self.master_list_path):
            with open(self.master_list_path, "r", encoding="utf-8") as f:
                master = json.load(f)

        for s in symbols:
            orig = s.upper().strip()
            target = orig
            
            if orig in master:
                m = master[orig]
                if m.get("mic_code"):
                    target = f"{orig}:{m['mic_code']}"
                elif m.get("type") == "Forex" and "/" not in orig:
                    target = f"{orig}/TRY"
            else:
                if orig in ["USD", "EUR", "GBP", "CHF", "JPY", "CAD", "AUD", "DKK", "SEK", "NOK", "SAR"]:
                    target = f"{orig}/TRY"
            
            formatted_symbols.append(target)
            sym_map[target] = orig

        try:
            sym_str = ",".join(formatted_symbols)
            url = f"{self.base_url}/quote?symbol={sym_str}&apikey={self.api_key}"
            response = requests.get(url, timeout=10)
            data = response.json()
            
            if "status" in data and data["status"] == "error":
                print(f"Twelve Data API Error: {data}")
                return {}

            results = {}
            if isinstance(data, dict):
                if "symbol" in data:
                    results[sym_map.get(formatted_symbols[0], symbols[0])] = self._parse_quote(data)
                else:
                    for s_target, quote_data in data.items():
                        if isinstance(quote_data, dict) and quote_data.get("status") != "error":
                            results[sym_map.get(s_target, s_target)] = self._parse_quote(quote_data)
            return results
        except Exception as e:
            print(f"Twelve Data API Exception: {e}")
            return {}

    def _parse_quote(self, q):
        try:
            return {
                "symbol": q.get("symbol"),
                "name": q.get("name") or q.get("symbol"),
                "price": float(q.get("price") or q.get("close") or 0.0),
                "change_percent": float(q.get("percent_change") or 0.0),
                "volume": int(q.get("volume") or 0),
                "high": float(q.get("high") or 0.0),
                "low": float(q.get("low") or 0.0),
                "close": float(q.get("close") or 0.0),
                "source": "TwelveData"
            }
        except Exception:
            return None

twelve_data_service = TwelveDataService()
