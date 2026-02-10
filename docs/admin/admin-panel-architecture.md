# InvestGuide Admin Panel - Mimari Tasarım

---

## 1. SİSTEM MİMARİSİ

```
┌─────────────────────────────────────────────────────────┐
│                   ADMIN WEB PANEL                       │
│                  (React + Vite)                         │
│                                                         │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐ │
│  │  Dashboard   │  │  Analytics   │  │   Users      │ │
│  └──────────────┘  └──────────────┘  └──────────────┘ │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐ │
│  │  Campaigns   │  │     Ads      │  │    Push      │ │
│  └──────────────┘  └──────────────┘  └──────────────┘ │
└─────────────────────────────────────────────────────────┘
                           │
                           │ HTTPS / WSS
                           ▼
┌─────────────────────────────────────────────────────────┐
│                    SUPABASE (BaaS)                      │
│                                                         │
│  ┌──────────────────────────────────────────────────┐  │
│  │          PostgreSQL Database                     │  │
│  │  - Users, Sessions, Events, Campaigns, etc.      │  │
│  └──────────────────────────────────────────────────┘  │
│                                                         │
│  ┌──────────────────────────────────────────────────┐  │
│  │          PostgREST API (Auto-generated)          │  │
│  │  - /rest/v1/users, /rest/v1/campaigns, etc.      │  │
│  └──────────────────────────────────────────────────┘  │
│                                                         │
│  ┌──────────────────────────────────────────────────┐  │
│  │          Realtime (WebSocket)                    │  │
│  │  - Live dashboard updates                        │  │
│  └──────────────────────────────────────────────────┘  │
│                                                         │
│  ┌──────────────────────────────────────────────────┐  │
│  │          Storage (S3-compatible)                 │  │
│  │  - Campaign images, Ad banners                   │  │
│  └──────────────────────────────────────────────────┘  │
│                                                         │
│  ┌──────────────────────────────────────────────────┐  │
│  │          Edge Functions (Deno)                   │  │
│  │  - Complex analytics, Push notifications         │  │
│  └──────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
                           │
                           │
                ┌──────────┴──────────┐
                │                     │
                ▼                     ▼
    ┌──────────────────┐   ┌──────────────────┐
    │  Mobile App      │   │  External APIs   │
    │  (Flutter)       │   │  - FCM/APNs      │
    │                  │   │  - SendGrid      │
    └──────────────────┘   └──────────────────┘
```

---

## 2. FRONTEND MİMARİSİ (React)

### 2.1 Klasör Yapısı

```
admin-panel/
├── public/
│   ├── favicon.ico
│   └── logo.png
├── src/
│   ├── assets/              # Static assets
│   │   ├── images/
│   │   └── icons/
│   │
│   ├── components/          # Reusable components
│   │   ├── common/
│   │   │   ├── Button/
│   │   │   ├── Card/
│   │   │   ├── Modal/
│   │   │   ├── Table/
│   │   │   └── ...
│   │   ├── charts/
│   │   │   ├── LineChart.tsx
│   │   │   ├── PieChart.tsx
│   │   │   ├── BarChart.tsx
│   │   │   └── MetricCard.tsx
│   │   └── layout/
│   │       ├── Sidebar.tsx
│   │       ├── Header.tsx
│   │       ├── Footer.tsx
│   │       └── Layout.tsx
│   │
│   ├── features/            # Feature-based modules
│   │   ├── auth/
│   │   │   ├── components/
│   │   │   ├── hooks/
│   │   │   ├── api.ts
│   │   │   └── store.ts
│   │   ├── dashboard/
│   │   │   ├── components/
│   │   │   ├── hooks/
│   │   │   ├── api.ts
│   │   │   └── types.ts
│   │   ├── users/
│   │   ├── campaigns/
│   │   ├── ads/
│   │   ├── notifications/
│   │   └── analytics/
│   │
│   ├── hooks/               # Global custom hooks
│   │   ├── useAuth.ts
│   │   ├── useDebounce.ts
│   │   ├── useLocalStorage.ts
│   │   └── ...
│   │
│   ├── lib/                 # Utilities & configurations
│   │   ├── supabase.ts      # Supabase client
│   │   ├── api.ts           # API helpers
│   │   ├── constants.ts
│   │   └── utils.ts
│   │
│   ├── pages/               # Page components
│   │   ├── Dashboard.tsx
│   │   ├── Users/
│   │   │   ├── UserList.tsx
│   │   │   └── UserDetail.tsx
│   │   ├── Campaigns/
│   │   ├── Ads/
│   │   ├── Notifications/
│   │   ├── Analytics/
│   │   └── Settings/
│   │
│   ├── store/               # Global state management
│   │   ├── authStore.ts
│   │   ├── uiStore.ts
│   │   └── index.ts
│   │
│   ├── types/               # TypeScript types
│   │   ├── user.ts
│   │   ├── campaign.ts
│   │   ├── analytics.ts
│   │   └── index.ts
│   │
│   ├── App.tsx
│   ├── main.tsx
│   └── router.tsx
│
├── .env.example
├── .env.local
├── package.json
├── tsconfig.json
├── vite.config.ts
└── tailwind.config.js
```

