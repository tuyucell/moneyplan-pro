-- Apply account suspension and deletion state consistently to private data.
-- Existing owner policies identify whose data may be accessed; these
-- restrictive guards additionally require the current account to be usable.

create or replace function public.is_current_user_active()
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1
    from public.users
    where id = auth.uid()
      and is_active
      and not is_banned
      and deleted_at is null
  );
$$;

revoke all on function public.is_current_user_active() from public;
grant execute on function public.is_current_user_active() to authenticated, service_role;

do $$
declare
  v_table text;
begin
  foreach v_table in array array[
    'users',
    'user_sessions',
    'user_events',
    'user_favorites',
    'search_history',
    'user_portfolio',
    'user_bank_accounts',
    'user_transactions',
    'user_portfolio_assets',
    'user_watchlists',
    'user_sync_status',
    'price_alerts',
    'scenarios',
    'user_ai_usage',
    'audit_logs',
    'user_activities',
    'page_visits',
    'account_deletion_requests'
  ]
  loop
    execute format(
      'drop policy if exists account_active_guard on public.%I',
      v_table
    );
    execute format(
      'create policy account_active_guard on public.%I as restrictive for all to authenticated using (public.is_current_user_active()) with check (public.is_current_user_active())',
      v_table
    );
  end loop;
end;
$$;
