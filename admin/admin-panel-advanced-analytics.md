# InvestGuide Admin Panel - Advanced Analytics & Metrics

## 📊 ENHANCED METRICS FRAMEWORK

Paddle'ın best practices'lerini baz alarak geliştirilmiş metrik sistemi.

---

## 1. USER ACTIVITY METRICS (Enhanced)

### 1.1 Active Users - Tüm Varyantlar

#### **DAU (Daily Active Users)**
```sql
-- Definition: User who performed at least 1 meaningful action today
SELECT COUNT(DISTINCT user_id) as dau
FROM user_events
WHERE timestamp >= CURRENT_DATE
  AND event_category IN ('engagement', 'feature_usage', 'monetization')
  -- Exclude passive events like 'screen_view' for more meaningful metric
```

#### **WAU (Weekly Active Users)**
```sql
SELECT COUNT(DISTINCT user_id) as wau
FROM user_events
WHERE timestamp >= CURRENT_DATE - INTERVAL '7 days'
  AND event_category IN ('engagement', 'feature_usage', 'monetization')
```

#### **MAU (Monthly Active Users)**
```sql
SELECT COUNT(DISTINCT user_id) as mau
FROM user_events
WHERE timestamp >= CURRENT_DATE - INTERVAL '30 days'
  AND event_category IN ('engagement', 'feature_usage', 'monetization')
```

#### **Custom Active User Definitions**
Farklı "aktif kullanıcı" tanımları için esnek sistem:

```typescript
interface ActiveUserDefinition {
  id: string;
  name: string;
  description: string;
  criteria: {
    eventNames?: string[];        // e.g., ['ai_chat_message', 'portfolio_updated']
    minEventCount?: number;        // e.g., 5 events per day
    minSessionDuration?: number;   // e.g., 120 seconds
    specificActions?: string[];    // e.g., ['completed_transaction']
  };
}

// Example: Power User Definition
const powerUserDef: ActiveUserDefinition = {
  id: 'power_user',
  name: 'Power User',
  description: 'Users who engage deeply with core features',
  criteria: {
    eventNames: ['ai_chat_message', 'portfolio_updated', 'market_data_viewed'],
    minEventCount: 10,
    minSessionDuration: 300, // 5 minutes
  }
};
```

### 1.2 Engagement Ratios (Critical KPIs)

#### **DAU/MAU Ratio (Stickiness)**
Product stickiness göstergesi. Ne kadar yüksekse, kullanıcılar o kadar sık dönüyor.

```sql
-- Industry benchmark: 20% good, 30%+ excellent
SELECT ROUND(
  (dau::DECIMAL / NULLIF(mau, 0)) * 100, 2
) as stickiness_percentage
```

**Grafik Önerisi:**
- Line chart (30 günlük trend)
- Target line at 20% (good) and 30% (excellent)
- Color coding: Red (<15%), Yellow (15-25%), Green (>25%)

#### **DAU/WAU Ratio**
```sql
SELECT ROUND(
  (dau::DECIMAL / NULLIF(wau, 0)) * 100, 2
) as dau_wau_ratio
```

#### **WAU/MAU Ratio**
```sql
SELECT ROUND(
  (wau::DECIMAL / NULLIF(mau, 0)) * 100, 2
) as wau_mau_ratio
```

**Dashboard Card:**
```
┌─────────────────────────────┐
│  Stickiness (DAU/MAU)       │
│                             │
│      23.5%  ↑ 2.3%         │
│  ████████░░░░░░░            │
│                             │
│  Target: 25%                │
│  vs Last Month: +2.3%       │
└─────────────────────────────┘
```

### 1.3 User Lifecycle Metrics

