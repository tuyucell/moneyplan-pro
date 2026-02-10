# InvestGuide Admin Panel - Detaylı Analiz

**Tarih:** 22 Ocak 2026  
**Platform:** React Web Application (Hugging Face Spaces)  
**Backend:** Supabase (PostgreSQL + Realtime + Auth + Storage)

---

## 1. PROJE HEDEFI

InvestGuide mobil uygulaması için merkezi bir yönetim paneli oluşturulması. Panel üzerinden kullanıcı davranışları izlenecek, kampanyalar yönetilecek, reklamlar düzenlenecek ve push notification gönderilecek.

---

## 2. TEMEL ÖZELLİKLER

### 2.1 Dashboard (Ana Sayfa)
- **Gerçek Zamanlı İstatistikler**
  - Toplam kullanıcı sayısı (Aktif/Pasif/Guest)
  - Günlük/Haftalık/Aylık aktif kullanıcılar (DAU/WAU/MAU)
  - Yeni kayıtlar (Son 24 saat, 7 gün, 30 gün)
  - Premium kullanıcı oranı
  - Ortalama session süresi
  - Churn rate (Kullanıcı kaybı oranı)
  
- **Kullanım Metrikleri**
  - En çok kullanılan özellikler
  - Ekran görüntüleme sıklığı
  - API çağrı istatistikleri
  - Hata ve crash raporları

- **Gelir Metrikleri**
  - Günlük/Aylık gelir (MRR - Monthly Recurring Revenue)
  - Conversion rate (Ücretsiz → Premium)
  - ARPU (Average Revenue Per User)
  - LTV (Lifetime Value)

- **Grafikler ve Görselleştirme**
  - Zaman serisi grafikleri (Chart.js/Recharts)
  - Kullanıcı segmentasyon pie charts
  - Coğrafi dağılım haritası
  - Funnel analizi

### 2.2 Kullanıcı Yönetimi
- **Kullanıcı Listesi**
  - Arama ve filtreleme (Email, isim, durum, üyelik tipi)
  - Sıralama (Kayıt tarihi, son aktivite, harcama)
  - Toplu işlemler (Ban, premium verme, silme)
  - Export (CSV, Excel)

- **Kullanıcı Detayları**
  - Profil bilgileri
  - Aktivite timeline'ı
  - Session geçmişi
  - İşlem geçmişi (Transaction history)
  - Davranış analizi (Hangi özellikleri kullanıyor)
  - Satın alma geçmişi
  - Push notification geçmişi

- **Kullanıcı Segmentasyonu**
  - Özel segment oluşturma
  - Kayıtlı segmentler (Power users, Churners, etc.)
  - Segment bazlı kampanya hedefleme

### 2.3 Kampanya Yönetimi
- **Kampanya Oluşturma**
  - Kampanya adı ve açıklama
  - Hedef kitle seçimi (Segment bazlı)
  - Başlangıç/Bitiş tarihi
  - Kampanya tipi (İndirim, Bonus, Özel özellik açma)
  - Trigger koşulları (Otomatik/Manuel)

- **Kampanya Takibi**
  - Aktif/Pasif/Tamamlanan kampanyalar
  - Katılım oranları
  - Conversion metrikleri
  - ROI hesaplaması

- **A/B Testing**
  - Kampanya varyantları oluşturma
  - Test sonuçları karşılaştırma
  - Otomatik kazanan seçimi

### 2.4 Reklam Yönetimi
- **İçerik Bazlı Reklamlar**
  - Banner reklamlar (Ana sayfa, yan menü)
  - In-app reklamlar
  - Native ads (İçerik akışında)
  
- **Reklam Oluşturma**
  - Görsel yükleme
  - Başlık ve açıklama
  - CTA (Call-to-Action) düğmesi
  - Target URL veya deep link
  - Gösterim koşulları (Kullanıcı segmenti, zaman, frekans)

- **Reklam Performansı**
  - Impression count
  - Click-through rate (CTR)
  - Conversion rate
  - Revenue per impression

- **Reklam Planlaması**
  - Zamanlama (Başlangıç/Bitiş)
  - Frequency capping (Aynı kullanıcıya gösterim limiti)
  - Priority/Weight sistemi

### 2.5 Push Notification Yönetimi
- **Bildirim Oluşturma**
  - Başlık ve mesaj
  - Rich media (Resim, emoji)
  - Deep link (Belirli ekrana yönlendirme)
  - Aksiyon düğmeleri
  - Hedef kitle (Tüm kullanıcılar, Segmentler, Bireysel)

- **Zamanlama**
  - Anında gönder
  - Gelecek tarih/saat
  - Optimal time (Kullanıcının en aktif olduğu saat)
  - Tekrarlayan bildirimler

- **Bildirim Geçmişi**
  - Gönderilen bildirimler
  - Delivery rate
  - Open rate
  - Click rate
  - Conversion tracking

- **Otomatik Bildirimler**
  - Welcome serisi (Yeni kullanıcılar)
  - Re-engagement (Inaktif kullanıcılar)
  - Feature discovery
  - Premium upsell

### 2.6 Analytics & User Tracking
- **Event Tracking**
  - Özel event tanımlama
  - Event parametreleri
  - Event sıklığı ve trends

- **Funnel Analysis**
  - Kullanıcı yolculuğu haritası
  - Drop-off noktaları
  - Conversion optimization

- **Cohort Analysis**
  - Cohort tanımlama (Kayıt tarihi bazlı)
  - Retention curves
  - Cohort bazlı davranış analizi

