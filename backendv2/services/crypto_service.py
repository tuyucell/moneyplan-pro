from pycoingecko import CoinGeckoAPI
from utils.cache import cache

class CryptoService:
    def __init__(self):
        self.cg = CoinGeckoAPI()

    def get_top_coins(self, limit=50):
        """
        Binance API üzerinden tüm kripto verilerini çeker, hacme göre sıralar ve ilk N tanesini getirir.
        API Key: Read-Only yetkili key kullanılıyor.
        Cache: 600 saniye (10 dakika)
        """
        cache_key = f"crypto_binance_top_{limit}"
        cached = cache.get(cache_key)
        if cached:
            return cached

        try:
            import requests
            # Binance Ticker 24hr Endpoint (Tüm coinler için)
            url = "https://api.binance.com/api/v3/ticker/24hr"
            headers = {
                "X-MBX-APIKEY": "r1JDHkU4IqRMvRhGKK9k5vIvu03MrrOwLQWxCpLnecjMpTwXAPE45xrd9q6tceHw"
            }
            
            resp = requests.get(url, headers=headers, timeout=10)
            if resp.status_code == 200:
                data = resp.json()
                
                # USDT paritelerini filtrele ve işle
                usdt_pairs = []
                for item in data:
                    s = item['symbol']
                    if s.endswith("USDT"):
                        # Sembolü ayrıştır (BTCUSDT -> BTC)
                        raw_symbol = s[:-4] 
                        # Kaldıraçlı tokenları (UP/DOWN/BEAR/BULL) basitçe filtrele
                        if "UP" in raw_symbol or "DOWN" in raw_symbol: continue
                        
                        try:
                            # Quote Volume (Hacim) sıralaması için float'a çevir
                            vol = float(item['quoteVolume'])
                            price = float(item['lastPrice'])
                            change = float(item['priceChangePercent'])
                            
                            usdt_pairs.append({
                                "id": raw_symbol.lower(),
                                "symbol": raw_symbol,
                                "name": raw_symbol, # Tam isim API'de yok, sembol kullanıyoruz
                                "price": price,
                                "change_24h": change,
                                "market_cap": 0, # Ticker endpointinde market cap yok
                                "volume": vol,
                                # Frontend'deki placeholder resim mantığı çalışacak
                                "image": f"https://assets.coincap.io/assets/icons/{raw_symbol.lower()}@2x.png" # Deneme: Coincap ikonları
                            })
                        except: continue

                # Hacme göre azalan sırala (En popülerler)
                usdt_pairs.sort(key=lambda x: x['volume'], reverse=True)
                
                # İstenen limit kadar al
                result = usdt_pairs[:limit]
                
                # Cache'le (10 Dakika)
                cache.set(cache_key, result, ttl_seconds=600)
                return result
                
        except Exception as e:
            print(f"Binance API Error: {e}")
            
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
            import requests
            headers = {"X-MBX-APIKEY": "r1JDHkU4IqRMvRhGKK9k5vIvu03MrrOwLQWxCpLnecjMpTwXAPE45xrd9q6tceHw"}

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
            
            # API Key gerekmez public endpoint ama varsa header ekleyelim
            headers = {"X-MBX-APIKEY": "r1JDHkU4IqRMvRhGKK9k5vIvu03MrrOwLQWxCpLnecjMpTwXAPE45xrd9q6tceHw"}
            
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
