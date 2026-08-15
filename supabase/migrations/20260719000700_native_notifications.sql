-- First-party notification inbox and native push device registry.

create table public.push_devices (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  platform text not null check (platform in ('ios', 'android')),
  token text not null,
  environment text not null default 'production'
    check (environment in ('sandbox', 'production')),
  app_version text,
  device_name text,
  is_active boolean not null default true,
  last_seen_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (platform, token)
);

create index push_devices_user_active_idx
  on public.push_devices(user_id, is_active);

create trigger push_devices_set_updated_at
before update on public.push_devices
for each row execute function public.set_updated_at();

create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  title text not null check (char_length(title) between 1 and 120),
  message text not null check (char_length(message) between 1 and 500),
  image_url text,
  action_url text,
  target_segment text not null default 'all'
    check (target_segment in ('all', 'premium', 'free', 'user')),
  target_user_id uuid references public.users(id) on delete set null,
  provider text not null default 'native' check (provider = 'native'),
  status text not null default 'queued'
    check (status in ('queued', 'sending', 'sent', 'partial', 'failed')),
  recipient_count integer not null default 0,
  delivered_count integer not null default 0,
  failed_count integer not null default 0,
  error_message text,
  created_by uuid references public.users(id) on delete set null,
  created_at timestamptz not null default now(),
  sent_at timestamptz
);

create index notifications_created_at_idx
  on public.notifications(created_at desc);

create table public.user_notifications (
  id uuid primary key default gen_random_uuid(),
  notification_id uuid not null references public.notifications(id) on delete cascade,
  user_id uuid not null references public.users(id) on delete cascade,
  delivery_status text not null default 'queued'
    check (delivery_status in ('queued', 'sent', 'failed')),
  delivered_at timestamptz,
  read_at timestamptz,
  created_at timestamptz not null default now(),
  unique (notification_id, user_id)
);

create index user_notifications_inbox_idx
  on public.user_notifications(user_id, created_at desc);
create index user_notifications_unread_idx
  on public.user_notifications(user_id, read_at) where read_at is null;

alter table public.push_devices enable row level security;
alter table public.notifications enable row level security;
alter table public.user_notifications enable row level security;

create policy push_devices_owner_read on public.push_devices
for select to authenticated
using (user_id = auth.uid() or public.is_admin());

create policy push_devices_owner_insert on public.push_devices
for insert to authenticated
with check (user_id = auth.uid());

create policy push_devices_owner_update on public.push_devices
for update to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

create policy push_devices_owner_delete on public.push_devices
for delete to authenticated
using (user_id = auth.uid());

create policy notifications_inbox_read on public.notifications
for select to authenticated
using (
  public.is_admin()
  or exists (
    select 1 from public.user_notifications un
    where un.notification_id = notifications.id
      and un.user_id = auth.uid()
  )
);

create policy notifications_admin_write on public.notifications
for all to authenticated
using (public.is_admin())
with check (public.is_admin());

create policy user_notifications_owner_read on public.user_notifications
for select to authenticated
using (user_id = auth.uid() or public.is_admin());

create policy user_notifications_owner_update on public.user_notifications
for update to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

create policy user_notifications_admin_write on public.user_notifications
for all to authenticated
using (public.is_admin())
with check (public.is_admin());

create policy account_active_guard on public.push_devices
as restrictive for all to authenticated
using (public.is_current_user_active())
with check (public.is_current_user_active());

create policy account_active_guard on public.notifications
as restrictive for all to authenticated
using (public.is_current_user_active())
with check (public.is_current_user_active());

create policy account_active_guard on public.user_notifications
as restrictive for all to authenticated
using (public.is_current_user_active())
with check (public.is_current_user_active());

do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'user_notifications'
  ) then
    alter publication supabase_realtime add table public.user_notifications;
  end if;
end;
$$;

grant select, insert, update, delete on public.push_devices to authenticated;
grant select on public.notifications to authenticated;
grant select, update on public.user_notifications to authenticated;
grant all on public.push_devices, public.notifications, public.user_notifications to service_role;