- **Session Tracking**
  - Session süresi
  - Screen flow
  - Session bazlı events

### 2.7 Ayarlar ve Konfigürasyon
- **Admin Kullanıcı Yönetimi**
  - Rol bazlı erişim (Super Admin, Admin, Analyst, Content Manager)
  - İzin yönetimi
  - Aktivite logu

- **Sistem Ayarları**
  - API rate limiting
  - Cache ayarları
  - Email/Push notification providers
  - Feature flags

- **İçerik Yönetimi**
  - Uygulama içi duyurular
  - FAQ yönetimi
  - Tutorial içerikleri

---

## 3. TEKNİK STACK

### 3.1 Frontend
- **Framework:** React 18+ (Vite)
- **UI Library:** 
  - Ant Design / Material-UI (Modern components)
  - TailwindCSS (Styling)
- **State Management:** Zustand / Redux Toolkit
- **Data Fetching:** React Query (TanStack Query)
- **Charts:** Recharts / Chart.js
- **Tables:** TanStack Table (React Table v8)
- **Forms:** React Hook Form + Zod validation
- **Routing:** React Router v6
- **Date Handling:** date-fns
- **Rich Text Editor:** TipTap / Quill

### 3.2 Backend & Database
- **BaaS:** Supabase
  - PostgreSQL (Database)
  - PostgREST (Auto API)
  - Realtime (WebSocket subscriptions)
  - Auth (Admin authentication)
  - Storage (Image/file uploads)
  - Edge Functions (Complex logic)

### 3.3 Deployment
- **Hosting:** Hugging Face Spaces (Gradio veya Streamlit alternatifi olarak Static hosting)
  - Alternatif: Vercel / Netlify (Daha uygun)
- **CI/CD:** GitHub Actions

### 3.4 Monitoring & Analytics
- **Error Tracking:** Sentry
- **Analytics:** Plausible / PostHog (Privacy-focused)
- **Logging:** Supabase logs + Custom logging

---

## 4. KULLANICI ROLLERİ VE İZİNLER

### 4.1 Super Admin
- Tüm yetkiler
- Admin kullanıcı ekleme/çıkarma
- Kritik sistem ayarları

### 4.2 Admin
- Kullanıcı yönetimi
- Kampanya ve reklam yönetimi
- Push notification gönderme
- Analytics görüntüleme

### 4.3 Analyst
- Sadece okuma yetkisi
- Analytics ve raporlar
- Export yetkisi

### 4.4 Content Manager
- Kampanya ve reklam yönetimi
- Push notification
- İçerik düzenleme

---

## 5. PERFORMANS VE GÜVENLİK

### 5.1 Performans
- **Lazy loading** (Route bazlı code splitting)
- **Data pagination** (Büyük listeler için)
- **Virtual scrolling** (Uzun listeler için)
- **Optimistic updates** (Hızlı UI feedback)
- **Cache stratejisi** (React Query ile)

### 5.2 Güvenlik
- **Row Level Security (RLS)** Supabase'de
- **API rate limiting**
- **JWT token authentication**
- **CORS policy**
- **Input sanitization**
- **SQL injection koruması** (Supabase otomatik)
- **XSS koruması**

---

## 6. ÖNCELİK SIRASI (MVP → FULL)

### Phase 1 - MVP (2-3 hafta)
- ✅ Authentication (Admin login)
- ✅ Dashboard (Temel metrikler)
- ✅ Kullanıcı listesi ve detayları
- ✅ Temel user tracking
- ✅ Push notification gönderme (Manuel)

### Phase 2 - Core Features (3-4 hafta)
- ✅ Kampanya yönetimi
- ✅ Reklam yönetimi
- ✅ Advanced analytics
- ✅ User segmentation
- ✅ Export functionality

### Phase 3 - Advanced (2-3 hafta)
- ✅ A/B testing
- ✅ Funnel analysis
- ✅ Cohort analysis
- ✅ Otomatik push notifications
- ✅ Admin rol yönetimi

### Phase 4 - Polish & Scale (ongoing)
- ✅ Performance optimization
- ✅ Advanced visualizations
- ✅ Custom reporting
- ✅ Realtime updates

---

## 7. BAŞARI KRİTERLERİ

1. **Kullanılabilirlik**
   - Admin kullanıcıları 5 dakikada kampanya oluşturabilmeli
   - Dashboard 2 saniyeden hızlı yüklenmeli
   - Responsive design (Mobil uyumlu)

2. **Veri Doğruluğu**
   - %100 gerçek zamanlı veri
   - Tutarlı metrikler
   - Audit trail (Her değişiklik loglanmalı)

3. **Güvenilirlik**
   - %99.9 uptime
   - Hata toleransı
   - Graceful degradation

4. **Ölçeklenebilirlik**
   - 100K+ kullanıcı verisi yönetilebilmeli
   - Paralel admin kullanımı
   - Büyük dosya exportları

---

## 8. ENTEGRASYON GEREKSİNİMLERİ

### 8.1 Mobil App ile
- **API Endpoints:** Supabase REST API
- **Realtime Sync:** WebSocket (Supabase Realtime)
- **Push Notifications:** 
  - FCM (Firebase Cloud Messaging) - Android
  - APNs (Apple Push Notification service) - iOS
  - OneSignal / Pusher alternatif

### 8.2 Third-party Services
- **Email:** SendGrid / Resend
- **SMS:** Twilio (opsiyonel)
- **Payment Analytics:** Stripe webhooks (if applicable)
- **External Analytics:** Mixpanel / Amplitude (veri import)
