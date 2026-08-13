alter table public.souls add column if not exists phone_normalized text;
alter table public.souls add column if not exists location text;
alter table public.souls add column if not exists evangelist_name text;

create or replace function public.churchmetric_normalize_soul_phone()
returns trigger language plpgsql security invoker set search_path=public,pg_temp as $$
begin
  new.phone_normalized:=nullif(regexp_replace(coalesce(new.phone,''),'[^0-9+]','','g'),'');
  return new;
end $$;
drop trigger if exists churchmetric_normalize_soul_phone_trigger on public.souls;
create trigger churchmetric_normalize_soul_phone_trigger before insert or update of phone on public.souls for each row execute function public.churchmetric_normalize_soul_phone();
update public.souls set phone_normalized=nullif(regexp_replace(coalesce(phone,''),'[^0-9+]','','g'),'') where phone is not null;
create index if not exists churchmetric_souls_phone_normalized_idx on public.souls(phone_normalized);

create or replace function public.churchmetric_create_soul_v1(p_branch_id uuid,p_event_id uuid,p_full_name text,p_email text default null,p_phone text default null,p_location text default null,p_evangelist_name text default null)
returns uuid language plpgsql security invoker set search_path=public,pg_temp as $$
declare v_event_branch uuid;v_id uuid;
begin
  if not public.churchmetric_can_manage_branch(p_branch_id) then raise exception 'not_authorized' using errcode='42501'; end if;
  select branch_id into v_event_branch from public.evangelism_events where id=p_event_id;
  if not found then raise exception 'event_not_found' using errcode='P0002'; end if;
  if v_event_branch is distinct from p_branch_id then raise exception 'event_branch_mismatch' using errcode='22023'; end if;
  if nullif(btrim(p_full_name),'') is null then raise exception 'full_name_required' using errcode='22023'; end if;
  insert into public.souls(branch_id,evangelism_event_id,recorded_by,full_name,email,phone,location,evangelist_name,status)
  values(p_branch_id,p_event_id,auth.uid(),btrim(p_full_name),nullif(lower(btrim(p_email)),''),nullif(btrim(p_phone),''),nullif(btrim(p_location),''),nullif(btrim(p_evangelist_name),''),'awaiting_contact') returning id into v_id;
  insert into public.soul_followups(branch_id,soul_id,assigned_to,status,created_by) values(p_branch_id,v_id,auth.uid(),'pending',auth.uid());
  insert into public.churchmetric_audit_events(branch_id,actor_id,action,entity_type,entity_id,metadata) values(p_branch_id,auth.uid(),'soul_created','soul',v_id,jsonb_build_object('event_id',p_event_id,'has_phone',nullif(btrim(p_phone),'') is not null));
  return v_id;
end $$;
revoke all on function public.churchmetric_create_soul_v1(uuid,uuid,text,text,text,text,text) from public,anon;
grant execute on function public.churchmetric_create_soul_v1(uuid,uuid,text,text,text,text,text) to authenticated;

