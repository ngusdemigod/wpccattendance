-- Keep the branch prefix in `prefix`; it is not part of a person's name.
create or replace function public.normalize_profile_full_name()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  while new.prefix is not null
    and btrim(new.prefix) <> ''
    and new.full_name is not null
    and left(new.full_name, char_length(new.prefix)) = new.prefix
  loop
    new.full_name := btrim(substring(new.full_name from char_length(new.prefix) + 1));
  end loop;

  return new;
end;
$$;

drop trigger if exists trg_profiles_z_normalize_full_name
  on public.profiles;
create trigger trg_profiles_z_normalize_full_name
before insert or update on public.profiles
for each row execute function public.normalize_profile_full_name();

drop trigger if exists trg_profiles_priv_z_normalize_full_name
  on public.profiles_priv_info;
create trigger trg_profiles_priv_z_normalize_full_name
before insert or update on public.profiles_priv_info
for each row execute function public.normalize_profile_full_name();

update public.profiles
set full_name = btrim(substring(full_name from char_length(prefix) + 1))
where prefix is not null
  and btrim(prefix) <> ''
  and full_name is not null
  and left(full_name, char_length(prefix)) = prefix;

update public.profiles_priv_info
set full_name = btrim(substring(full_name from char_length(prefix) + 1))
where prefix is not null
  and btrim(prefix) <> ''
  and full_name is not null
  and left(full_name, char_length(prefix)) = prefix;
