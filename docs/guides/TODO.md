# MoneyPlan Pro Proje Geliştirme Planı (TODO)

Bu liste, refaktör sonrası yapılacak geliştirmeleri ve eksikleri takip etmek için oluşturulmuştur.

## 0. App Store Yayın Engelleri (Öncelik Sırası)

### Faz A — İnceleme Engelleri

- [x] **Gerçek App Store aboneliği — kod:** StoreKit satın alma/geri yükleme, backend Apple doğrulaması, Supabase entitlement tablosu ve güvenli Pro durumu tamamlandı.
  - Ürün kimlikleri: `pro.moneyplan.app.pro.monthly`, `pro.moneyplan.app.pro.yearly`
  - [x] App Store Connect'te doğru bundle kimliğiyle `MoneyPlan Pro` uygulaması oluşturuldu (Apple ID: `6792566657`).
  - [x] Abonelik grubu `MoneyPlan Pro` ve aylık/yıllık ürünler oluşturuldu; 175 bölge, Türkiye fiyatları ve Türkçe yerelleştirmeler girildi.
  - [ ] İki abonelik için inceleme ekran görüntüsü eklenecek ve ilk uygulama sürümüyle birlikte incelemeye gönderilecek.
  - [ ] App Store Server API anahtarı oluşturulup yalnızca backend secret olarak eklenecek.
- [x] **Sign in with Apple — kod/Supabase:** Native nonce akışı, Apple butonu, entitlement ve Supabase Apple provider tamamlandı.
  - [x] Apple Developer'da `pro.moneyplan.app` için Sign in with Apple, Push Notifications ve App Groups etkinliği doğrulandı.
  - [x] `pro.moneyplan.app.MoneyPlanWidget` için yalnızca `group.pro.moneyplan.app` App Group ataması doğrulandı.
- [x] **Hesap ve veri silme:** Profil içinden güçlü onay, Auth kullanıcısının hard-delete edilmesi, ilişkili bulut kayıtları ve cihaz verilerinin silinmesi tamamlandı.
- [x] **AI güvenliği ve gizlilik — kod:** Gemini anahtarı binary'den kaldırıldı; AI backend, kullanıcı kotası ve açık veri işleme onayı tamamlandı.
  - [ ] Google AI Studio ek sözleşmesi hesap sahibi tarafından kabul edilecek; sızmış eski Gemini anahtarı iptal edilip yeni anahtar yalnızca backend secret olarak eklenecek.
  - [x] Güncel TR/EN gizlilik metni `moneyplan.pro` canlı sitesine yayımlandı.
  - [x] Bozuk `ios` gitlink'inden etkilenmemesi için GitHub Pages kaynağı temiz `gh-pages` dalının köküne taşındı.
- [x] **Dashboard ayar kalıcılığı:** HF Storage Bucket `tuyucel/moneyplanpro-storage`, Space'e `/data` yolunda okuma-yazma olarak bağlandı. Backend bu mount'u otomatik algılıyor; canlı teşhis `persistent: true` doğrulamasını döndürüyor. API anahtarları ve Supabase bootstrap secret'ları HF Secrets'ta kalmalı.
- [x] **Yanıltıcı/demo finans verileri:** BES simülasyonu, sabit fiyat fallback'leri, sahte sparklines ve widget örnek fiyatları kaldırıldı; yalnızca pozitif canlı fiyatlar gösteriliyor.
  - [x] Cüzdan hesaplamalarındaki sabit USD/EUR/GBP örnek kurları kaldırıldı; tarihli TCMB satış kuru, son başarılı çevrimdışı kayıt ve 08.00/16.45 yenileme pencereleri eklendi.
  - [ ] TCMB ticari kullanım izni yazılı teyit edilecek; teyit alınmazsa `tcmb_reference_rates` flag’i mağaza sürümünde kapatılacak.
  - [x] Gerçek sağlayıcısı olmayan örnek faiz/kripto reklamları mağaza sürümünde devre dışı bırakıldı.
  - [x] Kaynakların ön lisans incelemesi `docs/guides/DATA_LICENSING.md` içinde tamamlandı.
  - [x] İlk yayın kararı uygulandı: geniş piyasa kategori ekranlarını açan `live_market_data` uzaktan yönetilen flag'i varsayılan kapalı.
  - [x] Kayan yazı yalnızca CoinGecko kripto verisine indirildi; `market_ticker`, `market_news` ve `financial_calendar` ayrı flag'lerle yönetiliyor.
  - [x] FXStreet takvim yedeği silinmedi; ayrı `financial_calendar_fxstreet` flag'i arkasına alındı ve varsayılan kapalı.
  - [ ] FXStreet lisansı ve resmî API kimlik bilgileri alındıktan sonra eski web uç noktası resmî OAuth2 API ile değiştirilecek ve flag açılacak.
  - [x] Yazılı yeniden yayın izni doğrulanmadığı için finans haberleri ve ekonomik takvim varsayılan kapalı.
  - [ ] CoinGecko Demo planı ticari lisans içermediği için mağaza yayını öncesi en az Basic plan veya yazılı ticari izin alınacak.
  - [ ] Yazılı ticari izin/uygun plan alındıktan sonra geniş piyasa kategori ekranları için `live_market_data` yeniden açılacak.

