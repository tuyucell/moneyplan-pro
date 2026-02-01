# GitHub Pages Deployment Rehberi

## 🌐 GitHub Pages ile Privacy Policy & Terms Hosting

### Adım 1: GitHub Repository Oluştur

1. GitHub'da yeni repository oluştur:
   - Repository adı: `invest-guide-app` (veya mevcut repo kullan)
   - Public olarak ayarla

2. Yerel projeyi GitHub'a push et:
```bash
cd /Users/turgayyucel/invest-guide-app
git init
git add .
git commit -m "Initial commit with docs"
git branch -M main
git remote add origin https://github.com/KULLANICI_ADINIZ/invest-guide-app.git
git push -u origin main
```

### Adım 2: GitHub Pages Aktifleştir

1. GitHub repository sayfasına git
2. **Settings** sekmesine tıkla
3. Sol menüden **Pages** seç
4. **Source** bölümünde:
   - Branch: `main`
   - Folder: `/docs`
5. **Save** butonuna tıkla

### Adım 3: URL'leri Kontrol Et

5-10 dakika sonra sayfalar yayında olacak:

- **Ana Sayfa:** `https://KULLANICI_ADINIZ.github.io/invest-guide-app/`
- **Privacy Policy:** `https://KULLANICI_ADINIZ.github.io/invest-guide-app/privacy.html`
- **Terms of Service:** `https://KULLANICI_ADINIZ.github.io/invest-guide-app/terms.html`

### Adım 4: App Store Connect'te Kullan

Bu URL'leri App Store Connect'te şu alanlara gir:

1. **App Information > Privacy Policy URL:**
   ```
   https://KULLANICI_ADINIZ.github.io/invest-guide-app/privacy.html
   ```

2. **App Information > Terms of Service URL (Optional):**
   ```
   https://KULLANICI_ADINIZ.github.io/invest-guide-app/terms.html
   ```

3. **Support URL:**
   ```
   https://KULLANICI_ADINIZ.github.io/invest-guide-app/
   ```

---

## 🎨 Özelleştirme

### Renk Değiştirme

`docs/privacy.html` ve `docs/terms.html` dosyalarında:

```css
/* Mevcut mor renk */
color: #6B4FD8;

/* Kendi renginiz ile değiştirin */
color: #YOUR_COLOR;
```

### Logo Ekleme

Header bölümüne logo eklemek için:

```html
<header>
    <img src="logo.png" alt="Yatırım Rehberi" style="width: 100px; margin-bottom: 20px;">
    <h1>Gizlilik Politikası</h1>
    ...
</header>
```

### İletişim Bilgileri

Tüm dosyalarda `support@investguide.app` adresini kendi e-postanızla değiştirin.

---

## 📱 Özel Domain (Opsiyonel)

Kendi domain'iniz varsa (örn: investguide.app):

1. Domain sağlayıcınızda CNAME kaydı ekleyin:
   ```
   www.investguide.app -> KULLANICI_ADINIZ.github.io
   ```

2. GitHub Pages ayarlarında **Custom domain** alanına:
   ```
   www.investguide.app
   ```

3. **Enforce HTTPS** işaretleyin

4. URL'ler şu şekilde olacak:
   - `https://www.investguide.app/privacy.html`
   - `https://www.investguide.app/terms.html`

---

## ✅ Checklist

- [ ] GitHub repository oluşturuldu
- [ ] `docs/` klasörü push edildi
- [ ] GitHub Pages aktifleştirildi
- [ ] URL'ler test edildi (açılıyor mu?)
- [ ] İletişim bilgileri güncellendi
- [ ] App Store Connect'te URL'ler eklendi

---

## 🔧 Sorun Giderme

### Sayfa 404 Hatası Veriyor
- 5-10 dakika bekleyin (deployment süresi)
- Branch ve folder ayarlarını kontrol edin
- `docs/` klasöründe dosyalar var mı kontrol edin

### CSS Yüklenmiyor
- Dosya isimleri doğru mu? (`privacy.html`, `terms.html`)
- Büyük/küçük harf duyarlılığı (Linux sunucularda)

### Değişiklikler Görünmüyor
- GitHub'a push ettiniz mi?
- Tarayıcı cache'ini temizleyin (Cmd+Shift+R)
- 5-10 dakika bekleyin

---

## 📞 Yardım

GitHub Pages hakkında daha fazla bilgi:
- [GitHub Pages Dokümantasyonu](https://docs.github.com/en/pages)
- [Jekyll Themes](https://pages.github.com/themes/) (daha gelişmiş tasarım için)
