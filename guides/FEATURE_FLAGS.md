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
- ✅ Caches for 1 hour (reduces API calls)
- ✅ Persistent cache (works offline)
- ✅ Fail-open strategy (shows features on error)

## 🚀 Usage

### Admin Panel

1. Navigate to **System → Feature Flags**
2. Toggle switches to enable/disable features
3. Change PRO status or daily limits
4. Changes take effect immediately

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

## 🔧 Configuration

### Backend URL

Update in `remote_config_service.dart`:

```dart
static const String _baseUrl = 'https://your-api.com/api/v1';
```

### Cache Duration

Default: 1 hour. Change in `feature_flag_service.py`:

```python
cached_until=datetime.now() + timedelta(hours=1)
```

## 📊 Benefits

✅ **No App Store Deployment** - Change features instantly  
✅ **A/B Testing** - Test features with segments  
✅ **Kill Switch** - Disable broken features remotely  
✅ **Gradual Rollout** - Enable features for specific users  
✅ **Emergency Response** - Quick fixes without updates  
✅ **Analytics** - Track which features drive conversions  

## 🛡️ Fail-Safe Strategy

The system uses a **"fail-open"** approach:

- ❌ Network error → Show feature (don't block users)
- ❌ Backend down → Use cached flags
- ❌ Cache expired → Still show feature
- ✅ Only hide if explicitly disabled in backend

## 🔐 Security

- Admin endpoints should be protected with authentication
- Consider rate limiting on `/api/v1/features`
- Use HTTPS in production
- Validate feature IDs to prevent injection

## 📝 Adding New Features

1. **Backend**: Add to `DEFAULT_FLAGS` in `feature_flag_service.py`
2. **Admin Panel**: Automatically appears in UI
3. **Flutter**: Use `RemoteProFeatureGate` with new `featureId`

## 🐛 Troubleshooting

**Features not updating?**
- Check cache expiry (1 hour default)
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
4. **Gradual rollout** - Enable for small % first
5. **Have a rollback plan** - Keep previous config handy

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
**Version:** 1.0.0  
**Status:** ✅ Production Ready
