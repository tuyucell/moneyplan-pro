-- MoneyPlan Pro admin analytics RPCs.
-- All RPCs in this file require an authenticated admin user.

create or replace function public.get_dashboard_stats_v2()
returns table(total_users numeric, active_users numeric, premium_users numeric, total_revenue numeric)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  perform public.assert_admin();
  return query
  select
    count(*) filter (where deleted_at is null)::numeric,
    count(*) filter (
      where deleted_at is null and is_active
        and coalesce(last_login_at, last_seen_at, updated_at, created_at) > now() - interval '30 days'
    )::numeric,
    count(*) filter (where deleted_at is null and (is_premium or role in ('premium', 'pro', 'admin', 'super_admin')))::numeric,
    coalesce((select sum(amount) from public.user_transactions where type = 'income'), 0)::numeric
  from public.users;
end;
$$;

create or replace function public.get_user_growth_v2(period text default '30d')
returns table(activity_date text, total_users numeric, active_users numeric, premium_users numeric)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_start date;
begin
  perform public.assert_admin();
  v_start := case period
    when '24h' then current_date - 1
    when '7d' then current_date - 7
    when '30d' then current_date - 30
    when '90d' then current_date - 90
    else current_date - 30
  end;
  return query
  with dates as (
    select generate_series(v_start, current_date, interval '1 day')::date as day
  )
  select
    to_char(d.day, 'YYYY-MM-DD'),
    (select count(*) from public.users u where u.created_at::date <= d.day and u.deleted_at is null)::numeric,
    (select count(distinct e.user_id) from public.user_events e where e.timestamp::date = d.day)::numeric,
    (select count(*) from public.users u where u.created_at::date <= d.day and u.deleted_at is null
      and (u.is_premium or u.role in ('premium', 'pro', 'admin', 'super_admin')))::numeric
  from dates d
  order by d.day;
end;
$$;

create or replace function public.get_top_events(p_days_back integer default 7, p_limit_count integer default 10)
returns table(event_name text, event_category text, count bigint, unique_users bigint)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  perform public.assert_admin();
  return query
  select e.event_name, e.event_category, count(*)::bigint, count(distinct e.user_id)::bigint
  from public.user_events e
  where e.timestamp >= current_date - greatest(1, p_days_back)
  group by e.event_name, e.event_category
  order by count(*) desc
  limit greatest(1, least(p_limit_count, 100));
end;
$$;

create or replace function public.calculate_user_engagement_score(p_user_id uuid)
returns integer
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select least(count(*)::integer * 2, 40)
    + least(count(distinct date(timestamp))::integer * 5, 30)
    + case when exists (select 1 from public.users where id = p_user_id and is_premium) then 30 else 0 end
  from public.user_events
  where user_id = p_user_id and timestamp >= now() - interval '30 days';
$$;

create or replace function public.calculate_rfm_segments()
returns table(segment_name text, user_count bigint, percentage numeric, avg_engagement_score integer)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  perform public.assert_admin();
  return query
  with scored as (
    select
      u.id,
      public.calculate_user_engagement_score(u.id) score,
      case
        when u.is_premium and coalesce(u.last_seen_at, u.created_at) > now() - interval '7 days' then 'Active Leaders'
        when coalesce(u.last_seen_at, u.created_at) > now() - interval '7 days' then 'Regulars'
        when coalesce(u.last_seen_at, u.created_at) > now() - interval '30 days' then 'At Risk'
        else 'Hibernating'
      end segment
    from public.users u where u.deleted_at is null
  ), totals as (select count(*)::numeric total from scored)
  select s.segment, count(*)::bigint,
    round(count(*)::numeric / nullif(t.total, 0) * 100, 1),
    round(avg(s.score))::integer
  from scored s cross join totals t
  group by s.segment, t.total
  order by count(*) desc;
end;
$$;

create or replace function public.get_at_risk_users_v2()
returns table(
  user_id uuid, email_addr text, days_inactive integer, risk_status text,
  display_name text, engagement_score integer, recommended_action text, is_premium boolean
)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  perform public.assert_admin();
  return query
  select
    u.id, u.email,
    extract(day from now() - coalesce(u.last_login_at, u.last_seen_at, u.created_at))::integer,
    case
      when coalesce(u.last_login_at, u.last_seen_at, u.created_at) < now() - interval '90 days' then 'HIGH'
      when coalesce(u.last_login_at, u.last_seen_at, u.created_at) < now() - interval '60 days' then 'MEDIUM'
      else 'LOW'
    end,
    coalesce(u.display_name, u.full_name, 'User'),
    public.calculate_user_engagement_score(u.id),
    'Send Push Notification / Email'::text,
    u.is_premium
  from public.users u
  where u.deleted_at is null
    and coalesce(u.last_login_at, u.last_seen_at, u.created_at) < now() - interval '30 days'
  order by 3 desc
  limit 100;
