-- Server-verified Apple auto-renewable subscription entitlements.

create table public.user_subscriptions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  provider text not null default 'apple' check (provider = 'apple'),
  product_id text not null,
  transaction_id text not null,
  original_transaction_id text not null,
  status text not null check (status in ('active', 'expired', 'revoked')),
  environment text not null check (environment in ('Production', 'Sandbox')),
  purchased_at timestamptz,
  expires_at timestamptz not null,
  revoked_at timestamptz,
  raw_transaction jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (provider, transaction_id),
  unique (provider, original_transaction_id)
);

create index user_subscriptions_user_id_idx
on public.user_subscriptions(user_id, expires_at desc);

create trigger user_subscriptions_set_updated_at
before update on public.user_subscriptions
for each row execute function public.set_updated_at();

alter table public.user_subscriptions enable row level security;

create policy "Users can read their own subscriptions"
on public.user_subscriptions
for select
to authenticated
using (auth.uid() = user_id);

grant select on public.user_subscriptions to authenticated;
grant all on public.user_subscriptions to service_role;
