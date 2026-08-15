# MoneyPlan Pro — Piyasa Verisi Lisans Kontrolü

Son kontrol: 20 Temmuz 2026

Bu belge teknik/hukuki ön incelemedir; lisans veren kurumdan alınmış yazılı izin veya hukuk görüşü yerine geçmez.

## Mevcut kaynakların yayın durumu

| Kaynak | Mevcut kullanım | Ticari App Store durumu | Yayın kararı |
| --- | --- | --- | --- |
| CoinGecko | Kripto fiyatları, grafikler ve kayan yazı | Demo plan test/keşif içindir ve ticari lisans içermez. Basic ve üstü ücretli planlarda ticari lisans bulunur; görünür “Data provided by CoinGecko” bağlantısı gerekir. | Uygun ücretli plan etkinleştirilmeden mağaza sürümünde açılmamalı. |
| Finans haberleri RSS | Bloomberg HT, Habertürk, Investing ve Dünya başlık/açıklama/görselleri | RSS yayını ticari bir mobil uygulamada yeniden yayınlama izni anlamına gelmez. Bloomberg HT koşulları açık yazılı izin ister; Investing.com koşulları ticari yeniden dağıtımı kısıtlar. | `market_news` varsayılan kapalı kalmalı; yalnızca yazılı izinli/lisanslı kaynaklarla açılmalı. |
| FXStreet ekonomik takvim | Kimlik doğrulamasız web uç noktasından takvim verisi | Resmî API OAuth2 ile korunur ve FXStreet verinin sahibi olduğunu belirtir. Web uç noktasını taklit eden erişim lisans sağlamaz. | Entegrasyon kodu korunuyor ancak `financial_calendar_fxstreet` varsayılan kapalıdır. Lisans ve resmî kimlik bilgileri alınmadan açılmamalı. |
| Twelve Data | Global hisse/veri yedeği | Basic dahil bireysel planlar kişisel/dahili ve ticari olmayan kullanım içindir. Ticari gösterim Business planı ve bazı borsalar için ek izin gerektirir. | Ücretsiz katman mağaza sürümünde devre dışı kalmalı. |
| TradingView | Teknik analiz ve bazı fiyatlar | Koşullar ayrı sözleşme olmadan ticari servis/API kullanımını ve veri sağlayıcı izni olmadan üçüncü taraf ürünleri kısıtlar. | Ticari sözleşme olmadan backend veri kaynağı olarak kullanılmamalı. |
| Borsa İstanbul verisi | BIST fiyatları/endeksleri | Veriyi kullanıcıya dağıtmak için Dağıtıcı veya Alt Dağıtıcı lisansı gerekir. Gecikmeli veri de yetkili dağıtıcı üzerinden lisanslanır. | Yetkili dağıtıcıyla sözleşme yapılmadan canlı BIST verisi yayımlanmamalı. |
| TCMB | Döviz kurları | Kaynak gösterilerek yayımlanabilir; TCMB kullanım şartları ticari kullanımın yazılı izne tabi olduğunu belirtir. | Monetize edilen uygulama için yazılı izin alınmalı veya canlı kur özelliği kapatılmalı. |
| Yahoo Finance | Global piyasa yedeği/grafikler | Kullanılan Finance uçları resmi ve sözleşmeli bir geliştirici ürünü olarak belgelenmiyor. Genel Yahoo API şartları tek başına Finance verisini yeniden dağıtma hakkı sağlamaz. | Yazılı lisans olmadan mağaza sürümünde kullanılmamalı. |
| Mynet Finans | BIST/döviz/altın ve haber kazıma | MoneyPlan Pro'ya veri yeniden dağıtım hakkı veren bir API sözleşmesi bulunmuyor. | HTML kazıma mağaza sürümünde kullanılmamalı. |
| TEFAS | Fon fiyatları | Kamuya açık web sayfası, otomatik çekme ve ticari yeniden dağıtım izni anlamına gelmez; belgelenmiş bir lisans alınmadı. | Yazılı izin veya lisanslı sağlayıcı olmadan canlı fon verisi yayımlanmamalı. |

## Resmî kaynaklar

- CoinGecko API Terms: https://www.coingecko.com/en/api_terms
- CoinGecko API Pricing: https://www.coingecko.com/en/api/pricing
- Bloomberg HT kullanım koşulları: https://www.bloomberght.com/kullanimkosullari
- Investing.com şartları: https://cdn.investing.com/about-us/terms_and_conditions.pdf
- FXStreet Economic Calendar API: https://docs.fxstreet.com/api/calendar/
- FXStreet authentication: https://docs.fxstreet.com/api/authentication/introduction/
- Twelve Data commercial use: https://support.twelvedata.com/en/articles/5332349-commercial-and-personal-usage
- TradingView Terms: https://www.tradingview.com/policies/
- Borsa İstanbul veri lisanslama: https://www.borsaistanbul.com/sss/veri-dagitim-ve-endeks-lisanslama
- Borsa İstanbul veri yayını: https://www.borsaistanbul.com/veriler/veri-yayini
- TCMB kullanım şartları: https://www.tcmb.gov.tr/wps/wcm/connect/TR/TCMB%2BTR/Bottom%2BMenu/Diger/Kullanim%2BSartlari
- Yahoo Developer API Terms: https://legal.yahoo.com/us/en/yahoo/terms/product-atos/apiforydn/index.html

## Önerilen ilk sürüm kararı

1. Lisans alınana kadar BIST, fon, global hisse, döviz/altın ve teknik analiz canlı fiyatlarını mağaza yapısında kapat.
2. CoinGecko ticari lisans içeren uygun ücretli plan teyit edilip
   `COINGECKO_API_KEY` yönetim paneline eklendikten sonra, görünür kaynak
   bağlantısıyla `crypto_market_data` ve kripto-only `market_ticker` flag'lerini aç.
3. `market_news` yazılı yayın izni alınana kadar kapalı kalsın.
4. `financial_calendar` yalnızca resmî duyurulardan yönetim paneline girilen,
   kaynak kaydı tutulan etkinliklerle açılabilir. FXStreet yedeği ayrı
   `financial_calendar_fxstreet` flag'iyle kapalı kalır; lisans alınınca açılır.
5. Bütçe, gelir-gider, tasarruf hedefi, kullanıcı tarafından girilen portföy maliyetleri, hesaplayıcılar ve finansal eğitim içerikleri ilk sürümün çekirdeği olarak kalabilir.
6. Mağaza metni ve ekran görüntülerinde kapalı canlı veri özelliklerini göstermeden önce lisans kararı tamamlanmalı.
