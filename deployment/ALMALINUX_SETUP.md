# AlmaLinux Backend Kurulum Rehberi - Yatırım Rehberi

## 🔍 Adım 1: Sistem Kontrolü

### 1.1 İşletim Sistemi ve Versiyon
```bash
# OS bilgisi
cat /etc/os-release

# Kernel versiyon
uname -a

# Hostname
hostname
```

### 1.2 Mevcut Backend Durumu
```bash
# Backend çalışıyor mu?
ps aux | grep uvicorn

# Port 8000 dinleniyor mu?
ss -tulpn | grep 8000
# veya
netstat -tulpn | grep 8000

# Backend'e erişim testi
curl http://localhost:8000/
# Beklenen: {"status": "active"}

# Dışarıdan erişim testi
curl http://104.247.166.225:8000/
```

### 1.3 Nginx Kurulu mu?
```bash
# Nginx var mı?
which nginx
nginx -v

# Nginx çalışıyor mu?
systemctl status nginx
```

### 1.4 Certbot Kurulu mu?
```bash
# Certbot var mı?
which certbot
certbot --version
```

### 1.5 Firewall Durumu
```bash
# Firewalld durumu
systemctl status firewalld

# Açık portlar
firewall-cmd --list-all

# veya iptables
iptables -L -n
```

### 1.6 SELinux Durumu
```bash
# SELinux durumu (AlmaLinux'ta önemli!)
getenforce
sestatus
```

---

## 📦 Adım 2: Kurulum (AlmaLinux için)

### 2.1 Sistem Güncelleme
```bash
# Paket listesini güncelle
sudo dnf update -y

# EPEL repository ekle (Extra Packages)
sudo dnf install epel-release -y
```

### 2.2 Nginx Kurulumu
```bash
# Nginx kur
sudo dnf install nginx -y

# Versiyon kontrol
nginx -v

# Başlat ve aktifleştir
sudo systemctl start nginx
sudo systemctl enable nginx

# Durum kontrol
sudo systemctl status nginx
```

### 2.3 Certbot Kurulumu (Let's Encrypt için)
```bash
# Certbot ve Nginx plugin kur
sudo dnf install certbot python3-certbot-nginx -y

# Versiyon kontrol
certbot --version
```

### 2.4 Firewall Yapılandırması
```bash
# HTTP (80) ve HTTPS (443) portlarını aç
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https

# Backend port (8000) - sadece localhost'tan erişim
# (Nginx reverse proxy kullanacağız, dışarıya açmaya gerek yok)

# Firewall'u yeniden yükle
sudo firewall-cmd --reload

# Kontrol
sudo firewall-cmd --list-all
```

---

## 🔧 Adım 3: Nginx Yapılandırması

### 3.1 Backend Testi
```bash
# Backend çalışıyor mu kontrol et
curl http://localhost:8000/

# Çalışmıyorsa başlat
cd /root/invest-guide-app/backend  # veya backend path'iniz
source venv/bin/activate
uvicorn main:app --host 127.0.0.1 --port 8000 &
```

### 3.2 Nginx Config Oluştur
```bash
# Config dosyası oluştur
sudo nano /etc/nginx/conf.d/investguide.conf
```

**Config içeriği (IP ile - domain yoksa):**
```nginx
server {
    listen 80;
    server_name 104.247.166.225;

    # Güvenlik headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    # API endpoint
    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Timeout ayarları
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # Health check endpoint
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
}
```

**Config içeriği (Domain ile - varsa):**
```nginx
server {
    listen 80;
    server_name api.investguide.app;  # Domain'inizi yazın

    # Güvenlik headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
}
```

### 3.3 Nginx Config Test ve Restart
```bash
# Config syntax kontrol
sudo nginx -t

# Başarılıysa restart
sudo systemctl restart nginx

# Durum kontrol
sudo systemctl status nginx
```

### 3.4 Erişim Testi
```bash
# Nginx üzerinden backend'e erişim
curl http://104.247.166.225/

# Beklenen: {"status": "active"}

# Dışarıdan test (başka bir bilgisayardan)
curl http://104.247.166.225/
```

---

## 🔒 Adım 4: HTTPS Kurulumu (Domain varsa)

### 4.1 Domain DNS Ayarları
```bash
# Domain'iniz varsa DNS A kaydı ekleyin:
# api.investguide.app -> 104.247.166.225

# DNS propagation kontrol (5-10 dakika bekleyin)
nslookup api.investguide.app
dig api.investguide.app
```

### 4.2 Let's Encrypt SSL Sertifikası
```bash
# Domain ile SSL al
sudo certbot --nginx -d api.investguide.app

# Sorular:
# Email: your-email@example.com
# Terms: Agree (A)
# Share email: No (N)
# Redirect HTTP to HTTPS: Yes (2)

# Otomatik yenileme testi
sudo certbot renew --dry-run
```

### 4.3 SSL Sonrası Test
```bash
# HTTPS erişim
curl https://api.investguide.app/

# SSL sertifika kontrol
openssl s_client -connect api.investguide.app:443 -servername api.investguide.app
```

---

## 🚀 Adım 5: Systemd Service (Otomatik Başlatma)

