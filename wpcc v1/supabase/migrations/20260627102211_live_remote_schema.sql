


SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;


CREATE EXTENSION IF NOT EXISTS "pg_cron" WITH SCHEMA "pg_catalog";






COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE EXTENSION IF NOT EXISTS "hypopg" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "index_advisor" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "insert_username" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";






CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";






CREATE OR REPLACE FUNCTION "public"."add_fullname_top_level_claim"("event" "jsonb") RETURNS "jsonb"
    LANGUAGE "plpgsql" STABLE
    AS $$
declare
  user_fullname text;
  claims jsonb;
begin
  -- user_id is the Auth user id for the token being issued
  select p.full_name
    into user_fullname
  from public.profiles p
  where p.id = (event->>'user_id')::uuid;

  claims := event->'claims';

  -- Add/overwrite a TOP-LEVEL claim named "fullname"
  claims := jsonb_set(claims, '{fullname}', to_jsonb(user_fullname));

  event := jsonb_set(event, '{claims}', claims);
  return event;
end;
$$;


ALTER FUNCTION "public"."add_fullname_top_level_claim"("event" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."add_wp_info_to_jwt"("event" "jsonb") RETURNS "jsonb"
    LANGUAGE "plpgsql" STABLE SECURITY DEFINER
    AS $$declare
  uid uuid;
  claims jsonb := '{}'::jsonb;
  role_name text;
  dept_name text;
  branch_name text;
  dept_id uuid;
  branch_id uuid;
  user_full_name text;
begin
  -- Start with existing claims or initialize with an empty JSONB object
  claims := coalesce(event -> 'claims', '{}'::jsonb);

  -- Extract user ID from event (check both direct and nested user_id)
  uid := null;
  if event ? 'user_id' then
    uid := (event ->> 'user_id')::uuid;
  elsif event ? 'user' and (event -> 'user') ? 'id' then
    uid := (event -> 'user' ->> 'id')::uuid;
  end if;

  -- If UID is found, fetch the user role, department, and branch
  if uid is not null then
    -- Fetch role name from the roles table
    select r.rolename into role_name
    from public.roles r
    where r.memberid = uid
    limit 1;

    -- Fetch department and branch names using their respective IDs from the workers table
    select w.department_id, w.branch_id, d.name as dept_name, b.name as branch_name
    into dept_id, branch_id, dept_name, branch_name
    from public.workers w
    left join public.departments d on d.id = w.department_id
    left join public.branches b on b.id = w.branch_id
    where w.user_id = uid
    limit 1;

    -- Fetch full name from the profiles table
    select p.full_name into user_full_name
    from public.profiles p
    where p.id = uid
    limit 1;
  end if;

  -- Always set the claims fields (even if null)

  -- Set full name claim (full_name) as raw text
  if user_full_name is not null then
    claims := jsonb_set(claims, '{full_name}', to_jsonb(user_full_name), true);
  else
    claims := jsonb_set(claims, '{full_name}', 'null'::jsonb, true);
  end if;

  -- Set role claim (wprole) as raw text (role name)
  if role_name is not null then
    claims := jsonb_set(claims, '{wprole}', to_jsonb(role_name), true);
  else
    claims := jsonb_set(claims, '{wprole}', 'null'::jsonb, true);  -- Set null if role_name is missing
  end if;

  -- Set branch claim (wpbranch) as name (branch name)
  if branch_name is not null then
    claims := jsonb_set(claims, '{wpbranch}', to_jsonb(branch_name), true);  -- Branch name (text)
  else
    claims := jsonb_set(claims, '{wpbranch}', 'null'::jsonb, true);  -- Set null if branch_name is missing
  end if;

  -- Set department claim (wpdept) as name (department name)
  if dept_name is not null then
    claims := jsonb_set(claims, '{wpdept}', to_jsonb(dept_name), true);  -- Department name (text)
  else
    claims := jsonb_set(claims, '{wpdept}', 'null'::jsonb, true);  -- Set null if dept_name is missing
  end if;

  -- Set branch ID claim (wpbranch_id) as UUID (branch ID)
  if branch_id is not null then
    claims := jsonb_set(claims, '{wpbranch_id}', to_jsonb(branch_id), true);  -- Branch ID (UUID)
  else
    claims := jsonb_set(claims, '{wpbranch_id}', 'null'::jsonb, true);  -- Set null if branch_id is missing
  end if;

  -- Set department ID claim (wpdept_id) as UUID (department ID)
  if dept_id is not null then
    claims := jsonb_set(claims, '{wpdept_id}', to_jsonb(dept_id), true);  -- Department ID (UUID)
  else
    claims := jsonb_set(claims, '{wpdept_id}', 'null'::jsonb, true);  -- Set null if dept_id is missing
  end if;

  -- Update the event with the modified claims
  event := jsonb_set(event, '{claims}', claims, true);

  -- Return the updated event
  return event;
end;$$;


ALTER FUNCTION "public"."add_wp_info_to_jwt"("event" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."assign_membership_code"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
  UPDATE public.branches SET lastmember = lastmember + 1 WHERE id = NEW.branch_id;

  UPDATE public.profiles
  SET membership_code = (SELECT slug || lastmember FROM public.branches WHERE id = NEW.branch_id)
  WHERE id = NEW.memberid;

  INSERT INTO public.membershipcode (memberid, membershipcode)
  VALUES (NEW.memberid, (SELECT slug || lastmember FROM public.branches WHERE id = NEW.branch_id))
  ON CONFLICT (memberid) DO NOTHING;

  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."assign_membership_code"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."create_role_for_new_user"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  v_role_id uuid; -- adjust type if roletypes.id is not uuid
BEGIN
  SELECT id INTO v_role_id FROM public.roletypes WHERE rolename = 'member';
  IF v_role_id IS NULL THEN
    -- Create the 'member' role type automatically
    INSERT INTO public.roletypes (rolename) VALUES ('member') RETURNING id INTO v_role_id;
    -- If creation failed for some reason, raise an error
    IF v_role_id IS NULL THEN
      RAISE EXCEPTION 'Failed to create default roletype "member". Aborting.';
    END IF;
  END IF;

  INSERT INTO public.roles (memberid, full_name, roleid)
  VALUES (NEW.id, NEW.full_name, v_role_id);
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."create_role_for_new_user"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."current_user_branch"() RETURNS "uuid"
    LANGUAGE "sql" STABLE
    AS $$
  SELECT p.branch_id FROM public.profiles p WHERE p.id = (SELECT auth.uid()) LIMIT 1;
$$;


ALTER FUNCTION "public"."current_user_branch"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."fn_sync_comments_count"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
    IF (TG_OP = 'INSERT') THEN
        UPDATE public.posts
        SET comments_count = comments_count + 1
        WHERE id = NEW.post_id;
    ELSIF (TG_OP = 'DELETE') THEN
        UPDATE public.posts
        SET comments_count = comments_count - 1
        WHERE id = OLD.post_id;
    END IF;
    RETURN NULL;
END;
$$;


ALTER FUNCTION "public"."fn_sync_comments_count"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_current_rolename"() RETURNS "text"
    LANGUAGE "sql" STABLE SECURITY DEFINER
    AS $$
  SELECT rt.rolename
  FROM public.roles r
  JOIN public.roletypes rt ON rt.id = r.roleid
  WHERE r.memberid = (SELECT auth.uid())
  LIMIT 1;
$$;


ALTER FUNCTION "public"."get_current_rolename"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_current_user_branch"() RETURNS "uuid"
    LANGUAGE "sql" STABLE SECURITY DEFINER
    AS $$
  SELECT branch_id FROM public.profiles WHERE id = auth.uid();
$$;


ALTER FUNCTION "public"."get_current_user_branch"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_current_user_context"() RETURNS TABLE("user_id" "uuid", "branch_id" "uuid", "department_id" "uuid", "role_name" "text")
    LANGUAGE "sql" STABLE SECURITY DEFINER
    AS $$
  SELECT
    p.id::uuid AS user_id,
    p.branch_id::uuid,
    p.department_id::uuid,
    rt.rolename::text
  FROM public.profiles p
  LEFT JOIN public.roles r ON r.memberid = p.id
  LEFT JOIN public.roletypes rt ON rt.id = r.roleid
  WHERE p.id = (SELECT auth.uid())
  LIMIT 1;
$$;


ALTER FUNCTION "public"."get_current_user_context"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_current_user_department"() RETURNS "uuid"
    LANGUAGE "sql" STABLE SECURITY DEFINER
    AS $$
  SELECT (SELECT department_id FROM public.profiles WHERE id = auth.uid());
$$;


ALTER FUNCTION "public"."get_current_user_department"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_current_user_id"() RETURNS "uuid"
    LANGUAGE "sql" STABLE SECURITY DEFINER
    AS $$
  SELECT auth.uid();
$$;


ALTER FUNCTION "public"."get_current_user_id"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_current_user_role"() RETURNS "text"
    LANGUAGE "sql" STABLE SECURITY DEFINER
    AS $$
  SELECT role FROM public.profiles WHERE id = auth.uid();
$$;


ALTER FUNCTION "public"."get_current_user_role"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_my_branch"() RETURNS "uuid"
    LANGUAGE "sql" STABLE SECURITY DEFINER
    AS $$
  select branch_id from profiles where id = auth.uid();
$$;


ALTER FUNCTION "public"."get_my_branch"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_my_branch_id"() RETURNS "uuid"
    LANGUAGE "sql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  SELECT branch_id FROM public.profiles_priv_info WHERE id = auth.uid();
$$;


ALTER FUNCTION "public"."get_my_branch_id"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_my_department"() RETURNS "uuid"
    LANGUAGE "sql" STABLE SECURITY DEFINER
    AS $$
  select department_id from profiles where id = auth.uid();
$$;


ALTER FUNCTION "public"."get_my_department"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_my_role"() RETURNS "text"
    LANGUAGE "sql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  SELECT role FROM public.profiles_priv_info WHERE id = auth.uid();
$$;


ALTER FUNCTION "public"."get_my_role"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_profiles_view"() RETURNS TABLE("id" "uuid", "full_name" "text", "lastname" "text", "phone" "text", "department_id" "uuid", "department" "text", "membership_code" "text", "verified" boolean, "avatar" "text", "role" "text", "branch_id" "uuid", "email" "text", "address" "text", "occupation" "text", "created_at" timestamp without time zone)
    LANGUAGE "sql" SECURITY DEFINER
    AS $$
  SELECT
    p.id,
    p.full_name,
    p.lastname,
    p.phone,
    p.department_id,
    d.name AS department,
    p.membership_code,
    p.verified,
    p.avatar,
    CASE
      WHEN (get_current_user_role() = 'globaladmin'::text)
        OR (p.id = auth.uid())
        OR (get_current_user_role() = 'admin'::text AND p.branch_id = get_current_user_branch())
        OR (get_current_user_role() = 'superuser'::text AND p.department_id = (SELECT department_id FROM public.profiles WHERE id = auth.uid()))
      THEN p.role
      ELSE NULL
    END AS role,
    CASE
      WHEN (get_current_user_role() = 'globaladmin'::text)
        OR (p.id = auth.uid())
        OR (get_current_user_role() = 'admin'::text AND p.branch_id = get_current_user_branch())
        OR (get_current_user_role() = 'superuser'::text AND p.department_id = (SELECT department_id FROM public.profiles WHERE id = auth.uid()))
      THEN p.branch_id
      ELSE NULL
    END AS branch_id,
    CASE
      WHEN (get_current_user_role() = 'globaladmin'::text)
        OR (p.id = auth.uid())
        OR (get_current_user_role() = 'admin'::text AND p.branch_id = get_current_user_branch())
        OR (get_current_user_role() = 'superuser'::text AND p.department_id = (SELECT department_id FROM public.profiles WHERE id = auth.uid()))
      THEN p.email
      ELSE NULL
    END AS email,
    CASE
      WHEN (get_current_user_role() = 'globaladmin'::text)
        OR (p.id = auth.uid())
        OR (get_current_user_role() = 'admin'::text AND p.branch_id = get_current_user_branch())
        OR (get_current_user_role() = 'superuser'::text AND p.department_id = (SELECT department_id FROM public.profiles WHERE id = auth.uid()))
      THEN p.address
      ELSE NULL
    END AS address,
    CASE
      WHEN (get_current_user_role() = 'globaladmin'::text)
        OR (p.id = auth.uid())
        OR (get_current_user_role() = 'admin'::text AND p.branch_id = get_current_user_branch())
        OR (get_current_user_role() = 'superuser'::text AND p.department_id = (SELECT department_id FROM public.profiles WHERE id = auth.uid()))
      THEN p.occupation
      ELSE NULL
    END AS occupation,
    CASE
      WHEN (get_current_user_role() = 'globaladmin'::text)
        OR (p.id = auth.uid())
        OR (get_current_user_role() = 'admin'::text AND p.branch_id = get_current_user_branch())
        OR (get_current_user_role() = 'superuser'::text AND p.department_id = (SELECT department_id FROM public.profiles WHERE id = auth.uid()))
      THEN p.created_at
      ELSE NULL
    END AS created_at
  FROM public.profiles p
  LEFT JOIN public.departments d ON d.id = p.department_id
  WHERE
    (
      get_current_user_role() = 'globaladmin'::text
    )
    OR
    (p.id = auth.uid())
    OR
    (
      get_current_user_role() = 'admin'::text
      AND p.branch_id = get_current_user_branch()
    )
    OR
    (
      get_current_user_role() = 'worker'::text
      AND p.branch_id = get_current_user_branch()
    )
    OR
    (
      get_current_user_role() = 'superuser'::text
      AND (
        p.department_id = (SELECT department_id FROM public.profiles WHERE id = auth.uid())
        OR p.branch_id = get_current_user_branch()
      )
    );
$$;


ALTER FUNCTION "public"."get_profiles_view"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_user_branch"() RETURNS "uuid"
    LANGUAGE "sql" STABLE SECURITY DEFINER
    AS $$
  SELECT branch_id FROM public.profiles WHERE id = auth.uid();
$$;


ALTER FUNCTION "public"."get_user_branch"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_user_branch_id"() RETURNS "uuid"
    LANGUAGE "sql" STABLE SECURITY DEFINER
    AS $$
  SELECT branch_id FROM public.profiles WHERE id = auth.uid();
$$;


ALTER FUNCTION "public"."get_user_branch_id"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_user_department"() RETURNS "uuid"
    LANGUAGE "sql" STABLE SECURITY DEFINER
    AS $$
  SELECT department_id FROM public.profiles WHERE id = auth.uid();
$$;


ALTER FUNCTION "public"."get_user_department"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_user_department_id"() RETURNS "uuid"
    LANGUAGE "sql" STABLE SECURITY DEFINER
    AS $$
  SELECT department_id FROM public.profiles WHERE id = auth.uid();
$$;


ALTER FUNCTION "public"."get_user_department_id"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_user_role"() RETURNS "text"
    LANGUAGE "sql" STABLE SECURITY DEFINER
    AS $$
  SELECT role FROM public.profiles WHERE id = auth.uid();
$$;


ALTER FUNCTION "public"."get_user_role"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."handle_leaders_role_sync"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
begin
  if tg_op in ('UPDATE', 'DELETE') then
    perform public.sync_dept_leader_role_for_user(old.user_id);
  end if;

  if tg_op in ('INSERT', 'UPDATE') then
    perform public.sync_dept_leader_role_for_user(new.user_id);
  end if;

  return coalesce(new, old);
end;
$$;


ALTER FUNCTION "public"."handle_leaders_role_sync"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."is_admin"() RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    AS $$
  SELECT (public.get_current_user_role() = 'admin');
$$;


ALTER FUNCTION "public"."is_admin"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."is_admin_or_global"() RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    AS $$
  SELECT (public.get_current_user_role() = 'admin' OR public.get_current_user_role() = 'globaladmin');
$$;


ALTER FUNCTION "public"."is_admin_or_global"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."is_globaladmin"() RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    AS $$
  SELECT (public.get_current_user_role() = 'globaladmin');
$$;


ALTER FUNCTION "public"."is_globaladmin"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."is_self"("target_id" "uuid") RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    AS $$
  SELECT public.get_current_user_id() = target_id;
$$;


ALTER FUNCTION "public"."is_self"("target_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."posts_current_branch"("p_post_id" "uuid") RETURNS "uuid"
    LANGUAGE "sql" STABLE SECURITY DEFINER
    AS $$
  SELECT branch_id FROM public.posts WHERE id = p_post_id;
$$;


ALTER FUNCTION "public"."posts_current_branch"("p_post_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."posts_current_department"("p_post_id" "uuid") RETURNS "uuid"
    LANGUAGE "sql" STABLE SECURITY DEFINER
    AS $$
  SELECT department_id FROM public.posts WHERE id = p_post_id;
$$;


ALTER FUNCTION "public"."posts_current_department"("p_post_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."posts_reaction_counts_sync"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
    IF (TG_OP = 'INSERT') THEN
        -- Atomic Increment: The math happens inside the database engine.
        UPDATE public.posts
        SET reaction_counts = jsonb_set(
            reaction_counts,
            ARRAY[NEW.reaction_type],
            (COALESCE(reaction_counts->>NEW.reaction_type, '0')::int + 1)::text::jsonb
        )
        WHERE id = NEW.post_id;

    ELSIF (TG_OP = 'DELETE') THEN
        -- Atomic Decrement: Prevents counts from going below zero.
        UPDATE public.posts
        SET reaction_counts = jsonb_set(
            reaction_counts,
            ARRAY[OLD.reaction_type],
            GREATEST(0, (COALESCE(reaction_counts->>OLD.reaction_type, '0')::int - 1))::text::jsonb
        )
        WHERE id = OLD.post_id;
    END IF;

    RETURN NULL;
END;
$$;


ALTER FUNCTION "public"."posts_reaction_counts_sync"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."profiles_prevent_forbidden_inserts"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  -- Allow postgres role to perform direct inserts
  IF current_user = 'postgres' THEN
    RETURN NEW;
  END IF;

  -- Prevent non-postgres roles from inserting rows with restricted columns set
  IF TG_OP = 'INSERT' THEN
    IF (NEW.role IS NOT NULL) OR (NEW.membership_code IS NOT NULL) THEN
      RAISE EXCEPTION 'Direct INSERTs setting restricted profile columns are forbidden unless executed by postgres.';
    END IF;
  END IF;

  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."profiles_prevent_forbidden_inserts"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."profiles_prevent_forbidden_updates"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  -- Allow postgres role to perform direct updates
  IF current_user = 'postgres' THEN
    RETURN NEW;
  END IF;

  -- Prevent non-postgres roles from modifying restricted columns
  IF TG_OP = 'UPDATE' THEN
    IF (OLD.email IS DISTINCT FROM NEW.email)
      OR (OLD.role IS DISTINCT FROM NEW.role)
      OR (OLD.membership_code IS DISTINCT FROM NEW.membership_code)
      OR (OLD.department_id IS DISTINCT FROM NEW.department_id)
    THEN
      RAISE EXCEPTION 'Direct UPDATEs modifying restricted profile columns are forbidden unless executed by postgres.';
    END IF;
  END IF;

  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."profiles_prevent_forbidden_updates"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."profiles_to_roles_sync"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  v_role_rec RECORD;
BEGIN
  IF TG_OP = 'INSERT' THEN
    -- Look up the role type row named 'member' dynamically
    SELECT id, rolename INTO v_role_rec FROM public.roletypes WHERE rolename = 'member' LIMIT 1;

    -- If not found, raise a clear exception
    IF v_role_rec IS NULL THEN
      RAISE EXCEPTION 'roletypes row with rolename=member not found';
    END IF;

    INSERT INTO public.roles (memberid, roleid, full_name, rolename)
    VALUES (NEW.id, v_role_rec.id, NEW.full_name, v_role_rec.rolename)
    ON CONFLICT (memberid) DO NOTHING;
  END IF;

  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."profiles_to_roles_sync"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."restrict_early_clockout"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  event_end_time timestamptz;
BEGIN
  -- Check if clockout is being set (either during an insert or an update)
  IF (TG_OP = 'INSERT' AND NEW.clockout IS NOT NULL) OR 
     (TG_OP = 'UPDATE' AND NEW.clockout IS DISTINCT FROM OLD.clockout AND NEW.clockout IS NOT NULL) THEN
    
    -- Extract the event's end time
    SELECT endtime INTO event_end_time 
    FROM public.events 
    WHERE id = NEW.event_id;
    
    -- Restrict if endtime hasn't been met (or hasn't been set yet)
    IF event_end_time IS NULL OR CURRENT_TIMESTAMP < event_end_time THEN
      RAISE EXCEPTION 'You cannot clock out until the event has officially ended.';
    END IF;
    
  END IF;
  
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."restrict_early_clockout"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."rls_auto_enable"() RETURNS "event_trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'pg_catalog'
    AS $$
DECLARE
  cmd record;
BEGIN
  FOR cmd IN
    SELECT *
    FROM pg_event_trigger_ddl_commands()
    WHERE command_tag IN ('CREATE TABLE', 'CREATE TABLE AS', 'SELECT INTO')
      AND object_type IN ('table','partitioned table')
  LOOP
     IF cmd.schema_name IS NOT NULL AND cmd.schema_name IN ('public') AND cmd.schema_name NOT IN ('pg_catalog','information_schema') AND cmd.schema_name NOT LIKE 'pg_toast%' AND cmd.schema_name NOT LIKE 'pg_temp%' THEN
      BEGIN
        EXECUTE format('alter table if exists %s enable row level security', cmd.object_identity);
        RAISE LOG 'rls_auto_enable: enabled RLS on %', cmd.object_identity;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE LOG 'rls_auto_enable: failed to enable RLS on %', cmd.object_identity;
      END;
     ELSE
        RAISE LOG 'rls_auto_enable: skip % (either system schema or not in enforced list: %.)', cmd.object_identity, cmd.schema_name;
     END IF;
  END LOOP;
END;
$$;


ALTER FUNCTION "public"."rls_auto_enable"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."roles_to_profiles_sync"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$BEGIN
  -- Only update the role column on profiles when a role row is inserted/updated
  IF NEW.rolename IS NOT NULL THEN
    UPDATE public.profiles_priv_info
       SET role = NEW.rolename
     WHERE id = NEW.memberid;
  END IF;

  RETURN NEW;
END;$$;


ALTER FUNCTION "public"."roles_to_profiles_sync"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."same_branch_as_current"("target_user_id" "uuid") RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    AS $$
  SELECT (SELECT branch_id FROM public.profiles WHERE id = target_user_id) IS NOT DISTINCT FROM public.get_current_user_branch();
$$;


ALTER FUNCTION "public"."same_branch_as_current"("target_user_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."same_department_as_current"("target_user_id" "uuid") RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    AS $$
  SELECT (SELECT department_id FROM public.profiles WHERE id = target_user_id) IS NOT DISTINCT FROM public.get_current_user_department();
$$;


ALTER FUNCTION "public"."same_department_as_current"("target_user_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."sync_branch_prefix"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    IF (TG_OP = 'UPDATE' AND TG_TABLE_NAME = 'branches') THEN
        UPDATE public.profiles SET prefix = NEW.prefix WHERE branch_id = NEW.id;
        UPDATE public.profiles_priv_info SET prefix = NEW.prefix WHERE branch_id = NEW.id;
    ELSIF (TG_TABLE_NAME = 'profiles' OR TG_TABLE_NAME = 'profiles_priv_info') THEN
        SELECT prefix INTO NEW.prefix FROM public.branches WHERE id = NEW.branch_id;
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."sync_branch_prefix"() OWNER TO "postgres";


COMMENT ON FUNCTION "public"."sync_branch_prefix"() IS 'Maintains branch-based prefixes (e.g., WPCC/HQ/) across profiles. 
Triggered by branch prefix updates OR member branch reassignments.';



CREATE OR REPLACE FUNCTION "public"."sync_dept_leader_role_for_user"("target_user_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
  dept_leader_role record;
  has_active_assignment boolean;
  profile_full_name text;
begin
  if target_user_id is null then
    return;
  end if;

  select id, rolename
  into dept_leader_role
  from public.roletypes
  where rolename = 'dept_leader'
  limit 1;

  if dept_leader_role.id is null then
    raise exception 'roletypes row for dept_leader was not found';
  end if;

  select exists (
    select 1
    from public.leaders
    where user_id = target_user_id
      and is_active = true
  )
  into has_active_assignment;

  if has_active_assignment then
    select full_name
    into profile_full_name
    from public.profiles
    where id = target_user_id;

    insert into public.roles (memberid, full_name, roleid, rolename)
    values (
      target_user_id,
      coalesce(profile_full_name, target_user_id::text),
      dept_leader_role.id,
      dept_leader_role.rolename
    )
    on conflict (memberid) do update
    set
      full_name = excluded.full_name,
      roleid = excluded.roleid,
      rolename = excluded.rolename;
  else
    delete from public.roles
    where memberid = target_user_id
      and roleid = dept_leader_role.id
      and rolename = dept_leader_role.rolename;
  end if;
end;
$$;


ALTER FUNCTION "public"."sync_dept_leader_role_for_user"("target_user_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."sync_membership_code"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    UPDATE public.profiles SET membership_code = NEW.membershipcode WHERE id = NEW.memberid;
    UPDATE public.profiles_priv_info SET membership_code = NEW.membershipcode WHERE id = NEW.memberid;
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."sync_membership_code"() OWNER TO "postgres";


COMMENT ON FUNCTION "public"."sync_membership_code"() IS 'Enforces profiles.membership_code to always match the master record in membershipcode table.';



CREATE OR REPLACE FUNCTION "public"."sync_profile_verification"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    UPDATE public.profiles SET verified = NEW.verified WHERE id = NEW.id;
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."sync_profile_verification"() OWNER TO "postgres";


COMMENT ON FUNCTION "public"."sync_profile_verification"() IS 'Ensures public profiles reflect the verified status managed in individual private info.';



CREATE OR REPLACE FUNCTION "public"."sync_recurring_events_for_week"("p_week_start" "date" DEFAULT NULL::"date", "p_timezone" "text" DEFAULT 'Africa/Lagos'::"text") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'pg_temp'
    AS $$
declare
  v_timezone text := coalesce(nullif(btrim(p_timezone), ''), 'Africa/Lagos');
  v_local_now timestamp := timezone(v_timezone, now());
  v_week_start date := coalesce(
    p_week_start,
    (date_trunc('week', v_local_now)::date + interval '1 week')::date
  );
  v_week_end date := v_week_start + 7;
  v_candidates bigint := 0;
  v_inserted bigint := 0;
  v_updated bigint := 0;
  v_deactivated bigint := 0;
begin
  raise notice 'sync_recurring_events_for_week started timezone=% week_start=% week_end=%',
    v_timezone, v_week_start, v_week_end;

  with week_dates as (
    select
      gs::date as event_day,
      extract(dow from gs)::int as day_of_week,
      extract(month from gs)::int as month_of_year,
      extract(day from gs)::int as day_of_month,
      1 + (
        (
          extract(day from gs)::int
          - 1
          - extract(dow from date_trunc('month', gs))::int
          + 7
        ) / 7
      ) as week_of_month_in_month
    from generate_series(
      v_week_start::timestamp,
      (v_week_start + 6)::timestamp,
      interval '1 day'
    ) as gs
  ),
  matched_events as (
    select
      re.id as recurring_event_id,
      re.title,
      re.description,
      re.featured_url,
      re.recurrence_type,
      re.day_of_week,
      re.week_of_month,
      re.day_of_month,
      re.month,
      wd.event_day,
      (wd.event_day::timestamp + re.start_time) as start_at_local,
      case
        when re.end_time <= re.start_time then
          (wd.event_day::timestamp + re.end_time + interval '1 day')
        else
          (wd.event_day::timestamp + re.end_time)
      end as end_at_local
    from public.recurring_events re
    join week_dates wd
      on re.is_active is true
     and (
       (
         re.recurrence_type = 'weekly'
         and re.day_of_week = wd.day_of_week
       )
       or (
         re.recurrence_type = 'monthly'
         and re.day_of_month is not null
         and re.day_of_month = wd.day_of_month
         and (re.month is null or re.month = wd.month_of_year)
       )
       or (
         re.recurrence_type = 'monthly'
         and re.week_of_month is not null
         and re.day_of_week is not null
         and re.day_of_week = wd.day_of_week
         and re.week_of_month = wd.week_of_month_in_month
       )
       or (
         re.recurrence_type = 'yearly'
         and re.month is not null
         and re.day_of_month is not null
         and re.month = wd.month_of_year
         and re.day_of_month = wd.day_of_month
       )
     )
  ),
  upserted_events as (
    insert into public.events (
      recurring_event_id,
      title,
      description,
      event_date,
      scope,
      branch_id,
      created_by,
      created_at,
      isactive,
      "closed by",
      endtime,
      featured_url,
      location,
      latitude,
      longitude
    )
    select
      me.recurring_event_id,
      me.title,
      me.description,
      me.start_at_local,
      'global',
      null,
      'recurring_events_sync',
      now(),
      true,
      null,
      me.end_at_local at time zone v_timezone,
      me.featured_url,
      null,
      null,
      null
    from matched_events me
    on conflict (recurring_event_id, event_date) do update
      set title = excluded.title,
          description = excluded.description,
          isactive = excluded.isactive,
          "closed by" = excluded."closed by",
          endtime = excluded.endtime,
          featured_url = excluded.featured_url
    returning (xmax = 0) as inserted
  ),
  deactivated_rows as (
    update public.events e
       set isactive = false,
           "closed by" = 'recurring_events_sync'
     where e.recurring_event_id is not null
       and e.event_date::date >= v_week_start
       and e.event_date::date < v_week_end
       and not exists (
         select 1
           from matched_events me
          where me.recurring_event_id = e.recurring_event_id
            and me.event_day = e.event_date::date
       )
    returning 1
  )
  select
    (select count(*) from matched_events),
    coalesce((select count(*) filter (where inserted) from upserted_events), 0),
    coalesce((select count(*) filter (where not inserted) from upserted_events), 0),
    coalesce((select count(*) from deactivated_rows), 0)
  into v_candidates, v_inserted, v_updated, v_deactivated;

  raise notice 'sync_recurring_events_for_week finished candidates=% inserted=% updated=% deactivated=%',
    v_candidates, v_inserted, v_updated, v_deactivated;

  return jsonb_build_object(
    'timezone', v_timezone,
    'week_start', v_week_start,
    'week_end', v_week_end,
    'candidates', v_candidates,
    'inserted', v_inserted,
    'updated', v_updated,
    'deactivated', v_deactivated
  );
exception
  when others then
    raise exception 'sync_recurring_events_for_week failed: %', sqlerrm
      using errcode = sqlstate;
end;
$$;


ALTER FUNCTION "public"."sync_recurring_events_for_week"("p_week_start" "date", "p_timezone" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."sync_user_metadata"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'auth'
    AS $$
BEGIN
  -- Update auth.users metadata for the user being updated
  UPDATE auth.users 
  SET raw_app_meta_data = raw_app_meta_data || 
    jsonb_build_object('wprole', NEW.role, 'wpbranch_id', NEW.branch_id::text)
  WHERE id = NEW.id;
  
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."sync_user_metadata"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."sync_user_role"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    UPDATE public.profiles_priv_info SET role = NEW.rolename WHERE id = NEW.memberid;
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."sync_user_role"() OWNER TO "postgres";


COMMENT ON FUNCTION "public"."sync_user_role"() IS 'Synchronizes the master role from public.roles table to user metadata views.';



CREATE OR REPLACE FUNCTION "public"."sync_worker_department"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
  -- Update public.profiles
  UPDATE public.profiles
  SET department_id = NEW.department_id
  WHERE id = NEW.user_id;

  -- Update public.profiles_priv_info
  UPDATE public.profiles_priv_info
  SET department_id = NEW.department_id
  WHERE id = NEW.user_id;

  -- Update public.leaders
  UPDATE public.leaders
  SET department_id = NEW.department_id
  WHERE user_id = NEW.user_id;

  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."sync_worker_department"() OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "public"."announcements" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "title" "text" NOT NULL,
    "content" "text" NOT NULL,
    "scope" "text" NOT NULL,
    "branch_id" "uuid",
    "department_id" "uuid",
    "created_by" "uuid",
    "created_at" timestamp without time zone DEFAULT "now"(),
    "mediaurl" "text",
    "hasmedia" boolean,
    CONSTRAINT "announcements_scope_check" CHECK (("scope" = ANY (ARRAY['global'::"text", 'branch'::"text", 'department'::"text"])))
);

ALTER TABLE ONLY "public"."announcements" FORCE ROW LEVEL SECURITY;


ALTER TABLE "public"."announcements" OWNER TO "postgres";


COMMENT ON COLUMN "public"."announcements"."mediaurl" IS 'media url';



CREATE TABLE IF NOT EXISTS "public"."attendance" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid",
    "event_id" "uuid",
    "status" "text" DEFAULT 'pending'::"text",
    "latitude" numeric,
    "longitude" numeric,
    "created_at" timestamp without time zone DEFAULT "now"(),
    "branch_id" "uuid",
    "department_id" "uuid",
    "fullname" "text" NOT NULL,
    "confirmedby" "uuid",
    "confirmedby_name" "text",
    "clockout" timestamp with time zone,
    "closedlat" numeric,
    "closedlong" numeric,
    CONSTRAINT "attendance_status_check" CHECK (("status" = ANY (ARRAY['pending'::"text", 'confirmed'::"text", 'rejected'::"text", 'present'::"text"])))
);

ALTER TABLE ONLY "public"."attendance" FORCE ROW LEVEL SECURITY;


ALTER TABLE "public"."attendance" OWNER TO "postgres";


COMMENT ON TABLE "public"."attendance" IS 'Tracks member presence. UNIQUE CONSTRAINT: Only 1 record per person per department per event.';



COMMENT ON COLUMN "public"."attendance"."status" IS 'if the user is still in service or not';



COMMENT ON COLUMN "public"."attendance"."department_id" IS 'Part of the unique check: only 1 person per department per event can be on this table.';



COMMENT ON COLUMN "public"."attendance"."confirmedby" IS 'uuid of the confirmer';



CREATE TABLE IF NOT EXISTS "public"."attendance_audit_logs" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "event_id" "uuid" NOT NULL,
    "action" "text" NOT NULL,
    "occurred_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "distance_m" double precision,
    "latitude" double precision,
    "longitude" double precision,
    "user_full_name" "text",
    "request_ip" "inet",
    "user_agent" "text",
    "raw_payload" "jsonb",
    CONSTRAINT "attendance_audit_logs_action_check" CHECK (("action" = ANY (ARRAY['clock_in'::"text", 'clock_out'::"text", 'invalid_location'::"text", 'method_not_allowed'::"text", 'unauthorized'::"text"])))
);


ALTER TABLE "public"."attendance_audit_logs" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."branches" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "created_at" timestamp without time zone DEFAULT "now"(),
    "slug" "text" NOT NULL,
    "address" "text" NOT NULL,
    "contactnumber" "text",
    "lastmember" integer DEFAULT 0 NOT NULL,
    "prefix" "text"
);

ALTER TABLE ONLY "public"."branches" FORCE ROW LEVEL SECURITY;


ALTER TABLE "public"."branches" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."departments" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "created_at" timestamp without time zone DEFAULT "now"(),
    "description" "text"
);

ALTER TABLE ONLY "public"."departments" FORCE ROW LEVEL SECURITY;


ALTER TABLE "public"."departments" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."events" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "title" "text" NOT NULL,
    "description" "text",
    "event_date" timestamp without time zone,
    "scope" "text" NOT NULL,
    "branch_id" "uuid",
    "created_by" "text" NOT NULL,
    "created_at" timestamp without time zone DEFAULT "now"(),
    "isactive" boolean DEFAULT true NOT NULL,
    "closed by" "text",
    "endtime" timestamp with time zone,
    "featured_url" "text",
    "location" "text",
    "latitude" numeric DEFAULT 4.80850070633439,
    "longitude" numeric,
    "recurring_event_id" "uuid",
    CONSTRAINT "events_scope_check" CHECK (("scope" = ANY (ARRAY['global'::"text", 'branch'::"text", 'department'::"text"])))
);

ALTER TABLE ONLY "public"."events" FORCE ROW LEVEL SECURITY;


ALTER TABLE "public"."events" OWNER TO "postgres";


COMMENT ON COLUMN "public"."events"."created_by" IS 'name of full name of the creator';



CREATE TABLE IF NOT EXISTS "public"."profiles" (
    "id" "uuid" DEFAULT "auth"."uid"() NOT NULL,
    "branch_id" "uuid" NOT NULL,
    "department_id" "uuid",
    "full_name" "text" NOT NULL,
    "phone" "text",
    "bio" "text" DEFAULT ''::"text",
    "membership_code" "text",
    "date_joined" "date" DEFAULT CURRENT_DATE,
    "verified" boolean DEFAULT false,
    "created_at" timestamp without time zone DEFAULT "now"(),
    "avatar" "text",
    "lastname" "text",
    "firstname" "text",
    "prefix" "text",
    "email" character varying
);


ALTER TABLE "public"."profiles" OWNER TO "postgres";


COMMENT ON COLUMN "public"."profiles"."id" IS 'PRIVATE: id';



COMMENT ON COLUMN "public"."profiles"."phone" IS 'PRIVATE: phone';



CREATE OR REPLACE VIEW "public"."attendance_view" WITH ("security_invoker"='on') AS
 SELECT "a"."id" AS "attendance_id",
    "a"."user_id",
    "p"."full_name" AS "profile_full_name",
    "a"."fullname" AS "attendance_fullname",
    "a"."event_id",
    "e"."title" AS "event_title",
    "e"."event_date",
    "e"."scope" AS "event_scope",
    "a"."status" AS "attendance_status",
    "a"."branch_id",
    "br"."name" AS "branch_name",
    "a"."department_id",
    "dep"."name" AS "department_name",
    "a"."latitude",
    "a"."longitude",
    "a"."closedlat",
    "a"."closedlong",
    "a"."clockout",
    "a"."confirmedby",
    "a"."confirmedby_name",
    "a"."created_at" AS "attendance_created_at",
        CASE
            WHEN ("br"."prefix" IS NULL) THEN "p"."membership_code"
            ELSE ("br"."prefix" || "p"."membership_code")
        END AS "profile_membership_code"
   FROM (((("public"."attendance" "a"
     LEFT JOIN "public"."events" "e" ON (("e"."id" = "a"."event_id")))
     LEFT JOIN "public"."profiles" "p" ON (("p"."id" = "a"."user_id")))
     LEFT JOIN "public"."branches" "br" ON (("br"."id" = "a"."branch_id")))
     LEFT JOIN "public"."departments" "dep" ON (("dep"."id" = "a"."department_id")));


ALTER VIEW "public"."attendance_view" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."comments" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "post_id" "uuid" NOT NULL,
    "parent_comment_id" "uuid",
    "created_by" "uuid",
    "body" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "modified_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "is_edited" boolean DEFAULT false,
    "is_deleted" boolean DEFAULT false,
    "more" "jsonb",
    "commentor name" "text"
);

ALTER TABLE ONLY "public"."comments" FORCE ROW LEVEL SECURITY;


ALTER TABLE "public"."comments" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."course_enrollments" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid",
    "course_id" "uuid",
    "completed" boolean DEFAULT false,
    "created_at" timestamp without time zone DEFAULT "now"()
);

ALTER TABLE ONLY "public"."course_enrollments" FORCE ROW LEVEL SECURITY;


ALTER TABLE "public"."course_enrollments" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."courses" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "title" "text",
    "description" "text",
    "branch_id" "uuid",
    "created_at" timestamp without time zone DEFAULT "now"()
);

