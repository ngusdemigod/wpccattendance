-- Contain the live September 2026 RLS/RPC findings.
-- Cloudflare authenticates to Edge Functions using its existing secret bindings.
-- Edge Functions use service_role for these database calls; clients must not.
begin;
set local lock_timeout = '5s';
set local statement_timeout = '60s';

do $migration$
declare fn record;
begin
  for fn in select p.oid::regprocedure as signature
    from pg_proc p join pg_namespace n on n.oid=p.pronamespace
    where n.nspname='public' and p.prokind='f' and p.prosecdef
      and (p.proname in ('media_spotify_sync_config',
        'relink_profile_identity',
        'backfill_seed_auth_users',
        'churchmetric_claim_email_outbox',
        'claim_due_prayer_alert_occurrences',
        'create_prayer_alert_deliveries',
        'mark_prayer_alert_delivery_result',
        'mark_prayer_alert_occurrence_result',
        'mark_push_subscription_success',
        'materialize_prayer_alert_occurrences',
        'deactivate_push_subscription',
        'wpcc_claim_due_auto_give',
        'wpcc_complete_auto_give_claim',
        'wpcc_due_auto_give',
        'wpcc_advance_auto_give',
        'wpcc_record_paystack_transaction',
        'wpcc_initialize_giving_transaction',
        'sync_global_admin_role_for_user',
        'sync_dept_leader_role_for_user',
        'sync_recurring_events_for_week',
        'request_email_login_otp')
        or (p.prosrc like '%current_user%' and p.prosrc like '%service_role%'))
  loop
    execute format('revoke execute on function %s from public, anon, authenticated',fn.signature);
    execute format('grant execute on function %s to service_role',fn.signature);
  end loop;
end;
$migration$;

-- Never use user-editable metadata to choose another member's identity.
-- Email-based recovery must use an email confirmed by Supabase Auth.
CREATE OR REPLACE FUNCTION public.relink_current_auth_profile()
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'auth'
AS $function$
declare
  current_auth_user_id uuid := auth.uid();
  current_auth_email text;
  current_membership_code text;
begin
  if current_auth_user_id is null then
    raise exception 'No authenticated user.';
  end if;

  select
    case when email_confirmed_at is not null then nullif(btrim(email), '') end,
    nullif(btrim(raw_app_meta_data ->> 'membership_code'), '')
  into current_auth_email, current_membership_code
  from auth.users
  where id = current_auth_user_id;

  return public.relink_profile_identity(
    current_auth_user_id,
    current_auth_email,
    current_membership_code
  );
end;
$function$;

CREATE OR REPLACE FUNCTION public.resolve_current_profile_identity()
 RETURNS TABLE(profile_user_id uuid, membership_code text, email text, is_direct_auth_match boolean)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'auth'
AS $function$
declare
  current_auth_user_id uuid := auth.uid();
  current_auth_email text;
  current_membership_code text;
begin
  if current_auth_user_id is null then
    return;
  end if;

  select
    case when au.email_confirmed_at is not null then lower(nullif(btrim(au.email), '')) end,
    nullif(btrim(au.raw_app_meta_data ->> 'membership_code'), '')
  into current_auth_email, current_membership_code
  from auth.users au
  where au.id = current_auth_user_id;

  if exists (
    select 1
    from public.profiles p
    where p.id = current_auth_user_id
  ) then
    return query
    select
      p.id,
      coalesce(mc.membershipcode, pp.membership_code, p.membership_code),
      coalesce(pp.email, p.email, current_auth_email),
      true
    from public.profiles p
    left join public.membershipcode mc
      on mc.memberid = p.id
    left join public.profiles_priv_info pp
      on pp.id = p.id
    where p.id = current_auth_user_id
    limit 1;
    return;
  end if;

  if current_auth_email is not null then
    return query
    select
      pp.id,
      coalesce(mc.membershipcode, pp.membership_code, p.membership_code),
      pp.email,
      false
    from public.profiles_priv_info pp
    left join public.profiles p
      on p.id = pp.id
    left join public.membershipcode mc
      on mc.memberid = pp.id
    where lower(coalesce(pp.email, '')) = current_auth_email
    order by pp.created_at asc
    limit 1;

    if found then
      return;
    end if;
  end if;

  if current_membership_code is not null then
    return query
    select
      p.id,
      coalesce(mc.membershipcode, pp.membership_code, p.membership_code),
      coalesce(pp.email, p.email, current_auth_email),
      false
    from public.profiles p
    left join public.profiles_priv_info pp
      on pp.id = p.id
    left join public.membershipcode mc
      on mc.memberid = p.id
    where coalesce(mc.membershipcode, pp.membership_code, p.membership_code) =
        current_membership_code
    order by p.created_at asc
    limit 1;
  end if;
end;
$function$;

revoke execute on function public.relink_current_auth_profile() from public, anon;
revoke execute on function public.resolve_current_profile_identity() from public, anon;
grant execute on function public.relink_current_auth_profile() to authenticated, service_role;
grant execute on function public.resolve_current_profile_identity() to authenticated, service_role;

-- Client profile creation and authority changes use trusted backend workflows.
-- Keep ordinary personal-detail edits available under the existing row policies.
revoke insert, update on public.profiles, public.profiles_priv_info from public, anon, authenticated;
do $columns$
declare col record;
begin
  -- Remove any column-level grants as well as the table-level grants above.
  for col in select table_name,column_name from information_schema.columns
    where table_schema='public' and table_name in ('profiles','profiles_priv_info')
  loop
    execute format('revoke insert (%I), update (%I) on public.%I from public, anon, authenticated',
      col.column_name,col.column_name,col.table_name);
  end loop;
