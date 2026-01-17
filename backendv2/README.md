# InvestGuide Backend API

Bu proje, Flutter uygulaması için bir aracı (middleware) API sunar. Yahoo Finance, TEFAS ve TCMB gibi kaynaklardan veri çekip REST API olarak sunar.

## Kurulum (Local veya Uzak Sunucu)

1. Python 3.9+ yüklü olduğundan emin olun.
2. Bağımlılıkları yükleyin:
   ```bash
   pip install -r requirements.txt
   ```

## Çalıştırma

Geliştirme modunda çalıştırmak için backend klasöründe şu komutu girin:

```bash
uvicorn main:app --reload
```

Sunucu `http://127.0.0.1:8000` adresinde çalışacaktır.
Documentation (Swagger UI): `http://127.0.0.1:8000/docs`

## Endpointler

- **GET /**: Sağlık kontrolü
- **GET /api/v1/market/summary**: Ana sayfa için özet veriler (Altın, Dolar, BTC)
- **GET /api/v1/funds/{code}**: TEFAS fon detay (Örn: TCD, MAC)
- **GET /api/v1/currencies/tcmb**: TCMB resmi kurları

## Notlar

- `services/market_service.py` içinde önbellekleme (caching) mekanizması vardır. Varsayılan olarak 60 saniye bekler.
- TEFAS servisi bazen yanıt vermeyebilir, bu durumda cache'deki son veriyi kullanmak veya hata dönmek üzere yapılandırılmıştır.
