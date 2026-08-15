# Tarihsel not

Bu rapor 13 Ocak 2026 tarihli InvestGuide durumunun arşividir; güncel ürün
adı, teknik yapı ve yayın durumu için kullanılmamalıdır. MoneyPlan Pro'nun
güncel yayın paketi için [App Store gönderim paketi](APP_STORE_SUBMISSION.md)
ve [TODO listesine](TODO.md) bakın.

# 🚀 Production Hazırlık Raporu - InvestGuide

**Tarih:** 13 Ocak 2026  
**Versiyon:** 1.0.0+2  
**Durum Özeti:** ⚠️ **KISMEN HAZIR** - Kritik eksiklikler mevcut

---

## ✅ TAMAMLANAN ÖĞELER

### 1. **Kod Kalitesi ve Refactoring**
- ✅ WalletPage: 2400 → 600 satır (75% azalma)
- ✅ InvestmentWizard: 1100 → 150 satır (86% azalma)
- ✅ Widget ayrıştırması tamamlandı
- ✅ Flutter Analyze: Sadece 5 minor lint uyarısı (curly braces, type annotations)
- ✅ Toplam 151 Dart dosyası

### 2. **Backend API Servisleri**
- ✅ FastAPI backend kurulu ve çalışıyor
- ✅ 8 servis modülü aktif:
  - `market_service.py` - Piyasa verileri
  - `crypto_service.py` - Kripto para verileri
  - `bes_service.py` - BES fonları
  - `news_service.py` - Haberler
  - `macro_service.py` - Makro ekonomik göstergeler
  - `tcmb_service.py` - TCMB kurları
  - `ta_service.py` - Teknik analiz
  - `fmp_service.py` - FMP entegrasyonu
- ✅ CORS yapılandırması aktif
- ✅ API endpoint'leri tanımlı (v1)

### 3. **Supabase Entegrasyonu**
- ✅ Supabase bağlantısı yapılandırıldı
- ✅ Auth flow (PKCE) aktif
- ✅ Veritabanı servisleri hazır:
  - Assets (varlıklar)
  - Exchanges (borsalar)
  - User favorites (favoriler)
  - Search history (arama geçmişi)
  - Portfolio (portföy)

### 4. **Özellikler**
- ✅ Çoklu dil desteği (TR/EN)
- ✅ Tema desteği (Light/Dark)
- ✅ Google Sign-In entegrasyonu
- ✅ Home Widget desteği (iOS/Android)
- ✅ Routing yapısı (GoRouter)
- ✅ State management (Riverpod)

---

## ❌ KRİTİK EKSİKLİKLER (Production Blocker)

### 1. **🔴 Android Uygulama Kimliği**
**Dosya:** `android/app/build.gradle.kts`
```kotlin
applicationId = "com.example.invest_guide_new"  // ❌ DEĞIŞMELI!
namespace = "com.example.invest_guide_new"       // ❌ DEĞIŞMELI!
```
**Çözüm:**
```kotlin
applicationId = "com.turgayyucel.invest_guide"
namespace = "com.turgayyucel.invest_guide"
```

### 2. **🔴 Android Widget Receiver Uyumsuzluğu**
**Dosya:** `android/app/src/main/AndroidManifest.xml`
```xml
<receiver android:name="com.example.invest_guide.HomeWidgetProvider" ...>
```
**Sorun:** Package name `com.example.invest_guide` ama applicationId `com.example.invest_guide_new`

**Çözüm:** Widget receiver'ı yeni package'a taşı veya applicationId'yi tutarlı yap.

### 3. **🔴 Android Uygulama İsmi**
**Dosya:** `android/app/src/main/AndroidManifest.xml`
```xml
android:label="invest_guide_new"  // ❌ Kullanıcı dostu değil
```
**Çözüm:**
```xml
android:label="Yatırım Rehberi"
```

### 4. **🔴 Release Signing Eksik**
**Dosya:** `android/app/build.gradle.kts`
```kotlin
release {
    signingConfig = signingConfigs.getByName("debug")  // ❌ DEBUG KEY!
}
```
**Sorun:** Production APK debug key ile imzalanıyor.

**Çözüm:** Keystore oluştur ve release signing yapılandır:
```bash
keytool -genkey -v -keystore ~/invest-guide-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias invest-guide
```

### 5. **🔴 Unit Test Hatası**
**Dosya:** `test/widget_test.dart`
```
Bad state: No ProviderScope found
```
**Sorun:** Test MyApp'i ProviderScope olmadan başlatıyor.

**Çözüm:** Test dosyasını güncelle veya sil (şu an gereksiz counter testi var).

### 6. **🟡 Backend Bağlantı Hatası (Test Sırasında)**
```
Connection refused (OS Error: Connection refused, errno = 61)
address = 104.247.166.225, port = 55433
```
**Sorun:** Backend sunucusu test sırasında çalışmıyor veya yanlış IP/port.

**Çözüm:** Backend deployment yapılandırması gerekli.

---

## ⚠️ ORTA ÖNCELİKLİ EKSİKLİKLER

### 1. **API Key Yönetimi**
**Dosya:** `lib/core/config/env_config.dart`
```dart
static const String coinGeckoApiKey = '';  // Boş
static const String alphaVantageApiKey = '';  // Boş
```
**Durum:** Şu an opsiyonel, ancak rate limiting için gerekli olabilir.

### 2. **Backend Deployment**
- ⚠️ Backend servisi local'de çalışıyor
- ⚠️ Production URL yapılandırması yok
- ⚠️ Environment variables kullanılmıyor

**Önerilen Çözüm:**
- Railway / Render / DigitalOcean'da deploy et
- Environment variables ekle (.env dosyası)
- Frontend'de API base URL'i yapılandır

