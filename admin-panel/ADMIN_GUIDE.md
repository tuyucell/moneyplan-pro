# 👔 MoneyPlan Pro - Yönetici Kullanım Kılavuzu (Admin Guide)

Bu kılavuz, MoneyPlan Pro yönetici panelindeki özellikleri, araçları ve günlük operasyonları nasıl yöneteceğinizi adım adım açıklar.

---

## 🚀 1. Dashboard (Genel Bakış)
Dashboard, uygulamanın anlık sağlık durumunu ve büyüme verilerini gösteren ana merkezdir.

*   **Takip Edilen Metrikler:**
    *   **Total Users:** Kayıtlı toplam kullanıcı sayısı.
    *   **MAU/DAU:** Aylık ve günlük aktif kullanıcılar. Uygulamanın ne kadar "yapışkan" (stickiness) olduğunu gösterir.
    *   **Premium Conversion:** Ücretsiz kullanıcıların ne kadarının ücretli plana geçtiği (Yüzde üzerinden).
*   **Segmentasyon:** Kullanıcıların etkileşim düzeyine göre (RFM Analizi) hangi segmente ait olduğunu görebilirsiniz (Örn: "Sadık Kullanıcılar", "Risk Altındakiler").

---

## 👥 2. Kullanıcı Yönetimi (Users)
Kullanıcıların listesini görebilir, durumlarını değiştirebilir ve detaylı analiz yapabilirsiniz.

*   **Engagement Score (Etkileşim Puanı):** Kullanıcının uygulama içindeki aktivitelerine göre otomatik hesaplanır (0-100).
    *   *Örnek:* 80+ puan alan kullanıcılar "Power User" olarak kabul edilir.
*   **Aksiyonlar:**
    *   **Ban/Unban:** Kural ihlali yapan kullanıcıları askıya alabilirsiniz.
    *   **Premium Atama:** Manuel olarak kullanıcılara PRO özellikler tanımlayabilirsiniz.

---

## 💰 3. Fiyatlandırma ve Kampanya Yönetimi (Pricing)
Uygulama içi satış stratejilerini buradan yönetirsiniz.

*   **Fiyat Güncelleme:** Aylık ve yıllık planların baz fiyatlarını (USD/TRY) güncelleyebilirsiniz.
*   **Kampanya (Promotion):**
    *   *Örnek:* "Lansman İndirimi" adıyla %20'lik bir indirim tanımlayabilir ve bitiş tarihi belirleyebilirsiniz.
    *   Bu ayarlar yapıldığında uygulama içindeki fiyat etiketleri otomatik olarak "indirimli" hale gelir.
*   **Ücretsiz Deneme (Trial):** Yeni kullanıcılara kaç gün PRO erişim verileceğini ayarlayabilirsiniz.

---

## ⚙️ 4. Sistem Konfigürasyonu (App Settings)
Uygulamanın teknik "kalbi" buradaki anahtarlarla (keys) yönetilir.

*   **API Anahtarları:** Finansal verilerin çekildiği servislerin anahtarlarını güncelleyebilirsiniz.
*   **Feature Flags:** Uygulamadaki yeni bir özelliği (Örn: AI Portfolio Analysis) uygulama güncellemesi yapmadan anlık açıp kapatabilirsiniz.
*   *Dikkat:* Buradaki değişiklikler backend önbelleğine bağlı olarak 1-5 dakika içinde tüm kullanıcılara yansır.

---

## 📢 5. Reklam Yönetimi (Ads Manager)
Uygulama içi reklam gelirlerini optimize etmek için kullanılır.

*   **Ad Unit ID Yönetimi:** Google AdMob veya Unity Ads üzerinden aldığınız reklam kodlarını yerleşime göre güncelleyebilirsiniz (Örn: "Borsa Detay Altı Reklamı").
*   **Anlık Toggle:** Bir reklam alanında teknik sorun oluşursa uygulamayı güncellemeden reklamları o alan için kapatabilirsiniz.

---

## 🔔 7. Fiyat Alarmları (Cloud Monitoring)
Uygulama kapalıyken bile kullanıcıları fiyat hareketlerinden haberdar eden sistemdir.

*   **Çalışma Mantığı:** Kullanıcı mobilden alarm kurar -> Supabase'e kaydedilir -> Backend Monitor 60 saniyede bir kontrol eder -> Hedef fiyat geçilirse uygulama içi bildirim oluşturulur ve iOS'a doğrudan APNs ile gönderilir.
*   **Admin Paneli Yönetimi:** **Price Alerts** sekmesinden tüm aktif ve tetiklenmiş alarmları görebilir, kullanıcıların beklediği seviyeleri izleyebilirsiniz.
*   **Kritik Not:** Sunucu tarafındaki takibin çalışması için **App Settings** altındaki `SUPABASE_SERVICE_ROLE_KEY` alanının dolu olması gerekir.

---

## 🛠️ 8. Sistem Görevleri (System Tasks)
Teknik operasyonları ve temizlik işlemlerini manuel tetiklemek içindir.

*   **Veri Senkronizasyonu:** Borsa verilerini manuel güncelleyen script'leri (Python) buradan başlatabilirsiniz.
*   **Terminal İzleme:** Bir script çalıştığında oluşan çıktıları (Logs) gerçek zamanlı izleyebilirsiniz.
*   *Örnek:* `sync_market_prices.py` script'ini her sabah manuel tetikleyerek verileri kontrol edebilirsiniz.

---

## 📈 9. Analiz ve Canlı İzleme (Analytics & Live)
Veriye dayalı kararlar almak için en kritik bölümdür.

*   **Gelecek Tahmini:** Hangi kullanıcıların uygulamayı bırakma (Churn) riskinde olduğunu görebilirsiniz.
*   **Canlı İzleme (Live Monitor):** Şu an uygulamada kaç kişi var? Hangi ekranda geziyorlar? Gerçek zamanlı akıştan izleyebilirsiniz.
*   **Hangi Özellik Popüler?** Kullanıcıların en çok hangi sayfada ne kadar vakit geçirdiğini (sayfa başına saniye) analiz ederek kullanıcı deneyimini iyileştirebilirsiniz.

---

## 🆘 Destek ve Teknik Notlar
- **Hata Bildirimi:** Panel üzerinde beklenmedik bir hata (500 Error) alırsanız, **System Tasks** altındaki backend loglarını kontrol edin.
- **Güvenlik:** API anahtarlarını sadece yetkili personelle paylaşın. İndirim oranlarını kaydetmeden önce mutlaka **Önizleme (Preview)** kartlarını kontrol edin.

---
*Geliştiren: Antigravity AI Assistant*
