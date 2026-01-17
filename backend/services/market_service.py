import re
import requests
import time
from concurrent.futures import ThreadPoolExecutor
from utils.cache import cache
from utils.network import SafeRequest
from services.twelve_data_service import twelve_data_service

# --- PRO GÜNCELLEME SIKLIĞI (SANİYE) ---
TTL_MARKET = 60
# --------------------------------------

DATE_FMT_TR = '%d/%m/%Y'

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
                        except Exception:
                            pass

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
        except Exception:
            pass
        return None

    # --- Diğer metodlar (Şablon Gereği) ---
    def get_calendar(self, country_code: str = "ALL"):
        """
        EKONOMİK TAKVİM (DB): 
        Veritabanından (SQLite) manuel yüklenmiş veya kaydedilmiş verileri döner.
        """
        from database import get_db_connection
        from datetime import datetime, timezone, timedelta
        
        try:
            conn = get_db_connection()
            cursor = conn.cursor()
            
            # GMT+3 bazında şu anki zamanı al
            tz_tr = timezone(timedelta(hours=3))
            now_tr = datetime.now(tz_tr)
            # Günün başından itibaren getir (00:00:00)
            start_of_day = now_tr.replace(hour=0, minute=0, second=0, microsecond=0)
            now_str = start_of_day.strftime('%Y-%m-%d %H:%M:%S')
            
            # Dinamik Sorgu Oluşturma
            query = "SELECT * FROM calendar_events WHERE date_time >= ?"
            params = [now_str]

            if country_code and country_code.upper() != "ALL":
                # Ülke kodlarını ID'lere eşle
                id_map = {
                    "TR": [63, 32],
                    "US": [5],
                    "USA": [5],
                    "EU": [72],
                    "GBP": [12],
                    "GB": [12],
                    "DE": [4, 17],
                    "CA": [6],
                    "JP": [37],
                    "AU": [7, 25],
                    "NZ": [35],
                    "CH": [110, 39, 36]
                }
                target_ids = id_map.get(country_code.upper())
                if target_ids:
                    placeholders = ",".join(["?"] * len(target_ids))
                    query += f" AND country_id IN ({placeholders})"
                    params.extend(target_ids)
            
            query += " ORDER BY date_time ASC LIMIT 100"
            cursor.execute(query, tuple(params))
            rows = cursor.fetchall()
            conn.close()
            
            formatted = []
            months_tr = ["Ocak", "Şubat", "Mart", "Nisan", "Mayıs", "Haziran", 
                       "Temmuz", "Ağustos", "Eylül", "Ekim", "Kasım", "Aralık"]
            
            flag_map = {
                5: "us",     # USA
                63: "tr",    # Turkey
                32: "tr",    # Turkey (alt)
                72: "eu",    # Euro Zone
                12: "gb",    # UK (GBP)
                4: "de",     # Germany (DEM)
                6: "ca",     # Canada
                37: "jp",    # Japan
                7: "au",     # Australia
                35: "nz",    # New Zealand
                110: "ch",   # Switzerland
                39: "ch",    # Switzerland (alt)
                36: "ch",    # Switzerland (alt)
                51: "cn",    # China
                160: "in",   # India
                14: "in",    # India (alt)
                17: "de",    # Germany (Alt)
                25: "au",    # Australia (Alt)
                10: "it",    # Italy
                22: "fr",    # France
                26: "es",    # Spain
                21: "nl",    # Netherlands
                56: "ru"     # Russia
            }

            for row in rows:
                dt = datetime.fromisoformat(row["date_time"])
                formatted_date = f"{dt.day} {months_tr[dt.month-1]}"
                
                c_id = row["country_id"]
                flag_code = flag_map.get(c_id, "us")
                flag_url = f"https://flagcdn.com/w40/{flag_code}.png"
                if flag_code == "eu":
                    flag_url = "https://flagcdn.com/w40/eu.png"

                formatted.append({
                    "id": row["id"],
                    "date": formatted_date,
                    "time": dt.strftime('%H:%M'),
                    "title": row["title"],
                    "impact": row["impact"],
                    "actual": row["actual"],
                    "forecast": row["forecast"],
                    "previous": row["previous"],
                    "unit": row["unit"],
                    "country_id": c_id,
                    "flag_url": flag_url,
                    "currency": row["currency"]
                })
            
            return formatted
        except Exception as e:
            print(f"Calendar DB Error: {e}")
            return []

    def save_calendar_events(self, events: list):
        """
        Dışarıdan (JSON) gelen takvim verilerini DB'ye kaydeder.
        """
        from database import get_db_connection
        from datetime import datetime
        
        try:
            conn = get_db_connection()
            cursor = conn.cursor()
            
            # Mevcut eski (gelecek olmayan) verileri isteğe bağlı temizleyebiliriz
            # cursor.execute("DELETE FROM calendar_events") 

            for ev in events:
                # Kullanıcının JSON formatına göre parse et (Örn: "2026-01-14 16:30")
                dt_str = ev.get("date_time") or datetime.now().strftime('%Y-%m-%d %H:%M:%S')
                
                cursor.execute("""
                    INSERT INTO calendar_events 
                    (event_id, date_time, country_id, currency, title, impact, actual, forecast, previous, unit)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """, (
                    str(ev.get("event_id", "")),
                    dt_str,
                    ev.get("country_id", 0),
                    ev.get("currency", ""),
                    ev.get("short_name") or ev.get("title") or "Olay",
                    ev.get("importance") or ev.get("impact") or "Medium",
                    ev.get("actual", "-"),
                    ev.get("forecast", "-"),
                    ev.get("previous", "-"),
                    ev.get("unit", "")
                ))
            
            conn.commit()
            conn.close()
            return True
        except Exception as e:
            print(f"Error saving events: {e}")
            return False
    
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
            end_date = datetime.now().strftime(DATE_FMT_TR)
            days_back = 30
            if period == "3mo": days_back = 90
            elif period == "1y": days_back = 365
            elif period == "5y": days_back = 365 * 5
            
            start_date = (datetime.now() - timedelta(days=days_back)).strftime(DATE_FMT_TR)

            df = None
            # Hisse Senedi
            if ".IS" in symbol or symbol in ["THYAO", "GARAN", "AKBNK", "EREGL"]:
                clean = symbol.replace(".IS", "")
                df = investpy.get_stock_historical_data(stock=clean, country='turkey', from_date=start_date, to_date=end_date)
            # TEFAS Fonları (Robust Search)
            elif self._is_tefas_fund(symbol):
                df = self._fetch_fund_from_investpy(symbol, start_date, end_date)
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
                 except Exception:
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
        except Exception:
            pass
            
        return []

    def get_asset_detail(self, symbol):
        """
        ULTIMATE AGGREGATOR: Fmp (Detay) > Yahoo (Detay) > TradingView (Fiyat/Stats)
        """
        # 0. TEFAS Fon Kontrolü
        if self._is_tefas_fund(symbol):
            tefas_data = self._get_tefas_data(symbol)
            if tefas_data: return tefas_data
            
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
        except Exception:
            pass

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

    def _fetch_tefas_direct(self, symbol, start_date=None):
        """
        TEFAS Resmi Sitesinden Direkt Veri Çekme (Libraryless Fallback)
        Endpoint: https://www.tefas.gov.tr/api/DB/BindHistoryInfo
        """
        try:
            url = "https://www.tefas.gov.tr/api/DB/BindHistoryInfo"
            
            # Tarih formatı: dd.mm.yyyy olmalı
            # start_date genelde yyyy-mm-dd geliyor
            from datetime import datetime
            
            d_start = datetime.now()
            if start_date:
                try:
                    # Gelen format yyyy-mm-dd ise
                    d_start = datetime.strptime(start_date, "%Y-%m-%d")
                except:
                    # Belki dd/mm/yyyy geliyordur (DATE_FMT_TR)
                    try:
                        d_start = datetime.strptime(start_date, DATE_FMT_TR)
                    except:
                        pass
                        
            # Bitis bugun
            d_end = datetime.now()
            
            payload = {
                "fontip": "YAT",
                "sfontip": "",
                "bastarih": d_start.strftime("%d.%m.%Y"),
                "bittarih": d_end.strftime("%d.%m.%Y"),
                "fonkod": symbol.upper()
            }
            
            headers = {
                "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8",
                "Referer": "https://www.tefas.gov.tr/TarihselVeriler.aspx",
                "Origin": "https://www.tefas.gov.tr",
                "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
                "X-Requested-With": "XMLHttpRequest"
            }
            
            resp = requests.post(url, data=payload, headers=headers, timeout=10)
            if resp.status_code == 200:
                data = resp.json()
                # Data: {"data": [...]}
                if "data" in data and len(data["data"]) > 0:
                     import pandas as pd
                     rows = data["data"]
                     # columns: TARIH, FIYAT, KISI_SAYISI etc.
                     df = pd.DataFrame(rows)
                     # Tarih parse
                     df['date'] = pd.to_datetime(df['TARIH'], format='%d.%m.%Y', errors='coerce') # unix timestamp gelebilir mi? genelde integer
                     # Aslinda TARIH unix timestamp (ms) olarak geliyor olabilir: /Date(1705449600000)/
                     # Veya string "17.01.2024"
                     
                     # Genelde TEFAS API unix timestamp döner: /Date(1641254400000)/
                     # Bunu basitce handle edelim
                     if df['TARIH'].astype(str).str.contains("/Date").any():
                         # Regex ile timestamp al
                         df['date'] = df['TARIH'].astype(str).str.extract(r'(\d+)').astype(float) / 1000
                         df['date'] = pd.to_datetime(df['date'], unit='s')
                     
                     df.set_index('date', inplace=True)
                     df.rename(columns={'FIYAT': 'Close'}, inplace=True)
                     
                     # Fiyat "Close" string olabilir ? "3,14" gibi?
                     # API genelde float doner ama bazen string de olabilir.
                     
                     return df
                     
        except Exception as e:
            print(f"Direct TEFAS Fetch Error ({symbol}): {e}")
            
        return None

    def _fetch_from_tefas_crawler(self, symbol, start_date=None):
        """Fallback: tefas-crawler kütüphanesi ile çekim"""
        # 0. Önce kendi direkt metodumuzu deneyelim (Daha kontrollü)
        df_direct = self._fetch_tefas_direct(symbol, start_date)
        if df_direct is not None:
             return df_direct

        try:
             from tefas import Crawler
             import pandas as pd
             from datetime import datetime, timedelta
             
             crawler = Crawler()
             
             if not start_date:
                 # Son 30 gün
                 start_date = (datetime.now() - timedelta(days=30)).strftime("%Y-%m-%d")
             else:
                 # dd/mm/yyyy -> yyyy-mm-dd format dönüşümü gerekebilir
                 # Gelen format genelde dd/mm/yyyy
                 try:
                    d = datetime.strptime(start_date, DATE_FMT_TR)
                    start_date = d.strftime("%Y-%m-%d")
                 except ValueError:
                    pass # Zaten uygun olabilir

             # Crawler genelde tüm fonları çeker veya spesifik. 
             # tefas-crawler kütüphanesi 'fetch' metodu ile çalışır.
             # Örnek: crawler.fetch(start="2023-01-01", end="2023-01-05", name="AFT", columns=["code", "date", "price"])
             
             # Sadece ilgili fonu çekmek için
             result = crawler.fetch(start=start_date, name=symbol, columns=["code", "date", "price"])
             if result is not None and not result.empty:
                 # Sütun isimlerini standardize et (investpy return formatına benzet)
                 # investpy: Date (Index), Open, High, Low, Close, Currency
                 # tefas-crawler: code, date, price
                 
                 df = result.copy()
                 df['date'] = pd.to_datetime(df['date'])
                 df.set_index('date', inplace=True)
                 df.rename(columns={'price': 'Close'}, inplace=True)
                 df['Open'] = df['Close']
                 df['High'] = df['Close']
                 df['Low'] = df['Close']
                 return df
                 
        except Exception as e:
            # print(f"Tefas Crawler Error ({symbol}): {e}")
            pass
        return None

    def _fetch_fund_from_investpy(self, symbol, start_date=None, end_date=None):
        """Yardımcı: investpy veya tefas-crawler üzerinden fon verisi çekimi."""
        # 0. Önce tefas-crawler dene (Daha resmi ve stabil olabilir sunucularda)
        df_crawler = self._fetch_from_tefas_crawler(symbol, start_date)
        if df_crawler is not None:
             return df_crawler

        # 1. Fallback: Investpy
        try:
            import investpy
            from datetime import datetime, timedelta
            
            # ... investpy search_quotes ...
            try:
                search_results = investpy.search_quotes(text=symbol, products=['funds'], countries=['turkey'], n_results=1)
                if search_results:
                    if not start_date or not end_date:
                        end_date = datetime.now().strftime(DATE_FMT_TR)
                        start_date = (datetime.now() - timedelta(days=7)).strftime(DATE_FMT_TR)
                    df = search_results.retrieve_historical_data(from_date=start_date, to_date=end_date)
                    if df is not None and not df.empty:
                        return df
            except Exception:
                pass

            # ... investpy search_funds ...
            search_res = investpy.search_funds(by='symbol', value=symbol)
            if search_res is not None and not search_res.empty:
                tr_funds = search_res[search_res['country'] == 'turkey']
                if not tr_funds.empty:
                    full_name = tr_funds.iloc[0]['name']
                    if not start_date or not end_date:
                        end_date = datetime.now().strftime(DATE_FMT_TR)
                        start_date = (datetime.now() - timedelta(days=7)).strftime(DATE_FMT_TR)
                    return investpy.get_fund_historical_data(fund=full_name, country='turkey', from_date=start_date, to_date=end_date)
            
        except Exception as e:
            print(f"InvestPy/Total Failure ({symbol}): {e}")
            
        return None

    def _get_tefas_data(self, symbol):
        """TEFAS Fon Fiyatı Çekme (Robust)"""
        # Sadece son 7 günü çekmek yeterli (Fiyat + Günlük Değişim için)
        from datetime import datetime, timedelta
        start_date_limit = (datetime.now() - timedelta(days=7)).strftime(DATE_FMT_TR)
        
        df = self._fetch_fund_from_investpy(symbol, start_date=start_date_limit)
        
        if df is not None and not df.empty:
            last_row = df.iloc[-1]
            ret_rate = 0.0
            if len(df) >= 2:
                prev_close = float(df.iloc[-2]['Close'])
                last_close = float(df.iloc[-1]['Close'])
                if prev_close > 0:
                    ret_rate = ((last_close - prev_close) / prev_close) * 100
            
            return {
                "code": symbol,
                "symbol": symbol,
                "title": f"{symbol} Yatırım Fonu",
                "name": f"{symbol} Fonu",
                "type": "Yatırım Fonu (TEFAS)",
                "price": float(last_row['Close']),
                "daily_return": round(ret_rate, 2),
                "change_percent": round(ret_rate, 2),
                "description": "TEFAS Yatırım Fonu",
                "source": "Investpy/Robust"
            }
        return None

    def _is_tefas_fund(self, symbol):
        # Cache'de fon listesi yoksa yüklemeyi dene
        cache_key = "tefas_fund_list"
        cached_list = cache.get(cache_key)
        
        if not cached_list:
            try:
                import investpy
                # Türkiye'deki tüm fonları çek
                df_funds = investpy.get_funds(country='turkey')
                if df_funds is not None and not df_funds.empty:
                    cached_list = set(df_funds['symbol'].str.upper().tolist())
                    cache.set(cache_key, cached_list, ttl_seconds=86400)
            except Exception as e:
                print(f"TEFAS List Load Error: {e}")
                # Fallback: Hardcoded liste
                cached_list = {
                    "TCD", "AFT", "YAY", "TTE", "IPB", "AES", "IDH", "KZL", "IPJ", 
                    "KUB", "TI3", "KRS", "PPF", "HKH", "AYA", "MAC", "GMR", "TCA", 
                    "ZJ1", "ZJ2", "ZJ3", "ZJ4", "IIH", "BUY", "GSP", "HMB", "MPK"
                }

        if not cached_list:
             return symbol in ["TCD", "AFT", "YAY", "TTE", "IPB", "AES"]

        return symbol in cached_list

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
        Döviz Listesi: TradingView (Anlık) + ExchangeRate-API (Hata Payı Filler)
        """
        symbols = ["USD", "EUR", "GBP", "CHF", "JPY", "CAD", "AUD", "DKK", "SEK", "NOK", "SAR"]
        
        # 1. TradingView'dan anlık çekmeyi dene
        from services.ta_service import ta_service
        ta_results = ta_service.get_multiple_analysis(symbols)
        
        # 0 gelen veya eksik olan var mı kontrol et
        has_zeros = any(item.get("price", 0) <= 0 for item in ta_results) if ta_results else True
        
        if not has_zeros and len(ta_results) == len(symbols):
            return ta_results

        # 2. Eğer eksik varsa veya bazıları 0 ise ExchangeRate-API ile doldur
        try:
            from services.exchange_api_service import exchange_api_service
            api_rates = exchange_api_service.get_try_rates()
            
            if not ta_results: return api_rates or []
            
            api_map = {item["symbol"]: item for item in api_rates}
            final_results = []
            
            processed_symbols = set()
            for item in ta_results:
                sym = item["symbol"]
                if item.get("price", 0) <= 0 and sym in api_map:
                    final_results.append(api_map[sym])
                else:
                    final_results.append(item)
                processed_symbols.add(sym)
            
            for sym in symbols:
                if sym not in processed_symbols and sym in api_map:
                    final_results.append(api_map[sym])
                    
            return final_results
        except Exception as e:
            print(f"Currency fallback error: {e}")
            return ta_results or []

    def get_stock_markets(self):
        """Popüler Hisse Senetlerini Getir (TradingView Source)"""
        from services.ta_service import ta_service
        # Bölgesel Listeler
        tr_stocks = ["THYAO.IS", "GARAN.IS", "AKBNK.IS", "EREGL.IS", "ASELS.IS", "BIMAS.IS", 
                     "TUPRS.IS", "KCHOL.IS", "SISE.IS", "SAHOL.IS", "PETKM.IS", "FROTO.IS", "TOASO.IS", "TCELL.IS"]
        us_stocks = ["AAPL", "TSLA", "MSFT", "AMZN", "GOOGL", "NVDA", "META", "NFLX", "AMD", 
                     "INTC", "KO", "PEP", "MCD", "V", "MA", "JPM", "DIS", "BRK.B"]
        de_stocks = ["SAP", "SIE", "ALV", "DTE", "BMW", "VOW3", "BAS", "AIR", "DDAIF"]
        uk_stocks = ["SHEL", "HSBA", "AZN", "ULVR", "BP.", "BARC", "VOD", "LLOY", "NG."]
        
        all_symbols = tr_stocks + us_stocks + de_stocks + uk_stocks
        
        # TA servisinden çek
        ta_data = ta_service.get_multiple_analysis(all_symbols)
        
        # 2. Twelve Data ile US Hisselerini Güncelle (Anlık Veri)
        try:
            from services.twelve_data_service import twelve_data_service
            # Limit 8 credit/min olduğu için en önemli 8 US hissesini çekelim
            top_us = ["AAPL", "TSLA", "MSFT", "AMZN", "GOOGL", "NVDA", "META", "NFLX"]
            td_data = twelve_data_service.get_quotes(top_us)
            
            if td_data:
                for item in ta_data:
                    sym = item.get("symbol")
                    if sym in td_data:
                        # TA verisini Twelve Data anlık verisiyle güncelle
                        td_item = td_data[sym]
                        item["price"] = td_item["price"]
                        item["change_percent"] = td_item["change_percent"]
                        item["source"] = "TwelveData (Real-time)"
        except Exception as e:
            print(f"Twelve Data integration error: {e}")

        # Ülke Bilgisi Ekle
        if ta_data:
            # Clean symbols map for robust matching
            clean_tr = [s.replace(".IS", "") for s in tr_stocks]
            
            for item in ta_data:
                sym = item.get("symbol")
                # Basit eşleştirme (Clean symbol veya original)
                
                # TR Check
                if sym in tr_stocks or sym in clean_tr: 
                    item["country"] = "Turkey"
                # US Check
                elif sym in us_stocks: 
                    item["country"] = "USA"
                # DE Check
                elif sym in de_stocks: 
                    item["country"] = "Germany"
                # UK Check
                elif sym in uk_stocks: 
                    item["country"] = "UK"
                else: 
                    item["country"] = "Global"
                
        # Eğer TradingView boş dönerse (Çok nadir), FMP'ye fallback yapabiliriz
        if not ta_data:
            from services.fmp_service import fmp_service
            return fmp_service.get_stocks_dynamic()
            
        return ta_data

    def get_commodity_markets(self):
        """Emtia Piyasalarını Getir (TradingView Source)"""
        from services.ta_service import ta_service
        symbols = [
            "XAU/USD", "XAG/USD", "LCO/USD", "WTI/USD", "PLATINUM", "PALLADIUM", 
            "COPPER", "NATURAL_GAS", "CORN", "WHEAT", "SOYBEAN", 
            "COFFEE", "SUGAR", "COTTON"
        ] 
        # 1. TradingView Source (Primary)
        ta_data = ta_service.get_multiple_analysis(symbols)
        
        # 2. Twelve Data Fallback (For 0 or missing prices)
        has_zeros = any(item.get("price", 0) <= 0 for item in ta_data) if ta_data else True
        if has_zeros:
            missing = [s for s in symbols if not any(item["symbol"] == s and item.get("price", 0) > 0 for item in ta_data)]
            if missing:
                # Twelve Data free tier limit is 8 credits per minute.
                to_fetch = missing[:7] # Leave some buffer
                td_data = twelve_data_service.get_quotes(to_fetch)
                if td_data:
                    # Update results
                    for i, item in enumerate(ta_data):
                        sym = item["symbol"]
                        if sym in td_data and item.get("price", 0) <= 0:
                            ta_data[i] = td_data[sym]
                    
                    # Add completely missing ones
                    processed = [item["symbol"] for item in ta_data]
                    for sym, data in td_data.items():
                        if sym not in processed:
                            ta_data.append(data)

        return ta_data

    def get_etf_markets(self):
        """Popüler ETF'leri Getir (TradingView Source)"""
        from services.ta_service import ta_service
        symbols = ["SPY", "QQQ", "VOO", "GLD", "SLV", "VTI", "IVV", "ARKK"]
        return ta_service.get_multiple_analysis(symbols)

    def get_bond_markets(self):
        """Tahvil ve Bono Piyasasını Getir (TradingView Source)"""
        from services.ta_service import ta_service
        symbols = ["TLT", "BND", "AGG", "SHY", "IEF", "LQD", "HYG"]
        return ta_service.get_multiple_analysis(symbols)

    def get_top_funds(self):
        """Öne Çıkan TEFAS Fonlarını Getir (Dinamik)"""
        # OOM sorununu çözmek için listeyi en popüler 20 ile sınırlıyoruz.
        symbols = [
            # Popüler Değişken & Hisse
            "TCD", "AFT", "YAY", "TTE", "IPB", "AES", "IDH", "KZL", 
            "MAC", "GMR", "TCA", "ZJ1", "HMB", "MPK", "IIH", 
            # Kıymetli Maden & Döviz
            "KUB", "GSP", "HKH", "TI3", "DBH"
        ]
        
        # Batch olarak detaylarını çek
        results = self._fetch_batch_details(symbols)
        return results if results else []

    def _fetch_batch_details(self, symbols):
        """Yardımcı: Çoklu sembol verilerini paralel/seri çek"""
        results = []
        with ThreadPoolExecutor(max_workers=1) as executor:
            future_to_sym = {executor.submit(self.get_asset_detail, sym): sym for sym in symbols}
            for future in future_to_sym:
                try:
                    res = future.result()
                    if res and res.get("price", 0) > 0:
                        results.append(res)
                except Exception:
                    pass
        return results

market_provider = MarketDataProvider()