### 2.2 State Management Strategy

**Zustand Store Örneği:**

```typescript
// store/authStore.ts
import { create } from 'zustand';
import { supabase } from '@/lib/supabase';

interface AuthState {
  user: AdminUser | null;
  isLoading: boolean;
  isAuthenticated: boolean;
  login: (email: string, password: string) => Promise<void>;
  logout: () => Promise<void>;
  checkAuth: () => Promise<void>;
}

export const useAuthStore = create<AuthState>((set) => ({
  user: null,
  isLoading: true,
  isAuthenticated: false,
  
  login: async (email, password) => {
    const { data, error } = await supabase.auth.signInWithPassword({
      email,
      password,
    });
    if (error) throw error;
    set({ user: data.user, isAuthenticated: true });
  },
  
  logout: async () => {
    await supabase.auth.signOut();
    set({ user: null, isAuthenticated: false });
  },
  
  checkAuth: async () => {
    const { data } = await supabase.auth.getSession();
    set({ 
      user: data.session?.user || null,
      isAuthenticated: !!data.session,
      isLoading: false 
    });
  },
}));
```

### 2.3 React Query Setup

```typescript
// lib/api.ts
import { QueryClient } from '@tanstack/react-query';

export const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 1000 * 60 * 5, // 5 minutes
      retry: 2,
      refetchOnWindowFocus: false,
    },
  },
});

// features/dashboard/api.ts
import { useQuery } from '@tanstack/react-query';
import { supabase } from '@/lib/supabase';

export const useDashboardStats = () => {
  return useQuery({
    queryKey: ['dashboard', 'stats'],
    queryFn: async () => {
      const { data, error } = await supabase
        .rpc('get_dashboard_stats');
      
      if (error) throw error;
      return data;
    },
    refetchInterval: 30000, // Auto-refresh every 30s
  });
};
```

---

## 3. SUPABASE DATABASE ŞEMASI

### 3.1 Core Tables

#### 3.1.1 `users` (Mobil app kullanıcıları)
```sql
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email TEXT UNIQUE,
  full_name TEXT,
  phone TEXT,
  avatar_url TEXT,
  
  -- Account type
  account_type TEXT CHECK (account_type IN ('guest', 'email', 'google', 'apple')),
  is_premium BOOLEAN DEFAULT FALSE,
  premium_expires_at TIMESTAMPTZ,
  
  -- Metadata
  locale TEXT DEFAULT 'tr',
  timezone TEXT DEFAULT 'Europe/Istanbul',
  device_info JSONB, -- {platform, os_version, app_version, device_model}
  fcm_token TEXT, -- Push notification token
  
  -- Status
  is_active BOOLEAN DEFAULT TRUE,
  is_banned BOOLEAN DEFAULT FALSE,
  ban_reason TEXT,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  last_seen_at TIMESTAMPTZ,
  deleted_at TIMESTAMPTZ
);

-- Indexes
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_is_premium ON users(is_premium);
CREATE INDEX idx_users_created_at ON users(created_at);
CREATE INDEX idx_users_last_seen_at ON users(last_seen_at);
```

