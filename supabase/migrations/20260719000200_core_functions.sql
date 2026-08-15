-- MoneyPlan Pro client and operational RPCs.

create or replace function public.assert_admin()
returns void
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
begin
  if not public.is_admin() then
    raise exception 'Admin access required' using errcode = '42501';
  end if;
end;
$$;

create or replace function public.search_assets(search_term text, limit_count integer default 20)
returns setof public.assets
language sql
stable
security invoker
set search_path = public, pg_temp
as $$
  select a.*
  from public.assets a
  where a.is_active
    and (
      a.symbol ilike '%' || search_term || '%'
      or a.name ilike '%' || search_term || '%'
      or coalesce(a.name_tr, '') ilike '%' || search_term || '%'
      or coalesce(a.name_en, '') ilike '%' || search_term || '%'
      or exists (
        select 1 from unnest(a.search_keywords) keyword
        where keyword ilike '%' || search_term || '%'
      )
    )
  order by a.is_popular desc, a.volume_24h_usd desc nulls last, a.symbol
  limit greatest(1, least(limit_count, 100));
$$;

create or replace function public.check_and_increment_ai_usage(p_user_id uuid, p_type text)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_is_premium boolean := false;
  v_limit integer;
  v_usage integer;
  v_reset_date date;
  v_next_reset date := (date_trunc('month', current_date) + interval '1 month - 1 day')::date;
