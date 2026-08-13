create table if not exists public.member_update_verifications (
  id uuid primary key default gen_random_uuid(),
  member_id uuid not null references public.profiles(id) on delete cascade,
  actor_id uuid not null references auth.users(id) on delete cascade,
  otp_hash text not null,
  expires_at timestamptz not null,
  attempts smallint not null default 0,
  consumed_at timestamptz,
  created_at timestamptz not null default now()
);

alter table public.member_update_verifications enable row level security;
revoke all on public.member_update_verifications from anon, authenticated;
create index if not exists member_update_verifications_lookup_idx
  on public.member_update_verifications (member_id, actor_id, created_at desc);