#### 3.1.2 `user_sessions` (Tracking)
```sql
CREATE TABLE user_sessions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  
  session_start TIMESTAMPTZ DEFAULT NOW(),
  session_end TIMESTAMPTZ,
  duration_seconds INTEGER GENERATED ALWAYS AS (
    EXTRACT(EPOCH FROM (session_end - session_start))
  ) STORED,
  
  -- Session metadata
  device_info JSONB,
  app_version TEXT,
  platform TEXT, -- 'ios', 'android'
  
  -- Engagement
  screens_viewed INTEGER DEFAULT 0,
  events_count INTEGER DEFAULT 0,
  
created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_sessions_user_id ON user_sessions(user_id);
CREATE INDEX idx_sessions_start ON user_sessions(session_start);
```

#### 3.1.3 `user_events` (User Tracking)
```sql
CREATE TABLE user_events (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  session_id UUID REFERENCES user_sessions(id) ON DELETE CASCADE,
  
  -- Event details
  event_name TEXT NOT NULL, -- 'screen_view', 'button_click', 'feature_used', etc.
  event_category TEXT, -- 'navigation', 'engagement', 'monetization', etc.
  
  -- Event data
  properties JSONB, -- Flexible event properties
  screen_name TEXT,
  
  -- Context
  timestamp TIMESTAMPTZ DEFAULT NOW(),
  
  CONSTRAINT valid_event_name CHECK (LENGTH(event_name) > 0)
);

-- Indexes for fast queries
CREATE INDEX idx_events_user_id ON user_events(user_id);
CREATE INDEX idx_events_session_id ON user_events(session_id);
CREATE INDEX idx_events_name ON user_events(event_name);
CREATE INDEX idx_events_timestamp ON user_events(timestamp DESC);
CREATE INDEX idx_events_category ON user_events(event_category);
```

#### 3.1.4 `campaigns`
```sql
CREATE TABLE campaigns (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  
  -- Campaign details
  name TEXT NOT NULL,
  description TEXT,
  type TEXT CHECK (type IN ('discount', 'bonus', 'feature_unlock', 'trial')),
  
  -- Targeting
  target_segment JSONB, -- Segment criteria
  target_user_ids UUID[], -- Specific users (optional)
  
  -- Campaign configuration
  config JSONB, -- Campaign-specific config (discount amount, bonus days, etc.)
  
  -- Scheduling
  starts_at TIMESTAMPTZ NOT NULL,
  ends_at TIMESTAMPTZ,
  is_active BOOLEAN DEFAULT TRUE,
  
  -- Metrics
  total_impressions INTEGER DEFAULT 0,
  total_clicks INTEGER DEFAULT 0,
  total_conversions INTEGER DEFAULT 0,
  
  -- Metadata
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_campaigns_active ON campaigns(is_active, starts_at, ends_at);
CREATE INDEX idx_campaigns_type ON campaigns(type);
```

#### 3.1.5 `campaign_interactions`
```sql
CREATE TABLE campaign_interactions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  campaign_id UUID REFERENCES campaigns(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  
  interaction_type TEXT CHECK (interaction_type IN ('impression', 'click', 'conversion', 'dismiss')),
  
  metadata JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  
  UNIQUE(campaign_id, user_id, interaction_type, created_at)
);

CREATE INDEX idx_campaign_interactions_campaign ON campaign_interactions(campaign_id);
CREATE INDEX idx_campaign_interactions_user ON campaign_interactions(user_id);
```

