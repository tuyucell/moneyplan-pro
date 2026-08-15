# App Store Privacy Yanıt Envanteri

Bu belge, `ios/Runner/PrivacyInfo.xcprivacy`, uygulama içi gizlilik metni ve App Store Connect Privacy Nutrition Label yanıtlarının aynı kalması için hazırlanmıştır.

## Takip

- Kullanıcılar uygulamalar veya web siteleri arasında takip edilmez.
- Veriler davranışsal reklam, veri komisyonculuğu veya üçüncü taraf reklam ölçümü için paylaşılmaz.

## Kullanıcıya bağlı toplanan veriler

| Apple veri türü | Kullanım amacı |
| --- | --- |
| Ad | Hesap işlevi, kişiselleştirme |
| E-posta adresi | Kimlik doğrulama ve hesap iletişimi |
| Kullanıcı kimliği | Hesap işlevi ve uygulama analitiği |
| Cihaz kimliği | Kullanıcı isteğe bağlı açarsa APNs cihaz tokenı |
| Satın alma geçmişi | App Store abonelik yetkisinin doğrulanması |
| Diğer finansal bilgiler | Bütçe, gelir, gider, hesap, borç, birikim ve portföy işlevleri |
| E-postalar veya metin mesajları | Yalnızca kullanıcının isteğe bağlı seçtiği Gmail finansal iletileri |
| Diğer kullanıcı içeriği | Ekstreler, notlar, hedefler ve kullanıcı tarafından girilen içerik |
| Ürün etkileşimi | Özellik kullanımı, oturum ve sayfa etkileşimi analitiği |
| Diğer veri türleri | İsteğe bağlı doğum yılı, cinsiyet, meslek, finansal hedef ve risk tercihi |

Tüm türler için `tracking = false` kullanılmalıdır.

## İşleyiciler

- Supabase: kimlik doğrulama, veritabanı ve cihaz push kayıtları
- Hugging Face: MoneyPlan Pro backend barındırma
- Google: Google ile giriş, isteğe bağlı Gmail ve açık onay sonrası Gemini AI
- Apple: Sign in with Apple, App Store aboneliği, APNs ve uygulama dağıtımı

## App Store Connect bağlantıları

- Privacy Policy URL: `https://moneyplan.pro/privacy.html`
- Privacy Choices URL: `https://moneyplan.pro/privacy.html#deletion` (canlı sayfaya aynı `id` eklenmeli)

## Yayın öncesi kontrol

- App Store Connect’teki her yanıt bu dosyayla karşılaştırılmalı.
- Gemini ücretli/ücretsiz katman veya reklam SDK’sı değişirse envanter yeniden gözden geçirilmeli.
- Yeni bir SDK eklenirse SDK privacy manifest ve veri toplama davranışı doğrulanmalı.