ALTER TABLE ONLY "public"."courses" FORCE ROW LEVEL SECURITY;


ALTER TABLE "public"."courses" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."leaders" (
    "id" "uuid" DEFAULT "auth"."uid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "department_id" "uuid" NOT NULL,
    "branch_id" "uuid" NOT NULL,
    "created_at" timestamp without time zone DEFAULT "now"(),
    "title_id" "uuid" NOT NULL,
    "is_active" boolean DEFAULT true NOT NULL,
    "start_date" timestamp with time zone,
    "end_date" timestamp with time zone,
    CONSTRAINT "leaders_date_range_check" CHECK ((("end_date" IS NULL) OR ("start_date" IS NULL) OR ("end_date" >= "start_date")))
);

ALTER TABLE ONLY "public"."leaders" FORCE ROW LEVEL SECURITY;


ALTER TABLE "public"."leaders" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."leadership_titles" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "code" "text" NOT NULL,
    "name" "text" NOT NULL,
    "description" "text",
    "parent_role_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."leadership_titles" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."roletypes" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "rolename" "text" NOT NULL,
    "description" "text"
);


ALTER TABLE "public"."roletypes" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."department_leadership_view" WITH ("security_invoker"='true') AS
 SELECT "l"."id" AS "leader_id",
    "l"."user_id",
    "p"."full_name" AS "user_full_name",
    "p"."email" AS "user_email",
    "l"."department_id",
    "d"."name" AS "department_name",
    "l"."branch_id",
    "l"."title_id",
    "lt"."code" AS "title_code",
    "lt"."name" AS "title_name",
    "lt"."description" AS "title_description",
    "rt"."id" AS "parent_role_id",
    "rt"."rolename" AS "parent_role_name",
    "l"."is_active",
    "l"."start_date",
    "l"."end_date",
    "l"."created_at"
   FROM (((("public"."leaders" "l"
     JOIN "public"."leadership_titles" "lt" ON (("lt"."id" = "l"."title_id")))
     JOIN "public"."roletypes" "rt" ON (("rt"."id" = "lt"."parent_role_id")))
     LEFT JOIN "public"."departments" "d" ON (("d"."id" = "l"."department_id")))
     LEFT JOIN "public"."profiles" "p" ON (("p"."id" = "l"."user_id")));


