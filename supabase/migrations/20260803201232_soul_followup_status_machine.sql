create or replace function public.churchmetric_transition_soul(p_soul_id uuid,p_next_status text,p_notes text default null)
returns void language plpgsql security invoker set search_path='' as $$
declare current_row public.souls%rowtype;
begin
  select * into current_row from public.souls where id=p_soul_id for update;
  if not found then raise exception 'soul_not_found' using errcode='P0002'; end if;
  if not public.churchmetric_can_manage_branch(current_row.branch_id) then raise exception 'not_authorized' using errcode='42501'; end if;
  if not (
    (current_row.status='awaiting_contact' and p_next_status='contacted') or
    (current_row.status='contacted' and p_next_status='integrating') or
    (current_row.status='integrating' and p_next_status='integrated') or
    (current_row.status in ('awaiting_contact','contacted','integrating') and p_next_status='closed')
  ) then raise exception 'invalid_status_transition' using errcode='22023'; end if;
  update public.souls set status=p_next_status,updated_at=now() where id=p_soul_id;
  insert into public.soul_followups(branch_id,soul_id,completed_by,channel,status,completed_at,notes,created_by)
  values(current_row.branch_id,p_soul_id,auth.uid(),'other','completed',now(),nullif(btrim(p_notes),''),auth.uid());
  insert into public.churchmetric_audit_events(branch_id,actor_id,action,entity_type,entity_id,metadata)
  values(current_row.branch_id,auth.uid(),'soul_status_changed','soul',p_soul_id,jsonb_build_object('from',current_row.status,'to',p_next_status,'has_notes',nullif(btrim(p_notes),'') is not null));
end $$;

revoke all on function public.churchmetric_transition_soul(uuid,text,text) from public,anon;
grant execute on function public.churchmetric_transition_soul(uuid,text,text) to authenticated;
