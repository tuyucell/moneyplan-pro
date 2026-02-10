# InvestGuide Proje Geliştirme Planı (TODO)

Bu liste, refaktör sonrası yapılacak geliştirmeleri ve eksikleri takip etmek için oluşturulmuştur.

## 1. İzleme Listesi (Watchlist) Geliştirmeleri
- [ ] **Mini Grafikler (Sparklines)**: Varlık kartlarına 24 saatlik fiyat değişim grafiği ekle.
- [ ] **Canlı Fiyat Güncelleme**: Fiyatları belirli periyotlarla (Timer/Stream) otomatik güncelle.
- [ ] **Sıralama ve Filtreleme**: Alfabetik, fiyat değişimi veya varlık türüne göre sıralama ekle.

## 2. Varlık Detay Sayfaları (Asset Details)
- [ ] **Gelişmiş Grafikler**: TradingView benzeri veya SfCartesianChart ile detaylı grafikler.
- [ ] **Temel Analiz Verileri**: F/K, PD/DD, piyasa değeri gibi verileri ekle.
- [ ] **Haber Entegrasyonu**: Varlığa özel güncel haberleri listele.

## 3. Portföy Yönetimi
- [ ] **Varlık Ekleme**: Kullanıcının elindeki miktarı ve maliyeti girmesini sağla.
- [ ] **Kâr/Zarar Analizi**: Toplam portföyün anlık kâr/zarar durumunu hesapla.
- [ ] **Varlık Dağılım Pastası**: Portföyün yüzdesel dağılımını gösteren pasta grafiği ekle.

## 4. Uygulama Genel Refactoring
- [x] **WalletPage Refaktörü**: 2400 satırdan 600 satıra düşürüldü, widgetlar ayrıştırıldı.
- [x] **InvestmentWizard Refaktörü**: 1100 satırdan 150 satıra düşürüldü.
- [ ] **Hata Yönetimi (Error Handling)**: API istekleri ve boş veri durumları için daha şık UI bileşenleri ekle.
- [ ] **Tema Desteği**: Koyu mod (Dark Mode) uyumluluğunu gözden geçir ve eksikleri tamamla.

## 5. Yeni Özellikler
- [ ] **Bildirim Sistemi**: Önemli fiyat hareketleri veya bütçe aşımı için bildirimler.
- [ ] **Yapay Zeka Yatırım Danışmanı**: Yatırım sihirbazı verilerine göre AI tabanlı öneriler geliştir.
