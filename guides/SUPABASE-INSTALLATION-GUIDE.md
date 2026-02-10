# Admin Panel - Supabase Installation Guide

## 📋 Installation Order

**Mevcut database yapınızla uyumlu migration dosyaları oluşturuldu!**

### ✅ Step 1: Run Main Migration
```sql
-- File: supabase-admin-panel-migration.sql
-- Bu dosyayı Supabase SQL Editor'da çalıştırın
```

**Ne Yapar:**
- ✅ `users` tablosuna eksik kolonları ekler:
  - `is_premium`, `premium_expires_at`, `premium_started_at`
  - `is_active`, `is_banned`, `ban_reason`, `banned_at`
  - `device_info` (JSONB), `fcm_token`, `apns_token`
  - `last_seen_at`, `deleted_at`, `phone`

- ✅ Yeni tablolar oluşturur:
  - `user_sessions` - Session tracking
  - `user_events` - Event tracking
  - `campaigns`, `campaign_interactions` - Campaign management
  - `ads`, `ad_impressions` - Ad management  
  - `push_notifications`, `push_notification_logs` - Push notifications
  - `admin_users`, `admin_activity_logs` - Admin management
  - `user_segments` - User segmentation

- ✅ Triggers ekler:
  - Auto-update `updated_at` timestamps
  - Calculate session durations
  - Increment campaign/ad metrics
  - Update `last_seen_at` on user activity

- ✅ RLS Policies enable eder
  - Admin full access
  - User self-insert for sessions/events

---

### ✅ Step 2: Run Analytics Functions
```sql
-- File: supabase-admin-panel-functions.sql
-- Migration'dan SONRA bu dosyayı çalıştırın
```

**Ne Yapar:**
- ✅ **Dashboard Functions:**
  - `get_dashboard_stats()` - Tüm key metrics
  - `get_stickiness_metrics()` - DAU/MAU ratios
  
- ✅ **User Analytics:**
  - `get_user_activity_timeline(user_id, days)` - User activity
  - `get_user_growth(days)` - User growth trends
  - `get_new_vs_returning(days)` - New vs returning breakdown
  
- ✅ **Engagement & Churn:**
  - `calculate_user_engagement_score(user_id)` - 0-100 score
  - `get_at_risk_users(limit)` - At-risk user list
  - `calculate_churn_rate(days)` - Churn metrics
  
- ✅ **Feature & Retention:**
  - `get_top_events(days, limit)` - Most used features
  - `get_feature_adoption(days)` - Adoption rates
  - `get_retention_cohorts(weeks)` - Cohort retention
  - `calculate_rfm_segments()` - RFM segmentation
  
- ✅ **Campaign Analytics:**
  - `get_campaign_performance(campaign_id)` - Campaign stats

---

## 🚀 Quick Start Commands

### 1. Supabase SQL Editor'da çalıştırın:

```sql
-- STEP 1: Run migration
-- Copy-paste entire content of: supabase-admin-panel-migration.sql

-- STEP 2: Run functions
-- Copy-paste entire content of: supabase-admin-panel-functions.sql
```

### 2. İlk Admin Kullanıcısını Oluşturun

```sql
-- Option A: Mevcut Supabase Auth kullanıcısı varsa
INSERT INTO admin_users (id, email, full_name, role, is_active)
VALUES (
  'YOUR-AUTH-USER-ID',  -- auth.users tablosundan al
  'admin@yourdomain.com',
  'Admin User',
  'super_admin',
  TRUE
);

-- Option B: Yeni kullanıcı oluşturacaksanız
-- Önce Supabase Dashboard > Authentication'dan kullanıcı oluştur
-- Sonra yukarıdaki INSERT'i çalıştır
```

### 3. Test Edin

```sql
-- Dashboard stats'ı test et
SELECT get_dashboard_stats();

-- Stickiness metrics
SELECT get_stickiness_metrics();

-- User growth (son 30 gün)
SELECT * FROM get_user_growth(30);

-- En çok kullanılan özellikler
SELECT * FROM get_top_events(7, 10);
```

---

## 📊 Mevcut Database Yapınız

### Tablolar Eklendi
- [ ] `user_sessions`
- [ ] `user_events`
- [ ] `campaigns`
- [ ] `campaign_interactions`
- [ ] `ads`
- [ ] `ad_impressions`
- [ ] `push_notifications`
- [ ] `push_notification_logs`
- [ ] `admin_users`
- [ ] `admin_activity_logs`
- [ ] `user_segments`