ALTER VIEW "public"."department_leadership_view" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."department_requests" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid",
    "department_id" "uuid",
    "status" "text" DEFAULT 'pending'::"text",
    "created_at" timestamp without time zone DEFAULT "now"(),
    CONSTRAINT "department_requests_status_check" CHECK (("status" = ANY (ARRAY['pending'::"text", 'approved'::"text", 'passed'::"text", 'rejected'::"text"])))
);

ALTER TABLE ONLY "public"."department_requests" FORCE ROW LEVEL SECURITY;


ALTER TABLE "public"."department_requests" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."department_summary_view" WITH ("security_invoker"='on') AS
 SELECT "d"."id" AS "department_id",
    "d"."name" AS "department_name",
    ( SELECT "count"(*) AS "count"
           FROM "public"."profiles" "p"
          WHERE ("p"."department_id" = "d"."id")) AS "persons_count",
    "count"(DISTINCT
        CASE
            WHEN (("e"."isactive" = true) AND ("e"."scope" = 'department'::"text")) THEN "a"."event_id"
            ELSE NULL::"uuid"
        END) AS "active_departmental_events",
    "count"(DISTINCT
        CASE
            WHEN (("e"."isactive" = false) OR ("e"."event_date" < "now"()) OR ("e"."scope" <> 'department'::"text")) THEN "a"."event_id"
            ELSE NULL::"uuid"
        END) AS "past_departmental_events"
   FROM (("public"."departments" "d"
     LEFT JOIN "public"."attendance" "a" ON (("a"."department_id" = "d"."id")))
     LEFT JOIN "public"."events" "e" ON (("e"."id" = "a"."event_id")))
  GROUP BY "d"."id", "d"."name"
  ORDER BY "d"."name";


ALTER VIEW "public"."department_summary_view" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."workers" (
    "id" "uuid" DEFAULT "auth"."uid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "department_id" "uuid",
    "branch_id" "uuid" NOT NULL,
    "created_at" timestamp without time zone DEFAULT "now"(),
    "membershipcode" "text" DEFAULT '0'::"text" NOT NULL
);

ALTER TABLE ONLY "public"."workers" FORCE ROW LEVEL SECURITY;


ALTER TABLE "public"."workers" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."events_attendance_view" WITH ("security_invoker"='on') AS
 WITH "branch_worker_totals" AS (
         SELECT "w"."branch_id",
            "count"(DISTINCT "w"."user_id") AS "total_workers"
           FROM "public"."workers" "w"
          GROUP BY "w"."branch_id"
        ), "event_active_workers" AS (
         SELECT "a"."event_id",
            "count"(DISTINCT "a"."user_id") AS "active_worker"
           FROM "public"."attendance" "a"
          WHERE ("a"."event_id" IS NOT NULL)
          GROUP BY "a"."event_id"
        )
 SELECT "e"."id" AS "event_id",
    "e"."created_at" AS "created_time",
    "e"."title",
    "e"."description",
    "e"."featured_url" AS "featured_image",
    COALESCE("eaw"."active_worker", (0)::bigint) AS "active_worker",
    COALESCE("bwt"."total_workers", (0)::bigint) AS "total_workers",
    "e"."isactive" AS "is_active",
    "e"."closed by" AS "closed_by",
    "e"."scope" AS "event_scope",
    "e"."event_date" AS "event_start_date",
    "e"."endtime" AS "event_end_time",
    "e"."latitude" AS "event_latitude",
    "e"."longitude" AS "event_longitude",
    "e"."created_by",
    "e"."branch_id" AS "event_branch_id"
   FROM (("public"."events" "e"
     LEFT JOIN "event_active_workers" "eaw" ON (("eaw"."event_id" = "e"."id")))
     LEFT JOIN "branch_worker_totals" "bwt" ON (("bwt"."branch_id" = "e"."branch_id")));


ALTER VIEW "public"."events_attendance_view" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."global_admins" (
    "id" "uuid" NOT NULL,
    "created_at" timestamp without time zone DEFAULT "now"()
);

ALTER TABLE ONLY "public"."global_admins" FORCE ROW LEVEL SECURITY;


ALTER TABLE "public"."global_admins" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."membershipcode" (
    "memberid" "uuid" NOT NULL,
    "membershipcode" "text" NOT NULL
);

ALTER TABLE ONLY "public"."membershipcode" FORCE ROW LEVEL SECURITY;


ALTER TABLE "public"."membershipcode" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."otp_cooldowns" (
    "membership_code" "text" NOT NULL,
    "last_sent_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."otp_cooldowns" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."penalties" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid",
    "reported_by" "uuid",
    "reason" "text",
    "punishment" "text",
    "active" boolean DEFAULT true,
    "created_at" timestamp without time zone DEFAULT "now"()
);

ALTER TABLE ONLY "public"."penalties" FORCE ROW LEVEL SECURITY;


ALTER TABLE "public"."penalties" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."post_reactions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "post_id" "uuid" NOT NULL,
    "reaction_type" "text" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

ALTER TABLE ONLY "public"."post_reactions" FORCE ROW LEVEL SECURITY;


ALTER TABLE "public"."post_reactions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."posts" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "department_id" "uuid",
    "target_type" "text" DEFAULT 'department'::"text" NOT NULL,
    "title" "text" NOT NULL,
    "body" "text",
    "created_by" "uuid" DEFAULT "auth"."uid"(),
    "modified_by" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "modified_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "is_pinned" boolean DEFAULT false,
    "is_archived" boolean DEFAULT false,
    "reaction_counts" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "comments_count" integer DEFAULT 0,
    "branch_id" "uuid",
    "more" "jsonb" DEFAULT '{}'::"jsonb"
);


ALTER TABLE "public"."posts" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."posts_with_comments" WITH ("security_invoker"='on') AS
 SELECT "p"."id",
    "p"."target_type",
    "p"."branch_id",
    "b"."name" AS "branch_name",
    "p"."department_id",
    "d"."name" AS "department_name",
    "p"."body",
    "p"."created_by",
    "pr_creator"."full_name" AS "created_by_name",
    "p"."modified_by",
    "pr_modifier"."full_name" AS "modified_by_name",
    "p"."created_at",
    "p"."modified_at",
    "p"."is_pinned",
    "p"."reaction_counts" AS "reactions",
    "p"."comments_count",
    "p"."more" AS "post_more",
    "p"."is_archived" AS "post_archived",
    COALESCE(( SELECT "jsonb_agg"("sub"."c_obj" ORDER BY (("sub"."c_obj" ->> 'created_at'::"text"))::timestamp with time zone) AS "jsonb_agg"
           FROM ( SELECT "jsonb_build_object"('id', "c"."id", 'creator_id', "c"."created_by", 'creator', "jsonb_build_object"('name', COALESCE("c"."commentor name", "pr"."full_name")), 'parent_comment_id', "c"."parent_comment_id", 'created_at', "to_char"("c"."created_at", 'YYYY-MM-DD"T"HH24:MI:SSZ'::"text"), 'modified_at', "to_char"("c"."modified_at", 'YYYY-MM-DD"T"HH24:MI:SSZ'::"text"), 'is_edited', "c"."is_edited", 'is_deleted', "c"."is_deleted", 'more', COALESCE("c"."more", '{}'::"jsonb"), 'body', "c"."body") AS "c_obj"
                   FROM ("public"."comments" "c"
                     LEFT JOIN "public"."profiles" "pr" ON (("pr"."id" = "c"."created_by")))
                  WHERE ("c"."post_id" = "p"."id")) "sub"), '[]'::"jsonb") AS "comments"
   FROM (((("public"."posts" "p"
     LEFT JOIN "public"."branches" "b" ON (("b"."id" = "p"."branch_id")))
     LEFT JOIN "public"."departments" "d" ON (("d"."id" = "p"."department_id")))
     LEFT JOIN "public"."profiles" "pr_creator" ON (("pr_creator"."id" = "p"."created_by")))
     LEFT JOIN "public"."profiles" "pr_modifier" ON (("pr_modifier"."id" = "p"."modified_by")));


ALTER VIEW "public"."posts_with_comments" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."profile_attendance_view" AS
 SELECT "a"."id",
    "a"."user_id",
    "a"."event_id",
    "a"."status",
    "a"."latitude",
    "a"."longitude",
    "a"."closedlat",
    "a"."closedlong",
    "a"."created_at",
    "a"."branch_id",
    "a"."department_id",
    "a"."fullname",
    "p"."full_name" AS "profile_full_name",
    "p"."avatar" AS "profile_avatar",
    "p"."department_id" AS "profile_department_id",
    "p"."branch_id" AS "profile_branch_id",
        CASE
            WHEN ("br"."prefix" IS NULL) THEN "p"."membership_code"
            ELSE ("br"."prefix" || "p"."membership_code")
        END AS "profile_membership_code"
   FROM (("public"."attendance" "a"
     LEFT JOIN "public"."profiles" "p" ON (("p"."id" = "a"."user_id")))
     LEFT JOIN "public"."branches" "br" ON (("br"."id" = "p"."branch_id")));