#### 3.1.6 `ads`
```sql
CREATE TABLE ads (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  
  -- Ad content
  title TEXT NOT NULL,
  description TEXT,
  image_url TEXT,
  cta_text TEXT, -- Call-to-action button text
  cta_url TEXT, -- Deep link or external URL
  
  -- Targeting
  target_segment JSONB,
  placement TEXT CHECK (placement IN ('home_banner', 'sidebar', 'modal', 'native')),
  
  -- Scheduling
  starts_at TIMESTAMPTZ NOT NULL,
  ends_at TIMESTAMPTZ,
  is_active BOOLEAN DEFAULT TRUE,
  
  -- Display rules
  frequency_cap INTEGER DEFAULT 3, -- Max shows per user per day
  priority INTEGER DEFAULT 0,
  
  -- Metrics
  impressions INTEGER DEFAULT 0,
  clicks INTEGER DEFAULT 0,
  
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_ads_active ON ads(is_active, starts_at, ends_at);
CREATE INDEX idx_ads_placement ON ads(placement);
```

#### 3.1.7 `ad_impressions`
```sql
CREATE TABLE ad_impressions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  ad_id UUID REFERENCES ads(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  
  clicked BOOLEAN DEFAULT FALSE,
  clicked_at TIMESTAMPTZ,
  
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_ad_impressions_ad ON ad_impressions(ad_id);
CREATE INDEX idx_ad_impressions_user_date ON ad_impressions(user_id, created_at);
```

#### 3.1.8 `push_notifications`
```sql
CREATE TABLE push_notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  
  -- Notification content
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  image_url TEXT,
  deep_link TEXT,
  
  -- Targeting
  target_type TEXT CHECK (target_type IN ('all', 'segment', 'individual')),
  target_segment JSONB,
  target_user_ids UUID[],
  
  -- Scheduling
  scheduled_for TIMESTAMPTZ,
  sent_at TIMESTAMPTZ,
  status TEXT CHECK (status IN ('draft', 'scheduled', 'sending', 'sent', 'failed')),
  
  -- Metrics
  total_sent INTEGER DEFAULT 0,
  total_delivered INTEGER DEFAULT 0,
  total_opened INTEGER DEFAULT 0,
  total_clicked INTEGER DEFAULT 0,
  
  -- Metadata
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_push_status ON push_notifications(status, scheduled_for);
```

#### 3.1.9 `push_notification_logs`
```sql
CREATE TABLE push_notification_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  notification_id UUID REFERENCES push_notifications(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  
  -- Delivery status
  status TEXT CHECK (status IN ('sent', 'delivered', 'failed', 'opened', 'clicked')),
  error_message TEXT,
  
  -- Timestamps
  sent_at TIMESTAMPTZ,
  delivered_at TIMESTAMPTZ,
  opened_at TIMESTAMPTZ,
  clicked_at TIMESTAMPTZ,
  
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_push_logs_notification ON push_notification_logs(notification_id);
CREATE INDEX idx_push_logs_user ON push_notification_logs(user_id);
```

#### 3.1.10 `admin_users`
```sql
CREATE TABLE admin_users (
  id UUID PRIMARY KEY REFERENCES auth.users(id),
  
  email TEXT NOT NULL UNIQUE,
  full_name TEXT,
  role TEXT CHECK (role IN ('super_admin', 'admin', 'analyst', 'content_manager')),
  
  is_active BOOLEAN DEFAULT TRUE,
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

#### 3.1.11 `admin_activity_logs`
```sql
CREATE TABLE admin_activity_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  admin_id UUID REFERENCES admin_users(id),
  
  action TEXT NOT NULL, -- 'create_campaign', 'send_notification', 'ban_user', etc.
  resource_type TEXT, -- 'campaign', 'user', 'ad', etc.
  resource_id UUID,
  
  details JSONB,
  ip_address INET,
  
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_admin_logs_admin ON admin_activity_logs(admin_id);
CREATE INDEX idx_admin_logs_created ON admin_activity_logs(created_at DESC);
```

### 3.2 Database Functions (RPC)

#### 3.2.1 Dashboard Stats
```sql
CREATE OR REPLACE FUNCTION get_dashboard_stats()
RETURNS JSON AS $$
DECLARE
  result JSON;
