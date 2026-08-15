-- MoneyPlan Pro canonical baseline schema.
-- Consolidates the historical ad-hoc SQL files into one repeatable migration.

create extension if not exists pgcrypto with schema extensions;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create table public.users (
  id uuid primary key references auth.users(id) on delete cascade,
  email text unique,
  display_name text,
  full_name text,
  phone text,
  avatar_url text,
  preferred_currency text not null default 'TRY',
  preferred_language text not null default 'tr',
  theme text not null default 'system',
  is_email_verified boolean not null default false,
  auth_provider text not null default 'email',
  account_type text not null default 'email',
  role text not null default 'user' check (role in ('user', 'premium', 'pro', 'admin', 'super_admin')),
  is_premium boolean not null default false,
  premium_started_at timestamptz,
  premium_expires_at timestamptz,
  locale text not null default 'tr',
  timezone text not null default 'Europe/Istanbul',
  device_info jsonb not null default '{}'::jsonb,
  fcm_token text,
  apns_token text,
  is_active boolean not null default true,
  is_banned boolean not null default false,
  ban_reason text,
  banned_at timestamptz,
  banned_by uuid references auth.users(id) on delete set null,
  birth_year integer check (birth_year is null or birth_year between 1900 and 2100),
  gender text,
  occupation text,
  financial_goal text,
  risk_tolerance text,
  is_profile_completed boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  last_login_at timestamptz,
  last_seen_at timestamptz,
  deleted_at timestamptz
);

create index idx_users_created_at on public.users(created_at desc);
create index idx_users_last_seen_at on public.users(last_seen_at desc);
create index idx_users_premium on public.users(is_premium) where is_premium;

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  insert into public.users (
    id, email, display_name, full_name, avatar_url, is_email_verified,
    auth_provider, account_type, created_at, updated_at, last_login_at
  ) values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'display_name', new.raw_user_meta_data->>'full_name'),
    new.raw_user_meta_data->>'full_name',
    coalesce(new.raw_user_meta_data->>'avatar_url', new.raw_user_meta_data->>'picture'),
    new.email_confirmed_at is not null,
    coalesce(new.raw_app_meta_data->>'provider', 'email'),
    coalesce(new.raw_app_meta_data->>'provider', 'email'),
    new.created_at,
    new.updated_at,
    new.last_sign_in_at
  )
  on conflict (id) do update set
    email = excluded.email,
    display_name = coalesce(public.users.display_name, excluded.display_name),
    avatar_url = coalesce(public.users.avatar_url, excluded.avatar_url),
    is_email_verified = excluded.is_email_verified,
    auth_provider = excluded.auth_provider,
    last_login_at = excluded.last_login_at,
    updated_at = now();
  return new;
end;
$$;

create trigger on_auth_user_created
after insert or update of email, email_confirmed_at, last_sign_in_at, raw_user_meta_data on auth.users
for each row execute function public.handle_new_user();

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1 from public.users
    where id = auth.uid()
      and role in ('admin', 'super_admin')
      and is_active
      and not is_banned
      and deleted_at is null
  );
$$;

create trigger users_set_updated_at
before update on public.users
for each row execute function public.set_updated_at();

create table public.user_sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  session_start timestamptz not null default now(),
  session_end timestamptz,
  duration_seconds integer,
  device_info jsonb not null default '{}'::jsonb,
  app_version text,
  platform text check (platform is null or platform in ('ios', 'android', 'web', 'macos', 'windows', 'linux')),
  screens_viewed integer not null default 0,
  events_count integer not null default 0,
  created_at timestamptz not null default now()
);

create table public.user_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  session_id uuid references public.user_sessions(id) on delete set null,
  event_name text not null check (length(event_name) > 0),
  event_category text,
  properties jsonb not null default '{}'::jsonb,
  screen_name text,
  timestamp timestamptz not null default now()
);

create index idx_user_sessions_user_start on public.user_sessions(user_id, session_start desc);
create index idx_user_events_user_time on public.user_events(user_id, timestamp desc);
create index idx_user_events_name_time on public.user_events(event_name, timestamp desc);

create table public.asset_categories (
  id bigint generated by default as identity primary key,
  name text not null unique,
  display_name_tr text not null,
  display_name_en text not null,
  icon text,
  color text,
  sort_order integer not null default 0,
  is_active boolean not null default true
);

