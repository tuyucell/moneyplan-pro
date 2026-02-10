# MoneyPlan Pro Deployment - Quick Start

## 🚀 Hızlı Başlangıç / MoneyPlan Pro Deployment - Quick Start

Bu rehber, uygulamanızı App Store ve Play Store'a yüklemek ve web sitesini yayınlamak için gereken adımları özetler.

---

## 📱 1. Önce Yapılması Gerekenler

### ✅ Bilgi Toplama

Aşağıdaki bilgileri hazırlayın:

1.  **Şirket/Kişi Bilgileri:**
    - Şirket adı (veya adınız)
    - Adres (KVKK zorunluluğu)
    - E-posta adresi
    - Telefon numarası (opsiyonel)

2.  **Domain Adı:**
    - Almak istediğiniz domain (örn: `investguide.app`)

3.  **Developer Hesapları:**
    - Apple Developer ($99/yıl) - https://developer.apple.com
    - Google Play Developer ($25 tek seferlik) - https://play.google.com/console

### ✅ Yasal Dokümanları Güncelleme

Aşağıdaki dosyalardaki `[PLACEHOLDER]` alanlarını doldurun:

```bash
# Düzenlenecek dosyalar:
PRIVACY_POLICY.md
TERMS_OF_SERVICE.md
website/privacy.html
website/terms.html
website/kvkk.html
```

Değiştirilecek placeholder'lar:
- `[COMPANY_NAME]` → Şirket adınız
- `[COMPANY_ADDRESS]` → Adresiniz
- `[SUPPORT_EMAIL]` → Destek e-postanız
- `[PHONE_NUMBER]` → Telefon numaranız
- `[WEBSITE_URL]` → Web siteniz (domain aldıktan sonra)
- `[PRIVACY_POLICY_URL]` → Privacy policy URL'i
- `[CITY]` → Şehriniz

---

## 🌐 2. MoneyPlan Pro Website Deployment (1-2 saat)

### Adım 1: GitHub'a Push

```bash
cd /Users/turgayyucel/invest-guide-app

# Git başlat (eğer yoksa)
git init

# Dosyaları ekle
git add .

# Commit
git commit -m "Initial commit"

# GitHub'a push (önce GitHub'da repo oluşturun)
git remote add origin https://github.com/KULLANICI_ADINIZ/invest-guide-app.git
git push -u origin main
```

### Adım 2: GitHub Pages Aktifleştir

1.  GitHub repo → Settings → Pages
2.  Source: `main` branch, `/docs` folder
3.  Save
4.  5 dakika bekleyin
5.  Test edin: `https://KULLANICI_ADINIZ.github.io/invest-guide-app/`

### Adım 3: Domain Al ve Cloudflare Kur

1.  Domain satın alın (Namecheap, GoDaddy, veya Cloudflare)
2.  Cloudflare hesabı oluşturun
3.  Domain'i Cloudflare'e ekleyin
4.  Nameserver'ları güncelleyin
5.  DNS kayıtlarını ekleyin (A records + CNAME)
6.  GitHub Pages'de custom domain ekleyin

**Detaylı rehber:** `WEBSITE_DEPLOYMENT_GUIDE.md`

---

## 🤖 3. Android Deployment (2-3 saat)

### Adım 1: Keystore Oluştur

```bash
keytool -genkey -v -keystore android/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

**ÖNEMLİ:** Şifreleri kaydedin! Kaybederseniz uygulamayı güncelleyemezsiniz!

### Adım 2: key.properties Oluştur

`android/key.properties` dosyası oluşturun:

```properties
KEYSTORE_FILE=../upload-keystore.jks
KEYSTORE_PASSWORD=şifreniz
KEY_ALIAS=upload
KEY_PASSWORD=şifreniz
```

### Adım 3: Build ve Upload

```bash
# Deployment script kullan
./deploy.sh

# Veya manuel:
flutter clean
flutter pub get
flutter build appbundle --release
```

Upload: `build/app/outputs/bundle/release/app-release.aab` → Google Play Console

**Detaylı rehber:** `ANDROID_SIGNING_GUIDE.md`

---

## 🍎 4. iOS Deployment (2-3 saat)

### Adım 1: Apple Developer Hesabı

1.  https://developer.apple.com adresinden kayıt olun ($99/yıl)
2.  Certificates, Identifiers & Profiles → App IDs oluşturun

### Adım 2: App Store Connect

1.  https://appstoreconnect.apple.com
2.  My Apps → + → New App
3.  Bilgileri doldurun:
    - Name: Yatırım Rehberi
    - Bundle ID: com.turgayyucel.investguide
    - SKU: invest-guide-001

### Adım 3: Build ve Upload

```bash
# Deployment script kullan
./deploy.sh

# Veya manuel:
flutter clean
flutter pub get
flutter build ios --release

