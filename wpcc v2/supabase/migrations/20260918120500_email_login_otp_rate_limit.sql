create table if not exists public.email_login_otp_requests (
  id bigint generated always as identity primary key,
  email_hash text not null,
  requested_at timestamptz not null default now()
);

alter table public.email_login_otp_requests enable row level security;

create index if not exists email_login_otp_requests_lookup_idx
  on public.email_login_otp_requests (email_hash, requested_at desc);

create or replace function public.request_email_login_otp(p_email text)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_hash text := encode(extensions.digest(lower(btrim(p_email)), 'sha256'), 'hex');
begin
  if p_email is null or btrim(p_email) = '' then return false; end if;
  if exists (
    select 1 from public.email_login_otp_requests
    where email_hash = v_hash and requested_at > now() - interval '60 seconds'
  ) then return false; end if;
  if 5 <= (
    select count(*) from public.email_login_otp_requests
    where email_hash = v_hash and requested_at > now() - interval '1 hour'
  ) then return false; end if;
  insert into public.email_login_otp_requests(email_hash) values (v_hash);
  delete from public.email_login_otp_requests
    where requested_at < now() - interval '1 day';
  return true;
end;
$$;

revoke all on function public.request_email_login_otp(text) from public, anon, authenticated;
grant execute on function public.request_email_login_otp(text) to service_role;