### `users` Tablosu Güncellemeleri
- [ ] `phone` (TEXT)
- [ ] `is_premium` (BOOLEAN)
- [ ] `premium_expires_at` (TIMESTAMPTZ)
- [ ] `premium_started_at` (TIMESTAMPTZ)
- [ ] `is_active` (BOOLEAN)
- [ ] `is_banned` (BOOLEAN)
- [ ] `ban_reason` (TEXT)
- [ ] `banned_at` (TIMESTAMPTZ)
- [ ] `banned_by` (UUID)
- [ ] `device_info` (JSONB)
- [ ] `fcm_token` (TEXT)
- [ ] `apns_token` (TEXT)
- [ ] `last_seen_at` (TIMESTAMPTZ)
- [ ] `deleted_at` (TIMESTAMPTZ)

---

## 🔍 Verification Queries

Migration sonrası çalıştırıp doğrulayın:

### Check New Tables
```sql
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_name IN (
    'user_sessions', 'user_events', 'campaigns', 
    'ads', 'push_notifications', 'admin_users'
  )
ORDER BY table_name;
-- Beklenen: 6 satır dönmeli
```

### Check Users Table Columns
```sql
SELECT column_name, data_type 
FROM information_schema.columns
WHERE table_name = 'users'
  AND column_name IN (
    'is_premium', 'fcm_token', 'last_seen_at', 'device_info'
  );
-- Beklenen: 4 satır dönmeli
```

### Check Functions
```sql
SELECT routine_name 
FROM information_schema.routines
WHERE routine_schema = 'public'
  AND routine_name LIKE 'get_%' OR routine_name LIKE 'calculate_%'
ORDER BY routine_name;
-- Beklenen: 10+ fonksiyon
```

### Check Triggers
```sql
SELECT trigger_name, event_object_table
FROM information_schema.triggers
WHERE trigger_schema = 'public'
ORDER BY trigger_name;
-- Beklenen: 7+ trigger
```

---

## ⚠️ Önemli Notlar

### 1. Mevcut Verileriniz Güvende
- ✅ Migration sadece **ekler**, hiçbir veriyi **silmez** veya **değiştirmez**
- ✅ `ALTER TABLE ADD COLUMN IF NOT EXISTS` kullanılıyor
- ✅ Mevcut kolonlar değiştirilmiyor

### 2. RLS (Row Level Security)
- ✅ Tüm yeni tablolarda RLS enabled
- ✅ Admin users full access alıyor
- ✅ Normal users kendi session/event'lerini insert edebilir

### 3. Performance
- ✅ Tüm önemli kolonlarda index var
- ✅ Trigger'lar optimize edilmiş
- ✅ RPC functions SECURITY DEFINER ile çalışıyor

### 4. Compatibility
- ✅ Mevcut `users` tablonuzla uyumlu
- ✅ `auth.users` ile integrated
- ✅ Mevcut `search_assets` fonksiyonu korunuyor

---

## 🔄 Rollback (Geri Alma)

Eğer bir şeyler ters giderse:

