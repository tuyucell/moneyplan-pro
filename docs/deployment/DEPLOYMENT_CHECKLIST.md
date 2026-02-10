# 🎯 TestFlight Deployment - Final Checklist

## ✅ TAMAMLANAN HAZIRLIKLAR

### 📄 Dokümantasyon
- [x] **Privacy Policy** (PRIVACY_POLICY.md)
  - KVKK ve GDPR uyumlu
  - Türkçe ve İngilizce
  - HTML versiyonu hazır (docs/privacy.html)
  
- [x] **Terms of Service** (TERMS_OF_SERVICE.md)
  - Yasal koruma sağlayan
  - Risk uyarıları içeren
  - HTML versiyonu hazır (docs/terms.html)
  
- [x] **Store Listing Metinleri** (STORE_LISTING.md)
  - App Store açıklaması (TR/EN)
  - Play Store açıklaması (TR/EN)
  - Anahtar kelimeler
  - Screenshot caption'ları

- [x] **Screenshot Rehberi** (SCREENSHOT_GUIDE.md)
  - 8 screenshot stratejisi
  - Boyut ve format bilgileri
  - Tasarım önerileri
  - Araç tavsiyeleri

- [x] **TestFlight Deployment Rehberi** (TESTFLIGHT_DEPLOYMENT.md)
  - Adım adım talimatlar
  - Sorun giderme
  - Tester yönetimi

- [x] **GitHub Pages Sayfaları** (docs/)
  - index.html (landing page)
  - privacy.html
  - terms.html
  - README.md (deployment rehberi)

---

## 🚀 SONRAKİ ADIMLAR (Sırayla)

### 1. GitHub Pages Deployment (15 dakika)

```bash
# GitHub repository oluştur ve push et
cd /Users/turgayyucel/invest-guide-app
git init
git add .
git commit -m "Add store documentation and legal pages"
git branch -M main
git remote add origin https://github.com/KULLANICI_ADINIZ/invest-guide-app.git
git push -u origin main
```

**Sonra:**
1. GitHub → Settings → Pages
2. Source: `main` branch, `/docs` folder
3. Save
4. 5-10 dakika bekle
5. URL'leri test et:
   - `https://KULLANICI_ADINIZ.github.io/invest-guide-app/privacy.html`
   - `https://KULLANICI_ADINIZ.github.io/invest-guide-app/terms.html`

---

### 2. Screenshot Hazırlama (2-4 saat)

**Seçenekler:**

**A) Hızlı Yol - Gerçek Cihazda:**
```bash
# Test verileri ile uygulamayı çalıştır
flutter run --release

# Screenshot'ları al:
# - Ana ekran (dashboard)
# - Portföy sayfası
# - Bütçe sayfası
# - AI analiz
# - Piyasa verileri
# - Hesaplayıcılar
```

**B) Profesyonel Yol - Figma:**
1. [Figma](https://figma.com) hesabı aç (ücretsiz)
2. iPhone mockup template indir
3. Uygulama ekranlarını tasarla
4. Export: 1290x2796 px PNG

**C) Outsource:**
- Fiverr'da freelancer kirala ($50-100)
- 6-8 screenshot + caption

**Gerekli Screenshot'lar:**
- [ ] 1. Ana Ekran / Dashboard
- [ ] 2. Portföy Detayı
- [ ] 3. Bütçe Yönetimi
- [ ] 4. AI Analiz
- [ ] 5. Piyasa Verileri
- [ ] 6. Hesaplayıcılar
- [ ] 7. Yatırım Sihirbazı (opsiyonel)
- [ ] 8. Koyu Tema (opsiyonel)

---

### 3. App Icon Hazırlama (30 dakika)

**Gereksinimler:**
- 1024x1024 px
- PNG formatı
- Şeffaf OLMAYAN arka plan
- Köşeler yuvarlatılmamış (iOS otomatik yapar)