end;
$$;

create or replace function public.get_feature_adoption(p_days_back integer default 30)
returns table(feature_name text, total_users bigint, adoption_rate numeric, avg_uses_per_user numeric, trend text)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  perform public.assert_admin();
  return query
  with usage as (
    select event_name, count(distinct user_id) users, count(*) uses
    from public.user_events where timestamp >= current_date - greatest(1, p_days_back)
    group by event_name
  ), active as (
    select count(distinct user_id) total
    from public.user_events where timestamp >= current_date - greatest(1, p_days_back)
  )
  select u.event_name, u.users::bigint,
    round(u.users::numeric / nullif(a.total, 0) * 100, 1),
    round(u.uses::numeric / nullif(u.users, 0), 1),
    'stable'::text
  from usage u cross join active a
  order by u.users desc;
end;
$$;

create or replace function public.calculate_churn_rate(p_period_days integer default 30)
returns table(
  period_days integer, active_at_start bigint, churned bigint,
  retained bigint, churn_rate numeric, retention_rate numeric
)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_start bigint;
  v_retained bigint;
begin
  perform public.assert_admin();
  select count(distinct user_id) into v_start
  from public.user_events
  where timestamp >= current_date - p_period_days * 2
    and timestamp < current_date - p_period_days;
  select count(distinct e.user_id) into v_retained
  from public.user_events e
  where e.timestamp >= current_date - p_period_days
    and exists (
      select 1 from public.user_events prior
      where prior.user_id = e.user_id
        and prior.timestamp >= current_date - p_period_days * 2
        and prior.timestamp < current_date - p_period_days
    );
  return query select
    p_period_days, v_start, greatest(v_start - v_retained, 0), v_retained,
    round(greatest(v_start - v_retained, 0)::numeric / nullif(v_start, 0) * 100, 1),
    round(v_retained::numeric / nullif(v_start, 0) * 100, 1);
end;
$$;

create or replace function public.get_retention_cohorts()
returns table(
  period_start date, new_users bigint, day_1_retention numeric,
  day_7_retention numeric, day_14_retention numeric, day_30_retention numeric
)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  perform public.assert_admin();
  return query
  with cohorts as (
    select created_at::date cohort_date, id user_id
    from public.users where created_at >= current_date - interval '30 days' and deleted_at is null
  ), retention as (
    select c.cohort_date, count(distinct c.user_id) total,
      count(distinct e.user_id) filter (where e.timestamp::date = c.cohort_date + 1) day_1,
      count(distinct e.user_id) filter (where e.timestamp::date = c.cohort_date + 7) day_7,
      count(distinct e.user_id) filter (where e.timestamp::date = c.cohort_date + 14) day_14,
      count(distinct e.user_id) filter (where e.timestamp::date = c.cohort_date + 30) day_30
    from cohorts c left join public.user_events e on e.user_id = c.user_id
    group by c.cohort_date
  )
  select cohort_date, total::bigint,
    round(day_1::numeric / nullif(total, 0) * 100, 1),
    round(day_7::numeric / nullif(total, 0) * 100, 1),
    round(day_14::numeric / nullif(total, 0) * 100, 1),
    round(day_30::numeric / nullif(total, 0) * 100, 1)
  from retention order by cohort_date desc;
end;
$$;

create or replace function public.get_page_engagement_stats(p_days_back integer default 30)
returns table(category text, page_path text, avg_duration_seconds numeric, total_views bigint, unique_visitors bigint)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  perform public.assert_admin();
  return query
  select
    case
      when pv.page_path like '/market%' then 'Markets'
      when pv.page_path like '/portfolio%' then 'Wallet (Portfolio)'
      when pv.page_path like '/watchlist%' then 'Wallet (Watchlist)'
      when pv.page_path like '/analysis%' then 'Tools & Analysis'
      when pv.page_path like '/settings%' then 'Settings'
      when pv.page_path in ('/', '/dashboard') then 'Dashboard'
      else 'Other'
    end,
    pv.page_path,
    round(avg(pv.duration_seconds), 1),
    count(*)::bigint,
    count(distinct pv.user_id)::bigint
  from public.page_visits pv
  where pv.created_at >= current_date - greatest(1, p_days_back)
  group by 1, pv.page_path
  order by count(*) desc;
