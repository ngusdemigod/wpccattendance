create or replace function public.sync_profiles_from_priv_info()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.profiles
  set
    full_name = coalesce(new.full_name, profiles.full_name),
    firstname = coalesce(new.firstname, profiles.firstname),
    lastname = coalesce(new.lastname, profiles.lastname),
    prefix = coalesce(new.prefix, profiles.prefix),
    bio = coalesce(new.bio, profiles.bio),
    phone = coalesce(new.phone_number, new.phone, profiles.phone),
    date_joined = coalesce(new.date_joined_wpcc, new.date_joined, profiles.date_joined),
    updated_at = now()
  where id = new.id;

  return new;
end;
$$;

revoke all on function public.sync_profiles_from_priv_info() from public, anon, authenticated;
grant execute on function public.sync_profiles_from_priv_info() to service_role;

drop trigger if exists trg_sync_profiles_from_priv_info on public.profiles_priv_info;
create trigger trg_sync_profiles_from_priv_info
after insert or update of
  full_name,
  firstname,
  lastname,
  prefix,
  bio,
  phone,
  phone_number,
  date_joined,
  date_joined_wpcc
on public.profiles_priv_info
for each row
execute function public.sync_profiles_from_priv_info();

update public.profiles p
set
  full_name = coalesce(ppi.full_name, p.full_name),
  firstname = coalesce(ppi.firstname, p.firstname),
  lastname = coalesce(ppi.lastname, p.lastname),
  prefix = coalesce(ppi.prefix, p.prefix),
  bio = coalesce(ppi.bio, p.bio),
  phone = coalesce(ppi.phone_number, ppi.phone, p.phone),
  date_joined = coalesce(ppi.date_joined_wpcc, ppi.date_joined, p.date_joined),
  updated_at = now()
from public.profiles_priv_info ppi
where p.id = ppi.id;

do $$
declare
  table_record record;
begin
  for table_record in
    select tablename
    from pg_tables
    where schemaname = 'public'
  loop
    execute format(
      'alter table public.%I enable row level security',
      table_record.tablename
    );
  end loop;
end;
$$;

grant usage on schema public to authenticated, service_role;
grant select, insert, update, delete on all tables in schema public to authenticated, service_role;
grant usage, select on all sequences in schema public to authenticated, service_role;

alter default privileges in schema public
grant select, insert, update, delete on tables to authenticated, service_role;

alter default privileges in schema public
grant usage, select on sequences to authenticated, service_role;
