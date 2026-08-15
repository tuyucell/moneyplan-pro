alter table public.user_bank_accounts
  add column if not exists installment_plan jsonb not null default '[]'::jsonb;

alter table public.user_bank_accounts
  drop constraint if exists user_bank_accounts_installment_plan_array_check,
  add constraint user_bank_accounts_installment_plan_array_check
    check (jsonb_typeof(installment_plan) = 'array');

alter table public.user_transactions
  add column if not exists due_date timestamptz,
  add column if not exists is_paid boolean not null default false,
  add column if not exists payment_method text not null default 'cash',
  add column if not exists exclude_from_balance boolean not null default false,
  add column if not exists linked_transaction_id text;

alter table public.user_transactions
  drop constraint if exists user_transactions_payment_method_check,
  add constraint user_transactions_payment_method_check
    check (payment_method in (
      'cash',
      'creditCard',
      'debitCard',
      'bankTransfer',
      'autoPayment'
    ));