ALTER VIEW "public"."profile_attendance_view" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."profile_view" WITH ("security_invoker"='on') AS
 SELECT "p"."id" AS "user_id",
    "p"."full_name",
    "p"."firstname",
    "p"."lastname",
    "p"."phone",
    "p"."bio",
    "p"."membership_code",
    "p"."branch_id",
    "b"."name" AS "branch_name",
    "b"."id" AS "branch_id_confirm",
    "p"."department_id",
    "d"."name" AS "department_name",
    "d"."id" AS "department_id_confirm",
    "w"."membershipcode" AS "worker_membershipcode"
   FROM ((("public"."profiles" "p"
     LEFT JOIN "public"."branches" "b" ON (("p"."branch_id" = "b"."id")))
     LEFT JOIN "public"."departments" "d" ON (("p"."department_id" = "d"."id")))
     LEFT JOIN "public"."workers" "w" ON (("w"."user_id" = "p"."id")));


ALTER VIEW "public"."profile_view" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."profiles_priv_info" (
    "id" "uuid" DEFAULT "auth"."uid"() NOT NULL,
    "branch_id" "uuid" NOT NULL,
    "department_id" "uuid",
    "role" "text" DEFAULT 'member'::"text",
    "full_name" "text" NOT NULL,
    "phone" "text",
    "bio" "text",
    "membership_code" "text",
    "date_joined" "date" DEFAULT CURRENT_DATE,
    "verified" boolean DEFAULT false,
    "created_at" timestamp without time zone DEFAULT "now"(),
    "dob" "date",
    "occupation" "text",
    "address" "text",
    "email" "text",
    "avatar" "text",
    "lastname" "text",
    "firstname" "text",
    "profilecomplete" boolean DEFAULT false NOT NULL,
    "prefix" "text",
    "date_of_birth" "date",
    "gender" "text",
    "marital_status" "text",
    "phone_number" "text",
    "residential_address" "text",
    "date_joined_wpcc" "date",
    "water_baptism_date" "date",
    "maturity_class_completed" "text",
    "ministry_class_completed" "text",
    "mission_class_completed" "text",
    "emergency_contact" "text",
    CONSTRAINT "profiles_role_check" CHECK (("role" = ANY (ARRAY['member'::"text", 'worker'::"text", 'superuser'::"text", 'admin'::"text", 'globaladmin'::"text"])))
);


ALTER TABLE "public"."profiles_priv_info" OWNER TO "postgres";


COMMENT ON TABLE "public"."profiles_priv_info" IS 'private info of the profiles table';



COMMENT ON COLUMN "public"."profiles_priv_info"."id" IS 'PRIVATE: id';



COMMENT ON COLUMN "public"."profiles_priv_info"."phone" IS 'PRIVATE: phone';



COMMENT ON COLUMN "public"."profiles_priv_info"."dob" IS 'PRIVATE: dob';



COMMENT ON COLUMN "public"."profiles_priv_info"."occupation" IS 'Member occupation';



COMMENT ON COLUMN "public"."profiles_priv_info"."address" IS 'PRIVATE: address';



COMMENT ON COLUMN "public"."profiles_priv_info"."email" IS 'PRIVATE: email';



COMMENT ON COLUMN "public"."profiles_priv_info"."profilecomplete" IS 'PRIVATE: profilecomplete';



COMMENT ON COLUMN "public"."profiles_priv_info"."date_of_birth" IS 'Member''s date of birth (Privileged Information)';



COMMENT ON COLUMN "public"."profiles_priv_info"."gender" IS 'Member gender (M/F)';



COMMENT ON COLUMN "public"."profiles_priv_info"."marital_status" IS 'Member marital status (e.g. Single, Married)';



COMMENT ON COLUMN "public"."profiles_priv_info"."residential_address" IS 'Member residential address (Privileged)';



COMMENT ON COLUMN "public"."profiles_priv_info"."date_joined_wpcc" IS 'The date the member officially joined the church';



COMMENT ON COLUMN "public"."profiles_priv_info"."water_baptism_date" IS 'Date member was water baptized';



COMMENT ON COLUMN "public"."profiles_priv_info"."maturity_class_completed" IS 'Completion status for Maturity Class';



COMMENT ON COLUMN "public"."profiles_priv_info"."ministry_class_completed" IS 'Completion status for Ministry Class';



COMMENT ON COLUMN "public"."profiles_priv_info"."mission_class_completed" IS 'Completion status for Mission Class';



COMMENT ON COLUMN "public"."profiles_priv_info"."emergency_contact" IS 'Emergency contact phone number';



CREATE TABLE IF NOT EXISTS "public"."profileverification" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "memberid" "uuid" NOT NULL,
    "status" boolean DEFAULT false,
    "verifiedby" "uuid"
);

ALTER TABLE ONLY "public"."profileverification" FORCE ROW LEVEL SECURITY;


ALTER TABLE "public"."profileverification" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."recurring_events" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "title" "text" NOT NULL,
    "description" "text",
    "day_of_week" integer NOT NULL,
    "start_time" time without time zone NOT NULL,
    "end_time" time without time zone NOT NULL,
    "is_active" boolean DEFAULT true,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "featured_url" "text",
    "recurrence_type" character varying(10) DEFAULT 'weekly'::character varying NOT NULL,
    "week_of_month" integer,
    "day_of_month" integer,
    "month" integer,
    CONSTRAINT "recurring_events_day_of_month_check" CHECK ((("day_of_month" >= 1) AND ("day_of_month" <= 31))),
    CONSTRAINT "recurring_events_day_of_week_check" CHECK ((("day_of_week" >= 0) AND ("day_of_week" <= 6))),
    CONSTRAINT "recurring_events_month_check" CHECK ((("month" >= 1) AND ("month" <= 12))),
    CONSTRAINT "recurring_events_recurrence_type_check" CHECK ((("recurrence_type")::"text" = ANY ((ARRAY['weekly'::character varying, 'monthly'::character varying, 'yearly'::character varying])::"text"[]))),
    CONSTRAINT "recurring_events_week_of_month_check" CHECK ((("week_of_month" >= 1) AND ("week_of_month" <= 5)))
);


ALTER TABLE "public"."recurring_events" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."roles" (
    "memberid" "uuid" NOT NULL,
    "full_name" "text" NOT NULL,
    "roleid" "uuid" NOT NULL,
    "rolename" "text"
);


ALTER TABLE "public"."roles" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."systemreports" AS
 SELECT 'overview'::"text" AS "report_type",
    "jsonb_build_object"('total_workers', ( SELECT "count"(*) AS "count"
           FROM "public"."workers"), 'total_members', ( SELECT "count"(*) AS "count"
           FROM "public"."profiles"), 'total_departments', ( SELECT "count"(*) AS "count"
           FROM "public"."departments"), 'total_branches', ( SELECT "count"(*) AS "count"
           FROM "public"."branches"), 'upcoming_events', ( SELECT "count"(*) AS "count"
           FROM "public"."events"
          WHERE ("events"."event_date" > "now"())), 'active_workers', ( SELECT "count"(*) AS "count"
           FROM "public"."workers")) AS "data",
    "now"() AS "calculated_at";


ALTER VIEW "public"."systemreports" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."weekly_attendance_summary" WITH ("security_invoker"='on') AS
 SELECT "branch_id",
    "count"(*) AS "total_attendance",
    "count"(DISTINCT "user_id") AS "unique_attendees",
    "date_trunc"('week'::"text", "created_at") AS "week_start"
   FROM "public"."attendance"
  GROUP BY "branch_id", ("date_trunc"('week'::"text", "created_at"));


ALTER VIEW "public"."weekly_attendance_summary" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."weekly_branch_stats" WITH ("security_invoker"='on') AS
 SELECT "p"."branch_id",
    "count"(DISTINCT "a"."user_id") AS "workers_attended",
    "count"(DISTINCT "e"."id") AS "events_this_week"
   FROM (("public"."events" "e"
     LEFT JOIN "public"."attendance" "a" ON ((("a"."event_id" = "e"."id") AND ("a"."status" = 'confirmed'::"text"))))
     LEFT JOIN "public"."profiles" "p" ON (("p"."id" = "a"."user_id")))
  WHERE ("e"."event_date" >= "date_trunc"('week'::"text", "now"()))
  GROUP BY "p"."branch_id";


ALTER VIEW "public"."weekly_branch_stats" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."worker_profiles" WITH ("security_invoker"='on') AS
 SELECT "w"."id" AS "worker_id",
    "w"."user_id",
    "w"."branch_id",
    "b"."name" AS "branch_name",
    "w"."department_id",
    "d"."name" AS "department_name",
        CASE
            WHEN ("b"."prefix" IS NULL) THEN "w"."membershipcode"
            ELSE ("b"."prefix" || "w"."membershipcode")
        END AS "worker_membershipcode",
    "w"."created_at" AS "worker_created_at",
    "p"."id" AS "profile_id",
    "p"."full_name",
    "p"."phone",
    "p"."bio",
    "p"."membership_code" AS "profile_membership_code",
    "p"."date_joined",
    "p"."verified",
    "p"."avatar",
    "p"."lastname",
    "p"."firstname",
    "p"."created_at" AS "profile_created_at"
   FROM ((("public"."workers" "w"
     LEFT JOIN "public"."profiles" "p" ON (("p"."id" = "w"."user_id")))
     LEFT JOIN "public"."branches" "b" ON (("b"."id" = "w"."branch_id")))
     LEFT JOIN "public"."departments" "d" ON (("d"."id" = "w"."department_id")));


ALTER VIEW "public"."worker_profiles" OWNER TO "postgres";


ALTER TABLE ONLY "public"."announcements"
    ADD CONSTRAINT "announcements_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."attendance_audit_logs"
    ADD CONSTRAINT "attendance_audit_logs_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."attendance"
    ADD CONSTRAINT "attendance_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."attendance"
    ADD CONSTRAINT "attendance_user_event_unique" UNIQUE ("user_id", "event_id");



ALTER TABLE ONLY "public"."branches"
    ADD CONSTRAINT "branches_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."branches"
    ADD CONSTRAINT "branches_slug_key" UNIQUE ("slug");



ALTER TABLE ONLY "public"."comments"
    ADD CONSTRAINT "comments_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."course_enrollments"
    ADD CONSTRAINT "course_enrollments_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."courses"
    ADD CONSTRAINT "courses_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."department_requests"
    ADD CONSTRAINT "department_requests_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."departments"
    ADD CONSTRAINT "departments_name_key" UNIQUE ("name");



ALTER TABLE ONLY "public"."departments"
    ADD CONSTRAINT "departments_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."events"
    ADD CONSTRAINT "events_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."global_admins"
    ADD CONSTRAINT "global_admins_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."leaders"
    ADD CONSTRAINT "leaders_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."leadership_titles"
    ADD CONSTRAINT "leadership_titles_code_key" UNIQUE ("code");



ALTER TABLE ONLY "public"."leadership_titles"
    ADD CONSTRAINT "leadership_titles_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."membershipcode"
    ADD CONSTRAINT "membershipcode_pkey" PRIMARY KEY ("memberid");



ALTER TABLE ONLY "public"."otp_cooldowns"
    ADD CONSTRAINT "otp_cooldowns_pkey" PRIMARY KEY ("membership_code");



ALTER TABLE ONLY "public"."penalties"
    ADD CONSTRAINT "penalties_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."post_reactions"
    ADD CONSTRAINT "post_reactions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."post_reactions"
    ADD CONSTRAINT "post_reactions_post_id_user_id_reaction_type_key" UNIQUE ("post_id", "user_id", "reaction_type");



ALTER TABLE ONLY "public"."posts"
    ADD CONSTRAINT "posts_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_full_name_key" UNIQUE ("full_name");



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_membership_code_key" UNIQUE ("membership_code");



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."profiles_priv_info"
    ADD CONSTRAINT "profiles_priv_info_full_name_key" UNIQUE ("full_name");



ALTER TABLE ONLY "public"."profiles_priv_info"
    ADD CONSTRAINT "profiles_priv_info_membership_code_key" UNIQUE ("membership_code");



ALTER TABLE ONLY "public"."profiles_priv_info"
    ADD CONSTRAINT "profiles_priv_info_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."profileverification"
    ADD CONSTRAINT "profileverification_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."recurring_events"
    ADD CONSTRAINT "recurring_events_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."roles"
    ADD CONSTRAINT "roles_pkey" PRIMARY KEY ("memberid");



ALTER TABLE ONLY "public"."roletypes"
    ADD CONSTRAINT "roletypes_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."roletypes"
    ADD CONSTRAINT "roletypes_rolename_key" UNIQUE ("rolename");



ALTER TABLE ONLY "public"."attendance"
    ADD CONSTRAINT "unique_user_event_dept" UNIQUE NULLS NOT DISTINCT ("user_id", "event_id", "department_id");



COMMENT ON CONSTRAINT "unique_user_event_dept" ON "public"."attendance" IS 'Business Rule: A user can only have one attendance record per department per event ID. Used to prevent duplicate check-ins for the same department.';



ALTER TABLE ONLY "public"."workers"
    ADD CONSTRAINT "workers_pkey" PRIMARY KEY ("id");



CREATE INDEX "events_branch_id_idx" ON "public"."events" USING "btree" ("branch_id");



CREATE UNIQUE INDEX "events_recurring_event_id_event_date_key" ON "public"."events" USING "btree" ("recurring_event_id", "event_date");



CREATE INDEX "idx_announcements_branch_id" ON "public"."announcements" USING "btree" ("branch_id");



CREATE INDEX "idx_announcements_created_by" ON "public"."announcements" USING "btree" ("created_by");



CREATE INDEX "idx_announcements_department_id" ON "public"."announcements" USING "btree" ("department_id");



CREATE INDEX "idx_attendance_branch_department" ON "public"."attendance" USING "btree" ("branch_id", "department_id");



CREATE INDEX "idx_attendance_event_id" ON "public"."attendance" USING "btree" ("event_id");



CREATE INDEX "idx_attendance_user_id" ON "public"."attendance" USING "btree" ("user_id");



CREATE INDEX "idx_comments_created_by" ON "public"."comments" USING "btree" ("created_by");



CREATE INDEX "idx_comments_parent" ON "public"."comments" USING "btree" ("parent_comment_id");



CREATE INDEX "idx_comments_post_id" ON "public"."comments" USING "btree" ("post_id");



CREATE INDEX "idx_course_enrollments_course_id" ON "public"."course_enrollments" USING "btree" ("course_id");



CREATE INDEX "idx_course_enrollments_user_id" ON "public"."course_enrollments" USING "btree" ("user_id");



CREATE INDEX "idx_department_requests_department_id" ON "public"."department_requests" USING "btree" ("department_id");



CREATE INDEX "idx_department_requests_user_id" ON "public"."department_requests" USING "btree" ("user_id");



CREATE INDEX "idx_leaders_branch_id" ON "public"."leaders" USING "btree" ("branch_id");



CREATE INDEX "idx_leaders_department_id" ON "public"."leaders" USING "btree" ("department_id");



CREATE INDEX "idx_leaders_user_id" ON "public"."leaders" USING "btree" ("user_id");



CREATE INDEX "idx_penalties_reported_by" ON "public"."penalties" USING "btree" ("reported_by");



CREATE INDEX "idx_penalties_user_id" ON "public"."penalties" USING "btree" ("user_id");



CREATE INDEX "idx_post_reactions_post" ON "public"."post_reactions" USING "btree" ("post_id");



CREATE INDEX "idx_post_reactions_type" ON "public"."post_reactions" USING "btree" ("reaction_type");



CREATE INDEX "idx_post_reactions_user" ON "public"."post_reactions" USING "btree" ("user_id");



CREATE INDEX "idx_posts_branch_department" ON "public"."posts" USING "btree" ("branch_id", "department_id");



CREATE INDEX "idx_posts_branch_id" ON "public"."posts" USING "btree" ("branch_id");



CREATE INDEX "idx_posts_created_at" ON "public"."posts" USING "btree" ("created_at" DESC);



CREATE INDEX "idx_posts_created_by" ON "public"."posts" USING "btree" ("created_by");



CREATE INDEX "idx_posts_department_id" ON "public"."posts" USING "btree" ("department_id");



CREATE INDEX "idx_posts_id" ON "public"."posts" USING "btree" ("id");



CREATE INDEX "idx_posts_modified_by" ON "public"."posts" USING "btree" ("modified_by");



CREATE INDEX "idx_posts_target" ON "public"."posts" USING "btree" ("department_id", "target_type");



CREATE INDEX "idx_posts_target_type_id_created_at" ON "public"."posts" USING "btree" ("target_type", "department_id", "created_at" DESC);



CREATE INDEX "idx_profiles_branch_id" ON "public"."profiles" USING "btree" ("branch_id");



CREATE INDEX "idx_profiles_department_id" ON "public"."profiles" USING "btree" ("department_id");



CREATE INDEX "idx_profiles_id" ON "public"."profiles" USING "btree" ("id");



CREATE INDEX "idx_profileverification_memberid" ON "public"."profileverification" USING "btree" ("memberid");



CREATE INDEX "idx_profileverification_verifiedby" ON "public"."profileverification" USING "btree" ("verifiedby");



CREATE INDEX "idx_roles_memberid" ON "public"."roles" USING "btree" ("memberid");



CREATE INDEX "idx_roles_roleid" ON "public"."roles" USING "btree" ("roleid");



