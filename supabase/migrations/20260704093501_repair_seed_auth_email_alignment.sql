create or replace function public.backfill_seed_auth_users()
returns jsonb
language plpgsql
security definer
set search_path = public, auth, extensions
as $$
declare
  inserted_users integer := 0;
  inserted_identities integer := 0;
begin
  with profile_source as (
    select
      p.id as user_id,
      lower(
        coalesce(
          nullif(btrim(ppi.email), ''),
          nullif(btrim(p.email), ''),
          format(
            'seed+%s@wpcc.local.invalid',
            coalesce(
              nullif(
                regexp_replace(lower(btrim(p.membership_code)), '[^a-z0-9]+', '-', 'g'),
                ''
              ),
              replace(p.id::text, '-', '')
            )
          )
        )
      ) as auth_email,
      coalesce(
        nullif(btrim(ppi.email), ''),
        nullif(btrim(p.email), '')
      ) as real_email,
      nullif(btrim(p.membership_code), '') as membership_code,
      nullif(btrim(p.full_name), '') as full_name,
      p.branch_id,
      p.created_at
    from public.profiles p
    left join public.profiles_priv_info ppi on ppi.id = p.id
  )
  insert into auth.users (
    instance_id,
    id,
    aud,
    role,
    email,
    encrypted_password,
    confirmation_token,
    recovery_token,
    email_change_token_new,
    email_change,
    phone_change,
    phone_change_token,
    raw_app_meta_data,
    raw_user_meta_data,
    is_super_admin,
    created_at,
    updated_at,
    is_sso_user,
    is_anonymous
  )
  select
    '00000000-0000-0000-0000-000000000000'::uuid,
    src.user_id,
    'authenticated',
    'authenticated',
    src.auth_email,
    crypt(encode(gen_random_bytes(32), 'hex'), gen_salt('bf')),
    '',
    '',
    '',
    '',
    '',
    '',
    jsonb_strip_nulls(
      jsonb_build_object(
        'provider', 'email',
        'providers', jsonb_build_array('email'),
        'membership_code', src.membership_code,
        'wpbranch_id', src.branch_id,
        'seeded_profile', true,
        'placeholder_email', src.real_email is null
      )
    ),
    jsonb_strip_nulls(
      jsonb_build_object(
        'full_name', src.full_name,
        'membership_code', src.membership_code,
        'seeded_profile', true,
        'email_verified', false
      )
    ),
    false,
    coalesce(src.created_at::timestamptz, now()),
    now(),
    false,
    false
  from profile_source src
  where not exists (
    select 1
    from auth.users au
    where au.id = src.user_id
  );

  get diagnostics inserted_users = row_count;

  with profile_source as (
    select
      p.id as user_id,
      lower(
        coalesce(
          nullif(btrim(ppi.email), ''),
          nullif(btrim(p.email), ''),
          format(
            'seed+%s@wpcc.local.invalid',
            coalesce(
              nullif(
                regexp_replace(lower(btrim(p.membership_code)), '[^a-z0-9]+', '-', 'g'),
                ''
              ),
              replace(p.id::text, '-', '')
            )
          )
        )
      ) as auth_email
    from public.profiles p
    left join public.profiles_priv_info ppi on ppi.id = p.id
  )
  insert into auth.identities (
    id,
    provider_id,
    user_id,
    identity_data,
    provider,
    last_sign_in_at,
    created_at,
    updated_at
  )
  select
    gen_random_uuid(),
    src.user_id::text,
    src.user_id,
    jsonb_build_object(
      'sub', src.user_id::text,
      'email', src.auth_email,
      'email_verified', false,
      'phone_verified', false
    ),
    'email',
    null,
    now(),
    now()
  from profile_source src
  where not exists (
    select 1
    from auth.identities ai
    where ai.user_id = src.user_id
      and ai.provider = 'email'
  );

  get diagnostics inserted_identities = row_count;

  update auth.users au
  set
    email = src.auth_email,
    raw_app_meta_data = coalesce(au.raw_app_meta_data, '{}'::jsonb) ||
      jsonb_strip_nulls(
        jsonb_build_object(
          'provider', 'email',
          'providers', jsonb_build_array('email'),
          'membership_code', src.membership_code,
          'wpbranch_id', src.branch_id,
          'seeded_profile', true,
          'placeholder_email', src.real_email is null
        )
      ),
    raw_user_meta_data = coalesce(au.raw_user_meta_data, '{}'::jsonb) ||
      jsonb_strip_nulls(
        jsonb_build_object(
          'full_name', src.full_name,
          'membership_code', src.membership_code,
          'seeded_profile', true
        )
      ),
    updated_at = now()
  from (
    select
      p.id as user_id,
      lower(
        coalesce(
          nullif(btrim(ppi.email), ''),
          nullif(btrim(p.email), ''),
          format(
            'seed+%s@wpcc.local.invalid',
            coalesce(
              nullif(
                regexp_replace(lower(btrim(p.membership_code)), '[^a-z0-9]+', '-', 'g'),
                ''
              ),
              replace(p.id::text, '-', '')
            )
          )
        )
      ) as auth_email,
      coalesce(
        nullif(btrim(ppi.email), ''),
        nullif(btrim(p.email), '')
      ) as real_email,
      nullif(btrim(p.membership_code), '') as membership_code,
      nullif(btrim(p.full_name), '') as full_name,
      p.branch_id
    from public.profiles p
    left join public.profiles_priv_info ppi on ppi.id = p.id
  ) src
  where au.id = src.user_id
    and (
      au.email is distinct from src.auth_email
      or coalesce(au.raw_app_meta_data, '{}'::jsonb) ->> 'membership_code'
          is distinct from src.membership_code
      or coalesce(au.raw_app_meta_data, '{}'::jsonb) ->> 'placeholder_email'
          is distinct from case when src.real_email is null then 'true' else 'false' end
    );

  update auth.identities ai
  set
    identity_data = jsonb_build_object(
      'sub', src.user_id::text,
      'email', src.auth_email,
      'email_verified', false,
      'phone_verified', false
    ),
    updated_at = now()
  from (
    select
      p.id as user_id,
      lower(
        coalesce(
          nullif(btrim(ppi.email), ''),
          nullif(btrim(p.email), ''),
          format(
            'seed+%s@wpcc.local.invalid',
            coalesce(
              nullif(
                regexp_replace(lower(btrim(p.membership_code)), '[^a-z0-9]+', '-', 'g'),
                ''
              ),
              replace(p.id::text, '-', '')
            )
          )
        )
      ) as auth_email
    from public.profiles p
    left join public.profiles_priv_info ppi on ppi.id = p.id
  ) src
  where ai.user_id = src.user_id
    and ai.provider = 'email'
    and ai.identity_data ->> 'email' is distinct from src.auth_email;

  return jsonb_build_object(
    'inserted_users', inserted_users,
    'inserted_identities', inserted_identities
  );
end;
$$;

select public.backfill_seed_auth_users();
