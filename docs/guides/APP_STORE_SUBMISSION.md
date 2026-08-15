# MoneyPlan Pro — App Store gönderim paketi

Bu belge, MoneyPlan Pro 1.0 sürümünü App Store Connect'te göndermeden önce
kopyalanacak içerikleri ve son kalite kontrolünü bir arada tutar.

## Uygulama kimliği

| Alan | Değer |
| --- | --- |
| Uygulama adı | MoneyPlan Pro |
| Bundle ID | `pro.moneyplan.app` |
| Sürüm | `1.0.0` |
| Build | `8` |
| Birincil kategori | Finance |
| İkincil kategori | Education |
| Destek e-postası | trgy.ycl@gmail.com |
| Destek URL | https://moneyplan.pro/ |
| Gizlilik URL | https://moneyplan.pro/privacy.html |

## App Review notu

Aşağıdaki metni App Store Connect'teki **Notes** alanına yapıştırın:

> MoneyPlan Pro is a budgeting and financial-literacy app. It does not provide
> investment advice or guaranteed returns. Market data can be delayed and is
> shown for education and tracking. Crypto market data is provided by CoinGecko
> and is labelled in the app. Account creation is optional for exploring the
> app; users can create an account with email or Sign in with Apple to sync
> data. Users can permanently delete their account and associated cloud data
> from Profile > Delete Account and Data.

İnceleme için giriş gerekiyorsa, gerçek kullanıcı verisi içermeyen ayrı bir
demo hesabı oluşturun ve kullanıcı adı/şifreyi yalnızca **App Review
Information** alanına girin.

## Yüklenecek öğeler

- [ ] `docs/guides/STORE_LISTING.md` içindeki Türkçe metinler girildi.
- [ ] En az üç adet 6,9 inç PNG ekran görüntüsü yüklendi.
- [ ] Görsellerde gerçek kişisel veya finansal veri yok.
- [ ] Gizlilik ve destek URL'leri tarayıcıda açılıyor.
- [ ] `docs/guides/APP_STORE_PRIVACY.md` ile App Privacy cevapları eşleşiyor.
- [ ] Abonelik ürünlerinin inceleme görselleri ve açıklamaları eklendi.
- [ ] Export compliance sorusu `ITSAppUsesNonExemptEncryption = false` ile
  eşleşecek şekilde yanıtlandı.

## Gönderimden önce cihaz kontrolü

- [ ] İlk açılış, kayıt/giriş ve Apple ile giriş
- [ ] Gelir, gider ve düzenli işlem ekleme/düzenleme/silme
- [ ] Bütçe özeti ve birikim hedefleri
- [ ] Piyasalar: CoinGecko verisi, ticker, haberler ve ekonomik takvim
- [ ] İzleme listesi ve iPhone widget'ı
- [ ] Bildirim izni ver/reddet ve ayarlardan değiştirme
- [ ] Hesap ve veri silme
- [ ] Abonelik satın alma ve geri yükleme (TestFlight sandbox)

## Yayın öncesi kural

`live_market_data`, `gmail_import` ve `ai_features` App Store metninde veya
ekran görüntülerinde ancak o sürümde gerçekten etkin ve denetlenmişse yer
almalıdır. 1.0 için etkin olan piyasa yüzeyleri ticker, finans haberleri,
ekonomik takvim ve CoinGecko kripto verileridir.