end;
$$;

create or replace function public.get_daily_visit_frequency(p_days_back integer default 30)
returns table(visits_per_day integer, user_count bigint)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  perform public.assert_admin();
  return query
  with visits as (
    select user_id, created_at::date, count(*)::integer visit_count
    from public.page_visits
    where created_at >= current_date - greatest(1, p_days_back)
    group by user_id, created_at::date
  )
  select visit_count, count(distinct user_id)::bigint
  from visits group by visit_count order by visit_count;
end;
$$;

create or replace function public.get_live_active_users()
returns table(active_count integer, premium_count integer, latest_event_time timestamptz)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  perform public.assert_admin();
  return query
  select count(distinct u.id)::integer,
    count(distinct u.id) filter (where u.is_premium)::integer,
    max(e.timestamp)
  from public.users u join public.user_events e on e.user_id = u.id
  where e.timestamp >= now() - interval '5 minutes';
end;
$$;

create or replace function public.get_live_event_feed(p_limit integer default 30)
returns table(
  id uuid, user_id uuid, email text, event_name text,
  screen_name text, properties jsonb, event_timestamp timestamptz
)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  perform public.assert_admin();
  return query
  select e.id, e.user_id, u.email, e.event_name, e.screen_name, e.properties, e.timestamp
  from public.user_events e join public.users u on u.id = e.user_id
  order by e.timestamp desc limit greatest(1, least(p_limit, 200));
end;
$$;

create or replace function public.search_users_intelligence(
  p_search text default '', p_role text default null, p_status text default null,
  p_limit integer default 50, p_offset integer default 0
)
returns table(
  id uuid, email text, display_name text, is_premium boolean,
  last_seen_at timestamptz, created_at timestamptz,
  total_assets_count bigint, total_transactions_count bigint, account_status text
)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  perform public.assert_admin();
  return query
  select u.id, u.email, coalesce(u.display_name, u.full_name), u.is_premium,
    u.last_seen_at, u.created_at,
    (select count(*) from public.user_portfolio_assets a where a.user_id = u.id),
    (select count(*) from public.user_transactions t where t.user_id = u.id),
    case
      when u.is_banned then 'BANNED'
      when u.deleted_at is not null then 'DELETED'
      when u.last_seen_at > now() - interval '5 minutes' then 'ONLINE'
      else 'OFFLINE'
    end
  from public.users u
  where (coalesce(u.email, '') ilike '%' || p_search || '%' or coalesce(u.display_name, u.full_name, '') ilike '%' || p_search || '%')
    and (p_role is null or p_role = 'all' or (p_role = 'premium' and u.is_premium) or (p_role = 'free' and not u.is_premium) or u.role = p_role)
    and (p_status is null or p_status = 'all' or
      (p_status = 'banned' and u.is_banned) or
      (p_status = 'active' and u.is_active and not u.is_banned and u.deleted_at is null))
  order by u.last_seen_at desc nulls last
  limit greatest(1, least(p_limit, 200)) offset greatest(0, p_offset);
end;
$$;

create or replace function public.get_intelligence_live_feed(p_limit integer default 20)
returns table(id uuid, user_email text, activity_type text, activity_name text, metadata jsonb, created_at timestamptz)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  perform public.assert_admin();
  return query
  select a.id, u.email, a.activity_type, a.activity_name, a.metadata, a.created_at
  from public.user_activities a join public.users u on u.id = a.user_id
  order by a.created_at desc limit greatest(1, least(p_limit, 200));
end;
$$;

create or replace function public.get_cohort_retention()
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare v_result jsonb;
begin
  perform public.assert_admin();
  with cohorts as (
    select id user_id, date_trunc('week', created_at) cohort_week
    from public.users where created_at > now() - interval '12 weeks'
  ), activity as (
    select user_id, date_trunc('week', created_at) activity_week from public.user_activities
    union
    select user_id, date_trunc('week', created_at) from public.audit_logs where user_id is not null
  ), counts as (
    select c.cohort_week,
      (extract(day from a.activity_week - c.cohort_week) / 7)::integer week_number,
      count(distinct c.user_id) active_users
    from cohorts c left join activity a on a.user_id = c.user_id and a.activity_week >= c.cohort_week
    group by 1, 2
  ), sizes as (
    select cohort_week, count(*) cohort_size from cohorts group by cohort_week
  )
  select coalesce(jsonb_agg(to_jsonb(x) order by x.cohort_week desc, x.week_number), '[]'::jsonb)
  into v_result
  from (
    select c.cohort_week::text, c.week_number, c.active_users, s.cohort_size,
      round(c.active_users::numeric / nullif(s.cohort_size, 0) * 100) retention_rate
    from counts c join sizes s using(cohort_week)
  ) x;
  return v_result;