create table public.assets (
  id text primary key default gen_random_uuid()::text,
  category_id bigint references public.asset_categories(id) on delete set null,
  symbol text not null,
  name text not null,
  name_tr text,
  name_en text,
  category text,
  description text,
  description_tr text,
  description_en text,
  icon_url text,
  logo_url text,
  search_keywords text[] not null default '{}',
  current_price_usd numeric,
  change_24h numeric,
  price_change_24h numeric,
  price_change_percent_24h numeric,
  market_cap_usd numeric,
  volume_24h_usd numeric,
  last_price_update timestamptz,
  coingecko_id text,
  yahoo_symbol text,
  is_active boolean not null default true,
  is_popular boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(symbol, category_id)
);

create index idx_assets_symbol on public.assets(symbol);
create index idx_assets_category on public.assets(category_id);
create index idx_assets_popular on public.assets(is_popular, volume_24h_usd desc);

create table public.exchanges (
  id text primary key default gen_random_uuid()::text,
  name text not null,
  short_name text,
  description_tr text,
  description_en text,
  logo_url text,
  website_url text,
  app_ios_url text,
  app_android_url text,
  country_code text not null,
  country_name_tr text,
  country_name_en text,
  city text,
  timezone text,
  trading_hours_utc jsonb,
  trading_hours_local text,
  total_volume_24h_usd numeric,
  trust_score integer,
  year_established integer,
  supported_categories text[] not null default '{}',
  is_active boolean not null default true,
  is_featured boolean not null default false,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.asset_exchanges (
  id text primary key default gen_random_uuid()::text,
  asset_id text not null references public.assets(id) on delete cascade,
  exchange_id text not null references public.exchanges(id) on delete cascade,
  trading_pair text,
  base_currency text,
  quote_currency text,
  volume_24h_usd numeric,
  liquidity_score numeric,
  min_trade_amount numeric,
  min_trade_amount_currency text,
  lot_size numeric,
  lot_size_unit text,
  maker_fee_percent numeric,
  taker_fee_percent numeric,
  current_price numeric,
  last_price_update timestamptz,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(asset_id, exchange_id, trading_pair)
);

create table public.exchange_details (
  id uuid primary key default gen_random_uuid(),
  exchange_id text not null unique references public.exchanges(id) on delete cascade,
  account_opening_guide_tr text,
  account_opening_guide_en text,
  account_opening_steps jsonb,
  kyc_requirements jsonb,
  deposit_methods jsonb,
  withdrawal_methods jsonb,
  min_deposit_usd numeric,
  max_withdrawal_daily_usd numeric,
  security_features jsonb,
  is_regulated boolean,
  regulators text[],
  has_mobile_app boolean,
  has_api boolean,
  supported_languages text[],
  support_email text,
  support_phone text,
  support_hours text,
  special_notes_tr text,
  special_notes_en text,
  requires_broker boolean,
  recommended_brokers jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.exchange_reviews (
  id uuid primary key default gen_random_uuid(),
  exchange_id text not null references public.exchanges(id) on delete cascade,
  user_id uuid references public.users(id) on delete set null,
  rating integer not null check (rating between 1 and 5),
  title text,
  review_text text,
  ease_of_use_rating integer check (ease_of_use_rating between 1 and 5),
  fees_rating integer check (fees_rating between 1 and 5),
  security_rating integer check (security_rating between 1 and 5),
  support_rating integer check (support_rating between 1 and 5),
  is_verified_user boolean not null default false,
  is_approved boolean not null default false,
  helpful_count integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.popular_searches (
  id uuid primary key default gen_random_uuid(),
  asset_id text not null references public.assets(id) on delete cascade,
  search_count integer not null default 0,
  period text not null default 'daily',
  period_start date not null default current_date,
  updated_at timestamptz not null default now(),
  unique(asset_id, period, period_start)
);

create table public.user_favorites (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  asset_id text not null references public.assets(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique(user_id, asset_id)
);

create table public.search_history (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  search_query text not null,
  asset_id text references public.assets(id) on delete set null,
  searched_at timestamptz not null default now()
);

create table public.user_portfolio (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  asset_id text not null references public.assets(id) on delete cascade,
  exchange_id text references public.exchanges(id) on delete set null,
  quantity numeric not null default 0,
  average_buy_price numeric,
  currency text not null default 'USD',
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.user_bank_accounts (
  user_id uuid not null references public.users(id) on delete cascade,
  id text not null,
  account_name text not null,
  account_type text not null,
  balance numeric not null default 0,
  currency text not null default 'TRY',
  iban text,
  bank_name text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key(user_id, id)
);

create table public.user_transactions (
  user_id uuid not null references public.users(id) on delete cascade,
  id text not null,
  amount numeric not null check (amount >= 0),
  type text not null check (type in ('income', 'expense')),
  category_id text,
  description text,
  date timestamptz not null,
  currency text not null default 'TRY',
  account_id text,
  is_recurring boolean not null default false,
  recurrence_type text,
  recurrence_end_date timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key(user_id, id),
  foreign key(user_id, account_id) references public.user_bank_accounts(user_id, id) on delete set null (account_id)
);

create table public.user_portfolio_assets (
  id text primary key default gen_random_uuid()::text,
  user_id uuid not null references public.users(id) on delete cascade,
  symbol text not null,
  name text,
  type text,
  quantity numeric not null default 0,
  average_cost numeric not null default 0,
  currency text not null default 'USD',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(user_id, symbol)
);

create table public.user_watchlists (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  symbol text not null,
  asset_id text,
  asset_name text,
  asset_type text,
  added_at timestamptz not null default now(),
  unique(user_id, symbol)
);

create table public.user_sync_status (
  user_id uuid primary key references public.users(id) on delete cascade,
  last_synced_at timestamptz not null default now(),
  device_id text
);

create table public.price_alerts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  asset_id text not null,
  asset_name text not null,
  symbol text not null,
  target_price numeric not null,
  is_above boolean not null default true,
  is_active boolean not null default true,
  last_triggered_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index idx_price_alerts_active on public.price_alerts(is_active) where is_active;
create index idx_user_transactions_date on public.user_transactions(user_id, date desc);
create index idx_user_portfolio_assets_user on public.user_portfolio_assets(user_id);
create index idx_user_watchlists_user on public.user_watchlists(user_id);

create table public.scenarios (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  name text not null,
  description text,
  parameters jsonb not null default '{}'::jsonb,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.user_ai_usage (
  user_id uuid not null references public.users(id) on delete cascade,
  analysis_type text not null,
  usage_count integer not null default 0,
  last_used_at timestamptz not null default now(),
  reset_date date not null default (date_trunc('month', current_date) + interval '1 month - 1 day')::date,
  primary key(user_id, analysis_type)
);

create table public.market_interest_rates (
  id uuid primary key default gen_random_uuid(),
  type text not null unique,
  rate numeric not null,
  description text,
  last_updated timestamptz not null default now()
);

create table public.app_config (
  key text primary key,
  value jsonb not null,
  description text,
  updated_at timestamptz not null default now()
);

insert into public.app_config(key, value, description) values
  ('ai_limit_monthly_free', '3'::jsonb, 'Free monthly AI analysis limit'),
  ('ai_limit_monthly_premium', '10'::jsonb, 'Premium monthly AI analysis limit')
on conflict (key) do nothing;

insert into public.market_interest_rates(type, rate, description) values
  ('deposit_monthly', 3.5, 'Average monthly deposit rate'),
  ('credit_card_monthly', 4.25, 'Credit card monthly rate'),
  ('inflation_monthly', 3.0, 'Estimated monthly inflation')
on conflict (type) do nothing;

create table public.audit_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.users(id) on delete set null,
  admin_id uuid references auth.users(id) on delete set null default auth.uid(),
  action text not null,
  table_name text,
  record_id text,
  old_data jsonb,
  new_data jsonb,
  details jsonb,
  ip_address text,
  user_agent text,
  created_at timestamptz not null default now()
);

create table public.user_activities (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.users(id) on delete cascade,
  activity_type text not null,
  activity_name text not null,
  metadata jsonb not null default '{}'::jsonb,
  client_info jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table public.page_visits (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.users(id) on delete cascade,
  page_path text not null,
  duration_seconds integer not null default 0,
  created_at timestamptz not null default now()
);

create table public.account_deletion_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  reason text,
  status text not null default 'pending' check (status in ('pending', 'approved', 'rejected')),
  created_at timestamptz not null default now(),
  processed_at timestamptz,
  processed_by uuid references public.users(id) on delete set null
);

create index idx_audit_logs_created on public.audit_logs(created_at desc);
create index idx_audit_logs_user on public.audit_logs(user_id, created_at desc);
create index idx_user_activities_created on public.user_activities(created_at desc);
create index idx_page_visits_created on public.page_visits(created_at desc);
create index idx_deletion_requests_status on public.account_deletion_requests(status, created_at desc);

create trigger assets_set_updated_at before update on public.assets for each row execute function public.set_updated_at();
create trigger exchanges_set_updated_at before update on public.exchanges for each row execute function public.set_updated_at();
create trigger asset_exchanges_set_updated_at before update on public.asset_exchanges for each row execute function public.set_updated_at();
create trigger exchange_details_set_updated_at before update on public.exchange_details for each row execute function public.set_updated_at();
create trigger exchange_reviews_set_updated_at before update on public.exchange_reviews for each row execute function public.set_updated_at();
create trigger user_portfolio_set_updated_at before update on public.user_portfolio for each row execute function public.set_updated_at();
create trigger bank_accounts_set_updated_at before update on public.user_bank_accounts for each row execute function public.set_updated_at();
create trigger transactions_set_updated_at before update on public.user_transactions for each row execute function public.set_updated_at();
create trigger portfolio_assets_set_updated_at before update on public.user_portfolio_assets for each row execute function public.set_updated_at();
create trigger price_alerts_set_updated_at before update on public.price_alerts for each row execute function public.set_updated_at();
create trigger scenarios_set_updated_at before update on public.scenarios for each row execute function public.set_updated_at();
create trigger app_config_set_updated_at before update on public.app_config for each row execute function public.set_updated_at();

alter table public.users enable row level security;
alter table public.user_sessions enable row level security;
alter table public.user_events enable row level security;
alter table public.asset_categories enable row level security;
alter table public.assets enable row level security;
alter table public.exchanges enable row level security;
alter table public.asset_exchanges enable row level security;
alter table public.exchange_details enable row level security;
alter table public.exchange_reviews enable row level security;
alter table public.popular_searches enable row level security;
alter table public.user_favorites enable row level security;
alter table public.search_history enable row level security;
alter table public.user_portfolio enable row level security;
alter table public.user_bank_accounts enable row level security;
alter table public.user_transactions enable row level security;
alter table public.user_portfolio_assets enable row level security;
alter table public.user_watchlists enable row level security;
alter table public.user_sync_status enable row level security;
alter table public.price_alerts enable row level security;
alter table public.scenarios enable row level security;
alter table public.user_ai_usage enable row level security;
alter table public.market_interest_rates enable row level security;
alter table public.app_config enable row level security;
alter table public.audit_logs enable row level security;
alter table public.user_activities enable row level security;
alter table public.page_visits enable row level security;
alter table public.account_deletion_requests enable row level security;

create policy users_read on public.users for select to authenticated using (id = auth.uid() or public.is_admin());
create policy users_update on public.users for update to authenticated using (id = auth.uid() or public.is_admin()) with check (id = auth.uid() or public.is_admin());

create policy market_categories_read on public.asset_categories for select to anon, authenticated using (is_active);
create policy market_assets_read on public.assets for select to anon, authenticated using (is_active);
create policy market_exchanges_read on public.exchanges for select to anon, authenticated using (is_active);
create policy market_asset_exchanges_read on public.asset_exchanges for select to anon, authenticated using (is_active);
create policy market_exchange_details_read on public.exchange_details for select to anon, authenticated using (true);
create policy market_exchange_reviews_read on public.exchange_reviews for select to anon, authenticated using (is_approved or public.is_admin());
create policy market_popular_searches_read on public.popular_searches for select to anon, authenticated using (true);
create policy market_rates_read on public.market_interest_rates for select to anon, authenticated using (true);
create policy app_config_read on public.app_config for select to anon, authenticated using (true);
create policy market_admin_categories on public.asset_categories for all to authenticated using (public.is_admin()) with check (public.is_admin());
create policy market_admin_assets on public.assets for all to authenticated using (public.is_admin()) with check (public.is_admin());
create policy market_admin_exchanges on public.exchanges for all to authenticated using (public.is_admin()) with check (public.is_admin());
create policy market_admin_asset_exchanges on public.asset_exchanges for all to authenticated using (public.is_admin()) with check (public.is_admin());
create policy market_admin_exchange_details on public.exchange_details for all to authenticated using (public.is_admin()) with check (public.is_admin());
create policy market_admin_exchange_reviews on public.exchange_reviews for all to authenticated using (public.is_admin()) with check (public.is_admin());
create policy market_admin_rates on public.market_interest_rates for all to authenticated using (public.is_admin()) with check (public.is_admin());
create policy app_config_admin on public.app_config for all to authenticated using (public.is_admin()) with check (public.is_admin());

create policy sessions_owner on public.user_sessions for all to authenticated using (user_id = auth.uid() or public.is_admin()) with check (user_id = auth.uid() or public.is_admin());
create policy events_owner on public.user_events for all to authenticated using (user_id = auth.uid() or public.is_admin()) with check (user_id = auth.uid() or public.is_admin());
create policy favorites_owner on public.user_favorites for all to authenticated using (user_id = auth.uid() or public.is_admin()) with check (user_id = auth.uid() or public.is_admin());
create policy history_owner on public.search_history for all to authenticated using (user_id = auth.uid() or public.is_admin()) with check (user_id = auth.uid() or public.is_admin());
create policy portfolio_owner on public.user_portfolio for all to authenticated using (user_id = auth.uid() or public.is_admin()) with check (user_id = auth.uid() or public.is_admin());
create policy bank_accounts_owner on public.user_bank_accounts for all to authenticated using (user_id = auth.uid() or public.is_admin()) with check (user_id = auth.uid() or public.is_admin());
create policy transactions_owner on public.user_transactions for all to authenticated using (user_id = auth.uid() or public.is_admin()) with check (user_id = auth.uid() or public.is_admin());
create policy portfolio_assets_owner on public.user_portfolio_assets for all to authenticated using (user_id = auth.uid() or public.is_admin()) with check (user_id = auth.uid() or public.is_admin());
create policy watchlists_owner on public.user_watchlists for all to authenticated using (user_id = auth.uid() or public.is_admin()) with check (user_id = auth.uid() or public.is_admin());
create policy sync_status_owner on public.user_sync_status for all to authenticated using (user_id = auth.uid() or public.is_admin()) with check (user_id = auth.uid() or public.is_admin());
create policy alerts_owner on public.price_alerts for all to authenticated using (user_id = auth.uid() or public.is_admin()) with check (user_id = auth.uid() or public.is_admin());
create policy scenarios_owner on public.scenarios for all to authenticated using (user_id = auth.uid() or public.is_admin()) with check (user_id = auth.uid() or public.is_admin());
create policy ai_usage_owner on public.user_ai_usage for select to authenticated using (user_id = auth.uid() or public.is_admin());
create policy activities_owner on public.user_activities for insert to authenticated with check (user_id = auth.uid());
create policy activities_admin_read on public.user_activities for select to authenticated using (public.is_admin());
create policy page_visits_owner on public.page_visits for insert to authenticated with check (user_id = auth.uid());
create policy page_visits_admin_read on public.page_visits for select to authenticated using (public.is_admin());
create policy audit_insert on public.audit_logs for insert to authenticated with check (user_id = auth.uid() or admin_id = auth.uid());
create policy audit_admin_read on public.audit_logs for select to authenticated using (public.is_admin());
create policy deletion_owner on public.account_deletion_requests for select to authenticated using (user_id = auth.uid() or public.is_admin());
create policy deletion_admin_update on public.account_deletion_requests for update to authenticated using (public.is_admin()) with check (public.is_admin());

do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'user_activities'
  ) then
    alter publication supabase_realtime add table public.user_activities;
  end if;
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'audit_logs'
  ) then
    alter publication supabase_realtime add table public.audit_logs;
  end if;
end;
$$;

grant usage on schema public to anon, authenticated;
grant select on public.asset_categories, public.assets, public.exchanges, public.asset_exchanges,
  public.exchange_details, public.exchange_reviews, public.popular_searches,
  public.market_interest_rates, public.app_config to anon, authenticated;
grant select, insert, update, delete on all tables in schema public to authenticated;
grant usage, select on all sequences in schema public to authenticated;
