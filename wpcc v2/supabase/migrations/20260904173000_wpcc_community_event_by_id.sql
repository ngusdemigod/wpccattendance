create or replace function public.community_event_by_id(p_event_id uuid)
returns table(event_id uuid,title text,description text,event_scope text,source_table text,branch_id uuid,department_id uuid,event_start_at timestamptz,event_end_at timestamptz,featured_image text,location text,latitude double precision,longitude double precision,event_type text,is_ongoing boolean,is_upcoming boolean)
language sql stable security invoker set search_path=''
as $$
select e.event_id,e.title,e.description,e.event_scope,e.source_table,e.branch_id,e.department_id,e.event_start_at,e.event_end_at,e.featured_image,e.location,e.latitude,e.longitude,e.event_type,
       (e.event_start_at<=now() and coalesce(e.event_end_at,e.event_start_at+interval '4 hours')>=now()),
       (e.event_start_at>now())
from public.my_events e where e.event_id=p_event_id and e.is_active limit 1;
$$;
grant execute on function public.community_event_by_id(uuid) to authenticated;