BEGIN
  SELECT json_build_object(
    'total_users', (SELECT COUNT(*) FROM users WHERE deleted_at IS NULL),
    'active_users', (SELECT COUNT(*) FROM users WHERE is_active = TRUE),
    'premium_users', (SELECT COUNT(*) FROM users WHERE is_premium = TRUE),
    'new_users_today', (
      SELECT COUNT(*) FROM users 
      WHERE created_at >= CURRENT_DATE
    ),
    'new_users_week', (
      SELECT COUNT(*) FROM users 
      WHERE created_at >= CURRENT_DATE - INTERVAL '7 days'
    ),
    'new_users_month', (
      SELECT COUNT(*) FROM users 
      WHERE created_at >= CURRENT_DATE - INTERVAL '30 days'
    ),
    'dau', (
      SELECT COUNT(DISTINCT user_id) FROM user_sessions
      WHERE session_start >= CURRENT_DATE
    ),
    'wau', (
      SELECT COUNT(DISTINCT user_id) FROM user_sessions
      WHERE session_start >= CURRENT_DATE - INTERVAL '7 days'
    ),
    'mau', (
      SELECT COUNT(DISTINCT user_id) FROM user_sessions
      WHERE session_start >= CURRENT_DATE - INTERVAL '30 days'
    ),
    'avg_session_duration', (
      SELECT AVG(duration_seconds) FROM user_sessions
      WHERE session_end IS NOT NULL
      AND session_start >= CURRENT_DATE - INTERVAL '7 days'
    ),
    'total_sessions_today', (
      SELECT COUNT(*) FROM user_sessions
      WHERE session_start >= CURRENT_DATE
    )
  ) INTO result;
  
  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

#### 3.2.2 User Activity Timeline
```sql
CREATE OR REPLACE FUNCTION get_user_activity_timeline(target_user_id UUID, days_back INTEGER DEFAULT 30)
RETURNS TABLE (
  date DATE,
  sessions_count INTEGER,
  events_count INTEGER,
  total_duration_minutes INTEGER
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    DATE(s.session_start) as date,
    COUNT(DISTINCT s.id)::INTEGER as sessions_count,
    COUNT(e.id)::INTEGER as events_count,
    (SUM(s.duration_seconds) / 60)::INTEGER as total_duration_minutes
  FROM user_sessions s
  LEFT JOIN user_events e ON e.session_id = s.id
  WHERE s.user_id = target_user_id
    AND s.session_start >= CURRENT_DATE - days_back
  GROUP BY DATE(s.session_start)
  ORDER BY date DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

#### 3.2.3 Campaign Performance
```sql
CREATE OR REPLACE FUNCTION get_campaign_performance(campaign_id UUID)
RETURNS JSON AS $$
DECLARE
  result JSON;
BEGIN
  SELECT json_build_object(
    'impressions', COUNT(*) FILTER (WHERE interaction_type = 'impression'),
    'clicks', COUNT(*) FILTER (WHERE interaction_type = 'click'),
    'conversions', COUNT(*) FILTER (WHERE interaction_type = 'conversion'),
    'ctr', ROUND(
      (COUNT(*) FILTER (WHERE interaction_type = 'click')::DECIMAL / 
       NULLIF(COUNT(*) FILTER (WHERE interaction_type = 'impression'), 0) * 100), 2
    ),
    'conversion_rate', ROUND(
      (COUNT(*) FILTER (WHERE interaction_type = 'conversion')::DECIMAL / 
       NULLIF(COUNT(*) FILTER (WHERE interaction_type = 'click'), 0) * 100), 2
    )
  ) INTO result
  FROM campaign_interactions
  WHERE campaign_id = get_campaign_performance.campaign_id;
  
  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

### 3.3 Row Level Security (RLS)