#### **New vs Returning Users**
```sql
CREATE OR REPLACE FUNCTION get_new_vs_returning(days_back INTEGER DEFAULT 30)
RETURNS TABLE (
  date DATE,
  new_users INTEGER,
  returning_users INTEGER,
  total_active INTEGER
) AS $$
BEGIN
  RETURN QUERY
  WITH daily_active AS (
    SELECT 
      DATE(timestamp) as activity_date,
      user_id
    FROM user_events
    WHERE timestamp >= CURRENT_DATE - days_back
    GROUP BY DATE(timestamp), user_id
  ),
  user_first_activity AS (
    SELECT 
      user_id,
      MIN(DATE(timestamp)) as first_seen
    FROM user_events
    GROUP BY user_id
  )
  SELECT 
    da.activity_date::DATE,
    COUNT(da.user_id) FILTER (WHERE ufa.first_seen = da.activity_date)::INTEGER as new_users,
    COUNT(da.user_id) FILTER (WHERE ufa.first_seen < da.activity_date)::INTEGER as returning_users,
    COUNT(da.user_id)::INTEGER as total_active
  FROM daily_active da
  LEFT JOIN user_first_activity ufa ON da.user_id = ufa.user_id
  GROUP BY da.activity_date
  ORDER BY da.activity_date;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

**Grafik Önerisi:** Stacked area chart
- Mavi: Returning users (bottom)
- Yeşil: New users (top)
- Shows healthy balance (too many new users might indicate high churn)

#### **Resurrection Rate**
Geri dönen inaktif kullanıcılar (win-back success)

```sql
CREATE OR REPLACE FUNCTION get_resurrection_rate(lookback_days INTEGER DEFAULT 30)
RETURNS JSON AS $$
DECLARE
  result JSON;
BEGIN
  WITH inactive_users AS (
    -- Users who were inactive for 30+ days
    SELECT DISTINCT user_id
    FROM users
    WHERE last_seen_at < CURRENT_DATE - INTERVAL '30 days'
      AND last_seen_at >= CURRENT_DATE - INTERVAL '60 days'
  ),
  resurrected AS (
    -- Those who came back in the last lookback period
    SELECT DISTINCT iu.user_id
    FROM inactive_users iu
    INNER JOIN user_events e ON iu.user_id = e.user_id
    WHERE e.timestamp >= CURRENT_DATE - lookback_days
  )
  SELECT json_build_object(
    'total_inactive', (SELECT COUNT(*) FROM inactive_users),
    'resurrected', (SELECT COUNT(*) FROM resurrected),
    'resurrection_rate', ROUND(
      (SELECT COUNT(*) FROM resurrected)::DECIMAL / 
      NULLIF((SELECT COUNT(*) FROM inactive_users), 0) * 100, 2
    )
  ) INTO result;
  
  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

---

## 2. CHURN PREDICTION & PREVENTION

### 2.1 Early Warning Indicators

#### **Declining Engagement Score**
User-level engagement score (0-100) tracking