### Faz B — Mağaza Kalitesi

- [x] **Bildirim onayı — kod:** İlk açılışta otomatik izin isteme kaldırıldı; açıklama sonrası opt-in, Profil/Ayarlar kontrolü ve cihaz push kaydını pasifleştirme tamamlandı.
  - [ ] Gerçek cihazda izin ver/reddet/sonradan Ayarlar’dan aç senaryoları test edilecek.
- [x] **Gizlilik paketi — kod/envanter:** Uygulama ve widget `PrivacyInfo.xcprivacy` dosyaları ile App Store veri envanteri tamamlandı; kullanılmayan konum/fotoğraf izin açıklamaları kaldırıldı.
  - [x] App Store Connect Privacy Nutrition Label yanıtları `docs/guides/APP_STORE_PRIVACY.md` ile girildi ve yayımlandı.
- [x] **Finansal/yasal konumlandırma — ürün metni:** Piyasalar ekranı, kullanım koşulları ve mağaza metni bütçe/finansal eğitim odağı ve “yatırım tavsiyesi değildir” uyarısıyla güncellendi.
  - [x] KVKK aydınlatma metnindeki eski marka, OneSignal/Firebase ve doğrulanmamış güvenlik/saklama iddiaları mevcut mimariyle uyumlu hâle getirildi.
  - [ ] `DATA_LICENSING.md` kararına göre veri sağlayıcı izinleri tamamlanacak veya canlı fiyatlar mağaza sürümünde kapatılacak.
- [ ] **Gmail OAuth:** `gmail.readonly` için Google OAuth doğrulamasını ve kullanıcıya gösterilen veri kullanım açıklamasını tamamla.
  - [x] Doğrulama tamamlanana kadar `gmail_import` release flag’i mobil ve backend tarafında kapatıldı.
- [x] **Görsel paket — launch:** Varsayılan boş Flutter launch görseli MoneyPlan Pro logosuyla değiştirildi.
  - [ ] App Store ekran görüntüleri açıkça fiktif test verisiyle hazırlanacak.
    - [x] 6,9 inç iPhone için ilk onboarding görseli hazırlandı (`1320 × 2868`).
    - [x] Kurgusal gelir/gider verisiyle aylık özet görseli hazırlandı.
    - [x] Birikim/BES/hayat sigortası görseli anonim kurgusal plan adlarıyla hazırlandı.
    - [x] Finansal araçlar görseli 6,9 inç opak JPEG olarak hazırlandı.
    - [x] Lisans bekleyen piyasa ekranı final setten çıkarılıp arşivlendi.
    - [x] Boş izleme ekranı 1.0 mağaza setinden çıkarıldı.
    - [ ] Tam set App Store Connect'e yüklenecek.