end;
$$;

create or replace function public.get_user_segmentation()
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare v_result jsonb;
begin
  perform public.assert_admin();
  with stats as (
    select u.id, u.is_premium, count(a.id) activity_count
    from public.users u left join public.user_activities a
      on a.user_id = u.id and a.created_at > now() - interval '30 days'
    where u.deleted_at is null
    group by u.id, u.is_premium
  )
  select coalesce(jsonb_agg(to_jsonb(x)), '[]'::jsonb) into v_result
  from (
    select case
      when activity_count > 50 then 'Power User'
      when activity_count >= 10 then 'Active User'
      when activity_count >= 1 then 'Casual User'
      else 'At-Risk / Inactive'
    end segment,
    count(*) user_count,
    count(*) filter (where is_premium) premium_count
    from stats group by 1
  ) x;
  return v_result;
end;
$$;

create or replace function public.get_anomaly_detection()
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare v_result jsonb;
begin
  perform public.assert_admin();
  with anomalies as (
    select 'Multi-IP Usage'::text anomaly_type, u.email user_email,
      count(distinct a.ip_address)::bigint ip_count, null::bigint action_count,
      jsonb_agg(distinct a.ip_address) ips, max(a.created_at) latest_event, 'High'::text severity
    from public.audit_logs a join public.users u on u.id = a.user_id
    where a.created_at > now() - interval '7 days' and a.ip_address is not null
    group by u.email having count(distinct a.ip_address) > 3
    union all
    select 'Bot-like Activity', u.email, null::bigint, count(*)::bigint,
      null::jsonb, max(a.created_at), 'Critical'
    from public.audit_logs a join public.users u on u.id = a.user_id
    where a.created_at > now() - interval '10 minutes'
    group by u.email having count(*) > 100
  )
  select coalesce(jsonb_agg(to_jsonb(anomalies)), '[]'::jsonb) into v_result from anomalies;
  return v_result;
end;
$$;

create or replace function public.get_funnel_analysis()
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare v_result jsonb;
begin
  perform public.assert_admin();
  with steps as (
    select 1 step, 'Registration'::text stage, count(*)::bigint count from public.users
    union all select 2, 'Active Session', count(distinct user_id) from public.user_sessions
    union all select 3, 'Created Watchlist', count(distinct user_id) from public.user_watchlists
    union all select 4, 'Created Portfolio', count(distinct user_id) from public.user_portfolio_assets
  ), calculated as (
    select *, lag(count) over(order by step) prev_count from steps
  )
  select coalesce(jsonb_agg(jsonb_build_object(
    'step', step, 'stage', stage, 'count', count, 'prev_count', prev_count,
    'conversion_rate', round(count::numeric / nullif(prev_count, 0) * 100)
  ) order by step), '[]'::jsonb)
  into v_result from calculated;
  return v_result;
end;
$$;

grant execute on function public.get_dashboard_stats_v2() to authenticated;
grant execute on function public.get_user_growth_v2(text) to authenticated;
grant execute on function public.get_top_events(integer, integer) to authenticated;
grant execute on function public.calculate_rfm_segments() to authenticated;
grant execute on function public.get_at_risk_users_v2() to authenticated;
grant execute on function public.get_feature_adoption(integer) to authenticated;
grant execute on function public.calculate_churn_rate(integer) to authenticated;
grant execute on function public.get_retention_cohorts() to authenticated;
grant execute on function public.get_page_engagement_stats(integer) to authenticated;
grant execute on function public.get_daily_visit_frequency(integer) to authenticated;
grant execute on function public.get_live_active_users() to authenticated;
grant execute on function public.get_live_event_feed(integer) to authenticated;
grant execute on function public.search_users_intelligence(text, text, text, integer, integer) to authenticated;
grant execute on function public.get_intelligence_live_feed(integer) to authenticated;
grant execute on function public.get_cohort_retention() to authenticated;
grant execute on function public.get_user_segmentation() to authenticated;
grant execute on function public.get_anomaly_detection() to authenticated;
grant execute on function public.get_funnel_analysis() to authenticated;
