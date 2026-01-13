# TestFlight Deployment Rehberi - Yatırım Rehberi

## 📋 Ön Gereksinimler

### Apple Developer Account
- [ ] Apple Developer Program üyeliği ($99/yıl)
- [ ] Hesap aktif ve onaylı
- [ ] Ödeme bilgileri güncel

### Geliştirme Ortamı
- [ ] macOS (Ventura veya sonrası)
- [ ] Xcode 15+ yüklü
- [ ] Flutter SDK güncel
- [ ] CocoaPods yüklü

### Proje Hazırlığı
- [ ] Bundle Identifier belirlendi: `com.turgayyucel.invest_guide`
- [ ] App Icon hazır (1024x1024 px)
- [ ] Privacy Policy URL'i hazır
- [ ] Terms of Service URL'i hazır

---

## 🚀 Adım Adım TestFlight Deployment

### Adım 1: App Store Connect Hazırlığı

#### 1.1 App Store Connect'e Giriş
1. [App Store Connect](https://appstoreconnect.apple.com) adresine git
2. Apple ID ile giriş yap
3. **"My Apps"** sekmesine tıkla

#### 1.2 Yeni Uygulama Oluştur
1. **"+"** butonuna tıkla → **"New App"** seç
2. Bilgileri doldur:
   - **Platform:** iOS
   - **Name:** Yatırım Rehberi
   - **Primary Language:** Turkish
   - **Bundle ID:** com.turgayyucel.invest_guide (dropdown'dan seç)
   - **SKU:** invest-guide-001 (benzersiz ID)
   - **User Access:** Full Access

3. **"Create"** butonuna tıkla

#### 1.3 Uygulama Bilgilerini Tamamla

**App Information:**
- **Name:** Yatırım Rehberi
- **Subtitle:** Portföy & Bütçe Yönetimi
- **Category:** 
  - Primary: Finance
  - Secondary: Productivity
- **Content Rights:** Checkbox işaretle

**Pricing and Availability:**
- **Price:** Free
- **Availability:** All countries

**Privacy Policy:**
- URL: `https://yourdomain.com/privacy-policy` (GitHub Pages kullanabilirsiniz)

**App Privacy:**
1. **"Get Started"** butonuna tıkla
2. Veri toplama bilgilerini gir:
   - **Contact Info:** Email (for account)
   - **Financial Info:** Portfolio data (not collected by us)
   - **Usage Data:** Analytics (optional)
3. Her veri tipi için:
   - **Linked to User:** Yes/No
   - **Used for Tracking:** No
   - **Purpose:** App Functionality

---

### Adım 2: Xcode Yapılandırması

#### 2.1 Xcode'da Projeyi Aç
```bash
cd /Users/turgayyucel/invest-guide-app
open ios/Runner.xcworkspace
```

#### 2.2 Signing & Capabilities
1. **Runner** target'ı seç
2. **Signing & Capabilities** sekmesine git
3. **Automatically manage signing** işaretle
4. **Team:** Apple Developer hesabınızı seç
5. **Bundle Identifier:** `com.turgayyucel.invest_guide` olduğunu doğrula

#### 2.3 Deployment Info
1. **General** sekmesine git
2. **Deployment Info:**
   - **iOS Deployment Target:** 13.0
   - **iPhone** ve **iPad** işaretle
   - **Requires full screen:** Hayır
3. **App Icons and Launch Screen:**
   - App Icon set'ini kontrol et

#### 2.4 Info.plist Kontrolleri
`ios/Runner/Info.plist` dosyasını kontrol et:

```xml
<key>CFBundleDisplayName</key>
<string>Yatırım Rehberi</string>

<key>CFBundleShortVersionString</key>
<string>1.0.0</string>

<key>CFBundleVersion</key>
<string>1</string>

<!-- Privacy Descriptions -->
<key>NSCameraUsageDescription</key>
<string>Profil fotoğrafı eklemek için kamera erişimi gereklidir.</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>Profil fotoğrafı seçmek için galeri erişimi gereklidir.</string>

<!-- Gmail API için gerekli -->
<key>GIDClientID</key>
<string>203284079351-kd7jeam5pgcjvi4279d1d7hciodckdne.apps.googleusercontent.com</string>
```

---

### Adım 3: Build ve Archive

#### 3.1 Flutter Build
Terminal'de şu komutları çalıştır:

```bash
# Temizlik
flutter clean
flutter pub get

# iOS için build
flutter build ios --release
```

#### 3.2 Xcode Archive
1. Xcode'da **Product > Scheme > Runner** seç
2. **Product > Destination > Any iOS Device (arm64)** seç
3. **Product > Archive** tıkla
4. Build tamamlanana kadar bekle (5-10 dakika)

#### 3.3 Archive Validation
1. Archive tamamlandığında **Organizer** penceresi açılır
2. Son archive'i seç
3. **Validate App** butonuna tıkla
4. Signing seçeneklerini kontrol et:
   - **Automatically manage signing** seç
   - **Upload your app's symbols** işaretle
5. **Validate** butonuna tıkla
6. Hata yoksa devam et

---

### Adım 4: TestFlight'a Upload

#### 4.1 Upload İşlemi
1. Organizer'da archive'i seç
2. **Distribute App** butonuna tıkla
3. **App Store Connect** seç → **Next**
4. **Upload** seç → **Next**
5. Signing seçeneklerini kontrol et → **Next**
6. **Upload** butonuna tıkla
7. Upload tamamlanana kadar bekle (10-30 dakika)

#### 4.2 Processing Bekleme
1. App Store Connect'e git
2. **TestFlight** sekmesine tıkla
3. **iOS Builds** altında build'in "Processing" durumunu gör
4. Processing tamamlanana kadar bekle (30-60 dakika)
5. E-posta bildirimi gelecek: "Your build has finished processing"

---

### Adım 5: TestFlight Yapılandırması

#### 5.1 Build Bilgilerini Tamamla
1. App Store Connect → **TestFlight** → Build'i seç
2. **Test Details** bölümünü doldur:

**What to Test:**
```
Yatırım Rehberi v1.0.0 - İlk Beta Sürümü

Test Edilecek Özellikler:
✅ Portföy yönetimi (kripto, hisse, altın)
✅ Bütçe takibi ve kategori analizi
✅ AI destekli finansal öneriler
✅ Gmail entegrasyonu (BES/sigorta tarama)
✅ Piyasa verileri ve grafikler
✅ Finansal hesaplayıcılar
✅ Yatırım sihirbazı

Bilinen Sorunlar:
⚠️ Backend sunucusu geliştirme ortamında (yavaş olabilir)
⚠️ Bazı piyasa verileri 15-20 dakika gecikmeli

Geri Bildirim İçin:
📧 support@investguide.app
```

#### 5.2 Export Compliance
1. **Export Compliance** bölümünde:
   - **Is your app designed to use cryptography or does it contain or incorporate cryptography?**
   - **Yes** seç (HTTPS kullanıyoruz)
2. **Does your app qualify for any of the exemptions provided in Category 5, Part 2?**
   - **Yes** seç (Standard encryption)
3. **Save** butonuna tıkla

#### 5.3 Test Information
1. **Beta App Review Information:**
   - **First Name:** Turgay
   - **Last Name:** Yücel
   - **Email:** support@investguide.app
   - **Phone:** +90 XXX XXX XX XX

2. **Sign-In Required:** Yes
   - **Username:** test@investguide.app
   - **Password:** TestUser123!
   - **Notes:** Test hesabı - tüm özelliklere erişim var

3. **Notes:**
```
Gmail entegrasyonu test etmek için:
1. Google hesabı ile giriş yapın
2. Gmail erişim izni verin
3. Wallet > Gmail Sync sekmesine gidin

Backend API geliştirme ortamında çalışıyor.
Bazı veriler gerçek zamanlı olmayabilir.
```

---

### Adım 6: Test Kullanıcıları Ekleme

#### 6.1 Internal Testing (Dahili Test)
1. **TestFlight** → **Internal Testing** sekmesine git
2. **"+"** butonuna tıkla → **Create Group**
3. Grup adı: "Internal Testers"
4. **Add Build** → Son build'i seç
5. **Add Testers:**
   - Kendi e-postanız
   - Ekip üyeleri (varsa)
6. **Save** butonuna tıkla

**Not:** Internal testerlar hemen test edebilir (review gerekmez)

#### 6.2 External Testing (Harici Test)
1. **TestFlight** → **External Testing** sekmesine git
2. **"+"** butonuna tıkla → **Create Group**
3. Grup adı: "Beta Testers"
4. **Public Link:** Etkinleştir (isteğe bağlı)
5. **Add Build** → Son build'i seç
6. **Submit for Review** butonuna tıkla

**Not:** External testing için Apple review gerekir (1-2 gün)

---

### Adım 7: Tester Davetleri

#### 7.1 Davet E-postası Gönderme
1. Tester grubunu seç
2. **Add Testers** butonuna tıkla
3. E-posta adreslerini gir (virgülle ayır)
4. **Add** butonuna tıkla
5. Otomatik davet e-postası gönderilir

#### 7.2 Public Link Paylaşma (External için)
1. External grup ayarlarına git
2. **Public Link** bölümünü bul
3. Link'i kopyala: `https://testflight.apple.com/join/XXXXXXXX`
4. Sosyal medya, forum vb. paylaş

---

### Adım 8: Tester Talimatları

Testerlarınıza şu talimatları gönderin:

```
🎉 Yatırım Rehberi Beta Testine Hoş Geldiniz!

📱 TestFlight Kurulumu:
1. App Store'dan "TestFlight" uygulamasını indirin
2. Davet e-postasındaki "View in TestFlight" linkine tıklayın
3. TestFlight'ta "Install" butonuna basın
4. Uygulama yüklendikten sonra açın

🧪 Test Süreci:
• Tüm özellikleri deneyin
• Hataları not edin
• Geri bildirim gönderin (TestFlight içinden)
• Önerilerinizi paylaşın

📧 İletişim:
support@investguide.app

Teşekkürler! 🙏
```

---

## 🔄 Yeni Build Yükleme

Her güncelleme için:

1. **Versiyon Güncelle:**
   ```yaml
   # pubspec.yaml
   version: 1.0.1+2  # 1.0.1 = version, 2 = build number
   ```

2. **Build ve Upload:**
   ```bash
   flutter clean
   flutter build ios --release
   # Xcode'da Archive ve Upload
   ```

3. **TestFlight'ta Güncelle:**
   - Yeni build'i tester gruplarına ekle
   - "What to Test" notlarını güncelle

---

## ⚠️ Sık Karşılaşılan Sorunlar

### Sorun 1: "No profiles for 'com.turgayyucel.invest_guide' were found"
**Çözüm:**
1. Xcode → Preferences → Accounts
2. Apple ID'nizi seç → Download Manual Profiles
3. Signing & Capabilities → Team'i yeniden seç

### Sorun 2: "Archive failed - Build input file cannot be found"
**Çözüm:**
```bash
cd ios
pod deintegrate
pod install
cd ..
flutter clean
flutter build ios --release
```

### Sorun 3: "Missing Compliance"
**Çözüm:**
App Store Connect'te Export Compliance bilgilerini doldur (Adım 5.2)

### Sorun 4: "Invalid Bundle - Missing Info.plist values"
**Çözüm:**
`Info.plist` dosyasında privacy descriptions ekle (Adım 2.4)

### Sorun 5: "Processing stuck at 'Processing'"
**Çözüm:**
- 2-3 saat bekle
- Hala devam ederse Apple Developer Support'a ticket aç

---

## 📊 TestFlight Metrikleri

### Takip Edilecek Metrikler
- **Install Rate:** Davet edilen / Yükleyen
- **Session Count:** Kullanıcı başına oturum sayısı
- **Crash Rate:** Çökme oranı
- **Feedback Count:** Geri bildirim sayısı

### Başarı Kriterleri
- ✅ Crash rate < %1
- ✅ Install rate > %50
- ✅ Ortalama session > 5 dakika
- ✅ Pozitif geri bildirim > %80

---

## 🎯 Production'a Geçiş

Beta test başarılı olduktan sonra:

1. **App Store Review Hazırlığı:**
   - Screenshots hazırla (6-8 adet)
   - App Preview video (opsiyonel)
   - Store listing metinleri
   - Privacy Policy URL
   - Support URL

2. **Final Build:**
   - Versiyon: 1.0.0
   - Tüm debug kodları kaldır
   - Analytics ekle (opsiyonel)
   - Crash reporting (Firebase Crashlytics)

3. **Submit for Review:**
   - App Store Connect → App Store sekmesi
   - Build seç
   - Submit for Review
   - Review süresi: 1-7 gün

---

## 📞 Yardım ve Destek

### Apple Kaynakları
- [TestFlight Dokümantasyonu](https://developer.apple.com/testflight/)
- [App Store Connect Help](https://developer.apple.com/help/app-store-connect/)
- [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)

### Sorun Yaşarsanız
1. Apple Developer Forums
2. Stack Overflow (#testflight)
3. Flutter Community (#ios-help)

---

## ✅ Deployment Checklist

### Hazırlık
- [ ] Apple Developer hesabı aktif
- [ ] Bundle ID oluşturuldu
- [ ] App Icon hazır
- [ ] Privacy Policy URL hazır
- [ ] Signing certificates yapılandırıldı

### Build
- [ ] Flutter clean yapıldı
- [ ] iOS build başarılı
- [ ] Xcode archive oluşturuldu
- [ ] Validation başarılı
- [ ] Upload tamamlandı

### TestFlight
- [ ] Build processing tamamlandı
- [ ] Test details dolduruldu
- [ ] Export compliance tamamlandı
- [ ] Internal tester grubu oluşturuldu
- [ ] Davetler gönderildi

### Test
- [ ] En az 3 tester test etti
- [ ] Kritik hatalar düzeltildi
- [ ] Geri bildirimler değerlendirildi
- [ ] Crash rate < %1

### Production Hazırlık
- [ ] Screenshots hazır
- [ ] Store listing tamamlandı
- [ ] Final build yüklendi
- [ ] Review için hazır

---

**Başarılar! 🚀**

*Sorularınız için: support@investguide.app*
