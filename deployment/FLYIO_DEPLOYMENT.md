# Fly.io Deployment Rehberi - Yatırım Rehberi Backend

## 🚀 Fly.io ile 10 Dakikada Deployment

### Neden Fly.io?
- ✅ **Ücretsiz tier** (3 VM, 256MB RAM her biri)
- ✅ **Always-on** (cold start yok)
- ✅ **Otomatik HTTPS**
- ✅ **Global edge network** (hızlı)
- ✅ **Kolay deployment** (5 komut)
- ✅ **VPS uğraşı yok**

---

## 📋 Adım 1: Fly.io CLI Kurulumu

### Mac'te:
```bash
# Homebrew ile kur
brew install flyctl

# Versiyon kontrol
flyctl version
```

### Alternatif (Homebrew yoksa):
```bash
curl -L https://fly.io/install.sh | sh
```

---

## 🔐 Adım 2: Fly.io Hesabı ve Login

```bash
# Hesap oluştur ve login (tarayıcı açılır)
flyctl auth signup

# veya mevcut hesapla login
flyctl auth login
```

**Tarayıcıda:**
- GitHub ile sign up (en kolay)
- Email doğrula
- Kredi kartı GEREKMEZ (ücretsiz tier için)

---

## 📦 Adım 3: Backend Hazırlığı

### 3.1 Gerekli Dosyaları Oluştur

```bash
cd /Users/turgayyucel/invest-guide-app/backend
```

#### `fly.toml` oluştur:
```bash
cat > fly.toml << 'EOF'
app = "invest-guide-api"
primary_region = "ams"  # Amsterdam (Türkiye'ye en yakın)

[build]
  builder = "paketobuildpacks/builder:base"

[env]
  PORT = "8000"

[http_service]
  internal_port = 8000
  force_https = true
  auto_stop_machines = false
  auto_start_machines = true
  min_machines_running = 1

[[vm]]
  cpu_kind = "shared"
  cpus = 1
  memory_mb = 256
EOF
```

#### `Procfile` oluştur:
```bash
cat > Procfile << 'EOF'
web: uvicorn main:app --host 0.0.0.0 --port $PORT
EOF
```

#### `runtime.txt` oluştur (Python versiyonu):
```bash
cat > runtime.txt << 'EOF'
python-3.11
EOF
```

### 3.2 requirements.txt Kontrol
```bash
# Mevcut requirements.txt'yi kontrol et
cat requirements.txt

# Eksikse uvicorn ekle
echo "uvicorn[standard]==0.27.0" >> requirements.txt
```

---

## 🚀 Adım 4: Fly.io'ya Deploy

### 4.1 Uygulama Oluştur
```bash
# Backend dizininde
cd /Users/turgayyucel/invest-guide-app/backend

# Fly.io uygulaması oluştur
flyctl launch

# Sorular:
# App name: invest-guide-api (veya boş bırak, otomatik oluşturur)
# Region: Amsterdam (ams) - Türkiye'ye en yakın
# PostgreSQL: No (gerekmez)
# Redis: No (gerekmez)
# Deploy now: Yes
```

### 4.2 İlk Deployment
```bash
# Deploy et
flyctl deploy

# 2-3 dakika sürer...
# ✅ Deployment tamamlandı!
```

### 4.3 URL Al
```bash
# Uygulama bilgisi
flyctl info

# URL: https://invest-guide-api.fly.dev
# veya
flyctl status
```

---

## ✅ Adım 5: Test ve Doğrulama

### 5.1 Backend Testi
```bash
# Health check
curl https://invest-guide-api.fly.dev/

# Beklenen: {"status":"active"}

# Market summary test
curl https://invest-guide-api.fly.dev/api/v1/market/summary

# Crypto test
curl https://invest-guide-api.fly.dev/api/v1/market/crypto?limit=5
```

### 5.2 Logs Kontrol
```bash
# Canlı logları izle
flyctl logs

# Son 100 log
flyctl logs -n 100
```

### 5.3 Dashboard
```bash
# Web dashboard aç
flyctl dashboard
```

---

## 📱 Adım 6: Flutter'da URL Güncelle

```dart
// lib/core/constants/api_constants.dart
class ApiConstants {
  // Fly.io URL (HTTPS otomatik!)
  static const String baseUrl = 'https://invest-guide-api.fly.dev';
}
```

**Commit ve test et:**
```bash
cd /Users/turgayyucel/invest-guide-app

# Değişikliği kaydet
git add lib/core/constants/api_constants.dart
git commit -m "Update API URL to Fly.io"

# Flutter'da test et
flutter run
```

---

## 🔧 Adım 7: Yapılandırma ve Optimizasyon

