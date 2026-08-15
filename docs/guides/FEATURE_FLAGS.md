# Feature Flags (Remote Config) System

## 🎯 Overview

This system allows you to **control app features remotely** without deploying to app stores. You can enable/disable features, change PRO status, and adjust daily limits from the Admin Panel.

## 🏗️ Architecture

```
┌─────────────────┐
│  Admin Panel    │ ← Control features
│  (React)        │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Backend API    │ ← Store & serve flags
│  (FastAPI)      │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Flutter App    │ ← Fetch & cache flags
│  (Mobile)       │
└─────────────────┘
```

## 📱 How It Works

### 1. **Backend** (`/backend`)

**Files:**
- `models/feature_flag.py` - Data models
- `services/feature_flag_service.py` - Business logic
- `main.py` - API endpoints

**API Endpoints:**
- `GET /api/v1/features` - Get all feature flags
- `GET /api/v1/features/{flag_id}` - Get specific flag
- `PATCH /api/v1/features/{flag_id}` - Update flag (Admin)
- `POST /api/v1/features/check` - Check availability

**Storage:**
- Flags stored in SQLite `settings` table
- Key: `feature_flags`
- Auto-initializes with defaults on first run

### 2. **Admin Panel** (`/admin-panel`)

**Files:**
- `src/pages/FeatureFlags.tsx` - UI for managing flags
- `src/App.tsx` - Route: `/system/features`
- `src/components/Layout.tsx` - Menu item

**Features:**
- ✅ Enable/Disable features globally
- ✅ Toggle PRO requirement
- ✅ Set daily free limits
- ✅ View metadata
- ✅ Real-time updates

### 3. **Flutter App** (`/lib`)

**Files:**
- `core/services/remote_config_service.dart` - Service layer
- `features/subscription/presentation/widgets/remote_pro_feature_gate.dart` - Widget wrapper
- `main.dart` - Initialization

**Features:**
- ✅ Fetches flags on app start
- ✅ Caches for 5 minutes (reduces API calls)
- ✅ Persistent cache (works offline)
- ✅ Release-blocking flags fail closed

## 🚀 Usage

### Admin Panel

1. Navigate to **System → Feature Flags**
2. Toggle switches to enable/disable features
3. Change PRO status or daily limits
4. Mobil uygulamada değişiklikler en geç 5 dakikalık cache süresi sonunda uygulanır

### Flutter App

**Option 1: Use RemoteProFeatureGate (Recommended)**

```dart
RemoteProFeatureGate(
  featureId: 'ai_analyst',
  featureName: 'AI Portföy Analisti',
  child: YourFeatureWidget(),
  lockedChild: LockedStateWidget(), // Optional
  isFullPage: true, // Optional
)
```

**Option 2: Check Programmatically**

```dart
final isAvailable = await isFeatureAvailable(ref, 'scenario_planner');
if (isAvailable) {
  // Show feature
}
```

## 🎛️ Default Features

| Feature ID | Name | PRO | Daily Limit |
|-----------|------|-----|-------------|
| `ai_analyst` | AI Portföy Analisti | ✅ | 1 |
| `scenario_planner` | Gelecek Simülasyonu | ✅ | 1 |
| `investment_wizard` | Yatırım Asistanı | ✅ | 1 |
| `import_statement_ai` | AI Ekstre Okuma | ✅ | 1 |
| `email_automation` | E-posta Otomasyonu | ✅ | 0 |
| `export_csv` | CSV Export | ❌ | 1 |
| `export_pdf` | PDF Export | ❌ | 1 |
| `compound_interest` | Bileşik Faiz | ❌ | ∞ |
| `loan_calculator` | Kredi Hesaplayıcı | ❌ | ∞ |
| `credit_card_assistant` | Kredi Kartı Asistanı | ❌ | ∞ |
| `crypto_market_data` | CoinGecko Kripto Verileri | ❌ | ∞ |
| `market_ticker` | CoinGecko Kripto Kayan Yazısı | ❌ | ∞ |
| `tcmb_reference_rates` | TCMB Cüzdan Referans Kurları | ❌ | ∞ |
| `market_news` | Lisanslı Piyasa Haberleri | ❌ | ∞ |
| `financial_calendar` | Yönetilen Finansal Takvim | ❌ | ∞ |
| `financial_calendar_fxstreet` | FXStreet Takvim Yedeği | ❌ | ∞ |
| `live_market_data` | Canlı Piyasa Verileri | ❌ | ∞ |
| `gmail_import` | Gmail İçe Aktarma | ✅ | 0 |
| `ai_features` | AI Eğitim Özellikleri | ✅ | 0 |