begin
  if auth.uid() is null or (auth.uid() <> p_user_id and not public.is_admin()) then
    raise exception 'Not authorized' using errcode = '42501';
  end if;

  select coalesce(is_premium, false) into v_is_premium
  from public.users where id = p_user_id;

  select coalesce((value #>> '{}')::integer, 3) into v_limit
  from public.app_config
  where key = case when v_is_premium then 'ai_limit_monthly_premium' else 'ai_limit_monthly_free' end;
  v_limit := coalesce(v_limit, case when v_is_premium then 10 else 3 end);

  insert into public.user_ai_usage(user_id, analysis_type, usage_count, reset_date)
  values (p_user_id, p_type, 0, v_next_reset)
  on conflict (user_id, analysis_type) do nothing;

  select usage_count, reset_date into v_usage, v_reset_date
  from public.user_ai_usage
  where user_id = p_user_id and analysis_type = p_type
  for update;

  if current_date > v_reset_date then
    v_usage := 0;
    update public.user_ai_usage
    set usage_count = 0, reset_date = v_next_reset
    where user_id = p_user_id and analysis_type = p_type;
  end if;

  if v_usage >= v_limit then
    return jsonb_build_object(
      'allowed', false, 'is_premium', v_is_premium,
      'usage', v_usage, 'limit', v_limit,
      'message', 'Aylık analiz limitinize ulaştınız.'
    );
  end if;

  update public.user_ai_usage
  set usage_count = usage_count + 1, last_used_at = now()
  where user_id = p_user_id and analysis_type = p_type;

  return jsonb_build_object(
    'allowed', true, 'is_premium', v_is_premium,
    'usage', v_usage + 1, 'limit', v_limit,
    'remaining', v_limit - v_usage - 1
  );
end;
$$;

create or replace function public.analyze_purchase_decision(
  p_amount numeric,
  p_installments integer,
  p_installment_amount numeric,
  p_custom_rate numeric default null
)
returns jsonb
language plpgsql
security invoker
set search_path = public, pg_temp
as $$
declare
  v_rate numeric;
  v_total numeric;
  v_npv numeric := 0;
  v_recommendation text;
  v_gain numeric;
begin
  if p_amount <= 0 or p_installments <= 0 or p_installment_amount <= 0 then
    raise exception 'Amounts and installments must be positive';
  end if;

  if p_custom_rate is not null and p_custom_rate >= 0 then
    v_rate := p_custom_rate;
  else
    select rate into v_rate from public.market_interest_rates where type = 'deposit_monthly';
    v_rate := coalesce(v_rate, 3.5);
  end if;

  v_total := p_installments * p_installment_amount;
  for i in 1..p_installments loop
    v_npv := v_npv + p_installment_amount / power(1 + v_rate / 100.0, i);
  end loop;

  if v_npv < p_amount then
    v_recommendation := 'INSTALLMENT';
    v_gain := p_amount - v_npv;
  else
    v_recommendation := 'CASH';
    v_gain := v_npv - p_amount;
  end if;

  return jsonb_build_object(
    'recommendation', v_recommendation,
    'market_rate', v_rate,
    'cash_price', p_amount,
    'total_installment_price', v_total,
    'npv_cost', round(v_npv, 2),
    'opportunity_gain', round(v_gain, 2),
    'message', case
      when v_recommendation = 'INSTALLMENT' then 'Taksitli ödeme, paranın zaman değeri açısından daha avantajlı görünüyor.'
      else 'Nakit ödeme, toplam maliyet açısından daha avantajlı görünüyor.'
    end
  );
end;
$$;

create or replace function public.calculate_financial_pilot(
  p_user_id uuid,
  p_months integer default 3,
  p_simulate_purchase_amount numeric default 0,
  p_simulate_purchase_installments integer default 1,
  p_current_balance numeric default 0
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_balance numeric := p_current_balance;
  v_day_balance numeric;
  v_min_balance numeric;
  v_income numeric;
  v_expense numeric;
  v_date date;
  v_chart jsonb := '[]'::jsonb;
  v_insights jsonb := '[]'::jsonb;
  v_first_negative date;
  v_expense_multiplier numeric := 1;
  v_income_multiplier numeric := 1;
begin
  if auth.uid() is null or (auth.uid() <> p_user_id and not public.is_admin()) then
    raise exception 'Not authorized' using errcode = '42501';
  end if;
  p_months := greatest(1, least(p_months, 12));
  p_simulate_purchase_installments := greatest(1, p_simulate_purchase_installments);

  if v_balance = 0 then
    select coalesce(sum(balance), 0) into v_balance
    from public.user_bank_accounts
    where user_id = p_user_id and account_type not in ('Kredi Kartı', 'Kredi');
  end if;

  select
    coalesce((parameters->>'expense_multiplier')::numeric, 1),
    coalesce((parameters->>'income_multiplier')::numeric, 1)
  into v_expense_multiplier, v_income_multiplier
  from public.scenarios
  where user_id = p_user_id and is_active
  order by updated_at desc
  limit 1;
  v_expense_multiplier := coalesce(v_expense_multiplier, 1);
  v_income_multiplier := coalesce(v_income_multiplier, 1);

  v_day_balance := v_balance;
  v_min_balance := v_balance;

  for i in 0..(p_months * 30) loop
    v_date := current_date + i;

    select
      coalesce(sum(amount) filter (where type = 'income'), 0),
      coalesce(sum(amount) filter (where type = 'expense'), 0)
    into v_income, v_expense
    from public.user_transactions
    where user_id = p_user_id
      and (
        (not is_recurring and date::date = v_date)
        or (
          is_recurring
          and date::date <= v_date
          and (recurrence_end_date is null or recurrence_end_date::date >= v_date)
          and (
            (recurrence_type = 'daily')
            or (recurrence_type = 'weekly' and extract(dow from date) = extract(dow from v_date))
            or (recurrence_type = 'monthly' and extract(day from date) = extract(day from v_date))
            or (recurrence_type = 'yearly' and to_char(date, 'MM-DD') = to_char(v_date, 'MM-DD'))
          )
        )
      );

    v_income := v_income * v_income_multiplier;
    v_expense := v_expense * v_expense_multiplier;

    if p_simulate_purchase_amount > 0 and (
      i = 0 or (
        p_simulate_purchase_installments > 1
        and i > 0 and i % 30 = 0
        and i / 30 < p_simulate_purchase_installments
      )
    ) then
      v_expense := v_expense + p_simulate_purchase_amount / p_simulate_purchase_installments;
    end if;

    v_day_balance := v_day_balance + v_income - v_expense;
    v_min_balance := least(v_min_balance, v_day_balance);
    if v_day_balance < 0 and v_first_negative is null then
      v_first_negative := v_date;
    end if;

    v_chart := v_chart || jsonb_build_object(
      'date', v_date, 'balance', round(v_day_balance, 2),
      'income', round(v_income, 2), 'expense', round(v_expense, 2)
    );
  end loop;

  if v_first_negative is not null then
    v_insights := v_insights || jsonb_build_object(
      'type', 'CRITICAL', 'title', 'Nakit Eksikliği Riski',
      'message', v_first_negative || ' tarihinde bakiyeniz eksiye düşebilir.',
      'date', v_first_negative
    );
  else
    v_insights := v_insights || jsonb_build_object(
      'type', 'INFO', 'title', 'Nakit Akışı Dengeli',
      'message', 'Seçilen dönem için negatif bakiye öngörülmüyor.'
    );
  end if;

  return jsonb_build_object(
    'chart_data', v_chart,
    'insights', v_insights,
    'current_balance', round(v_balance, 2),
    'min_projected_balance', round(v_min_balance, 2),
    'safety_status', case when v_first_negative is null then 'SAFE' else 'CRITICAL' end,
    'scenario_applied', v_expense_multiplier <> 1 or v_income_multiplier <> 1
  );
end;
$$;

create or replace function public.calculate_spending_trend(p_user_id uuid, p_category text, p_months integer default 3)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_current numeric;
  v_average numeric;
  v_trend numeric;
begin
  if auth.uid() is null or (auth.uid() <> p_user_id and not public.is_admin()) then
    raise exception 'Not authorized' using errcode = '42501';
  end if;
  select coalesce(sum(amount), 0) into v_current
  from public.user_transactions
  where user_id = p_user_id and category_id = p_category and type = 'expense'
    and date >= date_trunc('month', current_date);
  select coalesce(avg(monthly_total), 0) into v_average
  from (
    select sum(amount) monthly_total
    from public.user_transactions
    where user_id = p_user_id and category_id = p_category and type = 'expense'
      and date >= date_trunc('month', current_date) - make_interval(months => p_months)
      and date < date_trunc('month', current_date)
    group by date_trunc('month', date)
  ) history;
  if v_average = 0 then
    return jsonb_build_object('current', v_current, 'average', 0, 'trend_pct', 0, 'status', 'new');
  end if;
  v_trend := round((v_current - v_average) / v_average * 100, 1);
  return jsonb_build_object(
    'current', v_current, 'average', v_average, 'trend_pct', v_trend,
    'status', case when v_trend > 15 then 'warning' when v_trend < -15 then 'good' else 'neutral' end
  );
end;
$$;

create or replace function public.analyze_user_financial_health(p_user_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_insights jsonb := '[]'::jsonb;
  v_balance numeric;
  v_expense numeric;
  v_income numeric;
  v_months integer;
begin
  if auth.uid() is null or (auth.uid() <> p_user_id and not public.is_admin()) then
    raise exception 'Not authorized' using errcode = '42501';
  end if;
  select coalesce(sum(balance), 0) into v_balance from public.user_bank_accounts where user_id = p_user_id;
  select
    coalesce(sum(amount) filter (where type = 'expense'), 0),
    coalesce(sum(amount) filter (where type = 'income'), 0)
  into v_expense, v_income
  from public.user_transactions
  where user_id = p_user_id and date >= date_trunc('month', current_date);
  if v_expense > v_income then
    v_insights := v_insights || jsonb_build_object(
      'type', 'budget_deficit', 'icon', '⚠️', 'title', 'Bütçe Açığı Uyarısı',
      'message', 'Bu ay giderler gelirlerden yüksek.', 'priority', 'high'
    );
  end if;
  if v_expense > 0 then
    v_months := floor(v_balance / v_expense);
    if v_months < 2 then
      v_insights := v_insights || jsonb_build_object(
        'type', 'cashflow_risk', 'icon', '💸', 'title', 'Nakit Akışı Riski',
        'message', 'Mevcut bakiye iki aylık harcamadan daha düşük.', 'priority', 'critical'
      );
    end if;
  end if;
  if jsonb_array_length(v_insights) = 0 then
    v_insights := v_insights || jsonb_build_object(
      'type', 'info', 'icon', '✅', 'title', 'Finansal Durum Stabil',
      'message', 'Mevcut verilere göre gelir/gider dengesi sağlıklı.', 'priority', 'low'
    );
  end if;
  return v_insights;
end;
$$;

create or replace function public.request_account_deletion(p_reason text)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if auth.uid() is null then
    raise exception 'Not authorized' using errcode = '42501';
  end if;
  if exists (
    select 1 from public.account_deletion_requests
    where user_id = auth.uid() and status = 'pending'
  ) then
    return jsonb_build_object('success', false, 'error', 'Active request already exists');
  end if;
  insert into public.account_deletion_requests(user_id, reason) values (auth.uid(), p_reason);
  return jsonb_build_object('success', true);
end;
$$;

create or replace function public.approve_deletion_request(p_request_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid;
begin
  perform public.assert_admin();
  select user_id into v_user_id
  from public.account_deletion_requests
  where id = p_request_id and status = 'pending'
  for update;
  if v_user_id is null then
    return jsonb_build_object('success', false, 'error', 'Request not found or already processed');
  end if;
  update public.users set deleted_at = now(), is_active = false where id = v_user_id;
  update public.account_deletion_requests
  set status = 'approved', processed_at = now(), processed_by = auth.uid()
  where id = p_request_id;
  return jsonb_build_object('success', true);
end;
$$;

create or replace function public.process_audit_log()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_old jsonb;
  v_new jsonb;
  v_user_id uuid;
  v_record_id text;
begin
  if tg_op <> 'INSERT' then v_old := to_jsonb(old); end if;
  if tg_op <> 'DELETE' then v_new := to_jsonb(new); end if;
  v_user_id := coalesce(
    nullif(coalesce(v_new->>'user_id', v_old->>'user_id'), '')::uuid,
    auth.uid()
  );
  v_record_id := coalesce(v_new->>'id', v_old->>'id');
  insert into public.audit_logs(user_id, action, table_name, record_id, old_data, new_data)
  values (v_user_id, tg_op, tg_table_name, v_record_id, v_old, v_new);
  return case when tg_op = 'DELETE' then old else new end;
end;
$$;

create trigger audit_user_transactions after insert or update or delete on public.user_transactions
for each row execute function public.process_audit_log();
create trigger audit_user_portfolio_assets after insert or update or delete on public.user_portfolio_assets
for each row execute function public.process_audit_log();
create trigger audit_user_watchlists after insert or update or delete on public.user_watchlists
for each row execute function public.process_audit_log();
create trigger audit_users after update on public.users
for each row execute function public.process_audit_log();

grant execute on function public.search_assets(text, integer) to anon, authenticated;
grant execute on function public.check_and_increment_ai_usage(uuid, text) to authenticated;
grant execute on function public.analyze_purchase_decision(numeric, integer, numeric, numeric) to authenticated;
grant execute on function public.calculate_financial_pilot(uuid, integer, numeric, integer, numeric) to authenticated;
grant execute on function public.calculate_spending_trend(uuid, text, integer) to authenticated;
grant execute on function public.analyze_user_financial_health(uuid) to authenticated;
grant execute on function public.request_account_deletion(text) to authenticated;
grant execute on function public.approve_deletion_request(uuid) to authenticated;