create or replace function public.churchmetric_soul_winning_report_v1(p_start_at timestamptz,p_end_at timestamptz,p_search text default '',p_branch_id uuid default null,p_page integer default 1,p_page_size integer default 25)
returns jsonb language plpgsql stable security invoker set search_path=public,pg_temp as $$
declare v_role text:=public.churchmetric_role();v_branch uuid:=public.churchmetric_branch_id();v_search text:=lower(btrim(coalesce(p_search,'')));v_page integer:=greatest(1,coalesce(p_page,1));v_size integer:=least(100,greatest(1,coalesce(p_page_size,25)));v_result jsonb;
begin
  if v_role not in ('admin','globaladmin') then raise exception 'Administrator access required' using errcode='42501'; end if;
  if p_start_at is null or p_end_at is null or p_start_at>p_end_at then raise exception 'Invalid period' using errcode='22007'; end if;
  if v_role='admin' and p_branch_id is not null and p_branch_id is distinct from v_branch then raise exception 'Cross-branch access is forbidden' using errcode='42501'; end if;
  with period_souls as materialized(select s.* from public.souls s where s.won_at between p_start_at and p_end_at and (p_branch_id is null or s.branch_id=p_branch_id)),event_rows as materialized(
    select e.id,e.title,e.description,e.location,e.starts_at,e.status,e.branch_id,count(ps.id)::bigint as souls_won,count(ps.id) filter(where ps.status in ('contacted','integrating','integrated'))::bigint as contacted,count(ps.id) filter(where ps.status='integrated')::bigint as integrated,count(ps.id) filter(where ps.status='awaiting_contact')::bigint as awaiting_contact
    from public.evangelism_events e left join period_souls ps on ps.evangelism_event_id=e.id where e.starts_at between p_start_at and p_end_at and (p_branch_id is null or e.branch_id=p_branch_id) group by e.id
  ),filtered as materialized(select * from event_rows e where v_search='' or lower(coalesce(e.title,'')||' '||coalesce(e.location,'')||' '||coalesce(e.status,'')||' '||e.starts_at::text) like '%'||v_search||'%'),page_rows as(select * from filtered order by starts_at desc,title limit v_size offset((v_page-1)*v_size))
  select jsonb_build_object('metrics',jsonb_build_object('souls_won',(select count(*) from period_souls),'contacted',(select count(*) from period_souls where status in ('contacted','integrating','integrated')),'integrated',(select count(*) from period_souls where status='integrated'),'awaiting_contact',(select count(*) from period_souls where status='awaiting_contact')),'total',(select count(*) from filtered),'page',v_page,'page_size',v_size,'events',coalesce((select jsonb_agg(to_jsonb(r) order by r.starts_at desc,r.title) from page_rows r),'[]'::jsonb)) into v_result;
  return v_result;
end $$;
revoke all on function public.churchmetric_soul_winning_report_v1(timestamptz,timestamptz,text,uuid,integer,integer) from public,anon;
grant execute on function public.churchmetric_soul_winning_report_v1(timestamptz,timestamptz,text,uuid,integer,integer) to authenticated;

create or replace function public.churchmetric_event_souls_v1(p_event_id uuid,p_search text default '',p_page integer default 1,p_page_size integer default 50)
returns jsonb language plpgsql stable security invoker set search_path=public,pg_temp as $$
declare v_role text:=public.churchmetric_role();v_search text:=lower(btrim(coalesce(p_search,'')));v_page integer:=greatest(1,coalesce(p_page,1));v_size integer:=least(100,greatest(1,coalesce(p_page_size,50)));v_title text;v_result jsonb;
begin
  if v_role not in ('admin','globaladmin') then raise exception 'Administrator access required' using errcode='42501'; end if;
  select title into v_title from public.evangelism_events where id=p_event_id;if not found then raise exception 'Event not found' using errcode='P0002';end if;
  with register as materialized(select s.id,s.full_name,s.email,s.phone,s.location,coalesce(s.evangelist_name,p.full_name,'Unassigned') evangelist_name,s.status,s.won_at from public.souls s left join public.profiles p on p.id=s.recorded_by where s.evangelism_event_id=p_event_id),filtered as materialized(select * from register r where v_search='' or lower(coalesce(r.full_name,'')||' '||coalesce(r.phone,'')||' '||coalesce(r.evangelist_name,'')||' '||coalesce(r.location,'')) like '%'||v_search||'%'),page_rows as(select * from filtered order by lower(full_name),id limit v_size offset((v_page-1)*v_size))
  select jsonb_build_object('event_id',p_event_id,'event_title',v_title,'total',(select count(*) from filtered),'page',v_page,'page_size',v_size,'rows',coalesce((select jsonb_agg(to_jsonb(r) order by lower(r.full_name),r.id) from page_rows r),'[]'::jsonb)) into v_result;return v_result;
end $$;
revoke all on function public.churchmetric_event_souls_v1(uuid,text,integer,integer) from public,anon;
grant execute on function public.churchmetric_event_souls_v1(uuid,text,integer,integer) to authenticated;