CREATE INDEX "idx_roles_rolename" ON "public"."roles" USING "btree" ("rolename");



CREATE INDEX "idx_workers_department_id" ON "public"."workers" USING "btree" ("department_id");



CREATE UNIQUE INDEX "leaders_one_active_assignment_per_user_idx" ON "public"."leaders" USING "btree" ("user_id") WHERE ("is_active" = true);



CREATE INDEX "leaders_title_id_idx" ON "public"."leaders" USING "btree" ("title_id");



CREATE INDEX "leadership_titles_parent_role_id_idx" ON "public"."leadership_titles" USING "btree" ("parent_role_id");



CREATE INDEX "profiles_priv_info_branch_id_idx" ON "public"."profiles_priv_info" USING "btree" ("branch_id");



CREATE INDEX "profiles_priv_info_department_id_idx" ON "public"."profiles_priv_info" USING "btree" ("department_id");



CREATE INDEX "profiles_priv_info_role_branch_id_department_id_idx" ON "public"."profiles_priv_info" USING "btree" ("role", "branch_id", "department_id");



CREATE INDEX "recurring_events_active_schedule_idx" ON "public"."recurring_events" USING "btree" ("recurrence_type", "day_of_week", "day_of_month", "month") WHERE ("is_active" IS TRUE);



CREATE UNIQUE INDEX "ux_post_reactions_post_user" ON "public"."post_reactions" USING "btree" ("post_id", "user_id");



CREATE INDEX "workers_branch_id_idx" ON "public"."workers" USING "btree" ("branch_id");



CREATE INDEX "workers_user_id_idx" ON "public"."workers" USING "btree" ("user_id");



CREATE OR REPLACE TRIGGER "leaders_role_sync" AFTER INSERT OR DELETE OR UPDATE ON "public"."leaders" FOR EACH ROW EXECUTE FUNCTION "public"."handle_leaders_role_sync"();



CREATE OR REPLACE TRIGGER "profiles_prevent_forbidden_inserts_trg" BEFORE INSERT ON "public"."profiles" FOR EACH ROW EXECUTE FUNCTION "public"."profiles_prevent_forbidden_inserts"();



CREATE OR REPLACE TRIGGER "profiles_prevent_forbidden_updates_trg" BEFORE UPDATE ON "public"."profiles" FOR EACH ROW EXECUTE FUNCTION "public"."profiles_prevent_forbidden_updates"();



CREATE OR REPLACE TRIGGER "profiles_sync_trigger" AFTER INSERT ON "public"."profiles" FOR EACH ROW EXECUTE FUNCTION "public"."profiles_to_roles_sync"();



CREATE OR REPLACE TRIGGER "roles_sync_trigger" AFTER INSERT OR UPDATE ON "public"."roles" FOR EACH ROW EXECUTE FUNCTION "public"."roles_to_profiles_sync"();



CREATE OR REPLACE TRIGGER "sync_user_metadata_trigger" AFTER INSERT OR UPDATE OF "role", "branch_id" ON "public"."profiles_priv_info" FOR EACH ROW EXECUTE FUNCTION "public"."sync_user_metadata"();



CREATE OR REPLACE TRIGGER "tr_restrict_early_clockout" BEFORE INSERT OR UPDATE ON "public"."attendance" FOR EACH ROW EXECUTE FUNCTION "public"."restrict_early_clockout"();



CREATE OR REPLACE TRIGGER "tr_sync_worker_department" AFTER INSERT OR UPDATE OF "department_id" ON "public"."workers" FOR EACH ROW EXECUTE FUNCTION "public"."sync_worker_department"();



CREATE OR REPLACE TRIGGER "trg_branches_prefix_sync" AFTER UPDATE OF "prefix" ON "public"."branches" FOR EACH ROW EXECUTE FUNCTION "public"."sync_branch_prefix"();



CREATE OR REPLACE TRIGGER "trg_membership_code_sync" AFTER INSERT OR UPDATE OF "membershipcode" ON "public"."membershipcode" FOR EACH ROW EXECUTE FUNCTION "public"."sync_membership_code"();



CREATE OR REPLACE TRIGGER "trg_profiles_prefix_init" BEFORE INSERT OR UPDATE OF "branch_id" ON "public"."profiles" FOR EACH ROW EXECUTE FUNCTION "public"."sync_branch_prefix"();



CREATE OR REPLACE TRIGGER "trg_profiles_priv_prefix_init" BEFORE INSERT OR UPDATE OF "branch_id" ON "public"."profiles_priv_info" FOR EACH ROW EXECUTE FUNCTION "public"."sync_branch_prefix"();



CREATE OR REPLACE TRIGGER "trg_role_sync" AFTER INSERT OR UPDATE OF "rolename" ON "public"."roles" FOR EACH ROW EXECUTE FUNCTION "public"."sync_user_role"();



CREATE OR REPLACE TRIGGER "trg_verification_sync" AFTER INSERT OR UPDATE OF "verified" ON "public"."profiles_priv_info" FOR EACH ROW EXECUTE FUNCTION "public"."sync_profile_verification"();



ALTER TABLE ONLY "public"."announcements"
    ADD CONSTRAINT "announcements_branch_id_fkey" FOREIGN KEY ("branch_id") REFERENCES "public"."branches"("id");



ALTER TABLE ONLY "public"."announcements"
    ADD CONSTRAINT "announcements_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "public"."profiles"("id");



ALTER TABLE ONLY "public"."announcements"
    ADD CONSTRAINT "announcements_department_id_fkey" FOREIGN KEY ("department_id") REFERENCES "public"."departments"("id");



ALTER TABLE ONLY "public"."attendance_audit_logs"
    ADD CONSTRAINT "attendance_audit_logs_event_id_fkey" FOREIGN KEY ("event_id") REFERENCES "public"."events"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."attendance_audit_logs"
    ADD CONSTRAINT "attendance_audit_logs_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."attendance"
    ADD CONSTRAINT "attendance_event_id_fkey" FOREIGN KEY ("event_id") REFERENCES "public"."events"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."attendance"
    ADD CONSTRAINT "attendance_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id");



ALTER TABLE ONLY "public"."comments"
    ADD CONSTRAINT "comments_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "public"."profiles"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."comments"
    ADD CONSTRAINT "comments_parent_comment_id_fkey" FOREIGN KEY ("parent_comment_id") REFERENCES "public"."comments"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."comments"
    ADD CONSTRAINT "comments_post_id_fkey" FOREIGN KEY ("post_id") REFERENCES "public"."posts"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."course_enrollments"
    ADD CONSTRAINT "course_enrollments_course_id_fkey" FOREIGN KEY ("course_id") REFERENCES "public"."courses"("id");



ALTER TABLE ONLY "public"."course_enrollments"
    ADD CONSTRAINT "course_enrollments_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id");



ALTER TABLE ONLY "public"."department_requests"
    ADD CONSTRAINT "department_requests_department_id_fkey" FOREIGN KEY ("department_id") REFERENCES "public"."departments"("id");



ALTER TABLE ONLY "public"."department_requests"
    ADD CONSTRAINT "department_requests_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."events"
    ADD CONSTRAINT "events_branch_id_fkey" FOREIGN KEY ("branch_id") REFERENCES "public"."branches"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."events"
    ADD CONSTRAINT "events_recurring_event_id_fkey" FOREIGN KEY ("recurring_event_id") REFERENCES "public"."recurring_events"("id") ON UPDATE CASCADE ON DELETE SET NULL;



ALTER TABLE ONLY "public"."global_admins"
    ADD CONSTRAINT "global_admins_id_fkey" FOREIGN KEY ("id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."leaders"
    ADD CONSTRAINT "leaders_branch_id_fkey" FOREIGN KEY ("branch_id") REFERENCES "public"."branches"("id");



ALTER TABLE ONLY "public"."leaders"
    ADD CONSTRAINT "leaders_department_id_fkey" FOREIGN KEY ("department_id") REFERENCES "public"."departments"("id");



ALTER TABLE ONLY "public"."leaders"
    ADD CONSTRAINT "leaders_title_id_fkey" FOREIGN KEY ("title_id") REFERENCES "public"."leadership_titles"("id") ON UPDATE CASCADE ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."leaders"
    ADD CONSTRAINT "leaders_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."leadership_titles"
    ADD CONSTRAINT "leadership_titles_parent_role_id_fkey" FOREIGN KEY ("parent_role_id") REFERENCES "public"."roletypes"("id") ON UPDATE CASCADE ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."membershipcode"
    ADD CONSTRAINT "membershipcode_memberid_fkey" FOREIGN KEY ("memberid") REFERENCES "public"."profiles"("id");



ALTER TABLE ONLY "public"."penalties"
    ADD CONSTRAINT "penalties_reported_by_fkey" FOREIGN KEY ("reported_by") REFERENCES "public"."profiles"("id");



ALTER TABLE ONLY "public"."penalties"
    ADD CONSTRAINT "penalties_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id");



ALTER TABLE ONLY "public"."post_reactions"
    ADD CONSTRAINT "post_reactions_post_id_fkey" FOREIGN KEY ("post_id") REFERENCES "public"."posts"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."post_reactions"
    ADD CONSTRAINT "post_reactions_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."posts"
    ADD CONSTRAINT "posts_branch_id_fkey" FOREIGN KEY ("branch_id") REFERENCES "public"."branches"("id");



ALTER TABLE ONLY "public"."posts"
    ADD CONSTRAINT "posts_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "public"."profiles"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."posts"
    ADD CONSTRAINT "posts_modified_by_fkey" FOREIGN KEY ("modified_by") REFERENCES "public"."profiles"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_branch_id_fkey" FOREIGN KEY ("branch_id") REFERENCES "public"."branches"("id");



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_department_id_fkey" FOREIGN KEY ("department_id") REFERENCES "public"."departments"("id");



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_id_fkey" FOREIGN KEY ("id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."profiles_priv_info"
    ADD CONSTRAINT "profiles_priv_info_branch_id_fkey" FOREIGN KEY ("branch_id") REFERENCES "public"."branches"("id");



ALTER TABLE ONLY "public"."profiles_priv_info"
    ADD CONSTRAINT "profiles_priv_info_department_id_fkey" FOREIGN KEY ("department_id") REFERENCES "public"."departments"("id");



