drop policy if exists souls_admin_delete on public.souls;

drop policy if exists souls_member_select_own on public.souls;
create policy souls_member_select_own
on public.souls for select to authenticated
using (recorded_by = auth.uid());

drop policy if exists souls_member_insert_own on public.souls;
create policy souls_member_insert_own
on public.souls for insert to authenticated
with check (
  recorded_by = auth.uid()
  and exists (
    select 1
    from public.profiles p
    where p.id = auth.uid()
      and p.branch_id = souls.branch_id
  )
  and exists (
    select 1
    from public.evangelism_events e
    where e.id = souls.evangelism_event_id
      and e.branch_id = souls.branch_id
  )
);

drop policy if exists evangelism_events_member_branch_select on public.evangelism_events;
create policy evangelism_events_member_branch_select
on public.evangelism_events for select to authenticated
using (
  exists (
    select 1 from public.profiles p
    where p.id = auth.uid()
      and p.branch_id = evangelism_events.branch_id
  )
);