**Araçlar:**
- [Canva](https://canva.com) (ücretsiz şablonlar)
- [Figma](https://figma.com)
- Adobe Illustrator
- Freelancer (Fiverr: $20-50)

**Icon Tasarım İpuçları:**
- Basit ve tanınabilir
- Mor/mavi tonlar (marka rengi)
- Finans/yatırım teması
- Grafik veya para sembolü
- Okunabilir (küçük boyutta)

**Icon Oluşturulduktan Sonra:**
```bash
# iOS için icon set oluştur
# Xcode'da: Assets.xcassets > AppIcon
# 1024x1024 dosyayı sürükle-bırak
```

---

### 4. App Store Connect Hazırlığı (1 saat)

#### 4.1 Uygulama Oluştur
1. [App Store Connect](https://appstoreconnect.apple.com)
2. My Apps → + → New App
3. Bilgileri doldur:
   - Name: **Yatırım Rehberi**
   - Primary Language: **Turkish**
   - Bundle ID: **com.turgayyucel.invest_guide**
   - SKU: **invest-guide-001**

#### 4.2 App Information
- **Subtitle:** Portföy & Bütçe Yönetimi
- **Category:** Finance (Primary), Productivity (Secondary)
- **Privacy Policy URL:** `https://KULLANICI_ADINIZ.github.io/invest-guide-app/privacy.html`
- **Support URL:** `https://KULLANICI_ADINIZ.github.io/invest-guide-app/`

#### 4.3 Pricing
- **Price:** Free
- **Availability:** All countries

#### 4.4 App Privacy
1. Get Started
2. Veri toplama bilgilerini gir:
   - **Contact Info:** Email (for account)
   - **Financial Info:** Portfolio data (not collected)
   - **Usage Data:** Analytics (optional)

---

### 5. Xcode Build & Archive (30 dakika)

```bash
# Temizlik ve hazırlık
flutter clean
flutter pub get

# iOS build
flutter build ios --release
```

**Xcode'da:**
1. `open ios/Runner.xcworkspace`
2. Product → Scheme → Runner
3. Product → Destination → Any iOS Device
4. Product → Archive
5. Validate App
6. Distribute App → App Store Connect
7. Upload

**Bekleme:** 30-60 dakika (Processing)

---

### 6. TestFlight Yapılandırması (30 dakika)

#### 6.1 Build Bilgileri
**What to Test:**
```
Yatırım Rehberi v1.0.0 - İlk Beta Sürümü

Test Edilecek Özellikler:
✅ Portföy yönetimi
✅ Bütçe takibi
✅ AI önerileri
✅ Gmail entegrasyonu
✅ Piyasa verileri
✅ Hesaplayıcılar

Bilinen Sorunlar:
⚠️ Backend geliştirme ortamında

Geri Bildirim: support@investguide.app
```

#### 6.2 Export Compliance
- Cryptography: **Yes**
- Exemption: **Yes** (Standard encryption)

#### 6.3 Test Information
- **Sign-In Required:** Yes
- **Username:** test@investguide.app
- **Password:** TestUser123!

---

### 7. Tester Davetleri (15 dakika)

#### Internal Testing
1. TestFlight → Internal Testing
2. Create Group: "Internal Testers"
3. Add Build
4. Add Testers (kendi e-postanız)

#### External Testing (Opsiyonel)
1. TestFlight → External Testing
2. Create Group: "Beta Testers"
3. Add Build
4. Submit for Review (1-2 gün)
5. Public Link oluştur

---

## 📊 ZAMAN ÇİZELGESİ

| Görev | Süre | Durum |
|-------|------|-------|
| GitHub Pages Deployment | 15 dk | ⏳ Bekliyor |
| Screenshot Hazırlama | 2-4 saat | ⏳ Bekliyor |
| App Icon Hazırlama | 30 dk | ⏳ Bekliyor |
| App Store Connect Setup | 1 saat | ⏳ Bekliyor |
| Xcode Build & Upload | 30 dk | ⏳ Bekliyor |
| TestFlight Yapılandırma | 30 dk | ⏳ Bekliyor |
| Tester Davetleri | 15 dk | ⏳ Bekliyor |
| **TOPLAM** | **5-7 saat** | |

**Processing & Review:**
- Build Processing: 30-60 dakika
- External Review (opsiyonel): 1-2 gün

---

## ⚠️ ÖNEMLİ NOTLAR

### Backend Deployment
TestFlight'tan önce backend'i deploy etmeniz **gerekmez**, ancak:
- Testerlar yavaş yanıt alabilir
- Bazı özellikler çalışmayabilir
- "What to Test" notlarında belirtin

**Backend deployment sonraya bırakılabilir (Production öncesi)**

### Test Hesabı
Mutlaka çalışan bir test hesabı oluşturun:
```
Email: test@investguide.app
Password: TestUser123!
```

Apple reviewer bu hesapla giriş yapacak!

### Screenshot Sırası Önemli
İlk 3 screenshot en önemli (App Store'da önce bunlar görünür):
1. Ana Ekran (WOW faktörü)
2. Portföy (ana özellik)
3. AI Analiz (farklılaştırıcı)

---

## 🎯 BAŞARI KRİTERLERİ

### TestFlight Onayı İçin:
- [ ] Build başarıyla upload edildi
- [ ] Processing tamamlandı
- [ ] Export Compliance dolduruldu
- [ ] Test bilgileri eklendi
- [ ] En az 1 internal tester test etti
- [ ] Kritik bug yok

### Production Hazırlığı İçin:
- [ ] 6-8 screenshot hazır
- [ ] App icon 1024x1024 px
- [ ] Privacy Policy URL aktif
- [ ] Store listing metinleri hazır
- [ ] Beta test başarılı (crash rate < %1)
- [ ] En az 10 tester pozitif geri bildirim

---

## 📞 YARDIM VE KAYNAKLAR

### Oluşturulan Dosyalar
- `PRIVACY_POLICY.md` - Gizlilik politikası (Markdown)
- `TERMS_OF_SERVICE.md` - Kullanım şartları (Markdown)
- `STORE_LISTING.md` - Store metinleri (TR/EN)
- `SCREENSHOT_GUIDE.md` - Screenshot rehberi
- `TESTFLIGHT_DEPLOYMENT.md` - Deployment rehberi
- `docs/privacy.html` - Privacy Policy (web)
- `docs/terms.html` - Terms of Service (web)
- `docs/index.html` - Landing page
- `docs/README.md` - GitHub Pages rehberi

### Faydalı Linkler
- [App Store Connect](https://appstoreconnect.apple.com)
- [TestFlight Docs](https://developer.apple.com/testflight/)
- [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [GitHub Pages](https://pages.github.com)

### İletişim
Sorularınız için: support@investguide.app

---

## ✅ HIZLI BAŞLANGIÇ

**Şu anda yapmanız gerekenler (öncelik sırasına göre):**

1. **GitHub'a Push Et** (15 dk)
   ```bash
   git init
   git add .
   git commit -m "Add documentation"
   git push
   ```

2. **GitHub Pages Aktifleştir** (5 dk)
   - Settings → Pages → Enable

3. **Screenshot'ları Hazırla** (2-4 saat)
   - En az 6 adet
   - 1290x2796 px

4. **App Icon Hazırla** (30 dk)
   - 1024x1024 px
   - Marka kimliği

5. **TestFlight'a Upload** (1 saat)
   - TESTFLIGHT_DEPLOYMENT.md takip et

---

**Başarılar! 🚀**

*Herhangi bir adımda takılırsanız, ilgili .md dosyasına bakın veya bana sorun!*
