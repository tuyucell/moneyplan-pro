# MoneyPlan Pro — Google Play gönderim paketi

Bu paket, Android sürümünü önce **Internal testing**, ardından kapalı/açık
test ve production hattına almak için kullanılır.

## Kimlik ve sürüm

| Alan | Değer |
| --- | --- |
| Uygulama adı | MoneyPlan Pro |
| Android application ID | `pro.moneyplan.app` |
| Sürüm | `1.0.0` |
| İlk version code | `4` |
| Target SDK | `36` (debug pakette doğrulandı) |
| Kategori | Finance |
| Destek e-postası | trgy.ycl@gmail.com |
| Web sitesi | https://moneyplan.pro/ |
| Gizlilik politikası | https://moneyplan.pro/privacy.html |
| Hesap/veri silme | https://moneyplan.pro/privacy.html#deletion |

`applicationId`, Google Play'de ilk production yüklemesinden sonra
değiştirilemez. Bu nedenle ilk uygulama kaydı marka kimliğiyle eşleşen
`pro.moneyplan.app` olarak oluşturuldu.

## Teknik yayın kapısı

1. [x] Android upload keystore oluşturuldu. Dosya ve yerel imzalama
   özellikleri git dışında tutulur; keystore ile parolasını güvenli bir parola
   yöneticisine yedekleyin.
2. [x] `android/app/key.properties` yerel olarak yapılandırıldı.
3. [x] Üretim paketi oluşturuldu:

   ```bash
   flutter build appbundle --release
   ```

   Son doğrulanan AAB: `60.6 MB`, SHA-256
   `6481f3ade31e0495416e392d758c11af1fd12bac3f9a87c8dbdfec24fcec7867`.

4. [x] `build/app/outputs/bundle/release/app-release.aab` Internal testing
   taslağına yüklendi ve Google Play tarafından kabul edildi:
   - Sürüm: `4 (1.0.0)`
   - Minimum API: `24`
   - Target SDK: `36`
   - Yeni kurulum indirme boyutu: yaklaşık `21 MB`
   - Durum: Internal testing kanalında aktif; `MoneyPlan Pro Internal Testers`
     listesine yayımlandı.
5. [x] Pixel 7 Pro / Android 11 (API 30) emülatöründe temiz kurulum; onboarding,
   beş ana sekme, yatırım fonları, finansal takvim, Bitcoin detay/grafik ve Pro
   ekranı duman testi geçti. Android Pro ekranında `Google Play’de yakında`
   metni doğrulandı.

İlk upload key parmak izleri (Google OAuth Android istemcisi oluştururken
kullanılacak):

- SHA-1: `B9:68:06:62:AA:19:31:46:5A:E2:8E:9D:C8:DF:12:F6:B1:15:BF:6D`
- SHA-256: `D8:34:55:D0:44:6A:F0:FE:27:4D:98:69:DF:D3:7F:C0:C1:13:5C:C0:5E:F8:E2:7A:40:B6:70:02:D4:78:9D:A5`

Release Gradle görevi artık keystore yoksa başarısız olur; bu, yanlışlıkla
debug anahtarıyla bir production AAB yüklenmesini engeller.

Google Play, yeni uygulama ve güncellemeler için güncel Android target API
kuralına uyulmasını ister. Yüklemeden hemen önce oluşturulan AAB'nin
`targetSdkVersion` değerini Play Console ile kontrol edin; gereksinim değişirse
Flutter/Android SDK sürümünü güncelleyin.

## Mağaza metni

### Kısa açıklama (80 karakter)

Gelir, gider ve tasarrufunu takip et; finansal alışkanlıklarını geliştir.

### Tam açıklama

MoneyPlan Pro, bütçe takibini kolaylaştıran, tasarruf alışkanlığı kazandırmayı
ve piyasaları daha bilinçli takip etmeyi amaçlayan bir finansal eğitim
uygulamasıdır.

- Gelir, gider ve düzenli işlem takibi
- Aylık ve yıllık bütçe görünümü
- Birikim hedefleri, banka hesapları ve kredi kartları
- Portföy kaydı, maliyet ve kâr/zarar görünümü
- CoinGecko kaynaklı kripto fiyatları ve geçmiş grafikler
- Onaylı kaynaklardan piyasa özeti, finans haberleri ve ekonomik takvim
- Bileşik faiz, kredi, emeklilik ve gelecek senaryosu araçları
- Ana ekran widget'ları

