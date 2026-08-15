alter table public.user_bank_accounts
  add column if not exists monthly_interest_rate numeric not null default 4.5,
  add column if not exists bsmv_rate numeric not null default 15,
  add column if not exists kkdf_rate numeric not null default 15,
  add column if not exists overdraft_limit numeric not null default 0,
  add column if not exists payment_day integer not null default 1,
  add column if not exists due_day integer not null default 10,
  add column if not exists is_active boolean not null default true;

alter table public.user_bank_accounts
  drop constraint if exists user_bank_accounts_monthly_interest_rate_check,
  add constraint user_bank_accounts_monthly_interest_rate_check
    check (monthly_interest_rate between 0 and 100),
  drop constraint if exists user_bank_accounts_bsmv_rate_check,
  add constraint user_bank_accounts_bsmv_rate_check
    check (bsmv_rate between 0 and 100),
  drop constraint if exists user_bank_accounts_kkdf_rate_check,
  add constraint user_bank_accounts_kkdf_rate_check
    check (kkdf_rate between 0 and 100),
  drop constraint if exists user_bank_accounts_payment_day_check,
  add constraint user_bank_accounts_payment_day_check
    check (payment_day between 1 and 31),
  drop constraint if exists user_bank_accounts_due_day_check,
  add constraint user_bank_accounts_due_day_check
    check (due_day between 1 and 31);
