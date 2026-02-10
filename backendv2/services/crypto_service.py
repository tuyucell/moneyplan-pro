from pycoingecko import CoinGeckoAPI
from utils.cache import cache
from services.settings_service import settings_service

class CryptoService:
    def __init__(self):
        self.cg = CoinGeckoAPI()

    def get_top_coins(self, limit=50):
        """
        Binance API (US Kısıtlaması) yerine CoinGecko Markets API kullanılır.
        """
        cache_key = f"crypto_gecko_top_{limit}"
        cached = cache.get(cache_key)
        if cached:
            return cached

        try:
            import requests
            # CoinGecko Markets (Resim, Fiyat, Değişim hepsi tek endpointte)
            url = "https://api.coingecko.com/api/v3/coins/markets"
            params = {
                "vs_currency": "usd",
                "order": "volume_desc", # Hacme göre sırala
                "per_page": limit,
                "page": 1,
                "sparkline": "false"
            }
            # Demo API (Rate limit: 30 calls/min)
            resp = requests.get(url, params=params, timeout=10)
            
            if resp.status_code == 200:
                data = resp.json()
                results = []
                for item in data:
                    results.append({
                        "id": item['id'],
                        "symbol": item['symbol'].upper(),
                        "name": item['name'],
                        "price": float(item['current_price'] or 0),
                        "change_24h": float(item['price_change_percentage_24h'] or 0),
                        "market_cap": float(item['market_cap'] or 0),
                        "volume": float(item['total_volume'] or 0),
                        "image": item['image']
                    })
                
                cache.set(cache_key, results, ttl_seconds=600)
                return results

        except Exception as e:
            print(f"CoinGecko Error: {e}")
            
        return []

    def get_fear_greed_index(self):
        """
        Kripto Korku ve Açgözlülük Endeksini getirir.
        Cache: 1 saat
        """
        cache_key = "crypto_fear_greed"
        cached = cache.get(cache_key)
        if cached:
            return cached

        try:
            import requests
            resp = requests.get("https://api.alternative.me/fng/?limit=1", timeout=5)
            if resp.status_code == 200:
                data = resp.json()
                if data and "data" in data and len(data["data"]) > 0:
                    result = {
                        "value": int(data["data"][0]["value"]),
                        "classification": data["data"][0]["value_classification"],
                        "timestamp": data["data"][0]["timestamp"]
                    }
                    cache.set(cache_key, result, ttl_seconds=3600)
                    return result
        except Exception as e:
            print(f"Fear & Greed Error: {e}")
        
        return {"value": 50, "classification": "Neutral", "timestamp": "0"}

    def get_asset_detail(self, symbol):
        """
        Binance API'den detaylı istatistikleri çeker.
        - 24s Hacim, Yüksek, Düşük
        - 52 Hafta (1 Yıl) En Yüksek / En Düşük (Klines üzerinden hesaplanır)
        """
        symbol = self._get_binance_symbol(symbol)
        result = {}
        
        try:
            binance_key = settings_service.get_value("BINANCE_API_KEY")
            headers = {"X-MBX-APIKEY": binance_key} if binance_key else {}

            # 1. 24 Saatlik İstatistikler (Hacim, Günlük Aralık)
            # https://api.binance.com/api/v3/ticker/24hr?symbol=BTCUSDT
            url_24h = "https://api.binance.com/api/v3/ticker/24hr"
            r1 = requests.get(url_24h, params={"symbol": symbol}, headers=headers, timeout=5)
            if r1.status_code == 200:
                d = r1.json()
                result["price"] = float(d.get("lastPrice", 0))
                result["change_percent"] = float(d.get("priceChangePercent", 0))
                result["volume"] = float(d.get("quoteVolume", 0)) # USDT Hacmi
                result["high_24h"] = float(d.get("highPrice", 0))
                result["low_24h"] = float(d.get("lowPrice", 0))
                # Market Cap Binance'de yok, frontend "-" gösterecek veya 0
                result["market_cap"] = 0 
            
            # 2. 52 Haftalık (1 Yıllık) En Yüksek / Düşük Hesabı
            # Haftalık mumlardan son 52 tanesini alıp min/max bulacağız
            url_kline = "https://api.binance.com/api/v3/klines"
            r2 = requests.get(url_kline, params={"symbol": symbol, "interval": "1w", "limit": 52}, headers=headers, timeout=5)
            if r2.status_code == 200:
                klines = r2.json()
                highs = [float(k[2]) for k in klines]
                lows = [float(k[3]) for k in klines]
                if highs and lows:
                    result["high_52w"] = max(highs)
                    result["low_52w"] = min(lows)
            
            # Ek bilgiler
            result["symbol"] = symbol.replace("USDT", "")
            result["currency"] = "USD"
            
            return result

        except Exception as e:
            print(f"Asset Detail Error ({symbol}): {e}")
            return {"price": 0}

    def _get_binance_symbol(self, symbol):
        s = symbol.upper()
        if not s.endswith("USDT") and s != "USDT":
            return f"{s}USDT"
        return s

    def get_history(self, symbol, period="1mo", interval="1d"):
        """
        Binance API üzerinden tarihsel verileri (Klines) çeker.
        Symbol: BTC, ETH vs. (Sonuna USDT eklenir)
        """
        try:
            import requests
            # Sembolü düzelt (BTC -> BTCUSDT)
            symbol = symbol.upper()
            if not symbol.endswith("USDT") and symbol != "USDT": 
                symbol = f"{symbol}USDT"
            
            # Period -> Limit dönüşümü (Basit mantık)
            limit = 30
            if period == "1wk": limit = 7
            elif period == "1mo": limit = 30
            elif period == "3mo": limit = 90
            elif period == "1y": limit = 365
            elif period == "ytd": limit = 180
            elif period == "max": limit = 500

            # Binance Klines Endpoint
            url = "https://api.binance.com/api/v3/klines"
            params = {
                "symbol": symbol,
                "interval": interval if interval in ['1d', '1wk', '1mo'] else '1d',
                "limit": limit
            }
            
            # API Key
            binance_key = settings_service.get_value("BINANCE_API_KEY")
            headers = {"X-MBX-APIKEY": binance_key} if binance_key else {}
            
            r = requests.get(url, params=params, headers=headers, timeout=10)
            if r.status_code == 200:
                klines = r.json()
                # Binance Format: [Open Time, Open, High, Low, Close, Volume, ...]
                # Frontend Beklentisi: {"timestamp": ..., "close": ...}
                formatted = []
                from datetime import datetime
                for k in klines:
                    formatted.append({
                        "date": datetime.fromtimestamp(k[0] / 1000).isoformat(), # Timestamp (ms) -> ISO String
                        "close": float(k[4]),
                        "high": float(k[2]),
                        "low": float(k[3]),
                        "open": float(k[1]),
                        "volume": float(k[5])
                    })
                return formatted
        except Exception as e:
            print(f"Crypto History Error ({symbol}): {e}")
        return []

crypto_service = CryptoService()
