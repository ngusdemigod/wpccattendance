create or replace function public.community_create_department_event(p_department_id uuid,p_event_type text,p_title text,p_description text,p_start_at timestamptz,p_end_at timestamptz,p_featured_url text,p_location text,p_latitude double precision default null,p_longitude double precision default null)
returns jsonb language plpgsql security definer set search_path=''
as $$
declare v_branch uuid; v_result jsonb; v_ids uuid[]; v_type text:=lower(coalesce(nullif(btrim(p_event_type),''),'service'));
begin
  if auth.uid() is null then raise exception 'Authentication required' using errcode='42501'; end if;
  if v_type not in ('service','meeting','rehearsal','training','special','other') then raise exception 'Unsupported event type'; end if;
  v_branch:=public.churchmetric_branch_id(); if v_branch is null then select p.branch_id into v_branch from public.profiles p where p.id=auth.uid(); end if;
  if v_branch is null or not public.can_manage_department_scope_content(v_branch,p_department_id) then raise exception 'Department event creation is not permitted' using errcode='42501'; end if;
  v_result:=public.create_scoped_event('department',v_branch,array[p_department_id],p_title,p_description,p_start_at,p_end_at,p_featured_url,p_location,p_latitude,p_longitude,auth.uid()::text);
  select coalesce(array_agg(value::uuid),array[]::uuid[]) into v_ids from jsonb_array_elements_text(v_result->'created_ids');
  update public.departmental_events set event_type=v_type,is_active=true,updated_at=now() where id=any(v_ids);
  return v_result||jsonb_build_object('event_type',v_type);
end; $$;
revoke all on function public.community_create_department_event(uuid,text,text,text,timestamptz,timestamptz,text,text,double precision,double precision) from public,anon;
grant execute on function public.community_create_department_event(uuid,text,text,text,timestamptz,timestamptz,text,text,double precision,double precision) to authenticated;
