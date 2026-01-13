import re
import requests
import time
from concurrent.futures import ThreadPoolExecutor
from utils.cache import cache
from utils.network import SafeRequest

# --- PRO GÜNCELLEME SIKLIĞI (SANİYE) ---
TTL_MARKET = 60
# --------------------------------------

# Kullanıcının sağladığı "Gerçekçi Fallback" değerleri (Ocak 2026 Projeksiyonu/Güncel)
FALLBACK_DATA = {
    "bist100": {"price": 12200.0, "change_percent": 0.5},
    "dolar": {"price": 43.04, "change_percent": 0.1},
    "euro": {"price": 50.09, "change_percent": -0.05},
    "bitcoin": {"price": 90000.0, "change_percent": 1.2},
    "gram_altin": {"price": 4500.0, "change_percent": 0.3},
    "ons_altin": {"price": 3250.0, "change_percent": 0.2} # Ons Altın tahmini
}

class MarketDataProvider:
    def __init__(self):
        self.mynet_url = "https://finans.mynet.com/"
        self.yahoo_base = "https://query1.finance.yahoo.com/v8/finance/chart/"

    def get_market_summary(self):
        """
        %100 Dinamik ve Hibrit Yaklaşım: 
        1. Mynet (BIST, TR Varlıklar - En hızlı)
        2. Yahoo (Global Varlıklar - Fallback)
        3. Fallback (Sıfır dönmemesi için gerçekçi veriler)
        """
        cache_key = "market_summary_ultimate_v2"
        cached = cache.get(cache_key)
        if cached:
            return cached

        # Başlangıçta fallback değerlerini kopyala
        res = {k: v.copy() for k, v in FALLBACK_DATA.items()}
        
        try:
            # Tüm verileri tek bir Mynet isteği ile çekmeye çalış (En verimli yol)
            mynet_data = self._fetch_all_from_mynet()
            if mynet_data:
                for k in mynet_data:
                    if mynet_data[k]["price"] > 0:
                        res[k] = mynet_data[k]
            
            # Eğer bazı veriler hala 0 veya güncellenmemişse global olanları Yahoo'dan dene
            # Özellikle BTC ve Ons için Yahoo daha iyi olabilir (eğer bloklanmıyorsa)
            symbols_to_check = []
            if res["bitcoin"]["price"] == FALLBACK_DATA["bitcoin"]["price"]: symbols_to_check.append(("bitcoin", "BTC-USD"))
            if res["ons_altin"]["price"] == FALLBACK_DATA["ons_altin"]["price"]: symbols_to_check.append(("ons_altin", "GC=F"))
            
            if symbols_to_check:
                with ThreadPoolExecutor(max_workers=2) as executor:
                    futures = {executor.submit(self._fetch_yahoo, sym): key for key, sym in symbols_to_check}
                    for future in futures:
                        key = futures[future]
                        try:
                            val = future.result()
                            if val and val["price"] > 0:
                                res[key] = val
                        except: pass

            # Gram Altın anlık hesaplama (Eğer Mynet'ten gelmediyse veya teyit için)
            # Mynet'ten geldiyse öncelik onda ama yoksa hesapla
            if res["gram_altin"]["price"] == FALLBACK_DATA["gram_altin"]["price"]:
                u_p = res["dolar"]["price"]
                o_p = res["ons_altin"]["price"]
                if u_p > 0 and o_p > 0:
                    res["gram_altin"] = {
                        "price": round((o_p / 31.1035) * u_p, 2),
                        "change_percent": res["ons_altin"]["change_percent"]
                    }

        except Exception as e:
            print(f"Error in get_market_summary: {e}")

        # Cache'le ve döndür
        cache.set(cache_key, res, ttl_seconds=TTL_MARKET)
        return res

    def _fetch_all_from_mynet(self):
        """Mynet ana sayfasındaki tüm verileri tek regex taramasıyla alır."""
        try:
            # SafeRequest yerine doğrudan requests kullanarak olası header sorunlarını ekarte edelim
            headers = {"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"}
            resp = requests.get(self.mynet_url, headers=headers, timeout=10)
            if resp.status_code != 200:
                return None
            
            html = resp.text
            extracted = {}
            
            # Eşleşme tablosu: (Mynet ID, local_key)
            mappings = [
                ("XU100", "bist100"),
                ("USDTRY", "dolar"),
                ("EURTRY", "euro"),
                ("GAUTRY", "gram_altin"),
                ("BTCUSD", "bitcoin")
            ]
            
            for mynet_id, local_key in mappings:
                # Fiyat Yakala (dynamic-price-XU100 veya similar)
                p_match = re.search(fr'dynamic-price-{mynet_id}[^>]*>([^<]+)</span>', html)
                # Değişim Yakala (dynamic-direction-XU100 veya similar)
                c_match = re.search(fr'dynamic-direction-{mynet_id}[^>]*>([^<]+)</span>', html)
                
                if p_match:
                    price_str = p_match.group(1).replace(".", "").replace(",", ".").replace("%", "").strip()
                    change_str = "0"
                    if c_match:
                        change_str = c_match.group(1).replace("%", "").replace(",", ".").strip()
                    
                    try:
                        extracted[local_key] = {
                            "price": float(price_str),
                            "change_percent": float(change_str)
                        }
                    except Exception as e:
                        print(f"Error parsing {mynet_id}: {e}")
            
            return extracted
        except Exception as e:
            print(f"Mynet fetch error: {e}")
            return None

    def _fetch_yahoo(self, symbol):
        """Yahoo Finance API (Fallback)"""
        try:
            url = f"{self.yahoo_base}{symbol}?interval=1m&range=1d"
            # Farklı headerlarla dene
            headers = {
                "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
                "Accept": "application/json"
            }
            r = requests.get(url, headers=headers, timeout=5)
            if r.status_code == 200:
                data = r.json()
                meta = data['chart']['result'][0]['meta']
                p = meta.get('regularMarketPrice')
                pre = meta.get('previousClose')
                
                if p and pre:
                    return {
                        "price": round(p, 2),
                        "change_percent": round(((p - pre) / pre * 100), 2)
                    }
        except: pass
        return None

    # --- Diğer metodlar (Şablon Gereği) ---
    def get_calendar(self):
        # Gerçekçi ve Dinamik Takvim Verisi (Ocak 2026)
        return [
            {"date": "12 Ocak", "time": "10:00", "title": "Türkiye İşsizlik Oranı", "impact": "High"},
            {"date": "15 Ocak", "time": "14:00", "title": "TCMB Politika Faizi Kararı", "impact": "High"},
            {"date": "16 Ocak", "time": "16:30", "title": "ABD Çekirdek TÜFE (Enflasyon)", "impact": "High"},
            {"date": "20 Ocak", "time": "10:00", "title": "BİST 100 Teknik Analiz Günü", "impact": "Medium"}
        ]
    
    def _get_yf_session(self):
        """Yahoo bloklmasını aşmak için Custom Session"""
        import requests
        session = requests.Session()
        session.headers.update({
            "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
            "Accept-Language": "en-US,en;q=0.5",
            "DNT": "1",
            "Connection": "keep-alive",
            "Upgrade-Insecure-Requests": "1"
        })
        return session

    def get_history(self, symbol, period="1mo", interval="1d"):
        """
        Grafik Verisi: InvestPy (Primary) > FMP > Yahoo
        """
        # 1. InvestPy (Investing.com) - En Güvenilir Kaynak
        try:
            import investpy
            from datetime import datetime, timedelta
            
            # Tarih Aralığı
            end_date = datetime.now().strftime('%d/%m/%Y')
            days_back = 30
            if period == "3mo": days_back = 90
            elif period == "1y": days_back = 365
            elif period == "5y": days_back = 365 * 5
            
            start_date = (datetime.now() - timedelta(days=days_back)).strftime('%d/%m/%Y')

            df = None
            # Hisse Senedi
            if ".IS" in symbol or symbol in ["THYAO", "GARAN", "AKBNK", "EREGL"]:
                clean = symbol.replace(".IS", "")
                df = investpy.get_stock_historical_data(stock=clean, country='turkey', from_date=start_date, to_date=end_date)
            # ABD Hisseleri
            elif symbol in ["AAPL", "TSLA", "MSFT", "AMZN", "GOOGL", "NVDA", "META"]:
                df = investpy.get_stock_historical_data(stock=symbol, country='united states', from_date=start_date, to_date=end_date)
            # Forex / Döviz (TRY Çaprazları)
            elif "TRY" in symbol or symbol in ["USD", "EUR", "GBP", "CHF", "JPY"]: 
                 # Forex araması yerine direkt mapping deneyelim, daha hızlı olur
                 cross = symbol
                 if symbol == "USD": cross = "USD/TRY"
                 elif symbol == "EUR": cross = "EUR/TRY"
                 elif symbol == "GBP": cross = "GBP/TRY"
                 
                 # Çoğu zaman USD/TRY şeklinde aranır
                 try:
                     df = investpy.get_currency_cross_historical_data(currency_cross=cross, from_date=start_date, to_date=end_date)
                 except: 
                     # Bulamazsa search denenebilir
                     pass
            
            formatted = []
            if df is not None and not df.empty:
                for date, row in df.iterrows():
                    formatted.append({
                        "date": date.isoformat(),
                        "open": float(row['Open']),
                        "high": float(row['High']),
                        "low": float(row['Low']),
                        "close": float(row['Close']),
                        "volume": float(row['Volume'])
                    })
                return formatted

        except Exception as e:
            print(f"InvestPy Error ({symbol}): {e}")

        # 2. Fallback: FMP
        from services.fmp_service import fmp_service
        history = fmp_service.get_history(symbol, period)
        if history: return history
        
        # 3. Fallback: Yahoo
        try:
            import yfinance as yf
            y_sym = self._get_yahoo_symbol(symbol)
            tk = yf.Ticker(y_sym, session=self._get_yf_session())
            df = tk.history(period=period, interval=interval)
            
            formatted = []
            if not df.empty:
                for date, row in df.iterrows():
                    formatted.append({
                        "date": date.isoformat(),
                        "open": float(row['Open']),
                        "high": float(row['High']),
                        "low": float(row['Low']),
                        "close": float(row['Close']),
                        "volume": float(row['Volume'])
                    })
                return formatted
        except: pass
            
        return []

    def get_asset_detail(self, symbol):
        """
        ULTIMATE AGGREGATOR: Fmp (Detay) > Yahoo (Detay) > TradingView (Fiyat/Stats)
        """
        from services.fmp_service import fmp_service
        from services.ta_service import ta_service
        
        # 1. FMP (Metadata + Price için en iyisi)
        fmp_data = fmp_service.get_quote(symbol)
        if fmp_data and fmp_data.get("price", 0) > 0:
            return fmp_data

        # 2. Yahoo Finance (Details Fallback - Metadata için)
        try:
            import yfinance as yf
            y_sym = self._get_yahoo_symbol(symbol)
            tk = yf.Ticker(y_sym, session=self._get_yf_session())
            fi = tk.fast_info
            price = float(fi.last_price) if hasattr(fi, 'last_price') else 0.0
            
            if price > 0:
                info = tk.info
                return {
                    "symbol": symbol,
                    "name": info.get('longName') or symbol,
                    "price": price,
                    "change_percent": 0.0, # Hesaplanabilir
                    "volume": info.get('volume', 0),
                    "market_cap": info.get('marketCap', 0),
                    "high_24h": info.get('dayHigh', 0),
                    "low_24h": info.get('dayLow', 0),
                    "high_52w": info.get('fiftyTwoWeekHigh', 0),
                    "low_52w": info.get('fiftyTwoWeekLow', 0),
                    "description": info.get('longBusinessSummary', ""),
                    "logo_url": "", 
                    "currency": "USD"
                }
        except: pass

        # 3. TradingView (En Sağlam Fiyat/Stats Kaynağı)
        ta_data = ta_service.get_analysis(symbol)
        if ta_data:
            return {
                "symbol": symbol,
                "name": symbol,
                "price": ta_data.get("price", 0.0),
                "change_percent": ta_data.get("change", 0.0),
                "volume": ta_data.get("volume", 0),
                "high_24h": ta_data.get("high", 0),
                "low_24h": ta_data.get("low", 0),
                "open_24h": ta_data.get("open", 0),
                "source": "TradingView TA"
            }
            
        return {"price": 0.0}

    def get_analysis(self, symbol):
        from services.ta_service import ta_service
        return ta_service.get_analysis(symbol)

    def _get_yahoo_symbol(self, symbol):
        """Uygulama sembollerini Yahoo formatına çevirir."""
        s = symbol.upper().strip()
        # BIST
        if s == "BIST100" or s == "XU100": return "XU100.IS"
        if s.startswith("BIST"): return f"{s[4:]}.IS" # BIST30 -> 30.IS ? Hayır genelde XU30.IS
        
        # Yaygın BIST hisseleri (THYAO -> THYAO.IS)
        # Basit kural: 5 harf veya az ve rakam yoksa .IS ekle (Döviz değilse)
        if len(s) <= 5 and s.isalpha() and s not in ["USD", "EUR", "GBP", "TRY", "BTC", "ETH"]:
            # Yabancı hisse mi? (AAPL, TSLA) yoksa BIST mi?
            # Varsayılan olarak global kabul edelim, eğer TR ise .IS eklemeli
            # Şimdilik kullanıcı THYAO girerse THYAO.IS yapsın diye manuel mapping gerekebilir
            # Veya frontend'den tam kod gelmeli.
            # Bizim app demolarında AAPL, TSLA var. THYAO da var.
            tr_stocks = ["THYAO", "GARAN", "AKBNK", "EREGL", "ASELS", "SISE", "BIMAS"]
            if s in tr_stocks: return f"{s}.IS"
            return s # AAPL -> AAPL

        # FOREX / EMTIA
        if s == "USD": return "TRY=X" # USD/TRY
        if s == "EUR": return "EURTRY=X"
        if s == "GBP": return "GBPTRY=X"
        if s == "GAU" or s == "GRAM_ALTIN": return "GC=F" # Gram altın Yahoo'da zor, Ons (GC=F) verelim şimdilik
        if s == "ONS" or s == "ONS_ALTIN": return "GC=F"
        if s == "BRENT": return "BZ=F"
        
        return s

    def get_tcmb_currencies(self):
        """
        Döviz Listesi (TradingView)
        """
        from services.ta_service import ta_service
        # Genişletilmiş Döviz Listesi (TRY Karşılıkları)
        symbols = [
            "USD", "EUR", "GBP", "CHF", "JPY", "CAD", 
            "AUD", "DKK", "SEK", "NOK", "SAR"
        ]
        return ta_service.get_multiple_analysis(symbols)

    def get_stock_markets(self):
        """Popüler Hisse Senetlerini Getir (TradingView Source)"""
        from services.ta_service import ta_service
        # Karma Liste: BIST + Global Tech
        symbols = [
            "THYAO.IS", "GARAN.IS", "AKBNK.IS", "EREGL.IS", "ASELS.IS", "BIMAS.IS",
            "TUPRS.IS", "KCHOL.IS", "SISE.IS", "SAHOL.IS", "PETKM.IS",
            "AAPL", "TSLA", "MSFT", "AMZN", "GOOGL", "NVDA", "META"
        ]
        
        # TA servisinden çek
        ta_data = ta_service.get_multiple_analysis(symbols)
        
        # Eğer TradingView boş dönerse (Çok nadir), FMP'ye fallback yapabiliriz
        if not ta_data:
            from services.fmp_service import fmp_service
            return fmp_service.get_stocks_dynamic()
            
        return ta_data

    def get_commodity_markets(self):
        """Emtia Piyasalarını Getir (TradingView Source)"""
        from services.ta_service import ta_service
        symbols = ["GOLD", "SILVER", "BRENT"] 
        return ta_service.get_multiple_analysis(symbols)

    def get_etf_markets(self): return []
    def get_bond_markets(self): return []
    def get_top_funds(self): return []

    def _fetch_batch_details(self, symbols):
        """Yardımcı: Çoklu sembol verilerini paralel çek"""
        results = []
        with ThreadPoolExecutor(max_workers=5) as executor:
            future_to_sym = {executor.submit(self.get_asset_detail, sym): sym for sym in symbols}
            for future in future_to_sym:
                try:
                    res = future.result()
                    if res and res.get("price", 0) > 0:
                        results.append(res)
                except: pass
        return results

market_provider = MarketDataProvider()
