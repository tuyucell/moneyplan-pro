-- Prevent authenticated users from escalating their own privileges through
-- direct updates to public.users while preserving normal profile edits.

create or replace function public.protect_user_privileges()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_actor_is_super_admin boolean := false;
begin
  -- Database maintenance and trusted server-side service-role requests are
  -- allowed to bootstrap and manage the first administrator.
  if auth.uid() is null or auth.role() = 'service_role' then
    return new;
  end if;

  if public.is_admin() then
    select exists (
      select 1
      from public.users
      where id = auth.uid()
        and role = 'super_admin'
        and is_active
        and not is_banned
        and deleted_at is null
    ) into v_actor_is_super_admin;

    -- A regular admin may manage users, but only another super admin may
    -- grant, alter, or revoke the super-admin role.
    if (old.role = 'super_admin' or new.role = 'super_admin')
       and not v_actor_is_super_admin then
      raise exception 'Only a super admin can modify the super-admin role';
    end if;

    return new;
  end if;

  if auth.uid() = old.id and (
    new.role is distinct from old.role
    or new.is_premium is distinct from old.is_premium
    or new.premium_started_at is distinct from old.premium_started_at
    or new.premium_expires_at is distinct from old.premium_expires_at
    or new.is_email_verified is distinct from old.is_email_verified
    or new.auth_provider is distinct from old.auth_provider
    or new.account_type is distinct from old.account_type
    or new.is_active is distinct from old.is_active
    or new.is_banned is distinct from old.is_banned
    or new.ban_reason is distinct from old.ban_reason
    or new.banned_at is distinct from old.banned_at
    or new.banned_by is distinct from old.banned_by
    or new.deleted_at is distinct from old.deleted_at
  ) then
    raise exception 'Users cannot modify protected account fields';
  end if;

  return new;
end;
$$;

drop trigger if exists users_protect_privileges on public.users;
create trigger users_protect_privileges
before update on public.users
for each row execute function public.protect_user_privileges();