### 5.1 Backend Path Bul
```bash
# Backend dizinine git
cd /root/invest-guide-app/backend  # veya path'iniz
pwd  # Path'i not edin
```

### 5.2 Service Dosyası Oluştur
```bash
sudo nano /etc/systemd/system/investguide.service
```

**Service içeriği:**
```ini
[Unit]
Description=InvestGuide FastAPI Backend
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/root/invest-guide-app/backend
Environment="PATH=/root/invest-guide-app/backend/venv/bin"
ExecStart=/root/invest-guide-app/backend/venv/bin/uvicorn main:app --host 127.0.0.1 --port 8000 --workers 4
Restart=always
RestartSec=10
StandardOutput=append:/var/log/investguide/app.log
StandardError=append:/var/log/investguide/error.log

[Install]
WantedBy=multi-user.target
```

### 5.3 Log Dizini Oluştur
```bash
# Log dizini
sudo mkdir -p /var/log/investguide
sudo chown root:root /var/log/investguide
```

### 5.4 Service Aktifleştir
```bash
# Systemd'yi yeniden yükle
sudo systemctl daemon-reload

# Service'i başlat
sudo systemctl start investguide

# Otomatik başlatmayı aktifleştir
sudo systemctl enable investguide

# Durum kontrol
sudo systemctl status investguide

# Logları izle
sudo journalctl -u investguide -f
```

### 5.5 Service Komutları
```bash
# Başlat
sudo systemctl start investguide

# Durdur
sudo systemctl stop investguide

# Yeniden başlat
sudo systemctl restart investguide

# Durum
sudo systemctl status investguide

# Loglar
sudo journalctl -u investguide -n 100
```

---

## 🛡️ Adım 6: SELinux Yapılandırması (AlmaLinux için Önemli!)

### 6.1 SELinux Durumu Kontrol
```bash
getenforce
# Enforcing ise SELinux aktif
```

### 6.2 Nginx için SELinux İzinleri
```bash
# Nginx'in network'e bağlanmasına izin ver
sudo setsebool -P httpd_can_network_connect 1

# Port 8000'e erişim izni
sudo semanage port -a -t http_port_t -p tcp 8000

# SELinux context ayarla (backend dizini için)
sudo chcon -R -t httpd_sys_content_t /root/invest-guide-app/backend
```

---

## ✅ Adım 7: Final Kontroller

### 7.1 Tüm Servislerin Durumu
```bash
# Backend service
sudo systemctl status investguide

# Nginx
sudo systemctl status nginx

# Firewall
sudo firewall-cmd --list-all
```

### 7.2 Erişim Testleri
```bash
# Localhost'tan
curl http://localhost:8000/

# Nginx üzerinden
curl http://104.247.166.225/

# HTTPS (domain varsa)
curl https://api.investguide.app/
```

### 7.3 Log Kontrolleri
```bash
# Backend logs
sudo journalctl -u investguide -n 50

# Nginx access log
sudo tail -f /var/log/nginx/access.log

# Nginx error log
sudo tail -f /var/log/nginx/error.log
```

---

## 🔧 Sorun Giderme

### Nginx başlamıyor
```bash
# SELinux kontrol
sudo ausearch -m avc -ts recent

# Port kullanımda mı?
sudo ss -tulpn | grep :80
```

### Backend'e erişilemiyor
```bash
# Backend çalışıyor mu?
sudo systemctl status investguide

# Port açık mı?
sudo ss -tulpn | grep :8000

# Firewall?
sudo firewall-cmd --list-all
```

### SSL hatası
```bash
# Certbot logs
sudo journalctl -u certbot

# Manuel SSL yenileme
sudo certbot renew --force-renewal
```

---

## 📊 Özet Komutlar (Hızlı Kurulum)

```bash
# 1. Sistem güncelle
sudo dnf update -y
sudo dnf install epel-release -y

# 2. Nginx ve Certbot kur
sudo dnf install nginx certbot python3-certbot-nginx -y

# 3. Firewall aç
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --reload

# 4. SELinux izinleri
sudo setsebool -P httpd_can_network_connect 1

# 5. Nginx config oluştur (yukarıdaki içerikle)
sudo nano /etc/nginx/conf.d/investguide.conf

# 6. Nginx başlat
sudo nginx -t
sudo systemctl start nginx
sudo systemctl enable nginx

# 7. Systemd service oluştur (yukarıdaki içerikle)
sudo nano /etc/systemd/system/investguide.service
sudo mkdir -p /var/log/investguide

# 8. Service başlat
sudo systemctl daemon-reload
sudo systemctl start investguide
sudo systemctl enable investguide

# 9. Test
curl http://104.247.166.225/
```

---

## 🎯 Sonraki Adım

Kurulum tamamlandıktan sonra:

1. **Flutter'da URL güncelle:**
```dart
// lib/core/constants/api_constants.dart
static const String baseUrl = 'http://104.247.166.225';
// veya HTTPS varsa
static const String baseUrl = 'https://api.investguide.app';
```

2. **TestFlight'a geç!** 🚀

---

Hangi adımdan başlamak istersiniz? Önce kontrol komutlarını çalıştıralım mı?
