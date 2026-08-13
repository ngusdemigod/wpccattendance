alter table public.targets add column if not exists period_label text;

create or replace function public.churchmetric_create_target_v1(
  p_branch_id uuid,p_title text,p_metric text,p_period_type text,p_period_label text,
  p_starts_at timestamptz,p_ends_at timestamptz,p_current_value numeric,p_goal_value numeric,
  p_progress_step numeric,p_notification_channels text[]
) returns uuid language plpgsql security invoker set search_path = '' as $$
declare new_id uuid;initial_value numeric;channel_name text;initially_achieved boolean;
begin
 if not public.churchmetric_can_manage_branch(p_branch_id)then raise exception 'not_authorized' using errcode='42501';end if;
 if p_period_type not in('day','week','month','year','event')then raise exception 'invalid_period' using errcode='22023';end if;
 if nullif(btrim(p_title),'')is null or nullif(btrim(p_metric),'')is null or nullif(btrim(p_period_label),'')is null then raise exception 'required_target_field' using errcode='22023';end if;
 if p_goal_value<=0 or p_progress_step<=0 or p_current_value<0 then raise exception 'invalid_target_value' using errcode='22023';end if;
 if p_ends_at<p_starts_at then raise exception 'invalid_target_dates' using errcode='22023';end if;
 if exists(select 1 from unnest(coalesce(p_notification_channels,'{}'))c where c not in('in_app','email'))then raise exception 'unsupported_notification_channel' using errcode='22023';end if;
 initial_value:=least(p_current_value,p_goal_value);initially_achieved:=initial_value>=p_goal_value;
 insert into public.targets(branch_id,title,metric,period_type,period_label,starts_at,ends_at,goal_value,current_value,progress_step,notification_channels,status,created_by)
 values(p_branch_id,btrim(p_title),btrim(p_metric),p_period_type,btrim(p_period_label),p_starts_at,p_ends_at,p_goal_value,initial_value,p_progress_step,coalesce(p_notification_channels,'{}'),case when initially_achieved then'achieved'else'active'end,auth.uid())returning id into new_id;
 insert into public.churchmetric_audit_events(branch_id,actor_id,action,entity_type,entity_id,metadata)values(p_branch_id,auth.uid(),'target_created','target',new_id,jsonb_build_object('period',p_period_type,'initial_value',initial_value,'goal_value',p_goal_value));
 if initially_achieved then
  insert into public.target_achievements(branch_id,target_id,title)values(p_branch_id,new_id,btrim(p_title))on conflict(target_id)do nothing;
  foreach channel_name in array coalesce(p_notification_channels,'{}')loop insert into public.notification_outbox(branch_id,event_type,aggregate_id,channel,payload,idempotency_key)values(p_branch_id,'target_achieved',new_id,channel_name,jsonb_build_object('target_id',new_id),new_id::text||':'||channel_name)on conflict(idempotency_key)do nothing;end loop;
 end if;return new_id;
end$$;
revoke all on function public.churchmetric_create_target_v1(uuid,text,text,text,text,timestamptz,timestamptz,numeric,numeric,numeric,text[])from public,anon;
grant execute on function public.churchmetric_create_target_v1(uuid,text,text,text,text,timestamptz,timestamptz,numeric,numeric,numeric,text[])to authenticated;

create or replace function public.churchmetric_add_target_progress(p_target_id uuid,p_delta numeric,p_idempotency_key text,p_source_type text default 'manual',p_source_id uuid default null)
returns table(value_after numeric,achieved boolean) language plpgsql security invoker set search_path = '' as $$
declare target_row public.targets%rowtype;next_value numeric;newly_achieved boolean:=false;channel_name text;
begin
 if p_delta=0 then raise exception 'progress_delta_required' using errcode='22023';end if;
 select*into target_row from public.targets where id=p_target_id for update;if not found then raise exception 'target_not_found' using errcode='P0002';end if;
 if not public.churchmetric_can_manage_branch(target_row.branch_id)then raise exception 'not_authorized' using errcode='42501';end if;
 select tpe.value_after into next_value from public.target_progress_events tpe where tpe.idempotency_key=p_idempotency_key;if found then return query select next_value,target_row.status='achieved';return;end if;
 next_value:=least(target_row.goal_value,greatest(0,target_row.current_value+p_delta));
 insert into public.target_progress_events(branch_id,target_id,delta,value_after,source_type,source_id,idempotency_key,recorded_by)values(target_row.branch_id,p_target_id,p_delta,next_value,p_source_type,p_source_id,p_idempotency_key,auth.uid());
 newly_achieved:=next_value>=target_row.goal_value and target_row.status<>'achieved';
 update public.targets set current_value=next_value,status=case when newly_achieved then'achieved'else status end,updated_at=now()where id=p_target_id;
 insert into public.churchmetric_audit_events(branch_id,actor_id,action,entity_type,entity_id,metadata)values(target_row.branch_id,auth.uid(),'target_progress_updated','target',p_target_id,jsonb_build_object('delta',p_delta,'value_after',next_value,'hit',newly_achieved));
 if newly_achieved then
  insert into public.target_achievements(branch_id,target_id,title)values(target_row.branch_id,p_target_id,target_row.title)on conflict(target_id)do nothing;
  foreach channel_name in array target_row.notification_channels loop if channel_name in('email','in_app')then insert into public.notification_outbox(branch_id,event_type,aggregate_id,channel,payload,idempotency_key)values(target_row.branch_id,'target_achieved',p_target_id,channel_name,jsonb_build_object('target_id',p_target_id),p_target_id::text||':'||channel_name)on conflict(idempotency_key)do nothing;end if;end loop;
 end if;return query select next_value,target_row.status='achieved'or newly_achieved;
end$$;

create or replace function public.churchmetric_targets_v1(p_branch_id uuid default null,p_search text default null,p_period text default null,p_page integer default 1,p_page_size integer default 25)
returns jsonb language sql stable security invoker set search_path = '' as $$
 with scoped as(select t.* from public.targets t where(p_branch_id is null or t.branch_id=p_branch_id)and(nullif(btrim(p_search),'')is null or t.title ilike'%'||btrim(p_search)||'%'or t.metric ilike'%'||btrim(p_search)||'%')and(p_period is null or t.period_type=p_period)),counted as(select count(*)total from scoped),items as(select*from scoped where status='active'order by ends_at,id offset(greatest(p_page,1)-1)*least(greatest(p_page_size,1),100)limit least(greatest(p_page_size,1),100)),trophies as(select a.id,a.target_id,a.title,a.achieved_at,t.period_type,t.period_label,t.goal_value,t.metric from public.target_achievements a join public.targets t on t.id=a.target_id where(p_branch_id is null or a.branch_id=p_branch_id)order by a.achieved_at desc)
 select jsonb_build_object('items',coalesce((select jsonb_agg(to_jsonb(i)order by i.ends_at,i.id)from items i),'[]'::jsonb),'trophies',coalesce((select jsonb_agg(to_jsonb(a)order by a.achieved_at desc)from trophies a),'[]'::jsonb),'pagination',jsonb_build_object('page',greatest(p_page,1),'page_size',least(greatest(p_page_size,1),100),'total',(select count(*)from scoped where status='active')))
$$;
revoke all on function public.churchmetric_targets_v1(uuid,text,text,integer,integer)from public,anon;
grant execute on function public.churchmetric_targets_v1(uuid,text,text,integer,integer)to authenticated;