İlk mağaza sürümünde `live_market_data`, `market_news`, `financial_calendar`,
`financial_calendar_fxstreet`, `gmail_import` ve `ai_features` kapalıdır.
`crypto_market_data` ile ona bağlı
`market_ticker`, yalnızca CoinGecko ticari kullanım hakkı olan bir plan
etkinleştirildikten sonra açılmalıdır. Bu üst seviye flag'ler mobil arayüzü ve
backend endpoint'lerini birlikte kapatır.

`tcmb_reference_rates`, canlı piyasa ekranı değildir; cüzdanın tarihli gösterge
satış kuru dönüşümünü yönetir. TCMB ticari kullanım teyidi olumsuzsa bu flag
dashboard'dan kapatılmalı; mobil uygulama son doğrulanmış yerel kuru yalnızca
çevrimdışı devamlılık için gösterir ve yeni kur çekmez.

## 🔧 Configuration

### Backend URL

Update in `remote_config_service.dart`:

```dart
static const String _baseUrl = 'https://your-api.com/api/v1';
```

### Cache Duration

Default: 5 minutes. Change in `feature_flag_service.py`:

```python
cached_until=datetime.now() + timedelta(minutes=5)
```

## 📊 Benefits

- ✅ **No App Store Deployment** - Change features without a new binary
- ✅ **Kill Switch** - Disable broken features remotely
- ✅ **Emergency Response** - Quick fixes without updates
- ✅ **Analytics** - Track which features drive conversions

## 🛡️ Fail-Safe Strategy

Sistem iki seviyeli güvenli davranış kullanır:

- Ağ/backend hatası → geçerli cache varsa son bilinen değer kullanılır.
- `crypto_market_data`, `market_ticker`, `market_news`, `financial_calendar`,
  `financial_calendar_fxstreet`, `live_market_data`, `gmail_import`,
  `ai_features` bilinmiyorsa → özellik kapalı
  kabul edilir.
- Diğer özellikler için mevcut ürün davranışı korunur.
- Backend market/news/fund ve AI endpoint'leri de aynı üst seviye flag'leri
  kontrol eder; yalnızca arayüzü gizlemeye güvenilmez.

## 🔐 Security

- Admin endpoint'leri admin oturumu ile korunur
- Feature ID'leri backend tarafından doğrulanır
- Use HTTPS in production
- Release-blocking endpoint'ler flag kapalıyken `503` döndürür

## 📝 Adding New Features

1. **Backend**: Add to `DEFAULT_FLAGS` in `feature_flag_service.py`
2. **Admin Panel**: Automatically appears in UI
3. **Flutter**: Use `RemoteProFeatureGate` with new `featureId`

## 🐛 Troubleshooting

**Features not updating?**
- Check cache expiry (5 minutes default)
- Force refresh: `remoteConfigService.fetchFlags(forceRefresh: true)`
- Clear cache: `remoteConfigService.clearCache()`

**Backend not responding?**
- App uses cached flags (works offline)
- Check backend logs: `uvicorn main:app --reload`

**Admin panel not showing changes?**
- Click "Refresh" button
- Check browser console for errors
- Verify backend is running on port 8000

## 📚 Best Practices

1. **Test in staging first** - Don't disable critical features in production
2. **Monitor analytics** - Track `pro_upsell_view` events
3. **Document changes** - Use metadata field for notes
4. **Have a rollback plan** - Keep previous config handy

## 🔄 Migration from Hardcoded Flags

Replace this:
```dart
ProFeatureGate(
  featureName: 'AI Analyst',
  child: MyFeature(),
)
```

With this:
```dart
RemoteProFeatureGate(
  featureId: 'ai_analyst',
  child: MyFeature(),
)
```

---

**Created:** 2026-01-22

**Updated:** 2026-07-20

**Version:** 1.1.0

**Status:** ✅ Production Ready
