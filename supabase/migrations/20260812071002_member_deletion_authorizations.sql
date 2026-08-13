create table if not exists public.member_deletion_authorizations (
  id uuid primary key default gen_random_uuid(),
  member_id uuid not null references public.profiles(id) on delete cascade,
  actor_id uuid not null references auth.users(id) on delete cascade,
  token_hash text not null unique,
  expires_at timestamptz not null,
  consumed_at timestamptz,
  created_at timestamptz not null default now()
);

alter table public.member_deletion_authorizations enable row level security;
revoke all on public.member_deletion_authorizations from public, anon, authenticated;
create index if not exists member_deletion_authorizations_lookup_idx
  on public.member_deletion_authorizations (member_id, actor_id, created_at desc);