- [x] **iOS hedefleri — kod:** Widget minimum iOS 15’e indirildi; uygulama ve widget test kapsamı olmadığı için iPhone-only dağıtıma alındı.
- [ ] **Kalite kapısı:**
  - [x] Birikim/BES/hayat sigortası yerel kayıtları Supabase kullanıcı kimliğine göre ayrıldı; eski tekil anahtar bir kez mevcut kullanıcıya taşınıyor.
  - [x] Uygulama açılışında ödenmemiş dönemleri kendiliğinden birikmiş bakiye sayma kaldırıldı; değerleme kullanıcı senkronizasyonuyla ilerliyor.
  - [x] Widget testi ve uygulama kapanışındaki asenkron kaynak temizliği düzeltildi.
  - [x] `flutter analyze`, tam `flutter test` ve backend direnç testleri hatasız geçiyor.
  - [x] iPhone 17 Pro / iOS 26.5 ve Pixel 7 Pro / Android 11 emülatörlerinde temiz kurulum, ana sekmeler, fonlar, finansal takvim, Bitcoin detay/grafik ve Pro ekranı duman testleri geçti.
  - [x] Feature flag’li `flutter build ios --release --no-codesign` başarıyla tamamlanıyor; son bundle 42 MB.
  - [ ] Gerçek cihazda kritik akışlar ve TestFlight regresyon turu yapılacak.
- [ ] **App Store Connect:**
  - [x] Uygulama adı, alt başlık, Finance/Education kategorileri ve Türkçe 1.0 mağaza metni girildi.
  - [x] Standart işletim sistemi/TLS şifrelemesi kullanan uygulama için `ITSAppUsesNonExemptEncryption = false` eklendi.
  - [x] App Privacy etiketi ile gizlilik/veri silme bağlantıları girildi ve yayımlandı.
  - [x] Yaş derecelendirmesi mevcut uygulama davranışına göre tamamlandı (`4+`).
  - [ ] EU trader bilgileri hesap sahibinin kimlik/işletme bilgileriyle tamamlanacak.
  - [ ] App Store Connect API kullanım sözleşmesi hesap sahibi tarafından kabul edilip API erişimi açılacak.
  - [ ] İnceleme iletişim bilgileri/notları ile normal kullanıcı demo hesabı hazırlanacak.
  - [ ] İlk build, ekran görüntüleri ve abonelik inceleme ekran görüntüleri yüklenecek.

## 1. İzleme Listesi (Watchlist) Geliştirmeleri
- [x] **Mini Grafikler (Sparklines)**: Varlık kartları ve portföy kalemlerinde fiyat geçmişi grafiği gösteriliyor.
- [x] **Canlı Fiyat Güncelleme**: İzleme listesi önbelleği 30 saniyede bir yenileniyor.
- [ ] **Sıralama ve Filtreleme**: Alfabetik, fiyat değişimi veya varlık türüne göre sıralama ekle.

## 2. Varlık Detay Sayfaları (Asset Details)
- [ ] **Gelişmiş Grafikler**: TradingView benzeri veya SfCartesianChart ile detaylı grafikler.
- [ ] **Temel Analiz Verileri**: F/K, PD/DD, piyasa değeri gibi verileri ekle.
- [ ] **Haber Entegrasyonu**: Varlığa özel güncel haberleri listele.

## 3. Portföy Yönetimi
- [x] **Varlık Ekleme**: Kullanıcının miktar ve ortalama maliyet girişi cihazda saklanıyor, oturum açıldığında Supabase ile eşitleniyor.
- [x] **Kâr/Zarar Analizi**: Toplam ve varlık bazında güncel değer, maliyet ve kâr/zarar hesaplanıyor.
- [ ] **Varlık Dağılım Pastası**: Portföyün yüzdesel dağılımını gösteren pasta grafiği ekle.

## 4. Uygulama Genel Refactoring
- [x] **WalletPage Refaktörü**: 2400 satırdan 600 satıra düşürüldü, widgetlar ayrıştırıldı.
- [x] **InvestmentWizard Refaktörü**: 1100 satırdan 150 satıra düşürüldü.
- [ ] **Hata Yönetimi (Error Handling)**: API istekleri ve boş veri durumları için daha şık UI bileşenleri ekle.
- [ ] **Tema Desteği**: Koyu mod (Dark Mode) uyumluluğunu gözden geçir ve eksikleri tamamla.

## 5. Yeni Özellikler
- [x] **Bildirim Sistemi**: Native APNs cihaz kaydı, admin gönderimi, uygulama içi gelen kutusu ve yerel fiyat alarmı tamamlandı.
  - [ ] Bütçe limiti/aşımı için otomatik bildirim kuralı geliştirilecek.
- [ ] **Yapay Zeka Finansal Eğitim Asistanı**: Kullanıcının verilerini açıklayan, alternatif senaryoları karşılaştıran ve yatırım tavsiyesi üretmeyen eğitim özetleri geliştir.
