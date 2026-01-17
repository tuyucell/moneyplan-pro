from tradingview_ta import TA_Handler, Interval, Exchange
from utils.cache import cache

class TradingViewService:
    def __init__(self):
        # 15 dakikalık cache (Analizler anlık değişmez)
        self.TTL = 900 

    def get_multiple_analysis(self, symbols):
        """Çoklu Sembol Analizi (Liste Görünümü İçin)"""
    def get_multiple_analysis(self, symbols):
        """
        Optimize Edilmiş Çoklu Analiz (Batch Request)
        Sembolleri screener'larına göre gruplayıp kütüphanenin 'get_multiple_analysis' fonksiyonunu kullanır.
        """
        from tradingview_ta import get_multiple_analysis
        
        # 1. Sembolleri Grupla
        groups = {
            "turkey": [],
            "america": [],
            "crypto": [],
            "forex": [],
            "cfd": []
        }
        
        # Orijinal sembol eşleşmesi için (Clean -> Original)
        symbol_map = {} 
        
        for sym in symbols:
            # Temizleme ve Sınıflandırma
            clean, screener, exchange = self._classify_symbol(sym)
            if screener in groups:
                # Kütüphane EXCHANGE:SYMBOL formatı istiyor (örn: NASDAQ:AAPL)
                formatted_sym = f"{exchange}:{clean}"
                groups[screener].append(formatted_sym)
                
                # Geri dönüş map'i: Gelen "NASDAQ:AAPL" anahtarını orijinal "AAPL" e çevirecek
                symbol_map[formatted_sym] = sym 
        
        results = []
        
        # 2. Her Grup İçin Batch İstek At
        for screener, sym_list in groups.items():
            if not sym_list: continue
            
            try:
                # Kütüphanenin toplu çekme fonksiyonu
                # Not: Exchange parametresi toplu çekimde opsiyoneldir veya screener yeterlidir.
                batch_res = get_multiple_analysis(
                    screener=screener,
                    interval=Interval.INTERVAL_1_DAY,
                    symbols=sym_list
                )
                
                # batch_res bir dictionary döner: {'THYAO': Analysis, 'GARAN': Analysis}
                if batch_res:
                    for clean_sym, analysis in batch_res.items():
                        orig_sym = symbol_map.get(clean_sym, clean_sym)
                        if analysis:
                            formatted = self._format_analysis(orig_sym, analysis)
                            if formatted: results.append(formatted)
                        else:
                            # Fallback if analysis is empty
                            results.append({
                                "symbol": orig_sym,
                                "name": orig_sym,
                                "price": 0.0,
                                "change_percent": 0.0,
                                "recommendation": "NEUTRAL",
                                "volume": 0,
                                "market_cap": 0,
                                "logo_url": ""
                            })
                            
            except Exception as e:
                print(f"TA Batch Error ({screener}): {e}")

        # 3. Sıralama (Hacim)
        results.sort(key=lambda x: x["volume"], reverse=True)
        return results

    def _classify_symbol(self, symbol):
        """Sembolü analiz eder: (CleanSymbol, Screener, Exchange)"""
        clean = symbol.replace(".IS", "").replace("USDT", "")
        screener = "turkey"
        exchange = "BIST"
        
        if "BTC" in symbol or "ETH" in symbol or "USDT" in symbol:
            screener = "crypto"
            exchange = "BINANCE"
            if not symbol.endswith("USDT") and symbol not in ["USDT"]:
                clean = f"{clean}USDT"
            else:
                clean = symbol
        
        elif symbol in ["AAPL", "TSLA", "MSFT", "AMZN", "GOOGL", "NVDA", "META"]:
            screener = "america"
            exchange = "NASDAQ"
            
        elif symbol in ["USD", "EUR", "GBP", "CHF", "JPY", "CAD", "AUD", "DKK", "SEK", "NOK", "SAR"]:
            screener = "forex" 
            exchange = "FX_IDC"
            clean = f"{symbol}TRY" # USD -> USDTRY, JPY -> JPYTRY
            
        elif symbol in ["GOLD", "SILVER", "BRENT", "UKOIL", "PLATINUM", "PALLADIUM", "COPPER", "NG1!", "CORN", "WHEAT", "SOYBEAN", "GC=F", "SI=F"]:
             screener = "cfd" # Çoğu emtia TVC veya CFD borsalarındadır.
             exchange = "TVC"
             
             if symbol in ["GOLD", "GC=F"]: clean = "GOLD"
             elif symbol in ["SILVER", "SI=F"]: clean = "SILVER"
             elif symbol in ["BRENT", "UKOIL"]: clean = "UKOIL"
             elif symbol == "NG1!": clean = "NG1!" # Natural Gas
             elif symbol == "COPPER": clean = "HG1!" # Copper Futures genelde HG1! dir veya TVC:COPPER
             elif symbol in ["CORN", "WHEAT", "SOYBEAN"]:
                 screener = "america" # Tarım ürünleri genelde CBOT (America)
                 exchange = "CBOT"
                 # ZC1! (Corn), ZW1! (Wheat), ZS1! (Soybean) vadeli kodları daha garantidir
                 if symbol == "CORN": clean = "ZC1!"
                 if symbol == "WHEAT": clean = "ZW1!"
                 if symbol == "SOYBEAN": clean = "ZS1!"

        return clean, screener, exchange

    def _format_analysis(self, symbol, analysis):
        """Analysis objesini dict'e çevirir"""
        try:
            # Extract indicators safely
            indicators = analysis.indicators
            price = float(indicators.get("close") or 0.0)
            change = float(indicators.get("change") or 0.0)
            
            # Simple heuristic for change_percent if not directly available as "change_abs"
            # TradingView 'change' is usually the percentage change in many screeners
            
            return {
                "symbol": symbol,
                "name": symbol, 
                "price": price,
                "change_percent": round(change, 2), # % Change
                "recommendation": (analysis.summary.get("RECOMMENDATION") or "NEUTRAL").upper(),
                "volume": float(indicators.get("volume") or 0.0),
                "market_cap": 0,
                "logo_url": f"https://s3-symbol-logo.tradingview.com/{symbol.lower()}.svg" 
            }
        except Exception as e:
            # print(f"Format Error: {e}")
            return None

    def get_analysis(self, symbol, exchange=None):
        """Tekli Analiz (Eski Yöntem - Detay Sayfası İçin)"""
        cache_key = f"ta_analysis_v5_{symbol}"
        cached = cache.get(cache_key)
        if cached: return cached

        try:
            clean, screener, final_exchange = self._classify_symbol(symbol)
            
            handler = TA_Handler(
                symbol=clean,
                screener=screener,
                exchange=final_exchange,
                interval=Interval.INTERVAL_1_DAY
            )
            
            analysis = handler.get_analysis()
            
            result = {
                "symbol": symbol,
                "price": analysis.indicators.get("close"),
                "open": analysis.indicators.get("open"),
                "high": analysis.indicators.get("high"),
                "low": analysis.indicators.get("low"),
                "volume": analysis.indicators.get("volume"),
                "change": analysis.indicators.get("change"),
                "recommendation": analysis.summary.get("RECOMMENDATION"),
                "score": {
                    "buy": analysis.summary.get("BUY"),
                    "sell": analysis.summary.get("SELL"),
                    "neutral": analysis.summary.get("NEUTRAL")
                },
                "indicators": {
                    "rsi": analysis.indicators.get("RSI"),
                    "macd": analysis.indicators.get("MACD.macd"),
                    "ema20": analysis.indicators.get("EMA20"),
                },
                "timestamp": analysis.time.isoformat()
            }
            
            cache.set(cache_key, result, ttl_seconds=self.TTL)
            return result

        except Exception as e:
            # print(f"Tv Analysis Error ({symbol}): {e}") # Log kirliliği yapmasın
            return None

ta_service = TradingViewService()