end;
$columns$;
grant update (bio,full_name,firstname,lastname,phone,display_name,initials,updated_at)
  on public.profiles to authenticated;
grant update (bio,occupation,residential_address,address,phone,phone_number,gender,
  marital_status,date_of_birth,dob,emergency_contact,full_name,firstname,lastname,
  water_baptism_date)
  on public.profiles_priv_info to authenticated;

create or replace function public.community_guard_profile_authority()
returns trigger language plpgsql security invoker set search_path=''
as $guard$
begin
  -- SECURITY INVOKER is deliberate: this sees the actual database executor.
  -- Vetted backend SECURITY DEFINER functions may still perform trusted syncs.
  if current_user in ('postgres','service_role','supabase_admin','supabase_auth_admin') then
    return new;
  end if;
  if tg_op='INSERT' then
    raise exception 'Profile creation requires the trusted backend' using errcode='42501';
  end if;
  if (to_jsonb(new) - array['bio','occupation','residential_address','address','phone',
      'phone_number','gender','marital_status','date_of_birth','dob','emergency_contact',
      'full_name','firstname','lastname','water_baptism_date','display_name','initials','updated_at'])
    is distinct from
     (to_jsonb(old) - array['bio','occupation','residential_address','address','phone',
      'phone_number','gender','marital_status','date_of_birth','dob','emergency_contact',
      'full_name','firstname','lastname','water_baptism_date','display_name','initials','updated_at']) then
    raise exception 'Restricted profile fields require the trusted backend' using errcode='42501';
  end if;
  return new;
end;
$guard$;
revoke all on function public.community_guard_profile_authority() from public,anon,authenticated;
drop trigger if exists community_guard_private_authority on public.profiles_priv_info;
create trigger community_guard_private_authority before insert or update on public.profiles_priv_info
for each row execute function public.community_guard_profile_authority();
drop trigger if exists community_guard_public_authority on public.profiles;
create trigger community_guard_public_authority before insert or update on public.profiles
for each row execute function public.community_guard_profile_authority();

-- Match old-row access to the existing new-row check, removing USING true.
do $policy$
declare allowed text;
begin
  select with_check into strict allowed from pg_policies
    where schemaname='public' and tablename='profiles' and policyname='profiles_unified_update';
  if allowed is null then raise exception 'Expected profile UPDATE check is missing'; end if;
  execute format('alter policy profiles_unified_update on public.profiles using (%s)',allowed);
end;
$policy$;

alter view public.systemreports set (security_invoker=true);
revoke all on public.systemreports from public, anon;
grant select on public.systemreports to authenticated,service_role;

-- Public image URLs continue to render. Listing/upsert SELECT is owner-only.
drop policy if exists profile_avatars_public_read on storage.objects;
drop policy if exists profile_avatars_select_own on storage.objects;
create policy profile_avatars_select_own on storage.objects for select to authenticated
using (bucket_id='profile-avatars' and (storage.foldername(name))[1]=(select auth.uid())::text);

-- TRUNCATE is not covered by RLS and is never required by mobile/web clients.
do $tables$
declare rel record;
begin
  for rel in select c.oid::regclass as name from pg_class c
    join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='public' and c.relkind in ('r','p')
  loop
    execute format('revoke truncate, references, trigger on table %s from public, anon, authenticated',rel.name);
  end loop;
end;
$tables$;

-- All affected bodies were inspected: unqualified app references use public.
-- pg_temp last prevents temporary objects shadowing those trusted references.
do $paths$
declare fn record;
begin
  for fn in select p.oid::regprocedure as signature
    from pg_proc p join pg_namespace n on n.oid=p.pronamespace
    where n.nspname='public' and p.prokind='f'
      and not exists(select 1 from unnest(coalesce(p.proconfig,array[]::text[])) cfg where cfg like 'search_path=%')
      and not exists(select 1 from pg_depend d where d.classid='pg_proc'::regclass and d.objid=p.oid and d.deptype='e')
  loop
    execute format('alter function %s set search_path = pg_catalog, public, extensions, pg_temp',fn.signature);
  end loop;
end;
$paths$;

-- Fail the entire migration if a sensitive function is still client-callable
-- or backend access was accidentally removed.
do $verify$
declare fn record;
begin
  for fn in select p.oid,p.oid::regprocedure as signature from pg_proc p
    join pg_namespace n on n.oid=p.pronamespace
    where n.nspname='public' and p.proname in ('media_spotify_sync_config','relink_profile_identity','backfill_seed_auth_users','churchmetric_claim_email_outbox','claim_due_prayer_alert_occurrences','create_prayer_alert_deliveries','mark_prayer_alert_delivery_result','mark_prayer_alert_occurrence_result','mark_push_subscription_success','materialize_prayer_alert_occurrences','deactivate_push_subscription','wpcc_claim_due_auto_give','wpcc_complete_auto_give_claim','wpcc_due_auto_give','wpcc_advance_auto_give','wpcc_record_paystack_transaction','wpcc_initialize_giving_transaction','sync_global_admin_role_for_user','sync_dept_leader_role_for_user','sync_recurring_events_for_week','request_email_login_otp')
  loop
    if has_function_privilege('anon',fn.oid,'EXECUTE')
      or has_function_privilege('authenticated',fn.oid,'EXECUTE')
      or not has_function_privilege('service_role',fn.oid,'EXECUTE') then
      raise exception 'Unexpected function grants: %',fn.signature;
    end if;
  end loop;
  if has_column_privilege('authenticated','public.profiles_priv_info','role','UPDATE')
    or has_column_privilege('authenticated','public.profiles','branch_id','UPDATE') then
    raise exception 'Client authority-column grants remain';
  end if;
end;
$verify$;
notify pgrst, 'reload schema';
commit;