```sql
-- Yeni tabloları sil
DROP TABLE IF EXISTS user_segments CASCADE;
DROP TABLE IF EXISTS admin_activity_logs CASCADE;
DROP TABLE IF EXISTS admin_users CASCADE;
DROP TABLE IF EXISTS push_notification_logs CASCADE;
DROP TABLE IF EXISTS push_notifications CASCADE;
DROP TABLE IF EXISTS ad_impressions CASCADE;
DROP TABLE IF EXISTS ads CASCADE;
DROP TABLE IF EXISTS campaign_interactions CASCADE;
DROP TABLE IF EXISTS campaigns CASCADE;
DROP TABLE IF EXISTS user_events CASCADE;
DROP TABLE IF EXISTS user_sessions CASCADE;

-- Users tablosundan eklenen kolonları sil
ALTER TABLE users
  DROP COLUMN IF EXISTS phone,
  DROP COLUMN IF EXISTS is_premium,
  DROP COLUMN IF EXISTS premium_expires_at,
  DROP COLUMN IF EXISTS premium_started_at,
  DROP COLUMN IF EXISTS is_active,
  DROP COLUMN IF EXISTS is_banned,
  DROP COLUMN IF EXISTS ban_reason,
  DROP COLUMN IF EXISTS banned_at,
  DROP COLUMN IF EXISTS banned_by,
  DROP COLUMN IF EXISTS device_info,
  DROP COLUMN IF EXISTS fcm_token,
  DROP COLUMN IF EXISTS apns_token,
  DROP COLUMN IF EXISTS last_seen_at,
  DROP COLUMN IF EXISTS deleted_at;

-- Functions'ları sil
DROP FUNCTION IF EXISTS get_dashboard_stats();
DROP FUNCTION IF EXISTS get_stickiness_metrics();
DROP FUNCTION IF EXISTS get_user_activity_timeline(UUID, INTEGER);
DROP FUNCTION IF EXISTS get_user_growth(INTEGER);
DROP FUNCTION IF EXISTS get_new_vs_returning(INTEGER);
DROP FUNCTION IF EXISTS calculate_user_engagement_score(UUID);
DROP FUNCTION IF EXISTS get_at_risk_users(INTEGER);
DROP FUNCTION IF EXISTS calculate_churn_rate(INTEGER);
DROP FUNCTION IF EXISTS get_top_events(INTEGER, INTEGER);
DROP FUNCTION IF EXISTS get_feature_adoption(INTEGER);
DROP FUNCTION IF EXISTS get_retention_cohorts(INTEGER);
DROP FUNCTION IF EXISTS calculate_rfm_segments();
DROP FUNCTION IF EXISTS get_campaign_performance(UUID);
DROP FUNCTION IF EXISTS increment_session_screens(UUID);
```

---

## 📱 Next Steps: Flutter Integration

Migration tamamlandıktan sonra Flutter app'e tracking ekleyin:

### 1. Create AnalyticsService

```dart
// lib/services/analytics_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class AnalyticsService {
  final SupabaseClient _supabase = Supabase.instance.client;
  String? _currentSessionId;
  
  Future<void> startSession() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    
    final response = await _supabase
      .from('user_sessions')
      .insert({
        'user_id': user.id,
        'device_info': await _getDeviceInfo(),
        'platform': Platform.isIOS ? 'ios' : 'android',
        'app_version': await _getAppVersion(),
      })
      .select()
      .single();
    
    _currentSessionId = response['id'];
    
    // Update last_seen_at
    await _supabase
      .from('users')
      .update({'last_seen_at': DateTime.now().toIso8601String()})
      .eq('id', user.id);
  }
  
  Future<void> endSession() async {
    if (_currentSessionId == null) return;
    
    await _supabase
      .from('user_sessions')
      .update({'session_end': DateTime.now().toIso8601String()})
      .eq('id', _currentSessionId!);
      
    _currentSessionId = null;
  }
  
  Future<void> trackEvent({
    required String eventName,
    required String eventCategory,
    String? screenName,
    Map<String, dynamic>? properties,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    
    await _supabase.from('user_events').insert({
      'user_id': user.id,
      'session_id': _currentSessionId,
      'event_name': eventName,
      'event_category': eventCategory,
      'screen_name': screenName,
      'properties': properties ?? {},
    });
  }
  
  Future<Map<String, dynamic>> _getDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();
    // Implement based on your needs
    return {
      'platform': Platform.isIOS ? 'ios' : 'android',
      'os_version': '...',
      'device_model': '...',
    };
  }
}
```

### 2. Use in App

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL',
    anonKey: 'YOUR_ANON_KEY',
  );
  
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final _analytics = AnalyticsService();
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _analytics.startSession();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _analytics.endSession();
    } else if (state == AppLifecycleState.resumed) {
      _analytics.startSession();
    }
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _analytics.endSession();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Your app
    );
  }
}
```

---

## ✅ Success!

Şimdi **tam functional bir admin panel database'i** hazır! 🎉

**Hazır olan:**
- ✅ User tracking (sessions, events)
- ✅ Campaign management
- ✅ Ad management
- ✅ Push notifications
- ✅ Admin users & audit logs
- ✅ Analytics functions (DAU/MAU, churn, retention, etc.)
- ✅ RLS security
- ✅ Automatic triggers

**Sıradaki:**
1. React admin panel frontend oluştur
2. Flutter app'e tracking ekle
3. İlk kampanyayı oluştur!

Hazır mısın? 🚀
