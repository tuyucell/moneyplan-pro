# MoneyPlan Pro — App Store Ekran Görüntüsü Planı

## Teknik gereksinimler

- Ana iPhone seti: iPhone 17 Pro Max simülatöründe dikey `1320 × 2868` PNG.
- iPhone 17 Pro referans seti: dikey `1206 × 2622` PNG. Bu ölçü App Store
  Connect tarafından 6,3 inç ekran için kabul edilir; ancak mağaza sayfası için
  ana set olarak 6,9 inç görselleri yüklemek tercih edilir.
- Apple, uygulama başına 1–10 ekran görüntüsüne izin verir.
- Görseller `.png`, `.jpg` veya `.jpeg` olmalı; alfa kanalı ya da şeffaflık
  içermemelidir.
- Güncel kurallar: [Apple Screenshot Specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/)

## Yayın seti

| Sıra | Ekran | Ana mesaj | Durum |
| --- | --- | --- | --- |
| 1 | Onboarding | Paranı tek yerden yönet | Hazır |
| 2 | Aylık özet | Gelirini, giderini ve kalan bütçeni gör | Hazır |
| 3 | Birikim planları | Birikim, BES ve hayat sigortası planlarını izle | Hazır |
| 4 | Araçlar | Bütçe ve finans hesaplayıcılarını kullan | Hazır |

İlk 1.0 gönderim seti yukarıdaki dört görseldir. İzleme listesi boş durumda
olduğu, piyasa/haber/takvim özellikleri ise lisans doğrulaması beklediği için bu
ekranlar mevcut mağaza setine dahil edilmez.

## İçerik kuralları

- Tüm hesap, bakiye, işlem ve portföy verileri kurgusal demo verisi olmalıdır.
- Gerçek e-posta, telefon, banka, kimlik veya API anahtarı görünmemelidir.
- `live_market_data`, `gmail_import` ve `ai_features` kapalıyken bu özellikler mağaza görsellerinde vaat edilmemelidir.
- Görseller uygulamanın mevcut sürümünü doğru temsil etmelidir.
- Finansal kazanç garantisi, yatırım tavsiyesi veya doğrulanmamış performans iddiası kullanılmamalıdır.

## Dosya düzeni

Hazır görseller `docs/app-store/screenshots/iphone-6.9/` altında sıra numarasıyla tutulur.

- `01-manage-your-money.png` (mevcut onboarding)
- `02-monthly-overview.png` (mevcut aylık özet)
- `03-savings-plans.jpg` (anonim kurgusal BES/hayat planları)
- `04-financial-tools.jpg`

Lisansı doğrulanmamış piyasa özelliklerini gösteren eski yakalamalar yanlışlıkla
yüklenmemesi için `docs/app-store/screenshots/archive/` altına taşındı.

6,3 inç QA/referans görselleri `docs/app-store/screenshots/iphone-6.3/`
altında tutulur. İlk gerçek yakalama:

- `06-financial-tools.jpg` — iPhone 17 Pro, `1206 × 2622`, opak JPEG
- Piyasa görseli lisans doğrulanana kadar arşivdedir ve yüklenmemelidir.

Kurgusal simülatör işlemleri gerektiğinde
`tool/seed_app_store_demo.dart` ile yeniden üretilebilir. Araç güvenlik için
yalnızca CoreSimulator içindeki bir uygulama `Documents` dizinine yazmayı kabul
eder.

## Yakalama akışı

1. Xcode’da `iPhone 17 Pro Max` simülatörünü seç ve uygulamayı başlat.
2. Her görselden önce demo verisini kontrol et; gerçek kişi, hesap, e-posta ve
   bakiye görünmemeli.
3. Simülatörden `File > Save Screen` kullan veya aşağıdaki komutu çalıştır:

   ```bash
   xcrun simctl io booted screenshot \
     docs/app-store/screenshots/iphone-6.9/03-markets.png
   ```

4. Son dosyayı `sips -g pixelWidth -g pixelHeight <dosya>` ile doğrula.
5. App Store Connect'e aynı cihaz sınıfından, tutarlı dil ve tema kullanan
   3–6 görsel yükle.

Mevcut iPhone 17 Pro referans yakalamaları `1206 × 2622` ölçüsündedir ve 6,3
inç QA seti için uygundur. Nihai mağaza seti yine de Pro Max simülatöründen
`1320 × 2868` olarak yakalanmalıdır.
