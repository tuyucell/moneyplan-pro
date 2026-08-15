-- Preserve the reference rate used when a foreign-currency transaction is
-- created or marked paid. Historical reports must not be revalued using
-- today's rate.
alter table public.user_transactions
  add column if not exists exchange_rate_to_try numeric,
  add column if not exists exchange_rate_date timestamptz,
  add column if not exists exchange_rate_source text;

alter table public.user_transactions
  drop constraint if exists user_transactions_exchange_rate_positive;

alter table public.user_transactions
  add constraint user_transactions_exchange_rate_positive
  check (exchange_rate_to_try is null or exchange_rate_to_try > 0);