### 3. **Lint Uyarıları**
**Dosya:** `lib/features/search/presentation/pages/category_page.dart`
- 5 adet minor lint uyarısı (curly braces, type annotations)
- Production blocker değil ama düzeltilmeli

### 4. **README Güncellemesi**
**Dosya:** `README.md`
- Hala boilerplate Flutter metni içeriyor
- Proje açıklaması, kurulum adımları eksik

---

## 📋 TODO LİSTESİ (Özellik Geliştirme)

### Yüksek Öncelik
- [ ] Mini grafikler (sparklines) - İzleme listesi
- [ ] Canlı fiyat güncelleme (WebSocket/Timer)
- [ ] Gelişmiş grafikler (TradingView benzeri)
- [ ] Portföy yönetimi (varlık ekleme, kâr/zarar)

### Orta Öncelik
- [ ] Temel analiz verileri (F/K, PD/DD)
- [ ] Haber entegrasyonu
- [ ] Sıralama ve filtreleme
- [ ] Varlık dağılım pastası

### Düşük Öncelik
- [ ] Bildirim sistemi
- [ ] AI yatırım danışmanı
- [ ] Koyu mod uyumluluğu kontrolü
- [ ] Hata yönetimi UI iyileştirmeleri

---

## 🔧 PRODUCTION ÖNCESİ YAPILACAKLAR (Checklist)

### Android
- [ ] 1. `applicationId` değiştir → `com.turgayyucel.invest_guide`
- [ ] 2. `namespace` değiştir → `com.turgayyucel.invest_guide`
- [ ] 3. Widget receiver package'ını düzelt
- [ ] 4. Uygulama ismini değiştir → `Yatırım Rehberi`
- [ ] 5. Release keystore oluştur
- [ ] 6. `build.gradle.kts` signing config güncelle
- [ ] 7. ProGuard rules ekle (obfuscation)
- [ ] 8. App icon ekle/güncelle

### iOS
- [ ] 1. Bundle Identifier kontrol et (şu an `com.turgayyucel.invest_guide`)
- [ ] 2. App Store Connect'te uygulama oluştur
- [ ] 3. Provisioning profiles oluştur
- [ ] 4. App icon ekle/güncelle
- [ ] 5. Privacy policy URL ekle (gerekirse)

### Backend
- [ ] 1. Production sunucuya deploy et
- [ ] 2. Environment variables yapılandır
- [ ] 3. HTTPS sertifikası ekle
- [ ] 4. Rate limiting ekle
- [ ] 5. Logging ve monitoring kur (Sentry, LogRocket vb.)
- [ ] 6. Database backup stratejisi

### Genel
- [ ] 1. Unit testleri düzelt/genişlet
- [ ] 2. Integration testleri ekle
- [ ] 3. README.md güncelle
- [ ] 4. Privacy Policy hazırla
- [ ] 5. Terms of Service hazırla
- [ ] 6. App Store / Play Store screenshots hazırla
- [ ] 7. Store listing metinleri yaz (TR/EN)
- [ ] 8. Beta test grubu oluştur (TestFlight / Internal Testing)

---

## 📊 PRODUCTION HAZıRLıK SKORU

| Kategori | Durum | Skor |
|----------|-------|------|
| **Kod Kalitesi** | ✅ İyi | 9/10 |
| **Backend API** | ✅ Hazır (local) | 7/10 |
| **Supabase** | ✅ Yapılandırıldı | 8/10 |
| **Android Config** | ❌ Eksik | 3/10 |
| **iOS Config** | ⚠️ Kısmen | 6/10 |
| **Testing** | ❌ Eksik | 2/10 |
| **Deployment** | ❌ Yapılmadı | 0/10 |
| **Dokümantasyon** | ⚠️ Eksik | 4/10 |

**TOPLAM:** 39/80 (%49) - **PRODUCTION HAZIR DEĞİL**

---

## ⏱️ TAHMİNİ SÜRE

| Görev | Süre |
|-------|------|
| Android yapılandırma düzeltmeleri | 2-3 saat |
| iOS yapılandırma | 1-2 saat |
| Backend deployment | 3-4 saat |
| Test düzeltmeleri | 2-3 saat |
| Store assets (icon, screenshots) | 4-6 saat |
| Dokümantasyon | 2-3 saat |
| Beta testing | 1-2 hafta |

**TOPLAM:** ~20-25 saat geliştirme + 1-2 hafta test

---

## 🎯 ÖNERİLEN YAYINLAMA STRATEJİSİ

### Faz 1: Teknik Hazırlık (1-2 gün)
1. Android/iOS yapılandırma düzeltmeleri
2. Backend deployment
3. Test düzeltmeleri

### Faz 2: Store Hazırlık (2-3 gün)
1. App icon ve screenshots
2. Store listing metinleri
3. Privacy policy / ToS

### Faz 3: Beta Test (1-2 hafta)
1. TestFlight (iOS) / Internal Testing (Android)
2. Bug fixing
3. Kullanıcı geri bildirimleri

### Faz 4: Production Launch
1. Store submission
2. Review süreci (3-7 gün)
3. Soft launch (belirli bölgeler)
4. Full launch

---

## 📞 SONUÇ

**Production'a hazır mı?** ❌ **HAYIR**

**Neden?**
- Android yapılandırması eksik/hatalı
- Release signing yapılmamış
- Backend deployment yapılmamış
- Test coverage yetersiz
- Store assets hazır değil

**Ne zaman hazır olur?**
- Minimum: 3-4 gün (sadece teknik düzeltmeler)
- İdeal: 2-3 hafta (beta test dahil)

**İlk adım ne olmalı?**
1. Android applicationId ve package name düzeltmeleri
2. Release keystore oluşturma
3. Backend deployment (Railway/Render önerilir)
