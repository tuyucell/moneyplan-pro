alter table public.user_bank_accounts
  add column if not exists due_days_after_statement integer not null default 10,
  add column if not exists balance_effective_date timestamptz;

update public.user_bank_accounts
set balance_effective_date = coalesce(balance_effective_date, created_at)
where balance_effective_date is null;

alter table public.user_bank_accounts
  drop constraint if exists user_bank_accounts_due_days_after_statement_check,
  add constraint user_bank_accounts_due_days_after_statement_check
    check (due_days_after_statement between 1 and 45);

comment on column public.user_bank_accounts.due_days_after_statement is
  'Number of calendar days from credit-card statement date to due date.';

comment on column public.user_bank_accounts.balance_effective_date is
  'Snapshot date from which initial balance and subsequent ledger rows apply.';