### 7.1 Environment Variables (Gerekirse)
```bash
# Secret ekle
flyctl secrets set API_KEY=your_secret_key

# Listele
flyctl secrets list
```

### 7.2 Scaling (Ücretsiz tier'da 3 VM'e kadar)
```bash
# VM sayısını artır (opsiyonel)
flyctl scale count 2

# Memory artır (ücretli)
flyctl scale memory 512
```

### 7.3 Regions (Multi-region deployment)
```bash
# Başka region ekle (opsiyonel, ücretli)
flyctl regions add fra  # Frankfurt
flyctl regions add lhr  # London
```

---

## 📊 Monitoring ve Yönetim

### Logs
```bash
# Canlı loglar
flyctl logs

# Hata logları
flyctl logs --level error
```

### Status
```bash
# Uygulama durumu
flyctl status

# VM'lerin durumu
flyctl machine list
```

### Restart
```bash
# Yeniden başlat
flyctl apps restart invest-guide-api
```

### SSH (Debug için)
```bash
# VM'e SSH ile bağlan
flyctl ssh console
```

---

## 🔄 Güncelleme (Yeni Kod Deploy)

```bash
# Backend'de değişiklik yaptıktan sonra
cd /Users/turgayyucel/invest-guide-app/backend

# Deploy et
flyctl deploy

# Otomatik build, deploy ve restart olur
```

---

## 💰 Maliyet

### Ücretsiz Tier
- **3 shared-cpu VM** (256MB RAM her biri)
- **3GB persistent volume** (kullanmıyoruz)
- **160GB outbound transfer/ay**

**Yeterli mi?** ✅ Evet! Beta test için fazlasıyla yeterli.

### Ücretli (Gerekirse)
- **Dedicated CPU:** $0.02/saat (~$15/ay)
- **Extra Memory:** $0.0000022/MB/saat
- **Extra VM:** $0.02/saat

---

## 🎯 Hızlı Başlangıç (Tüm Komutlar)

```bash
# 1. Fly.io CLI kur
brew install flyctl

# 2. Login
flyctl auth login

# 3. Backend dizinine git
cd /Users/turgayyucel/invest-guide-app/backend

# 4. Gerekli dosyaları oluştur
cat > fly.toml << 'EOF'
app = "invest-guide-api"
primary_region = "ams"

[build]
  builder = "paketobuildpacks/builder:base"

[env]
  PORT = "8000"

[http_service]
  internal_port = 8000
  force_https = true
  auto_stop_machines = false
  auto_start_machines = true
  min_machines_running = 1

[[vm]]
  cpu_kind = "shared"
  cpus = 1
  memory_mb = 256
EOF

cat > Procfile << 'EOF'
web: uvicorn main:app --host 0.0.0.0 --port $PORT
EOF

cat > runtime.txt << 'EOF'
python-3.11
EOF

# 5. Deploy
flyctl launch
# Sorulara cevap ver, deploy et

# 6. Test
flyctl status
curl https://invest-guide-api.fly.dev/

# 7. Flutter'da URL güncelle
# lib/core/constants/api_constants.dart
# static const String baseUrl = 'https://invest-guide-api.fly.dev';
```

---

## ⚠️ Sorun Giderme

### Build hatası
```bash
# Logları kontrol et
flyctl logs

# Manuel build
flyctl deploy --verbose
```

### App başlamıyor
```bash
# VM durumu
flyctl machine list

# Restart
flyctl apps restart invest-guide-api

# SSH ile debug
flyctl ssh console
python --version
which uvicorn
```

### Port hatası
```bash
# fly.toml'de PORT doğru mu?
# Procfile'da $PORT kullanılıyor mu?
```

---

## 🎉 Başarı Kriterleri

- ✅ `flyctl status` → running
- ✅ `curl https://invest-guide-api.fly.dev/` → {"status":"active"}
- ✅ Flutter app'te API çalışıyor
- ✅ Loglar temiz (hata yok)

---

## 📞 Yardım

### Fly.io Dokümantasyon
- [Fly.io Docs](https://fly.io/docs/)
- [Python Deployment](https://fly.io/docs/languages-and-frameworks/python/)
- [Troubleshooting](https://fly.io/docs/getting-started/troubleshooting/)

### Community
- [Fly.io Community](https://community.fly.io/)
- Discord: [fly.io/discord](https://fly.io/discord)

---

## 🚀 Sonraki Adım

Deployment tamamlandıktan sonra:

1. **Flutter'da test et**
2. **TestFlight'a geç!**
3. **Screenshot'ları hazırla**
4. **Beta test başlat**

**Toplam süre:** 10-15 dakika 🎯

---

Hazırsanız başlayalım! İlk komut:

```bash
brew install flyctl
```

Kurulum tamamlandıktan sonra devam edelim! 🚀