```sql
-- Enable RLS on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE campaigns ENABLE ROW LEVEL SECURITY;
ALTER TABLE ads ENABLE ROW LEVEL SECURITY;
-- ... etc

-- Admin users can read/write everything
CREATE POLICY admin_all ON users
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM admin_users
      WHERE id = auth.uid() AND is_active = TRUE
    )
  );

-- Similar policies for other tables
CREATE POLICY admin_all ON campaigns FOR ALL TO authenticated USING (
  EXISTS (SELECT 1 FROM admin_users WHERE id = auth.uid() AND is_active = TRUE)
);

-- Analysts can only read
CREATE POLICY analyst_readonly ON users
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM admin_users
      WHERE id = auth.uid() 
        AND role = 'analyst' 
        AND is_active = TRUE
    )
  );
```

---

## 4. API ENDPOINTS (Supabase PostgREST)

### 4.1 Users
```
GET    /rest/v1/users                    # List users (with filters)
GET    /rest/v1/users?id=eq.{uuid}       # Get specific user
PATCH  /rest/v1/users?id=eq.{uuid}       # Update user
POST   /rest/v1/users                    # Create user (if needed)
DELETE /rest/v1/users?id=eq.{uuid}       # Soft delete

# Example filters:
GET /rest/v1/users?is_premium=eq.true
GET /rest/v1/users?created_at=gte.2026-01-01
GET /rest/v1/users?order=created_at.desc&limit=20
```

### 4.2 Analytics
```
POST   /rest/v1/rpc/get_dashboard_stats
POST   /rest/v1/rpc/get_user_activity_timeline
POST   /rest/v1/rpc/get_campaign_performance
```

### 4.3 Campaigns
```
GET    /rest/v1/campaigns
POST   /rest/v1/campaigns
PATCH  /rest/v1/campaigns?id=eq.{uuid}
DELETE /rest/v1/campaigns?id=eq.{uuid}
```

### 4.4 Push Notifications
```
GET    /rest/v1/push_notifications
POST   /rest/v1/push_notifications
GET    /rest/v1/push_notification_logs?notification_id=eq.{uuid}
```

### 4.5 Supabase Edge Functions (Complex Logic)
```
POST   /functions/v1/send-push-notification
POST   /functions/v1/generate-report
POST   /functions/v1/process-campaign
```

---

## 5. USER TRACKING STRATEGY

### 5.1 Event Categories

```typescript
// Event taxonomy
enum EventCategory {
  NAVIGATION = 'navigation',
  ENGAGEMENT = 'engagement',
  MONETIZATION = 'monetization',
  FEATURE_USAGE = 'feature_usage',
  ERROR = 'error',
  PERFORMANCE = 'performance',
}

enum EventName {
  // Navigation
  SCREEN_VIEW = 'screen_view',
  TAB_SWITCH = 'tab_switch',
  
  // Engagement
  BUTTON_CLICK = 'button_click',
  FORM_SUBMIT = 'form_submit',
  SEARCH = 'search',
  FILTER_APPLIED = 'filter_applied',
  
  // Monetization
  VIEWED_PAYWALL = 'viewed_paywall',
  INITIATED_PURCHASE = 'initiated_purchase',
  COMPLETED_PURCHASE = 'completed_purchase',
  CANCELLED_PURCHASE = 'cancelled_purchase',
  
  // Feature usage
  AI_CHAT_MESSAGE = 'ai_chat_message',
  MARKET_DATA_VIEWED = 'market_data_viewed',
  PORTFOLIO_UPDATED = 'portfolio_updated',
  REMINDER_CREATED = 'reminder_created',
  
  // Error
  API_ERROR = 'api_error',
  CRASH = 'crash',
}
```

### 5.2 Tracking Implementation (Flutter App Side)

