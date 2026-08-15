# MoneyPlan Pro

MoneyPlan Pro, Türkiye odaklı bütçe takibi, tasarruf alışkanlığı ve finansal
okuryazarlık uygulamasıdır. Amaç; gelir-giderini görünür kılmak, hedeflerine
ilerlemeyi kolaylaştırmak ve kullanıcıların piyasaları yatırım tavsiyesi
almadan daha bilinçli takip etmesine yardımcı olmaktır.

## Uygulama kapsamı

- Gelir, gider, düzenli işlem, banka hesabı ve kredi kartı takibi
- Aylık/yıllık bütçe görünümü ile birikim hedefleri
- Portföy kaydı, maliyet ve kâr/zarar görünümü
- Kripto piyasaları ve geçmiş fiyat grafikleri (CoinGecko, yaklaşık 15 dakika
  önbellek)
- Onaylı kaynaklardan piyasa özeti ticker'ı, finans haberleri ve ekonomik
  takvim
- Bileşik faiz, kredi, emeklilik ve gelecek senaryosu araçları
- İsteğe bağlı bildirimler, iPhone Ana Ekran widget'ları ve Apple ile giriş

MoneyPlan Pro finansal eğitim ve takip içindir. Piyasa verileri gecikebilir;
uygulama içeriği yatırım tavsiyesi ya da getiri garantisi değildir.

## Teknoloji

- Flutter / Dart
- Supabase: kimlik doğrulama ve kullanıcı verileri
- FastAPI: MoneyPlan Pro middleware API
- Hugging Face Spaces: API ve yönetim paneli barındırma
- CoinGecko: kripto verileri

## Geliştirme kurulumu

```bash
flutter pub get
flutter run
```

Uygulamanın Supabase ve backend adresleri `lib/core/config/env_config.dart`
ile yönetilir. Gizli anahtarları kaynak koda veya mobil pakete koymayın;
backend anahtarlarını yönetim panelindeki App Settings ya da dağıtım secret'ları
ile yönetin.

## Yayın kaynakları

- [Mağaza metinleri](docs/guides/STORE_LISTING.md)
- [App Store ekran görüntüsü planı](docs/guides/APP_STORE_SCREENSHOTS.md)
- [App Store gönderim paketi](docs/guides/APP_STORE_SUBMISSION.md)
- [Google Play gönderim paketi](docs/guides/GOOGLE_PLAY_SUBMISSION.md)
- [Gizlilik envanteri](docs/guides/APP_STORE_PRIVACY.md)
- [Veri kaynağı ve lisans notları](docs/guides/DATA_LICENSING.md)
- [Ürün TODO listesi](docs/guides/TODO.md)

## Destek ve yasal bağlantılar

- Web: [moneyplan.pro](https://moneyplan.pro/)
- Gizlilik: [moneyplan.pro/privacy.html](https://moneyplan.pro/privacy.html)
- Koşullar: [moneyplan.pro/terms.html](https://moneyplan.pro/terms.html)
- Destek: trgy.ycl@gmail.com
