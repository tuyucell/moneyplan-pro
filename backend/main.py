from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from services.market_service import market_provider
from services.crypto_service import crypto_service
from services.bes_service import bes_service
from services.bes_service import bes_service
from services.news_service import news_service
from services.macro_service import macro_service
from services.tcmb_service import tcmb_service

app = FastAPI(
    title="InvestGuide Middleware API",
    version="1.1.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
def health_check():
    return {"status": "active"}

@app.get("/api/v1/market/summary")
def get_market_summary():
    return market_provider.get_market_summary()

@app.get("/api/v1/market/history/{symbol}")
def get_market_history(symbol: str, period: str = "1mo", interval: str = "1d"):
    """
    GRAFİK VERİSİ: Dinamik yönlendirme (Crypto -> Binance, Stocks -> MarketProvider)
    """
    s_upper = symbol.upper()
    if s_upper.endswith("USDT") or s_upper in ["BTC", "ETH", "USDT", "SOL", "BNB", "XRP", "ZEC", "POL", "FDUSD", "DOGE"]:
        return crypto_service.get_history(symbol, period, interval)
        
    return market_provider.get_history(symbol, period, interval)

@app.get("/api/v1/market/detail/{symbol}")
def get_asset_detail(symbol: str):
    """
    DETAY VERİSİ: Dinamik yönlendirme (Crypto -> Binance, Stocks -> MarketProvider)
    """
    s_upper = symbol.upper()
    # Crypto Check
    if s_upper.endswith("USDT") or s_upper in ["BTC", "ETH", "USDT", "SOL", "BNB", "XRP", "ZEC", "POL", "FDUSD", "DOGE"]:
        return crypto_service.get_asset_detail(symbol)
    
    # Stocks, Forex, Gold -> MarketProvider (Yahoo)
    return market_provider.get_asset_detail(symbol)

@app.get("/api/v1/market/analysis/{symbol}")
def get_asset_analysis(symbol: str):
    """
    TEKNİK ANALİZ VERİSİ (TradingView)
    Al/Sat Sinyalleri, RSI, MACD, MA vb.
    """
    return market_provider.get_analysis(symbol)

@app.get("/api/v1/market/stocks")
def get_stock_markets():
    return market_provider.get_stock_markets()

@app.get("/api/v1/market/commodities")
def get_commodity_markets():
    return market_provider.get_commodity_markets()

@app.get("/api/v1/market/etfs")
def get_etf_markets():
    return market_provider.get_etf_markets()

@app.get("/api/v1/market/bonds")
def get_bond_markets():
    return market_provider.get_bond_markets()

@app.get("/api/v1/market/calendar")
def get_market_calendar():
    return market_provider.get_calendar()

@app.get("/api/v1/market/crypto")
def get_crypto_markets(limit: int = 50):
    return crypto_service.get_top_coins(limit)

@app.get("/api/v1/market/crypto/fear-greed")
def get_crypto_fear_greed():
    return crypto_service.get_fear_greed_index()

@app.get("/api/v1/funds/top")
def get_top_funds():
    return market_provider.get_top_funds()

@app.get("/api/v1/funds/bes/top")
def get_bes_funds():
    return bes_service.get_top_pension_funds()

@app.get("/api/v1/currencies/tcmb")
def get_tcmb_rates():
    return market_provider.get_tcmb_currencies()

@app.get("/api/v1/news")
def get_latest_news(limit: int = 20):
    return news_service.get_latest_news(limit)

@app.get("/api/v1/macro/{country_code}")
def get_macro_indicators(country_code: str):
    """
    Fetches macro-economic indicators (GDP, Inflation, etc.).
    Uses TCMB/TUIK data for 'TR', World Bank for others.
    """
    if country_code.upper() == "TR":
        # Türkiye için özel TCMB/TÜİK verisi
        tcmb_data = tcmb_service.get_macro_indicators()
        if tcmb_data:
            return {
                "country": "TR",
                "timestamp": tcmb_data.get("date"), # veya now
                "data": tcmb_data,
                "source": "TCMB & TÜİK (Güncel)"
            }
    
    # Diğer ülkeler veya TR fallback için World Bank
    return macro_service.get_country_indicators(country_code)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