ALTER TABLE ONLY "public"."profiles_priv_info"
    ADD CONSTRAINT "profiles_priv_info_id_fkey" FOREIGN KEY ("id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."profileverification"
    ADD CONSTRAINT "profileverification_memberid_fkey" FOREIGN KEY ("memberid") REFERENCES "public"."profiles"("id");



ALTER TABLE ONLY "public"."profileverification"
    ADD CONSTRAINT "profileverification_verifiedby_fkey" FOREIGN KEY ("verifiedby") REFERENCES "public"."roles"("memberid");



ALTER TABLE ONLY "public"."roles"
    ADD CONSTRAINT "roles_memberid_fkey" FOREIGN KEY ("memberid") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."roles"
    ADD CONSTRAINT "roles_roleid_fkey" FOREIGN KEY ("roleid") REFERENCES "public"."roletypes"("id");



ALTER TABLE ONLY "public"."roles"
    ADD CONSTRAINT "roles_rolename_fkey" FOREIGN KEY ("rolename") REFERENCES "public"."roletypes"("rolename");



ALTER TABLE ONLY "public"."workers"
    ADD CONSTRAINT "workers_branch_id_fkey" FOREIGN KEY ("branch_id") REFERENCES "public"."branches"("id");



ALTER TABLE ONLY "public"."workers"
    ADD CONSTRAINT "workers_department_id_fkey" FOREIGN KEY ("department_id") REFERENCES "public"."departments"("id");



ALTER TABLE ONLY "public"."workers"
    ADD CONSTRAINT "workers_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



CREATE POLICY "Enable read access for all users" ON "public"."departments" FOR SELECT USING (true);



ALTER TABLE "public"."attendance" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "attendance_audit_insert_own" ON "public"."attendance_audit_logs" FOR INSERT TO "authenticated" WITH CHECK (("user_id" = "auth"."uid"()));



ALTER TABLE "public"."attendance_audit_logs" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "attendance_unified_delete" ON "public"."attendance" FOR DELETE TO "authenticated" USING (((( SELECT ("auth"."jwt"() ->> 'wprole'::"text")) = 'globaladmin'::"text") OR (( SELECT "auth"."uid"() AS "uid") = "user_id")));



CREATE POLICY "attendance_unified_insert" ON "public"."attendance" FOR INSERT TO "authenticated" WITH CHECK (((( SELECT "auth"."uid"() AS "uid") = "user_id") OR (( SELECT ("auth"."jwt"() ->> 'wprole'::"text")) = 'globaladmin'::"text") OR ((( SELECT ("auth"."jwt"() ->> 'wprole'::"text")) = 'admin'::"text") AND (("branch_id" = (( SELECT ("auth"."jwt"() ->> 'wpbranch_id'::"text")))::"uuid") OR ("department_id" = (( SELECT ("auth"."jwt"() ->> 'wpdept_id'::"text")))::"uuid"))) OR ((( SELECT ("auth"."jwt"() ->> 'wprole'::"text")) = 'superuser'::"text") AND ("department_id" = (( SELECT ("auth"."jwt"() ->> 'wpdept_id'::"text")))::"uuid") AND ("branch_id" = (( SELECT ("auth"."jwt"() ->> 'wpbranch_id'::"text")))::"uuid"))));



CREATE POLICY "attendance_unified_select" ON "public"."attendance" FOR SELECT TO "authenticated" USING (((( SELECT "auth"."uid"() AS "uid") = "user_id") OR (( SELECT ("auth"."jwt"() ->> 'wprole'::"text")) = 'globaladmin'::"text") OR ((( SELECT ("auth"."jwt"() ->> 'wprole'::"text")) = ANY (ARRAY['admin'::"text", 'superuser'::"text", 'worker'::"text"])) AND ("branch_id" = (( SELECT ("auth"."jwt"() ->> 'wpbranch_id'::"text")))::"uuid"))));



CREATE POLICY "attendance_unified_update" ON "public"."attendance" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (((( SELECT "auth"."uid"() AS "uid") = "user_id") OR (( SELECT ("auth"."jwt"() ->> 'wprole'::"text")) = 'globaladmin'::"text")));



ALTER TABLE "public"."branches" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "branches_unified_select" ON "public"."branches" FOR SELECT TO "authenticated" USING (true);



ALTER TABLE "public"."comments" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "comments_unified_insert" ON "public"."comments" FOR INSERT TO "authenticated" WITH CHECK (((( SELECT ("auth"."jwt"() ->> 'wprole'::"text")) = 'globaladmin'::"text") OR (EXISTS ( SELECT 1
   FROM "public"."posts" "p"
  WHERE (("p"."id" = "comments"."post_id") AND ("p"."branch_id" = (( SELECT ("auth"."jwt"() ->> 'wpbranch_id'::"text")))::"uuid"))))));



CREATE POLICY "comments_unified_select" ON "public"."comments" FOR SELECT TO "authenticated" USING (((( SELECT ("auth"."jwt"() ->> 'wprole'::"text")) = 'globaladmin'::"text") OR ("created_by" = ( SELECT "auth"."uid"() AS "uid")) OR (EXISTS ( SELECT 1
   FROM "public"."posts" "p"
  WHERE (("p"."id" = "comments"."post_id") AND (("p"."target_type" = 'global'::"text") OR ("p"."branch_id" = (( SELECT ("auth"."jwt"() ->> 'wpbranch_id'::"text")))::"uuid")))))));



ALTER TABLE "public"."department_requests" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."departments" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."events" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "events_unified_insert" ON "public"."events" FOR INSERT TO "authenticated" WITH CHECK ((( SELECT ("auth"."jwt"() ->> 'wprole'::"text")) = ANY (ARRAY['admin'::"text", 'globaladmin'::"text"])));



CREATE POLICY "events_unified_select" ON "public"."events" FOR SELECT TO "authenticated" USING ((("scope" = 'global'::"text") OR ("branch_id" = (( SELECT ("auth"."jwt"() ->> 'wpbranch_id'::"text")))::"uuid")));



ALTER TABLE "public"."leadership_titles" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "leadership_titles_select_authenticated" ON "public"."leadership_titles" FOR SELECT TO "authenticated" USING (true);



ALTER TABLE "public"."membershipcode" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."otp_cooldowns" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."posts" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "posts_unified_delete" ON "public"."posts" FOR DELETE TO "authenticated" USING (((( SELECT ("auth"."jwt"() ->> 'wprole'::"text")) = 'globaladmin'::"text") OR ("created_by" = ( SELECT "auth"."uid"() AS "uid")) OR ((( SELECT ("auth"."jwt"() ->> 'wprole'::"text")) = 'admin'::"text") AND ("branch_id" = (( SELECT ("auth"."jwt"() ->> 'wpbranch_id'::"text")))::"uuid"))));



CREATE POLICY "posts_unified_insert" ON "public"."posts" FOR INSERT TO "authenticated" WITH CHECK (((( SELECT ("auth"."jwt"() ->> 'wprole'::"text")) = 'globaladmin'::"text") OR ((( SELECT ("auth"."jwt"() ->> 'wprole'::"text")) = 'admin'::"text") AND ("branch_id" = (( SELECT ("auth"."jwt"() ->> 'wpbranch_id'::"text")))::"uuid")) OR ((( SELECT ("auth"."jwt"() ->> 'wprole'::"text")) = ANY (ARRAY['superuser'::"text", 'worker'::"text"])) AND ("branch_id" = (( SELECT ("auth"."jwt"() ->> 'wpbranch_id'::"text")))::"uuid") AND ("department_id" = (( SELECT ("auth"."jwt"() ->> 'wpdept_id'::"text")))::"uuid"))));



CREATE POLICY "posts_unified_select" ON "public"."posts" FOR SELECT TO "authenticated" USING (((( SELECT ("auth"."jwt"() ->> 'wprole'::"text")) = 'globaladmin'::"text") OR (( SELECT "auth"."uid"() AS "uid") = "created_by") OR ("target_type" = 'global'::"text") OR ((( SELECT ("auth"."jwt"() ->> 'wprole'::"text")) = ANY (ARRAY['admin'::"text", 'superuser'::"text", 'worker'::"text", 'member'::"text"])) AND ("branch_id" = (( SELECT ("auth"."jwt"() ->> 'wpbranch_id'::"text")))::"uuid"))));



CREATE POLICY "posts_unified_update" ON "public"."posts" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (((( SELECT ("auth"."jwt"() ->> 'wprole'::"text")) = 'globaladmin'::"text") OR ("created_by" = ( SELECT "auth"."uid"() AS "uid")) OR ((( SELECT ("auth"."jwt"() ->> 'wprole'::"text")) = 'admin'::"text") AND ("branch_id" = (( SELECT ("auth"."jwt"() ->> 'wpbranch_id'::"text")))::"uuid"))));



ALTER TABLE "public"."profiles" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."profiles_priv_info" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "profiles_priv_info_unified_select" ON "public"."profiles_priv_info" FOR SELECT TO "authenticated" USING (((( SELECT "auth"."uid"() AS "uid") = "id") OR (( SELECT "public"."get_my_role"() AS "get_my_role") = 'globaladmin'::"text") OR ((( SELECT "public"."get_my_role"() AS "get_my_role") = ANY (ARRAY['admin'::"text", 'superuser'::"text", 'worker'::"text"])) AND ("branch_id" = ( SELECT "public"."get_my_branch_id"() AS "get_my_branch_id")))));



CREATE POLICY "profiles_unified_delete" ON "public"."profiles" FOR DELETE TO "authenticated" USING (((( SELECT "auth"."uid"() AS "uid") = "id") OR (( SELECT ("auth"."jwt"() ->> 'wprole'::"text")) = 'globaladmin'::"text") OR ((( SELECT ("auth"."jwt"() ->> 'wprole'::"text")) = 'admin'::"text") AND (("branch_id")::"text" = ( SELECT ("auth"."jwt"() ->> 'wpbranch_id'::"text"))))));



CREATE POLICY "profiles_unified_insert" ON "public"."profiles" FOR INSERT TO "authenticated" WITH CHECK (((( SELECT ("auth"."jwt"() ->> 'wprole'::"text")) = 'globaladmin'::"text") OR ("id" = ( SELECT "auth"."uid"() AS "uid")) OR ((( SELECT ("auth"."jwt"() ->> 'wprole'::"text")) = 'admin'::"text") AND (("branch_id")::"text" = ( SELECT ("auth"."jwt"() ->> 'wpbranch_id'::"text")))) OR ((( SELECT ("auth"."jwt"() ->> 'wprole'::"text")) = 'superuser'::"text") AND ((("department_id")::"text" = ( SELECT ("auth"."jwt"() ->> 'wpdept_id'::"text"))) OR (("branch_id")::"text" = ( SELECT ("auth"."jwt"() ->> 'wpbranch_id'::"text")))))));



CREATE POLICY "profiles_unified_select" ON "public"."profiles" FOR SELECT TO "authenticated" USING (((( SELECT "auth"."uid"() AS "uid") = "id") OR (( SELECT ("auth"."jwt"() ->> 'wprole'::"text")) = 'globaladmin'::"text") OR ((( SELECT ("auth"."jwt"() ->> 'wprole'::"text")) = ANY (ARRAY['admin'::"text", 'superuser'::"text", 'worker'::"text"])) AND (("branch_id")::"text" = ( SELECT ("auth"."jwt"() ->> 'wpbranch_id'::"text"))))));



CREATE POLICY "profiles_unified_update" ON "public"."profiles" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (((( SELECT ("auth"."jwt"() ->> 'wprole'::"text")) = 'globaladmin'::"text") OR ("id" = ( SELECT "auth"."uid"() AS "uid")) OR ((( SELECT ("auth"."jwt"() ->> 'wprole'::"text")) = 'admin'::"text") AND (("branch_id")::"text" = ( SELECT ("auth"."jwt"() ->> 'wpbranch_id'::"text")))) OR ((( SELECT ("auth"."jwt"() ->> 'wprole'::"text")) = 'superuser'::"text") AND ((("department_id")::"text" = ( SELECT ("auth"."jwt"() ->> 'wpdept_id'::"text"))) OR (("branch_id")::"text" = ( SELECT ("auth"."jwt"() ->> 'wpbranch_id'::"text")))))));



ALTER TABLE "public"."recurring_events" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "recurring_events_unified_insert" ON "public"."recurring_events" FOR INSERT TO "authenticated" WITH CHECK ((("auth"."jwt"() ->> 'wprole'::"text") = ANY (ARRAY['admin'::"text", 'globaladmin'::"text"])));



CREATE POLICY "recurring_events_unified_select" ON "public"."recurring_events" FOR SELECT TO "authenticated" USING (true);



ALTER TABLE "public"."roles" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."roletypes" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."workers" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "workers_select_policy" ON "public"."workers" FOR SELECT TO "authenticated" USING ((("public"."get_my_role"() = 'globaladmin'::"text") OR (("public"."get_my_role"() = ANY (ARRAY['admin'::"text", 'superuser'::"text", 'worker'::"text"])) AND ("branch_id" = "public"."get_my_branch_id"()))));





ALTER PUBLICATION "supabase_realtime" OWNER TO "postgres";









GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";


















































































































































































































GRANT ALL ON FUNCTION "public"."add_fullname_top_level_claim"("event" "jsonb") TO "service_role";
GRANT ALL ON FUNCTION "public"."add_fullname_top_level_claim"("event" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."add_fullname_top_level_claim"("event" "jsonb") TO "anon";



REVOKE ALL ON FUNCTION "public"."add_wp_info_to_jwt"("event" "jsonb") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."add_wp_info_to_jwt"("event" "jsonb") TO "service_role";
GRANT ALL ON FUNCTION "public"."add_wp_info_to_jwt"("event" "jsonb") TO "supabase_auth_admin";



REVOKE ALL ON FUNCTION "public"."assign_membership_code"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."assign_membership_code"() TO "anon";
GRANT ALL ON FUNCTION "public"."assign_membership_code"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."assign_membership_code"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."create_role_for_new_user"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."create_role_for_new_user"() TO "anon";
GRANT ALL ON FUNCTION "public"."create_role_for_new_user"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_role_for_new_user"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."current_user_branch"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."current_user_branch"() TO "anon";
GRANT ALL ON FUNCTION "public"."current_user_branch"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."current_user_branch"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."fn_sync_comments_count"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."fn_sync_comments_count"() TO "anon";
GRANT ALL ON FUNCTION "public"."fn_sync_comments_count"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."fn_sync_comments_count"() TO "service_role";



GRANT ALL ON FUNCTION "public"."get_current_rolename"() TO "service_role";



GRANT ALL ON FUNCTION "public"."get_current_user_branch"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."get_current_user_context"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."get_current_user_context"() TO "service_role";



GRANT ALL ON FUNCTION "public"."get_current_user_department"() TO "anon";
GRANT ALL ON FUNCTION "public"."get_current_user_department"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_current_user_department"() TO "service_role";



GRANT ALL ON FUNCTION "public"."get_current_user_id"() TO "anon";
GRANT ALL ON FUNCTION "public"."get_current_user_id"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_current_user_id"() TO "service_role";



GRANT ALL ON FUNCTION "public"."get_current_user_role"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."get_my_branch"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."get_my_branch"() TO "service_role";



GRANT ALL ON FUNCTION "public"."get_my_branch_id"() TO "anon";
GRANT ALL ON FUNCTION "public"."get_my_branch_id"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_my_branch_id"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."get_my_department"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."get_my_department"() TO "anon";
GRANT ALL ON FUNCTION "public"."get_my_department"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_my_department"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."get_my_role"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."get_my_role"() TO "anon";
GRANT ALL ON FUNCTION "public"."get_my_role"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_my_role"() TO "service_role";



GRANT ALL ON FUNCTION "public"."get_profiles_view"() TO "anon";
GRANT ALL ON FUNCTION "public"."get_profiles_view"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_profiles_view"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."get_user_branch"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."get_user_branch"() TO "service_role";



GRANT ALL ON FUNCTION "public"."get_user_branch_id"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."get_user_department"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."get_user_department"() TO "anon";
GRANT ALL ON FUNCTION "public"."get_user_department"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_user_department"() TO "service_role";



GRANT ALL ON FUNCTION "public"."get_user_department_id"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."get_user_role"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."get_user_role"() TO "anon";
GRANT ALL ON FUNCTION "public"."get_user_role"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_user_role"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."handle_leaders_role_sync"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."handle_leaders_role_sync"() TO "service_role";



GRANT ALL ON FUNCTION "public"."is_admin"() TO "anon";
GRANT ALL ON FUNCTION "public"."is_admin"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."is_admin"() TO "service_role";



GRANT ALL ON FUNCTION "public"."is_admin_or_global"() TO "anon";
GRANT ALL ON FUNCTION "public"."is_admin_or_global"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."is_admin_or_global"() TO "service_role";



GRANT ALL ON FUNCTION "public"."is_globaladmin"() TO "anon";
GRANT ALL ON FUNCTION "public"."is_globaladmin"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."is_globaladmin"() TO "service_role";



GRANT ALL ON FUNCTION "public"."is_self"("target_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."is_self"("target_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."is_self"("target_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."posts_current_branch"("p_post_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."posts_current_department"("p_post_id" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."posts_reaction_counts_sync"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."posts_reaction_counts_sync"() TO "anon";
GRANT ALL ON FUNCTION "public"."posts_reaction_counts_sync"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."posts_reaction_counts_sync"() TO "service_role";



GRANT ALL ON FUNCTION "public"."profiles_prevent_forbidden_inserts"() TO "anon";
GRANT ALL ON FUNCTION "public"."profiles_prevent_forbidden_inserts"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."profiles_prevent_forbidden_inserts"() TO "service_role";



GRANT ALL ON FUNCTION "public"."profiles_prevent_forbidden_updates"() TO "anon";
GRANT ALL ON FUNCTION "public"."profiles_prevent_forbidden_updates"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."profiles_prevent_forbidden_updates"() TO "service_role";



GRANT ALL ON FUNCTION "public"."profiles_to_roles_sync"() TO "service_role";



GRANT ALL ON FUNCTION "public"."restrict_early_clockout"() TO "anon";
GRANT ALL ON FUNCTION "public"."restrict_early_clockout"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."restrict_early_clockout"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."rls_auto_enable"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."rls_auto_enable"() TO "anon";
GRANT ALL ON FUNCTION "public"."rls_auto_enable"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."rls_auto_enable"() TO "service_role";



GRANT ALL ON FUNCTION "public"."roles_to_profiles_sync"() TO "anon";
GRANT ALL ON FUNCTION "public"."roles_to_profiles_sync"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."roles_to_profiles_sync"() TO "service_role";



GRANT ALL ON FUNCTION "public"."same_branch_as_current"("target_user_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."same_department_as_current"("target_user_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."same_department_as_current"("target_user_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."same_department_as_current"("target_user_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."sync_branch_prefix"() TO "anon";
GRANT ALL ON FUNCTION "public"."sync_branch_prefix"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."sync_branch_prefix"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."sync_dept_leader_role_for_user"("target_user_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."sync_dept_leader_role_for_user"("target_user_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."sync_membership_code"() TO "anon";
GRANT ALL ON FUNCTION "public"."sync_membership_code"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."sync_membership_code"() TO "service_role";



GRANT ALL ON FUNCTION "public"."sync_profile_verification"() TO "anon";
GRANT ALL ON FUNCTION "public"."sync_profile_verification"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."sync_profile_verification"() TO "service_role";



GRANT ALL ON FUNCTION "public"."sync_recurring_events_for_week"("p_week_start" "date", "p_timezone" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."sync_recurring_events_for_week"("p_week_start" "date", "p_timezone" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."sync_recurring_events_for_week"("p_week_start" "date", "p_timezone" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."sync_user_metadata"() TO "anon";
GRANT ALL ON FUNCTION "public"."sync_user_metadata"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."sync_user_metadata"() TO "service_role";



GRANT ALL ON FUNCTION "public"."sync_user_role"() TO "anon";
GRANT ALL ON FUNCTION "public"."sync_user_role"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."sync_user_role"() TO "service_role";



GRANT ALL ON FUNCTION "public"."sync_worker_department"() TO "anon";
GRANT ALL ON FUNCTION "public"."sync_worker_department"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."sync_worker_department"() TO "service_role";






























GRANT ALL ON TABLE "public"."announcements" TO "anon";
GRANT ALL ON TABLE "public"."announcements" TO "authenticated";
GRANT ALL ON TABLE "public"."announcements" TO "service_role";



GRANT ALL ON TABLE "public"."attendance" TO "anon";
GRANT ALL ON TABLE "public"."attendance" TO "authenticated";
GRANT ALL ON TABLE "public"."attendance" TO "service_role";



GRANT ALL ON TABLE "public"."attendance_audit_logs" TO "anon";
GRANT ALL ON TABLE "public"."attendance_audit_logs" TO "authenticated";
GRANT ALL ON TABLE "public"."attendance_audit_logs" TO "service_role";



GRANT ALL ON TABLE "public"."branches" TO "service_role";
GRANT SELECT ON TABLE "public"."branches" TO "supabase_auth_admin";
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "public"."branches" TO "anon";
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "public"."branches" TO "authenticated";



GRANT ALL ON TABLE "public"."departments" TO "service_role";
GRANT SELECT ON TABLE "public"."departments" TO "supabase_auth_admin";
GRANT SELECT ON TABLE "public"."departments" TO PUBLIC;



GRANT ALL ON TABLE "public"."events" TO "anon";
GRANT ALL ON TABLE "public"."events" TO "authenticated";
GRANT ALL ON TABLE "public"."events" TO "service_role";



GRANT ALL ON TABLE "public"."profiles" TO "anon";
GRANT ALL ON TABLE "public"."profiles" TO "authenticated";
GRANT ALL ON TABLE "public"."profiles" TO "service_role";



GRANT ALL ON TABLE "public"."attendance_view" TO "anon";
GRANT ALL ON TABLE "public"."attendance_view" TO "authenticated";
GRANT ALL ON TABLE "public"."attendance_view" TO "service_role";



GRANT ALL ON TABLE "public"."comments" TO "anon";
GRANT ALL ON TABLE "public"."comments" TO "authenticated";
GRANT ALL ON TABLE "public"."comments" TO "service_role";



GRANT ALL ON TABLE "public"."course_enrollments" TO "anon";
GRANT ALL ON TABLE "public"."course_enrollments" TO "authenticated";
GRANT ALL ON TABLE "public"."course_enrollments" TO "service_role";



GRANT ALL ON TABLE "public"."courses" TO "anon";
GRANT ALL ON TABLE "public"."courses" TO "authenticated";
GRANT ALL ON TABLE "public"."courses" TO "service_role";



GRANT ALL ON TABLE "public"."leaders" TO "anon";
GRANT ALL ON TABLE "public"."leaders" TO "authenticated";
GRANT ALL ON TABLE "public"."leaders" TO "service_role";



GRANT ALL ON TABLE "public"."leadership_titles" TO "anon";
GRANT ALL ON TABLE "public"."leadership_titles" TO "authenticated";
GRANT ALL ON TABLE "public"."leadership_titles" TO "service_role";



GRANT ALL ON TABLE "public"."roletypes" TO "anon";
GRANT ALL ON TABLE "public"."roletypes" TO "authenticated";
GRANT ALL ON TABLE "public"."roletypes" TO "service_role";



GRANT ALL ON TABLE "public"."department_leadership_view" TO "anon";
GRANT ALL ON TABLE "public"."department_leadership_view" TO "authenticated";
GRANT ALL ON TABLE "public"."department_leadership_view" TO "service_role";



GRANT ALL ON TABLE "public"."department_requests" TO "anon";
GRANT ALL ON TABLE "public"."department_requests" TO "authenticated";
GRANT ALL ON TABLE "public"."department_requests" TO "service_role";



GRANT ALL ON TABLE "public"."department_summary_view" TO "anon";
GRANT ALL ON TABLE "public"."department_summary_view" TO "authenticated";
GRANT ALL ON TABLE "public"."department_summary_view" TO "service_role";



GRANT ALL ON TABLE "public"."workers" TO "service_role";
GRANT SELECT ON TABLE "public"."workers" TO "supabase_auth_admin";
GRANT ALL ON TABLE "public"."workers" TO "anon";
GRANT ALL ON TABLE "public"."workers" TO "authenticated";



GRANT ALL ON TABLE "public"."events_attendance_view" TO "anon";
GRANT ALL ON TABLE "public"."events_attendance_view" TO "authenticated";
GRANT ALL ON TABLE "public"."events_attendance_view" TO "service_role";



GRANT ALL ON TABLE "public"."global_admins" TO "anon";
GRANT ALL ON TABLE "public"."global_admins" TO "authenticated";
GRANT ALL ON TABLE "public"."global_admins" TO "service_role";



GRANT ALL ON TABLE "public"."membershipcode" TO "anon";
GRANT ALL ON TABLE "public"."membershipcode" TO "authenticated";
GRANT ALL ON TABLE "public"."membershipcode" TO "service_role";



GRANT ALL ON TABLE "public"."otp_cooldowns" TO "anon";
GRANT ALL ON TABLE "public"."otp_cooldowns" TO "authenticated";
GRANT ALL ON TABLE "public"."otp_cooldowns" TO "service_role";



GRANT ALL ON TABLE "public"."penalties" TO "anon";
GRANT ALL ON TABLE "public"."penalties" TO "authenticated";
GRANT ALL ON TABLE "public"."penalties" TO "service_role";



GRANT ALL ON TABLE "public"."post_reactions" TO "anon";
GRANT ALL ON TABLE "public"."post_reactions" TO "authenticated";
GRANT ALL ON TABLE "public"."post_reactions" TO "service_role";



GRANT ALL ON TABLE "public"."posts" TO "anon";
GRANT ALL ON TABLE "public"."posts" TO "authenticated";
GRANT ALL ON TABLE "public"."posts" TO "service_role";



GRANT ALL ON TABLE "public"."posts_with_comments" TO "anon";
GRANT ALL ON TABLE "public"."posts_with_comments" TO "authenticated";
GRANT ALL ON TABLE "public"."posts_with_comments" TO "service_role";



GRANT ALL ON TABLE "public"."profile_attendance_view" TO "anon";
GRANT ALL ON TABLE "public"."profile_attendance_view" TO "authenticated";
GRANT ALL ON TABLE "public"."profile_attendance_view" TO "service_role";



GRANT ALL ON TABLE "public"."profile_view" TO "anon";
GRANT ALL ON TABLE "public"."profile_view" TO "authenticated";
GRANT ALL ON TABLE "public"."profile_view" TO "service_role";



GRANT ALL ON TABLE "public"."profiles_priv_info" TO "anon";
GRANT ALL ON TABLE "public"."profiles_priv_info" TO "authenticated";
GRANT ALL ON TABLE "public"."profiles_priv_info" TO "service_role";



GRANT ALL ON TABLE "public"."profileverification" TO "anon";
GRANT ALL ON TABLE "public"."profileverification" TO "authenticated";
GRANT ALL ON TABLE "public"."profileverification" TO "service_role";



GRANT ALL ON TABLE "public"."recurring_events" TO "anon";
GRANT ALL ON TABLE "public"."recurring_events" TO "authenticated";
GRANT ALL ON TABLE "public"."recurring_events" TO "service_role";



GRANT ALL ON TABLE "public"."roles" TO "service_role";
GRANT SELECT ON TABLE "public"."roles" TO "supabase_auth_admin";



GRANT ALL ON TABLE "public"."systemreports" TO "anon";
GRANT ALL ON TABLE "public"."systemreports" TO "authenticated";
GRANT ALL ON TABLE "public"."systemreports" TO "service_role";



GRANT ALL ON TABLE "public"."weekly_attendance_summary" TO "anon";
GRANT ALL ON TABLE "public"."weekly_attendance_summary" TO "authenticated";
GRANT ALL ON TABLE "public"."weekly_attendance_summary" TO "service_role";



GRANT ALL ON TABLE "public"."weekly_branch_stats" TO "anon";
GRANT ALL ON TABLE "public"."weekly_branch_stats" TO "authenticated";
GRANT ALL ON TABLE "public"."weekly_branch_stats" TO "service_role";



GRANT ALL ON TABLE "public"."worker_profiles" TO "anon";
GRANT ALL ON TABLE "public"."worker_profiles" TO "authenticated";
GRANT ALL ON TABLE "public"."worker_profiles" TO "service_role";









ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "service_role";



































drop extension if exists "pg_net";

drop trigger if exists "tr_restrict_early_clockout" on "public"."attendance";

drop trigger if exists "trg_branches_prefix_sync" on "public"."branches";

drop trigger if exists "leaders_role_sync" on "public"."leaders";

drop trigger if exists "trg_membership_code_sync" on "public"."membershipcode";

drop trigger if exists "profiles_prevent_forbidden_inserts_trg" on "public"."profiles";

drop trigger if exists "profiles_prevent_forbidden_updates_trg" on "public"."profiles";

drop trigger if exists "profiles_sync_trigger" on "public"."profiles";

drop trigger if exists "trg_profiles_prefix_init" on "public"."profiles";

drop trigger if exists "sync_user_metadata_trigger" on "public"."profiles_priv_info";

drop trigger if exists "trg_profiles_priv_prefix_init" on "public"."profiles_priv_info";

drop trigger if exists "trg_verification_sync" on "public"."profiles_priv_info";

drop trigger if exists "roles_sync_trigger" on "public"."roles";

drop trigger if exists "trg_role_sync" on "public"."roles";

drop trigger if exists "tr_sync_worker_department" on "public"."workers";

drop policy "comments_unified_insert" on "public"."comments";

drop policy "comments_unified_select" on "public"."comments";

drop policy "profiles_priv_info_unified_select" on "public"."profiles_priv_info";

drop policy "workers_select_policy" on "public"."workers";

revoke references on table "public"."branches" from "anon";

revoke trigger on table "public"."branches" from "anon";

revoke truncate on table "public"."branches" from "anon";

revoke references on table "public"."branches" from "authenticated";

revoke trigger on table "public"."branches" from "authenticated";

revoke truncate on table "public"."branches" from "authenticated";

revoke references on table "public"."departments" from "anon";

revoke trigger on table "public"."departments" from "anon";

revoke truncate on table "public"."departments" from "anon";

revoke references on table "public"."departments" from "authenticated";

revoke trigger on table "public"."departments" from "authenticated";

revoke truncate on table "public"."departments" from "authenticated";

revoke references on table "public"."roles" from "anon";

revoke trigger on table "public"."roles" from "anon";

revoke truncate on table "public"."roles" from "anon";

revoke references on table "public"."roles" from "authenticated";

revoke trigger on table "public"."roles" from "authenticated";

revoke truncate on table "public"."roles" from "authenticated";

alter table "public"."announcements" drop constraint "announcements_branch_id_fkey";

alter table "public"."announcements" drop constraint "announcements_created_by_fkey";

alter table "public"."announcements" drop constraint "announcements_department_id_fkey";

alter table "public"."attendance" drop constraint "attendance_event_id_fkey";

alter table "public"."attendance" drop constraint "attendance_user_id_fkey";

alter table "public"."attendance_audit_logs" drop constraint "attendance_audit_logs_event_id_fkey";

alter table "public"."attendance_audit_logs" drop constraint "attendance_audit_logs_user_id_fkey";

alter table "public"."comments" drop constraint "comments_created_by_fkey";

alter table "public"."comments" drop constraint "comments_parent_comment_id_fkey";

alter table "public"."comments" drop constraint "comments_post_id_fkey";

alter table "public"."course_enrollments" drop constraint "course_enrollments_course_id_fkey";

alter table "public"."course_enrollments" drop constraint "course_enrollments_user_id_fkey";

alter table "public"."department_requests" drop constraint "department_requests_department_id_fkey";

alter table "public"."department_requests" drop constraint "department_requests_user_id_fkey";

alter table "public"."events" drop constraint "events_branch_id_fkey";

alter table "public"."events" drop constraint "events_recurring_event_id_fkey";

alter table "public"."leaders" drop constraint "leaders_branch_id_fkey";

alter table "public"."leaders" drop constraint "leaders_department_id_fkey";

alter table "public"."leaders" drop constraint "leaders_title_id_fkey";

alter table "public"."leaders" drop constraint "leaders_user_id_fkey";

alter table "public"."leadership_titles" drop constraint "leadership_titles_parent_role_id_fkey";

alter table "public"."membershipcode" drop constraint "membershipcode_memberid_fkey";

alter table "public"."penalties" drop constraint "penalties_reported_by_fkey";

alter table "public"."penalties" drop constraint "penalties_user_id_fkey";

alter table "public"."post_reactions" drop constraint "post_reactions_post_id_fkey";

alter table "public"."post_reactions" drop constraint "post_reactions_user_id_fkey";

alter table "public"."posts" drop constraint "posts_branch_id_fkey";

alter table "public"."posts" drop constraint "posts_created_by_fkey";

alter table "public"."posts" drop constraint "posts_modified_by_fkey";

alter table "public"."profiles" drop constraint "profiles_branch_id_fkey";

alter table "public"."profiles" drop constraint "profiles_department_id_fkey";

alter table "public"."profiles_priv_info" drop constraint "profiles_priv_info_branch_id_fkey";

alter table "public"."profiles_priv_info" drop constraint "profiles_priv_info_department_id_fkey";

alter table "public"."profileverification" drop constraint "profileverification_memberid_fkey";

alter table "public"."profileverification" drop constraint "profileverification_verifiedby_fkey";

alter table "public"."recurring_events" drop constraint "recurring_events_recurrence_type_check";

alter table "public"."roles" drop constraint "roles_roleid_fkey";

alter table "public"."roles" drop constraint "roles_rolename_fkey";

alter table "public"."workers" drop constraint "workers_branch_id_fkey";

alter table "public"."workers" drop constraint "workers_department_id_fkey";

alter table "public"."workers" drop constraint "workers_user_id_fkey";

alter table "public"."announcements" add constraint "announcements_branch_id_fkey" FOREIGN KEY (branch_id) REFERENCES public.branches(id) not valid;

alter table "public"."announcements" validate constraint "announcements_branch_id_fkey";

alter table "public"."announcements" add constraint "announcements_created_by_fkey" FOREIGN KEY (created_by) REFERENCES public.profiles(id) not valid;

alter table "public"."announcements" validate constraint "announcements_created_by_fkey";

alter table "public"."announcements" add constraint "announcements_department_id_fkey" FOREIGN KEY (department_id) REFERENCES public.departments(id) not valid;

alter table "public"."announcements" validate constraint "announcements_department_id_fkey";

alter table "public"."attendance" add constraint "attendance_event_id_fkey" FOREIGN KEY (event_id) REFERENCES public.events(id) ON UPDATE CASCADE ON DELETE CASCADE not valid;

alter table "public"."attendance" validate constraint "attendance_event_id_fkey";

alter table "public"."attendance" add constraint "attendance_user_id_fkey" FOREIGN KEY (user_id) REFERENCES public.profiles(id) not valid;

alter table "public"."attendance" validate constraint "attendance_user_id_fkey";

alter table "public"."attendance_audit_logs" add constraint "attendance_audit_logs_event_id_fkey" FOREIGN KEY (event_id) REFERENCES public.events(id) ON DELETE CASCADE not valid;

alter table "public"."attendance_audit_logs" validate constraint "attendance_audit_logs_event_id_fkey";

alter table "public"."attendance_audit_logs" add constraint "attendance_audit_logs_user_id_fkey" FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE not valid;

alter table "public"."attendance_audit_logs" validate constraint "attendance_audit_logs_user_id_fkey";

alter table "public"."comments" add constraint "comments_created_by_fkey" FOREIGN KEY (created_by) REFERENCES public.profiles(id) ON DELETE SET NULL not valid;

alter table "public"."comments" validate constraint "comments_created_by_fkey";

alter table "public"."comments" add constraint "comments_parent_comment_id_fkey" FOREIGN KEY (parent_comment_id) REFERENCES public.comments(id) ON DELETE CASCADE not valid;

alter table "public"."comments" validate constraint "comments_parent_comment_id_fkey";

alter table "public"."comments" add constraint "comments_post_id_fkey" FOREIGN KEY (post_id) REFERENCES public.posts(id) ON DELETE CASCADE not valid;

alter table "public"."comments" validate constraint "comments_post_id_fkey";

alter table "public"."course_enrollments" add constraint "course_enrollments_course_id_fkey" FOREIGN KEY (course_id) REFERENCES public.courses(id) not valid;

alter table "public"."course_enrollments" validate constraint "course_enrollments_course_id_fkey";

alter table "public"."course_enrollments" add constraint "course_enrollments_user_id_fkey" FOREIGN KEY (user_id) REFERENCES public.profiles(id) not valid;

alter table "public"."course_enrollments" validate constraint "course_enrollments_user_id_fkey";

alter table "public"."department_requests" add constraint "department_requests_department_id_fkey" FOREIGN KEY (department_id) REFERENCES public.departments(id) not valid;

alter table "public"."department_requests" validate constraint "department_requests_department_id_fkey";

alter table "public"."department_requests" add constraint "department_requests_user_id_fkey" FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE not valid;

alter table "public"."department_requests" validate constraint "department_requests_user_id_fkey";

alter table "public"."events" add constraint "events_branch_id_fkey" FOREIGN KEY (branch_id) REFERENCES public.branches(id) ON UPDATE CASCADE ON DELETE CASCADE not valid;

alter table "public"."events" validate constraint "events_branch_id_fkey";

alter table "public"."events" add constraint "events_recurring_event_id_fkey" FOREIGN KEY (recurring_event_id) REFERENCES public.recurring_events(id) ON UPDATE CASCADE ON DELETE SET NULL not valid;

alter table "public"."events" validate constraint "events_recurring_event_id_fkey";

alter table "public"."leaders" add constraint "leaders_branch_id_fkey" FOREIGN KEY (branch_id) REFERENCES public.branches(id) not valid;

alter table "public"."leaders" validate constraint "leaders_branch_id_fkey";

alter table "public"."leaders" add constraint "leaders_department_id_fkey" FOREIGN KEY (department_id) REFERENCES public.departments(id) not valid;

alter table "public"."leaders" validate constraint "leaders_department_id_fkey";

alter table "public"."leaders" add constraint "leaders_title_id_fkey" FOREIGN KEY (title_id) REFERENCES public.leadership_titles(id) ON UPDATE CASCADE ON DELETE RESTRICT not valid;

alter table "public"."leaders" validate constraint "leaders_title_id_fkey";

alter table "public"."leaders" add constraint "leaders_user_id_fkey" FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE not valid;

alter table "public"."leaders" validate constraint "leaders_user_id_fkey";

alter table "public"."leadership_titles" add constraint "leadership_titles_parent_role_id_fkey" FOREIGN KEY (parent_role_id) REFERENCES public.roletypes(id) ON UPDATE CASCADE ON DELETE RESTRICT not valid;

alter table "public"."leadership_titles" validate constraint "leadership_titles_parent_role_id_fkey";

alter table "public"."membershipcode" add constraint "membershipcode_memberid_fkey" FOREIGN KEY (memberid) REFERENCES public.profiles(id) not valid;

alter table "public"."membershipcode" validate constraint "membershipcode_memberid_fkey";

alter table "public"."penalties" add constraint "penalties_reported_by_fkey" FOREIGN KEY (reported_by) REFERENCES public.profiles(id) not valid;

alter table "public"."penalties" validate constraint "penalties_reported_by_fkey";

alter table "public"."penalties" add constraint "penalties_user_id_fkey" FOREIGN KEY (user_id) REFERENCES public.profiles(id) not valid;

alter table "public"."penalties" validate constraint "penalties_user_id_fkey";

alter table "public"."post_reactions" add constraint "post_reactions_post_id_fkey" FOREIGN KEY (post_id) REFERENCES public.posts(id) ON DELETE CASCADE not valid;

alter table "public"."post_reactions" validate constraint "post_reactions_post_id_fkey";

alter table "public"."post_reactions" add constraint "post_reactions_user_id_fkey" FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE not valid;

alter table "public"."post_reactions" validate constraint "post_reactions_user_id_fkey";

alter table "public"."posts" add constraint "posts_branch_id_fkey" FOREIGN KEY (branch_id) REFERENCES public.branches(id) not valid;

alter table "public"."posts" validate constraint "posts_branch_id_fkey";

alter table "public"."posts" add constraint "posts_created_by_fkey" FOREIGN KEY (created_by) REFERENCES public.profiles(id) ON DELETE SET NULL not valid;

alter table "public"."posts" validate constraint "posts_created_by_fkey";

alter table "public"."posts" add constraint "posts_modified_by_fkey" FOREIGN KEY (modified_by) REFERENCES public.profiles(id) ON DELETE SET NULL not valid;

alter table "public"."posts" validate constraint "posts_modified_by_fkey";

alter table "public"."profiles" add constraint "profiles_branch_id_fkey" FOREIGN KEY (branch_id) REFERENCES public.branches(id) not valid;

alter table "public"."profiles" validate constraint "profiles_branch_id_fkey";

alter table "public"."profiles" add constraint "profiles_department_id_fkey" FOREIGN KEY (department_id) REFERENCES public.departments(id) not valid;

alter table "public"."profiles" validate constraint "profiles_department_id_fkey";

alter table "public"."profiles_priv_info" add constraint "profiles_priv_info_branch_id_fkey" FOREIGN KEY (branch_id) REFERENCES public.branches(id) not valid;

alter table "public"."profiles_priv_info" validate constraint "profiles_priv_info_branch_id_fkey";

alter table "public"."profiles_priv_info" add constraint "profiles_priv_info_department_id_fkey" FOREIGN KEY (department_id) REFERENCES public.departments(id) not valid;

alter table "public"."profiles_priv_info" validate constraint "profiles_priv_info_department_id_fkey";

alter table "public"."profileverification" add constraint "profileverification_memberid_fkey" FOREIGN KEY (memberid) REFERENCES public.profiles(id) not valid;

alter table "public"."profileverification" validate constraint "profileverification_memberid_fkey";

alter table "public"."profileverification" add constraint "profileverification_verifiedby_fkey" FOREIGN KEY (verifiedby) REFERENCES public.roles(memberid) not valid;

alter table "public"."profileverification" validate constraint "profileverification_verifiedby_fkey";

alter table "public"."recurring_events" add constraint "recurring_events_recurrence_type_check" CHECK (((recurrence_type)::text = ANY ((ARRAY['weekly'::character varying, 'monthly'::character varying, 'yearly'::character varying])::text[]))) not valid;

alter table "public"."recurring_events" validate constraint "recurring_events_recurrence_type_check";

alter table "public"."roles" add constraint "roles_roleid_fkey" FOREIGN KEY (roleid) REFERENCES public.roletypes(id) not valid;

alter table "public"."roles" validate constraint "roles_roleid_fkey";

alter table "public"."roles" add constraint "roles_rolename_fkey" FOREIGN KEY (rolename) REFERENCES public.roletypes(rolename) not valid;

alter table "public"."roles" validate constraint "roles_rolename_fkey";

alter table "public"."workers" add constraint "workers_branch_id_fkey" FOREIGN KEY (branch_id) REFERENCES public.branches(id) not valid;

alter table "public"."workers" validate constraint "workers_branch_id_fkey";

alter table "public"."workers" add constraint "workers_department_id_fkey" FOREIGN KEY (department_id) REFERENCES public.departments(id) not valid;

alter table "public"."workers" validate constraint "workers_department_id_fkey";

alter table "public"."workers" add constraint "workers_user_id_fkey" FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE not valid;

alter table "public"."workers" validate constraint "workers_user_id_fkey";

create or replace view "public"."attendance_view" as  SELECT a.id AS attendance_id,
    a.user_id,
    p.full_name AS profile_full_name,
    a.fullname AS attendance_fullname,
    a.event_id,
    e.title AS event_title,
    e.event_date,
    e.scope AS event_scope,
    a.status AS attendance_status,
    a.branch_id,
    br.name AS branch_name,
    a.department_id,
    dep.name AS department_name,
    a.latitude,
    a.longitude,
    a.closedlat,
    a.closedlong,
    a.clockout,
    a.confirmedby,
    a.confirmedby_name,
    a.created_at AS attendance_created_at,
        CASE
            WHEN (br.prefix IS NULL) THEN p.membership_code
            ELSE (br.prefix || p.membership_code)
        END AS profile_membership_code
   FROM ((((public.attendance a
     LEFT JOIN public.events e ON ((e.id = a.event_id)))
     LEFT JOIN public.profiles p ON ((p.id = a.user_id)))
     LEFT JOIN public.branches br ON ((br.id = a.branch_id)))
     LEFT JOIN public.departments dep ON ((dep.id = a.department_id)));


create or replace view "public"."department_leadership_view" as  SELECT l.id AS leader_id,
    l.user_id,
    p.full_name AS user_full_name,
    p.email AS user_email,
    l.department_id,
    d.name AS department_name,
    l.branch_id,
    l.title_id,
    lt.code AS title_code,
    lt.name AS title_name,
    lt.description AS title_description,
    rt.id AS parent_role_id,
    rt.rolename AS parent_role_name,
    l.is_active,
    l.start_date,
    l.end_date,
    l.created_at
   FROM ((((public.leaders l
     JOIN public.leadership_titles lt ON ((lt.id = l.title_id)))
     JOIN public.roletypes rt ON ((rt.id = lt.parent_role_id)))
     LEFT JOIN public.departments d ON ((d.id = l.department_id)))
     LEFT JOIN public.profiles p ON ((p.id = l.user_id)));


create or replace view "public"."department_summary_view" as  SELECT d.id AS department_id,
    d.name AS department_name,
    ( SELECT count(*) AS count
           FROM public.profiles p
          WHERE (p.department_id = d.id)) AS persons_count,
    count(DISTINCT
        CASE
            WHEN ((e.isactive = true) AND (e.scope = 'department'::text)) THEN a.event_id
            ELSE NULL::uuid
        END) AS active_departmental_events,
    count(DISTINCT
        CASE
            WHEN ((e.isactive = false) OR (e.event_date < now()) OR (e.scope <> 'department'::text)) THEN a.event_id
            ELSE NULL::uuid
        END) AS past_departmental_events
   FROM ((public.departments d
     LEFT JOIN public.attendance a ON ((a.department_id = d.id)))
     LEFT JOIN public.events e ON ((e.id = a.event_id)))
  GROUP BY d.id, d.name
  ORDER BY d.name;


create or replace view "public"."events_attendance_view" as  WITH branch_worker_totals AS (
         SELECT w.branch_id,
            count(DISTINCT w.user_id) AS total_workers
           FROM public.workers w
          GROUP BY w.branch_id
        ), event_active_workers AS (
         SELECT a.event_id,
            count(DISTINCT a.user_id) AS active_worker
           FROM public.attendance a
          WHERE (a.event_id IS NOT NULL)
          GROUP BY a.event_id
        )
 SELECT e.id AS event_id,
    e.created_at AS created_time,
    e.title,
    e.description,
    e.featured_url AS featured_image,
    COALESCE(eaw.active_worker, (0)::bigint) AS active_worker,
    COALESCE(bwt.total_workers, (0)::bigint) AS total_workers,
    e.isactive AS is_active,
    e."closed by" AS closed_by,
    e.scope AS event_scope,
    e.event_date AS event_start_date,
    e.endtime AS event_end_time,
    e.latitude AS event_latitude,
    e.longitude AS event_longitude,
    e.created_by,
    e.branch_id AS event_branch_id
   FROM ((public.events e
     LEFT JOIN event_active_workers eaw ON ((eaw.event_id = e.id)))
     LEFT JOIN branch_worker_totals bwt ON ((bwt.branch_id = e.branch_id)));


create or replace view "public"."posts_with_comments" as  SELECT p.id,
    p.target_type,
    p.branch_id,
    b.name AS branch_name,
    p.department_id,
    d.name AS department_name,
    p.body,
    p.created_by,
    pr_creator.full_name AS created_by_name,
    p.modified_by,
    pr_modifier.full_name AS modified_by_name,
    p.created_at,
    p.modified_at,
    p.is_pinned,
    p.reaction_counts AS reactions,
    p.comments_count,
    p.more AS post_more,
    p.is_archived AS post_archived,
    COALESCE(( SELECT jsonb_agg(sub.c_obj ORDER BY ((sub.c_obj ->> 'created_at'::text))::timestamp with time zone) AS jsonb_agg
           FROM ( SELECT jsonb_build_object('id', c.id, 'creator_id', c.created_by, 'creator', jsonb_build_object('name', COALESCE(c."commentor name", pr.full_name)), 'parent_comment_id', c.parent_comment_id, 'created_at', to_char(c.created_at, 'YYYY-MM-DD"T"HH24:MI:SSZ'::text), 'modified_at', to_char(c.modified_at, 'YYYY-MM-DD"T"HH24:MI:SSZ'::text), 'is_edited', c.is_edited, 'is_deleted', c.is_deleted, 'more', COALESCE(c.more, '{}'::jsonb), 'body', c.body) AS c_obj
                   FROM (public.comments c
                     LEFT JOIN public.profiles pr ON ((pr.id = c.created_by)))
                  WHERE (c.post_id = p.id)) sub), '[]'::jsonb) AS comments
   FROM ((((public.posts p
     LEFT JOIN public.branches b ON ((b.id = p.branch_id)))
     LEFT JOIN public.departments d ON ((d.id = p.department_id)))
     LEFT JOIN public.profiles pr_creator ON ((pr_creator.id = p.created_by)))
     LEFT JOIN public.profiles pr_modifier ON ((pr_modifier.id = p.modified_by)));


create or replace view "public"."profile_attendance_view" as  SELECT a.id,
    a.user_id,
    a.event_id,
    a.status,
    a.latitude,
    a.longitude,
    a.closedlat,
    a.closedlong,
    a.created_at,
    a.branch_id,
    a.department_id,
    a.fullname,
    p.full_name AS profile_full_name,
    p.avatar AS profile_avatar,
    p.department_id AS profile_department_id,
    p.branch_id AS profile_branch_id,
        CASE
            WHEN (br.prefix IS NULL) THEN p.membership_code
            ELSE (br.prefix || p.membership_code)
        END AS profile_membership_code
   FROM ((public.attendance a
     LEFT JOIN public.profiles p ON ((p.id = a.user_id)))
     LEFT JOIN public.branches br ON ((br.id = p.branch_id)));


create or replace view "public"."profile_view" as  SELECT p.id AS user_id,
    p.full_name,
    p.firstname,
    p.lastname,
    p.phone,
    p.bio,
    p.membership_code,
    p.branch_id,
    b.name AS branch_name,
    b.id AS branch_id_confirm,
    p.department_id,
    d.name AS department_name,
    d.id AS department_id_confirm,
    w.membershipcode AS worker_membershipcode
   FROM (((public.profiles p
     LEFT JOIN public.branches b ON ((p.branch_id = b.id)))
     LEFT JOIN public.departments d ON ((p.department_id = d.id)))
     LEFT JOIN public.workers w ON ((w.user_id = p.id)));


create or replace view "public"."systemreports" as  SELECT 'overview'::text AS report_type,
    jsonb_build_object('total_workers', ( SELECT count(*) AS count
           FROM public.workers), 'total_members', ( SELECT count(*) AS count
           FROM public.profiles), 'total_departments', ( SELECT count(*) AS count
           FROM public.departments), 'total_branches', ( SELECT count(*) AS count
           FROM public.branches), 'upcoming_events', ( SELECT count(*) AS count
           FROM public.events
          WHERE (events.event_date > now())), 'active_workers', ( SELECT count(*) AS count
           FROM public.workers)) AS data,
    now() AS calculated_at;


create or replace view "public"."weekly_attendance_summary" as  SELECT branch_id,
    count(*) AS total_attendance,
    count(DISTINCT user_id) AS unique_attendees,
    date_trunc('week'::text, created_at) AS week_start
   FROM public.attendance
  GROUP BY branch_id, (date_trunc('week'::text, created_at));


create or replace view "public"."weekly_branch_stats" as  SELECT p.branch_id,
    count(DISTINCT a.user_id) AS workers_attended,
    count(DISTINCT e.id) AS events_this_week
   FROM ((public.events e
     LEFT JOIN public.attendance a ON (((a.event_id = e.id) AND (a.status = 'confirmed'::text))))
     LEFT JOIN public.profiles p ON ((p.id = a.user_id)))
  WHERE (e.event_date >= date_trunc('week'::text, now()))
  GROUP BY p.branch_id;


create or replace view "public"."worker_profiles" as  SELECT w.id AS worker_id,
    w.user_id,
    w.branch_id,
    b.name AS branch_name,
    w.department_id,
    d.name AS department_name,
        CASE
            WHEN (b.prefix IS NULL) THEN w.membershipcode
            ELSE (b.prefix || w.membershipcode)
        END AS worker_membershipcode,
    w.created_at AS worker_created_at,
    p.id AS profile_id,
    p.full_name,
    p.phone,
    p.bio,
    p.membership_code AS profile_membership_code,
    p.date_joined,
    p.verified,
    p.avatar,
    p.lastname,
    p.firstname,
    p.created_at AS profile_created_at
   FROM (((public.workers w
     LEFT JOIN public.profiles p ON ((p.id = w.user_id)))
     LEFT JOIN public.branches b ON ((b.id = w.branch_id)))
     LEFT JOIN public.departments d ON ((d.id = w.department_id)));



  create policy "comments_unified_insert"
  on "public"."comments"
  as permissive
  for insert
  to authenticated
with check (((( SELECT (auth.jwt() ->> 'wprole'::text)) = 'globaladmin'::text) OR (EXISTS ( SELECT 1
   FROM public.posts p
  WHERE ((p.id = comments.post_id) AND (p.branch_id = (( SELECT (auth.jwt() ->> 'wpbranch_id'::text)))::uuid))))));



  create policy "comments_unified_select"
  on "public"."comments"
  as permissive
  for select
  to authenticated
using (((( SELECT (auth.jwt() ->> 'wprole'::text)) = 'globaladmin'::text) OR (created_by = ( SELECT auth.uid() AS uid)) OR (EXISTS ( SELECT 1
   FROM public.posts p
  WHERE ((p.id = comments.post_id) AND ((p.target_type = 'global'::text) OR (p.branch_id = (( SELECT (auth.jwt() ->> 'wpbranch_id'::text)))::uuid)))))));



  create policy "profiles_priv_info_unified_select"
  on "public"."profiles_priv_info"
  as permissive
  for select
  to authenticated
using (((( SELECT auth.uid() AS uid) = id) OR (( SELECT public.get_my_role() AS get_my_role) = 'globaladmin'::text) OR ((( SELECT public.get_my_role() AS get_my_role) = ANY (ARRAY['admin'::text, 'superuser'::text, 'worker'::text])) AND (branch_id = ( SELECT public.get_my_branch_id() AS get_my_branch_id)))));



  create policy "workers_select_policy"
  on "public"."workers"
  as permissive
  for select
  to authenticated
using (((public.get_my_role() = 'globaladmin'::text) OR ((public.get_my_role() = ANY (ARRAY['admin'::text, 'superuser'::text, 'worker'::text])) AND (branch_id = public.get_my_branch_id()))));


CREATE TRIGGER tr_restrict_early_clockout BEFORE INSERT OR UPDATE ON public.attendance FOR EACH ROW EXECUTE FUNCTION public.restrict_early_clockout();

CREATE TRIGGER trg_branches_prefix_sync AFTER UPDATE OF prefix ON public.branches FOR EACH ROW EXECUTE FUNCTION public.sync_branch_prefix();

CREATE TRIGGER leaders_role_sync AFTER INSERT OR DELETE OR UPDATE ON public.leaders FOR EACH ROW EXECUTE FUNCTION public.handle_leaders_role_sync();

CREATE TRIGGER trg_membership_code_sync AFTER INSERT OR UPDATE OF membershipcode ON public.membershipcode FOR EACH ROW EXECUTE FUNCTION public.sync_membership_code();

CREATE TRIGGER profiles_prevent_forbidden_inserts_trg BEFORE INSERT ON public.profiles FOR EACH ROW EXECUTE FUNCTION public.profiles_prevent_forbidden_inserts();

CREATE TRIGGER profiles_prevent_forbidden_updates_trg BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION public.profiles_prevent_forbidden_updates();

CREATE TRIGGER profiles_sync_trigger AFTER INSERT ON public.profiles FOR EACH ROW EXECUTE FUNCTION public.profiles_to_roles_sync();

CREATE TRIGGER trg_profiles_prefix_init BEFORE INSERT OR UPDATE OF branch_id ON public.profiles FOR EACH ROW EXECUTE FUNCTION public.sync_branch_prefix();

CREATE TRIGGER sync_user_metadata_trigger AFTER INSERT OR UPDATE OF role, branch_id ON public.profiles_priv_info FOR EACH ROW EXECUTE FUNCTION public.sync_user_metadata();

CREATE TRIGGER trg_profiles_priv_prefix_init BEFORE INSERT OR UPDATE OF branch_id ON public.profiles_priv_info FOR EACH ROW EXECUTE FUNCTION public.sync_branch_prefix();

CREATE TRIGGER trg_verification_sync AFTER INSERT OR UPDATE OF verified ON public.profiles_priv_info FOR EACH ROW EXECUTE FUNCTION public.sync_profile_verification();

CREATE TRIGGER roles_sync_trigger AFTER INSERT OR UPDATE ON public.roles FOR EACH ROW EXECUTE FUNCTION public.roles_to_profiles_sync();

CREATE TRIGGER trg_role_sync AFTER INSERT OR UPDATE OF rolename ON public.roles FOR EACH ROW EXECUTE FUNCTION public.sync_user_role();

CREATE TRIGGER tr_sync_worker_department AFTER INSERT OR UPDATE OF department_id ON public.workers FOR EACH ROW EXECUTE FUNCTION public.sync_worker_department();

drop trigger if exists "tr_check_filters" on "realtime"."subscription";