```dart
// lib/services/analytics_service.dart
class AnalyticsService {
  final SupabaseClient _supabase;
  String? _currentSessionId;
  
  Future<void> startSession() async {
    final session = await _supabase
      .from('user_sessions')
      .insert({
        'user_id': _supabase.auth.currentUser?.id,
        'device_info': await _getDeviceInfo(),
        'app_version': AppConfig.version,
        'platform': Platform.isIOS ? 'ios' : 'android',
      })
      .select()
      .single();
    
    _currentSessionId = session['id'];
  }
  
  Future<void> endSession() async {
    if (_currentSessionId == null) return;
    
    await _supabase
      .from('user_sessions')
      .update({'session_end': DateTime.now().toIso8601String()})
      .eq('id', _currentSessionId!);
  }
  
  Future<void> trackEvent({
    required String eventName,
    required String eventCategory,
    String? screenName,
    Map<String, dynamic>? properties,
  }) async {
    await _supabase.from('user_events').insert({
      'user_id': _supabase.auth.currentUser?.id,
      'session_id': _currentSessionId,
      'event_name': eventName,
      'event_category': eventCategory,
      'screen_name': screenName,
      'properties': properties,
    });
  }
  
  Future<void> trackScreenView(String screenName) async {
    await trackEvent(
      eventName: 'screen_view',
      eventCategory: 'navigation',
      screenName: screenName,
    );
    
    // Update session screens viewed count
    if (_currentSessionId != null) {
      await _supabase.rpc('increment_session_screens', {
        'session_id': _currentSessionId,
      });
    }
  }
}
```

### 5.3 Key Metrics to Track

1. **User Acquisition**
   - New signups by source
   - Registration completion rate
   - Guest → Registered conversion

2. **Engagement**
   - DAU/WAU/MAU
   - Session frequency
   - Session duration
   - Feature adoption rate
   - Retention curves (D1, D7, D30)

3. **Monetization**
   - Free → Premium conversion rate
   - Trial → Paid conversion
   - Revenue per user (ARPU)
   - Lifetime value (LTV)
   - Churn rate

4. **Product Usage**
   - Most used features
   - Feature drop-off points
   - AI chat usage patterns
   - Market data queries
   - Portfolio management activity

5. **Performance**
   - API response times
   - Crash-free users %
   - Error rates

---

## 6. DEPLOYMENT PLANLAMASI

### 6.1 Hugging Face Spaces Deployment

```yaml
# spaces.yml
title: InvestGuide Admin Panel
emoji: 📊
colorFrom: blue
colorTo: purple
sdk: docker
pinned: false
```

```dockerfile
# Dockerfile
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY . .

# Build
RUN npm run build

# Serve with a simple static server
RUN npm install -g serve

EXPOSE 7860

CMD ["serve", "-s", "dist", "-l", "7860"]
```

### 6.2 Environment Variables (Hugging Face Secrets)

```
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=your-anon-key
VITE_SUPABASE_SERVICE_KEY=your-service-key (for admin operations)
```

---

## 7. GÜVENLİK ÖNLEMLERİ

1. **Authentication**
   - Supabase Auth (Email/Password for admins)
   - JWT tokens with short expiry
   - Refresh token rotation

2. **Authorization**
   - Role-based access control (RBAC)
   - Row-level security (RLS) policies
   - Permission checks on every request

3. **Data Protection**
   - HTTPS only
   - SQL injection prevention (Supabase automatic)
   - Input validation (Zod schemas)
   - XSS protection (React automatic)

4. **Audit Trail**
   - Log all admin actions
   - Track who changed what/when
   - Immutable logs

5. **Rate Limiting**
   - Supabase built-in rate limiting
   - Additional Edge Function rate limits
   - Prevent API abuse

---

## 8. NEXT STEPS

### Immediate (Week 1)
- [x] Create detailed analysis ✅
- [x] Design architecture ✅
- [ ] Setup Supabase project
- [ ] Create database schema
- [ ] Setup React project with Vite
- [ ] Implement authentication

### Short-term (Weeks 2-3)
- [ ] Build dashboard with real-time stats
- [ ] Implement user management
- [ ] Basic tracking system
- [ ] Manual push notifications

### Medium-term (Weeks 4-6)
- [ ] Campaign management
- [ ] Ad management
- [ ] Advanced analytics
- [ ] User segmentation

### Long-term (Weeks 7+)
- [ ] A/B testing
- [ ] Automated workflows
- [ ] Advanced reporting
- [ ] Performance optimization

Bu mimari ile ölçeklenebilir, güvenli ve performanslı bir admin panel oluşturabiliriz! 🚀