MoneyPlan Pro finansal eğitim ve takip içindir. Piyasa verileri gecikebilir;
uygulama içeriği yatırım tavsiyesi ya da getiri garantisi değildir.

## Görsel seti

| Öğe | Durum |
| --- | --- |
| Uygulama simgesi | [app-icon.png](../google-play/app-icon.png), `512 × 512` opak PNG, hazır |
| Feature graphic | [feature-graphic.jpg](../google-play/feature-graphic.jpg), `1024 × 500`, opak JPEG, hazır |
| Telefon ekran görüntüleri | Gerçek Android emülatör/cihazdan en az 2; önerilen 4 adet `1080 × 1920` veya üzeri, hazırlanacak |

iPhone ekran görüntüleri Google Play'e yüklenmez. Android setinde şu dört
gerçek akış yakalanmalıdır: aylık bütçe özeti, birikim hedefi, Piyasalar ve
Araçlar. Görseller kişisel veri içermemeli, ekranın gerçek uygulama deneyimini
göstermeli ve şeffaflık içermemelidir.

**Feature graphic alt metni:** Mor degrade zemin üzerinde tasarruf hedefleri ve
büyümeyi simgeleyen cüzdan, hedef ve yükselen çizgi illüstrasyonu.

## Play Console kontrolleri

- [ ] App access: Giriş gerektiren akışlar için demo hesap verisi veya net
  inceleme talimatı girildi.
- [ ] Data safety: `APP_STORE_PRIVACY.md` envanteri, Android SDK'ları da
  kapsayacak şekilde doğrulandı.
- [ ] Data deletion: Uygulama içi silme akışı ve
  `https://moneyplan.pro/privacy.html#deletion` web bağlantısı girildi.
- [ ] Content rating ve target audience tamamlandı.
- [ ] Privacy policy URL açılıyor.
- [x] Internal testing AAB yüklendi ve Play paket doğrulamasından geçti.
- [x] `MoneyPlan Pro Internal Testers` listesi oluşturuldu ve ilk tester
  eklendi.
- [x] Sürüm `4 (1.0.0)` internal testing kanalına yayımlandı.
- [ ] Tester, katılım bağlantısındaki daveti kabul etti:
  `https://play.google.com/apps/internaltest/4701189161548833506`
- [ ] Google Play üzerinden dağıtılan paket gerçek Android cihazda kritik
  akışlarla test edildi.

Google Play önizlemesinde görülen yayın engeli olmayan uyarılar:

- Tester eklenmediği için sürüm henüz hiçbir kullanıcıya dağıtılamaz.
- R8/ProGuard kapalı olduğu için deobfuscation dosyası bulunmuyor. Mevcut
  sürüm obfuscation kullanmadığından bu uyarı beklenir; küçültme daha sonra
  açılırsa mapping dosyası da yüklenmelidir.

## Android'e özgü yayın engelleri

### Google ile giriş

- [x] Firebase Android uygulaması `pro.moneyplan.app` için kaydedildi ve
  güncel `google-services.json` dosyası projeye eklendi.
- [x] Google Auth Platform'da bu package ve upload key SHA-1 parmak iziyle
  Android OAuth istemcisi oluşturuldu.
- [x] OAuth consent screen `External / In production` durumuna alındı; Google
  ile giriş mağaza sürümünde herkese açık. Supabase Google provider ayarlarını
  bu istemciyle gerçek Android cihazda doğrulayın.
- [ ] Gmail ekstre içe aktarma, `gmail.readonly` kısıtlı izni için Google
  doğrulaması tamamlanana kadar kapalı kalmalı.

### Abonelikler

Mevcut backend doğrulama ucu Apple App Store işlemleri içindir. Android'de
satın alma butonu güvenli olarak "hazırlık aşamasında" kalır. Google Play
abonelik ürünlerini açmadan önce Google Play Developer API/service account
doğrulaması, Play purchase-token backend doğrulaması ve restore testleri
tamamlanmalıdır. İlk Android sürümü ücretsiz olarak gönderilebilir.

### Bildirimler

Mevcut native push kaydı APNs/iOS içindir. Android için FCM cihaz kaydı ve
`POST_NOTIFICATIONS` izin akışı tamamlanmadan Google Play metninde push
bildirim vaat edilmemelidir.