# Sonra Xcode'da:
open ios/Runner.xcworkspace
# Product → Archive → Distribute
```

**Detaylı rehber:** `TESTFLIGHT_DEPLOYMENT.md`

---

## 📸 5. Ekran Görüntüleri ve Grafikler

### iOS (App Store)

**Gerekli boyutlar:**
- iPhone 15 Pro Max: 1290 x 2796 px (6-8 adet)
- iPad Pro: 2048 x 2732 px (opsiyonel)

### Android (Play Store)

**Gerekli boyutlar:**
- Phone: 1080 x 1920 px (min 2, max 8)
- Tablet: 1600 x 2560 px (opsiyonel)
- Feature Graphic: 1024 x 500 px (zorunlu)

**Araçlar:**
- Figma (ücretsiz) - https://figma.com
- Canva (ücretsiz) - https://canva.com
- Gerçek cihazda screenshot al

**Detaylı rehber:** `SCREENSHOT_GUIDE.md`

---

## 🎯 6. Store Listing Bilgileri

### App Store Connect

```
Name: MoneyPlan Pro - Portföy & Bütçe
Subtitle: Portföy & Bütçe Yönetimi
Category: Finance (Primary), Productivity (Secondary)
Age Rating: 17+
Privacy Policy: https://yourdomain.com/privacy.html
Support URL: https://yourdomain.com/
```

### Google Play Console

```
App Name: Yatırım Rehberi - Portföy & Bütçe
Short Description: Portföy takibi, bütçe yönetimi ve AI destekli yatırım analizi
Category: Finance
Content Rating: Everyone
Privacy Policy: https://yourdomain.com/privacy.html
```

**Tüm metinler:** `STORE_LISTING.md`

---

## ✅ Deployment Checklist

### Web Sitesi
- [ ] GitHub'a push edildi
- [ ] GitHub Pages aktif
- [ ] Domain alındı
- [ ] Cloudflare DNS yapılandırıldı
- [ ] HTTPS çalışıyor
- [ ] Tüm sayfalar erişilebilir
- [ ] Placeholder'lar güncellendi

### Android
- [ ] Keystore oluşturuldu ve yedeklendi
- [ ] key.properties dosyası oluşturuldu
- [ ] AAB build edildi
- [ ] Play Console'da uygulama oluşturuldu
- [ ] Ekran görüntüleri yüklendi
- [ ] Store listing tamamlandı
- [ ] Internal testing yapıldı
- [ ] Production'a yüklendi

### iOS
- [ ] Apple Developer hesabı aktif
- [ ] App Store Connect'te uygulama oluşturuldu
- [ ] Ekran görüntüleri yüklendi
- [ ] Store listing tamamlandı
- [ ] Xcode'da archive edildi
- [ ] TestFlight'a yüklendi
- [ ] Beta test yapıldı
- [ ] Review'a gönderildi

---

## 🛠️ Faydalı Komutlar

### Deployment Script

```bash
# İnteraktif menü
./deploy.sh

# Veya direkt komutlar:
./deploy.sh clean          # Temizlik
./deploy.sh android-full   # Android full deployment
./deploy.sh ios-full       # iOS full deployment
./deploy.sh bundle         # Android AAB build
./deploy.sh verify         # Signing doğrula
```

### Version Güncelleme

`pubspec.yaml` dosyasında:
```yaml
version: 1.0.1+5  # 1.0.1 = version name, 5 = build number
```

Her release'de build number'ı artırın!

---

## 📚 Tüm Rehberler

1. **WEBSITE_DEPLOYMENT_GUIDE.md** - Web sitesi deployment
2. **ANDROID_SIGNING_GUIDE.md** - Android keystore ve signing
3. **TESTFLIGHT_DEPLOYMENT.md** - iOS TestFlight
4. **SCREENSHOT_GUIDE.md** - Ekran görüntüleri
5. **STORE_LISTING.md** - Store metinleri
6. **DEPLOYMENT_CHECKLIST.md** - Detaylı checklist

---

## ⏱️ Tahmini Süre

| Görev | Süre |
|-------|------|
| Bilgi toplama ve placeholder güncelleme | 1 saat |
| Web sitesi deployment | 1-2 saat |
| Android keystore + build | 1 saat |
| iOS build + upload | 1 saat |
| Ekran görüntüleri hazırlama | 2-4 saat |
| Store listing tamamlama | 1-2 saat |
| Test ve düzeltmeler | 2-3 saat |
| **TOPLAM** | **9-14 saat** |

**Bekleme süreleri:**
- DNS propagation: 2-48 saat
- App Store review: 1-3 gün
- Play Store review: Birkaç saat - 1-2 gün

---

## 🆘 Yardım

Herhangi bir adımda takılırsanız:

1. İlgili detaylı rehbere bakın
2. Hata mesajını Google'da arayın
3. GitHub Issues'da sorun açın
4. [SUPPORT_EMAIL] adresine e-posta gönderin

---

**Başarılar! 🚀**
