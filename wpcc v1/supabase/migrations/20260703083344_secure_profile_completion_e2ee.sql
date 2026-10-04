create extension if not exists pgcrypto;

alter table public.profiles
  add column if not exists display_name text,
  add column if not exists initials text,
  add column if not exists avatar_is_encrypted boolean not null default true,
  add column if not exists avatar_storage_path text,
  add column if not exists avatar_nonce text,
  add column if not exists avatar_encryption_algorithm text not null default 'AES-256-GCM',
  add column if not exists avatar_encryption_version integer not null default 1,
  add column if not exists setup_completed boolean not null default false,
  add column if not exists setup_completed_at timestamptz,
  add column if not exists updated_at timestamptz not null default now();

update public.profiles
set
  display_name = coalesce(display_name, full_name),
  initials = coalesce(
    initials,
    upper(
      left(coalesce(firstname, split_part(full_name, ' ', 1), 'A'), 1) ||
      left(coalesce(lastname, nullif(split_part(full_name, ' ', 2), ''), 'G'), 1)
    )
  ),
  setup_completed = coalesce(setup_completed, false) or coalesce((
    select ppi.profilecomplete
    from public.profiles_priv_info ppi
    where ppi.id = profiles.id
  ), false),
  setup_completed_at = case
    when setup_completed_at is not null then setup_completed_at
    when coalesce((
      select ppi.profilecomplete
      from public.profiles_priv_info ppi
      where ppi.id = profiles.id
    ), false) then now()
    else setup_completed_at
  end,
  updated_at = now();

create table if not exists public.worker_private_profiles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  phone_ciphertext text,
  phone_nonce text,
  address_ciphertext text,
  address_nonce text,
  encryption_algorithm text not null default 'AES-256-GCM',
  encryption_version integer not null default 1,
  aad_context jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint worker_private_profiles_user_id_key unique (user_id)
);

create table if not exists public.profile_key_recipients (
  id uuid primary key default gen_random_uuid(),
  profile_user_id uuid not null references auth.users(id) on delete cascade,
  recipient_user_id uuid not null references auth.users(id) on delete cascade,
  wrapped_dek text not null,
  wrap_nonce text,
  wrap_algorithm text not null,
  key_version integer not null default 1,
  created_at timestamptz not null default now(),
  constraint profile_key_recipients_profile_recipient_version_key
    unique (profile_user_id, recipient_user_id, key_version)
);

comment on table public.worker_private_profiles is
  'Client encrypted worker profile fields. Supabase stores ciphertext and metadata only.';

comment on table public.profile_key_recipients is
  'Wrapped user DEKs for explicitly authorized recipients. TODO: wire admin public key provisioning before use.';

grant select, insert, update, delete on public.worker_private_profiles to authenticated;
grant select, insert, update, delete on public.profile_key_recipients to authenticated;

alter table public.worker_private_profiles enable row level security;
alter table public.profile_key_recipients enable row level security;

drop policy if exists worker_private_profiles_select_own on public.worker_private_profiles;
create policy worker_private_profiles_select_own
on public.worker_private_profiles
for select
to authenticated
using ((select auth.uid()) = user_id);

drop policy if exists worker_private_profiles_insert_own on public.worker_private_profiles;
create policy worker_private_profiles_insert_own
on public.worker_private_profiles
for insert
to authenticated
with check ((select auth.uid()) = user_id);

drop policy if exists worker_private_profiles_update_own on public.worker_private_profiles;
create policy worker_private_profiles_update_own
on public.worker_private_profiles
for update
to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

drop policy if exists worker_private_profiles_delete_own on public.worker_private_profiles;
create policy worker_private_profiles_delete_own
on public.worker_private_profiles
for delete
to authenticated
using ((select auth.uid()) = user_id);

drop policy if exists profile_key_recipients_select_owner_or_recipient on public.profile_key_recipients;
create policy profile_key_recipients_select_owner_or_recipient
on public.profile_key_recipients
for select
to authenticated
using (
  (select auth.uid()) = profile_user_id
  or (select auth.uid()) = recipient_user_id
);

drop policy if exists profile_key_recipients_insert_owner on public.profile_key_recipients;
create policy profile_key_recipients_insert_owner
on public.profile_key_recipients
for insert
to authenticated
with check ((select auth.uid()) = profile_user_id);

drop policy if exists profile_key_recipients_update_owner on public.profile_key_recipients;
create policy profile_key_recipients_update_owner
on public.profile_key_recipients
for update
to authenticated
using ((select auth.uid()) = profile_user_id)
with check ((select auth.uid()) = profile_user_id);

drop policy if exists profile_key_recipients_delete_owner on public.profile_key_recipients;
create policy profile_key_recipients_delete_owner
on public.profile_key_recipients
for delete
to authenticated
using ((select auth.uid()) = profile_user_id);

-- Profile avatar objects are stored in Cloudflare R2. Supabase Storage
-- buckets and storage.objects policies are intentionally not created here.