```sql
CREATE OR REPLACE FUNCTION calculate_user_engagement_score(target_user_id UUID)
RETURNS INTEGER AS $$
DECLARE
  score INTEGER := 0;
  recent_sessions INTEGER;
  recent_events INTEGER;
  avg_session_duration INTEGER;
  days_since_last_active INTEGER;
BEGIN
  -- Session frequency (0-30 points)
  SELECT COUNT(*) INTO recent_sessions
  FROM user_sessions
  WHERE user_id = target_user_id
    AND session_start >= CURRENT_DATE - INTERVAL '7 days';
  score := score + LEAST(recent_sessions * 3, 30);
  
  -- Event activity (0-30 points)
  SELECT COUNT(*) INTO recent_events
  FROM user_events
  WHERE user_id = target_user_id
    AND timestamp >= CURRENT_DATE - INTERVAL '7 days';
  score := score + LEAST(recent_events, 30);
  
  -- Session quality (0-25 points)
  SELECT AVG(duration_seconds) INTO avg_session_duration
  FROM user_sessions
  WHERE user_id = target_user_id
    AND session_end IS NOT NULL
    AND session_start >= CURRENT_DATE - INTERVAL '7 days';
  score := score + LEAST((avg_session_duration / 60), 25);
  
  -- Recency (0-15 points)
  SELECT DATE_PART('day', NOW() - MAX(timestamp)) INTO days_since_last_active
  FROM user_events
  WHERE user_id = target_user_id;
  
  IF days_since_last_active = 0 THEN
    score := score + 15;
  ELSIF days_since_last_active <= 1 THEN
    score := score + 12;
  ELSIF days_since_last_active <= 3 THEN
    score := score + 8;
  ELSIF days_since_last_active <= 7 THEN
    score := score + 4;
  END IF;
  
  RETURN score;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

#### **At-Risk User Detection**
```sql
CREATE OR REPLACE FUNCTION get_at_risk_users()
RETURNS TABLE (
  user_id UUID,
  email TEXT,
  engagement_score INTEGER,
  days_inactive INTEGER,
  risk_level TEXT,
  recommended_action TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    u.id,
    u.email,
    calculate_user_engagement_score(u.id) as engagement_score,
    DATE_PART('day', NOW() - u.last_seen_at)::INTEGER as days_inactive,
    CASE 
      WHEN calculate_user_engagement_score(u.id) < 20 THEN 'HIGH'
      WHEN calculate_user_engagement_score(u.id) < 40 THEN 'MEDIUM'
      ELSE 'LOW'
    END as risk_level,
    CASE 
      WHEN calculate_user_engagement_score(u.id) < 20 THEN 'Send win-back campaign'
      WHEN calculate_user_engagement_score(u.id) < 40 THEN 'Send re-engagement push'
      ELSE 'Monitor'
    END as recommended_action
  FROM users u
  WHERE u.is_active = TRUE
    AND u.deleted_at IS NULL
    AND calculate_user_engagement_score(u.id) < 60
  ORDER BY engagement_score ASC
  LIMIT 100;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

**Grafik Önerisi:** Heatmap Chart
- X-axis: Days since last active
- Y-axis: Engagement score
- Color: Risk level (Red = High risk, Yellow = Medium, Green = Low)
- Clickable cells to see users in that segment

### 2.2 Churn Rate Calculation

```sql
CREATE OR REPLACE FUNCTION calculate_churn_rate(period_days INTEGER DEFAULT 30)
RETURNS JSON AS $$
DECLARE
  result JSON;
  churned_count INTEGER;
  active_start_count INTEGER;
BEGIN
  -- Users who were active at the start of the period
  SELECT COUNT(DISTINCT user_id) INTO active_start_count
  FROM user_events
  WHERE timestamp >= CURRENT_DATE - (period_days * 2)
    AND timestamp < CURRENT_DATE - period_days;
  
  -- Users who were active at start but NOT in current period
  SELECT COUNT(*) INTO churned_count
  FROM (
    SELECT DISTINCT user_id
    FROM user_events
    WHERE timestamp >= CURRENT_DATE - (period_days * 2)
      AND timestamp < CURRENT_DATE - period_days
    EXCEPT
    SELECT DISTINCT user_id
    FROM user_events
    WHERE timestamp >= CURRENT_DATE - period_days
  ) churned;
  
  SELECT json_build_object(
    'period_days', period_days,
    'active_at_start', active_start_count,
    'churned', churned_count,
    'churn_rate', ROUND(
      churned_count::DECIMAL / NULLIF(active_start_count, 0) * 100, 2
    )
  ) INTO result;
  
  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

---

## 3. ADVANCED DASHBOARD GRAPHS

### 3.1 User Growth Trends (Line Chart)

**Data to Display:**
- Total users (cumulative)
- Active users (MAU)
- Premium users
- Guest users

**Chart Config:**
```typescript
{
  type: 'line',
  data: {
    labels: ['Jan', 'Feb', 'Mar', ...],
    datasets: [
      {
        label: 'Total Users',
        data: [1200, 1450, 1680, ...],
        borderColor: '#3b82f6',
        backgroundColor: 'rgba(59, 130, 246, 0.1)',
        fill: true,
      },
      {
        label: 'MAU',
        data: [800, 920, 1050, ...],
        borderColor: '#10b981',
        fill: false,
      },
      {
        label: 'Premium Users',
        data: [120, 145, 168, ...],
        borderColor: '#f59e0b',
        fill: false,
      }
    ]
  },
  options: {
    responsive: true,
    interaction: {
      mode: 'index',
      intersect: false,
    },
    plugins: {
      tooltip: {
        enabled: true,
        callbacks: {
          footer: (tooltipItems) => {
            // Show growth rate
            const current = tooltipItems[0].parsed.y;
            const previous = tooltipItems[0].dataset.data[tooltipItems[0].dataIndex - 1];
            const growth = ((current - previous) / previous * 100).toFixed(1);
            return `Growth: ${growth}%`;
          }
        }
      }
    }
  }
}
```

### 3.2 Engagement Funnel (Funnel Chart)

```typescript
interface FunnelStep {
  name: string;
  users: number;
  percentage: number;
  dropOff: number;
}

const engagementFunnel: FunnelStep[] = [
  { name: 'App Opens', users: 10000, percentage: 100, dropOff: 0 },
  { name: 'Logged In', users: 8500, percentage: 85, dropOff: 15 },
  { name: 'Viewed Content', users: 7200, percentage: 72, dropOff: 13 },
  { name: 'Used Feature', users: 4800, percentage: 48, dropOff: 24 },
  { name: 'Premium Upgrade', users: 480, percentage: 4.8, dropOff: 43.2 },
];
```

**Visualization:** 
- Inverted pyramid
- Each step shows count + percentage
- Red highlighting on biggest drop-offs
- Clickable to drill into user cohort

### 3.3 Cohort Retention Matrix (Heatmap)

```
Week 0  Week 1  Week 2  Week 3  Week 4
Jan W1  100%    45%     38%     32%     28%  
Jan W2  100%    48%     40%     35%     30%
Jan W3  100%    52%     44%     38%     33%
Feb W1  100%    55%     48%     42%     --
Feb W2  100%    58%     51%     --      --
```

**Color Scale:**
- Dark Green: >50%
- Light Green: 40-50%
- Yellow: 30-40%
- Orange: 20-30%
- Red: <20%

### 3.4 Feature Adoption (Horizontal Bar Chart)

```typescript
const featureAdoption = [
  { feature: 'AI Chat', users: 6500, percentage: 65, trend: 'up' },
  { feature: 'Portfolio Tracker', users: 5200, percentage: 52, trend: 'up' },
  { feature: 'Market Watch', users: 4800, percentage: 48, trend: 'stable' },
  { feature: 'Reminders', users: 3200, percentage: 32, trend: 'down' },
  { feature: 'Bank Accounts', users: 2100, percentage: 21, trend: 'up' },
];
```

**With Icons:**
- 📈 Up trending (green arrow)
- ➡️ Stable (gray dash)
- 📉 Down trending (red arrow)

### 3.5 Session Duration Distribution (Histogram)

```typescript
const sessionDurationBuckets = {
  '0-30s': 1200,
  '30s-1m': 2400,
  '1-2m': 3200,
  '2-5m': 4500,
  '5-10m': 2800,
  '10-30m': 1200,
  '30m+': 400,
};
```

Shows if users are getting value (longer sessions) or bouncing

### 3.6 Geographic Heatmap

```typescript
const usersByCountry = [
  { country: 'TR', users: 8500, mau: 5200 },
  { country: 'US', users: 1200, mau: 800 },
  { country: 'GB', users: 800, mau: 500 },
  { country: 'DE', users: 650, mau: 420 },
  // ...
];
```

**Interactive World Map:**
- Choropleth visualization
- Hover: Show details
- Click: Filter to that geography

### 3.7 Real-time Activity Feed

```typescript
interface ActivityItem {
  timestamp: Date;
  userId: string;
  userName: string;
  action: string;
  details?: any;
}

// Live feed using Supabase Realtime
supabase
  .channel('admin_activity_feed')
  .on('postgres_changes', 
    { event: 'INSERT', schema: 'public', table: 'user_events' },
    (payload) => {
      // Add to feed
      addToActivityFeed(payload.new);
    }
  )
  .subscribe();
```

**Display:**
```
🟢 2 seconds ago
   John Doe completed a transaction

🟢 5 seconds ago
   Jane Smith upgraded to Premium

🟡 12 seconds ago
   Mike Johnson opened AI chat

⚪ 45 seconds ago
   Sarah Lee viewed market data
```

### 3.8 Conversion Funnel (Premium Upsell)

```
┌────────────────────────────────────┐
│  Free Users          10,000  100%  │
├────────────────────────────────────┤
│  Viewed Paywall       3,500   35%  │  ← 65% never see it
├────────────────────────────────────┤
│  Clicked Upgrade      1,400   14%  │  ← 21% drop
├────────────────────────────────────┤
│  Started Checkout       800    8%  │  ← 6% drop
├────────────────────────────────────┤
│  Completed Purchase     480  4.8%  │  ← 3.2% drop
└────────────────────────────────────┘
```

---

## 4. SMART ALERTS & ANOMALY DETECTION

### 4.1 Automated Alerts

```sql
CREATE TABLE metric_alerts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  
  metric_name TEXT NOT NULL, -- 'dau', 'mau', 'churn_rate', etc.
  condition TEXT NOT NULL, -- 'drops_below', 'exceeds', 'changes_by'
  threshold DECIMAL NOT NULL,
  
  is_active BOOLEAN DEFAULT TRUE,
  notification_channels TEXT[], -- ['email', 'slack', 'push']
  
  last_triggered_at TIMESTAMPTZ,
  created_by UUID REFERENCES admin_users(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Example alerts
INSERT INTO metric_alerts (metric_name, condition, threshold, notification_channels)
VALUES 
  ('dau', 'drops_below', 1000, ARRAY['email', 'slack']),
  ('churn_rate', 'exceeds', 5.0, ARRAY['email']),
  ('mau', 'changes_by', -10.0, ARRAY['slack']),
  ('avg_session_duration', 'drops_below', 120, ARRAY['email']);
```

### 4.2 Anomaly Detection Function

```sql
CREATE OR REPLACE FUNCTION detect_anomalies()
RETURNS TABLE (
  metric_name TEXT,
  current_value DECIMAL,
  expected_range_min DECIMAL,
  expected_range_max DECIMAL,
  severity TEXT,
  detected_at TIMESTAMPTZ
) AS $$
BEGIN
  -- Statistical anomaly detection using standard deviation
  -- This is a simplified example
  RETURN QUERY
  WITH metric_history AS (
    SELECT 
      'dau' as metric,
      COUNT(DISTINCT user_id)::DECIMAL as value
    FROM user_events
    WHERE timestamp >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY DATE(timestamp)
  ),
  stats AS (
    SELECT 
      metric,
      AVG(value) as mean,
      STDDEV(value) as stddev
    FROM metric_history
    GROUP BY metric
  ),
  current_metrics AS (
    SELECT 
      'dau' as metric,
      COUNT(DISTINCT user_id)::DECIMAL as current_value
    FROM user_events
    WHERE timestamp >= CURRENT_DATE
  )
  SELECT 
    cm.metric as metric_name,
    cm.current_value,
    (s.mean - 2 * s.stddev) as expected_range_min,
    (s.mean + 2 * s.stddev) as expected_range_max,
    CASE 
      WHEN cm.current_value < (s.mean - 2 * s.stddev) THEN 'HIGH'
      WHEN cm.current_value > (s.mean + 2 * s.stddev) THEN 'HIGH'
      WHEN cm.current_value < (s.mean - s.stddev) THEN 'MEDIUM'
      WHEN cm.current_value > (s.mean + s.stddev) THEN 'MEDIUM'
      ELSE 'LOW'
    END as severity,
    NOW() as detected_at
  FROM current_metrics cm
  JOIN stats s ON cm.metric = s.metric
  WHERE cm.current_value < (s.mean - 2 * s.stddev)
     OR cm.current_value > (s.mean + 2 * s.stddev);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

---

## 5. ADVANCED SEGMENTATION

### 5.1 RFM Analysis (Recency, Frequency, Monetary)

```sql
CREATE OR REPLACE FUNCTION calculate_rfm_score()
RETURNS TABLE (
  user_id UUID,
  recency_score INTEGER,
  frequency_score INTEGER,
  monetary_score INTEGER,
  rfm_segment TEXT
) AS $$
BEGIN
  RETURN QUERY
  WITH user_metrics AS (
    SELECT 
      u.id as user_id,
      DATE_PART('day', NOW() - u.last_seen_at) as days_since_last_active,
      COUNT(s.id) as session_count,
      CASE WHEN u.is_premium THEN 1 ELSE 0 END as monetary_value
    FROM users u
    LEFT JOIN user_sessions s ON u.id = s.user_id
      AND s.session_start >= CURRENT_DATE - INTERVAL '90 days'
    WHERE u.deleted_at IS NULL
    GROUP BY u.id, u.last_seen_at, u.is_premium
  ),
  rfm_scores AS (
    SELECT 
      user_id,
      CASE 
        WHEN days_since_last_active <= 7 THEN 5
        WHEN days_since_last_active <= 14 THEN 4
        WHEN days_since_last_active <= 30 THEN 3
        WHEN days_since_last_active <= 60 THEN 2
        ELSE 1
      END as recency_score,
      CASE 
        WHEN session_count >= 30 THEN 5
        WHEN session_count >= 20 THEN 4
        WHEN session_count >= 10 THEN 3
        WHEN session_count >= 5 THEN 2
        ELSE 1
      END as frequency_score,
      CASE 
        WHEN monetary_value > 0 THEN 5
        ELSE 1
      END as monetary_score
    FROM user_metrics
  )
  SELECT 
    user_id,
    recency_score::INTEGER,
    frequency_score::INTEGER,
    monetary_score::INTEGER,
    CASE 
      WHEN recency_score >= 4 AND frequency_score >= 4 AND monetary_score >= 4 THEN 'Champions'
      WHEN recency_score >= 3 AND frequency_score >= 3 AND monetary_score >= 4 THEN 'Loyal Customers'
      WHEN recency_score >= 4 AND frequency_score <= 2 THEN 'New Users'
      WHEN recency_score <= 2 AND frequency_score >= 4 AND monetary_score >= 4 THEN 'At Risk'
      WHEN recency_score <= 2 AND frequency_score <= 2 THEN 'Lost'
      WHEN recency_score >= 3 AND frequency_score >= 3 AND monetary_score <= 2 THEN 'Potential Premium'
      ELSE 'Needs Attention'
    END as rfm_segment
  FROM rfm_scores;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

**Visualization: RFM Cube**
3D scatter plot or grouped bar chart showing user distribution across segments

---

## 6. PREDICTIVE ANALYTICS

### 6.1 LTV Prediction

```sql
CREATE OR REPLACE FUNCTION predict_user_ltv(target_user_id UUID)
RETURNS DECIMAL AS $$
DECLARE
  avg_session_count DECIMAL;
  engagement_score INTEGER;
  is_premium BOOLEAN;
  predicted_ltv DECIMAL := 0;
BEGIN
  -- Get user metrics
  SELECT 
    COUNT(s.id)::DECIMAL,
    calculate_user_engagement_score(target_user_id),
    u.is_premium
  INTO avg_session_count, engagement_score, is_premium
  FROM users u
  LEFT JOIN user_sessions s ON u.id = s.user_id
  WHERE u.id = target_user_id
  GROUP BY u.id, u.is_premium;
  
  -- Simple LTV calculation (can be ML-based in production)
  IF is_premium THEN
    predicted_ltv := 50; -- Base premium value
    predicted_ltv := predicted_ltv + (engagement_score * 0.5);
    predicted_ltv := predicted_ltv + (avg_session_count * 0.1);
  ELSE
    predicted_ltv := 5; -- Base free user value (ad revenue, potential conversion)
    predicted_ltv := predicted_ltv + (engagement_score * 0.1);
  END IF;
  
  RETURN predicted_ltv;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

### 6.2 Conversion Probability

```sql
CREATE OR REPLACE FUNCTION predict_conversion_probability(target_user_id UUID)
RETURNS DECIMAL AS $$
DECLARE
  engagement INTEGER;
  session_count INTEGER;
  days_since_signup INTEGER;
  viewed_paywall BOOLEAN;
  probability DECIMAL := 0;
BEGIN
  -- Gather signals
  SELECT 
    calculate_user_engagement_score(target_user_id),
    COUNT(s.id),
    DATE_PART('day', NOW() - u.created_at),
    EXISTS(
      SELECT 1 FROM user_events 
      WHERE user_id = target_user_id 
        AND event_name = 'viewed_paywall'
    )
  INTO engagement, session_count, days_since_signup, viewed_paywall
  FROM users u
  LEFT JOIN user_sessions s ON u.id = s.user_id
  WHERE u.id = target_user_id
  GROUP BY u.id, u.created_at;
  
  -- Calculate probability (0-100)
  probability := 10; -- Base
  
  IF engagement > 60 THEN probability := probability + 30; END IF;
  IF engagement > 40 THEN probability := probability + 15; END IF;
  
  IF session_count > 20 THEN probability := probability + 20; END IF;
  IF session_count > 10 THEN probability := probability + 10; END IF;
  
  IF viewed_paywall THEN probability := probability + 25; END IF;
  
  IF days_since_signup BETWEEN 3 AND 14 THEN 
    probability := probability + 15; -- Sweet spot for conversion
  END IF;
  
  RETURN LEAST(probability, 100);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

---

## 7. DASHBOARD LAYOUT RECOMMENDATION

### **Top Row:** Key Metrics (4 Cards)
```
┌────────────┬────────────┬────────────┬────────────┐
│    MAU     │    DAU     │ Stickiness │   Churn    │
│   12,450   │   2,935    │   23.6%    │   3.2%     │
│   +12.5%   │   +5.3%    │   +2.1%    │   -0.5%    │
└────────────┴────────────┴────────────┴────────────┘
```

### **Second Row:** Growth Chart (Full Width)
```
┌──────────────────────────────────────────────────┐
│  User Growth Over Time (Line Chart)             │
│  - Total Users, MAU, Premium Users               │
│  - 30-day trend with growth indicators           │
└──────────────────────────────────────────────────┘
```

### **Third Row:** Engagement Split (2 Columns)
```
┌────────────────────────┬────────────────────────┐
│ New vs Returning       │  Feature Adoption      │
│ (Stacked Area)         │  (Horizontal Bar)      │
└────────────────────────┴────────────────────────┘
```

### **Fourth Row:** Cohort & Segments (2 Columns)
```
┌────────────────────────┬────────────────────────┐
│ Retention Cohort       │  RFM Segments          │
│ (Heatmap)              │  (Pie Chart)           │
└────────────────────────┴────────────────────────┘
```

### **Bottom:** At-Risk Users & Real-time Feed
```
┌────────────────────────┬────────────────────────┐
│ At-Risk Users (Table)  │  Live Activity Feed    │
│ - Top 10 users         │  - Real-time events    │
│ - Recommended actions  │  - Auto-refresh        │
└────────────────────────┴────────────────────────┘
```

---

Bu gelişmiş metrik ve grafik sistemiyle **industry-standard** bir analytics dashboard'u oluşturursun! 🚀
