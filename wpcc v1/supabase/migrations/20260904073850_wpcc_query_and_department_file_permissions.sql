-- WPCC v76: privileged worker-query assignment and department-private files.
-- This migration deliberately extends existing tables/functions rather than replacing them.

alter table public.worker_queries
  add column if not exists category text not null default 'Other',
  add column if not exists related_worker_id uuid references public.profiles(id) on delete set null;

alter table public.worker_queries
  alter column status set default 'open';

alter table public.worker_queries
  drop constraint if exists worker_queries_category_check;

alter table public.worker_queries
  add constraint worker_queries_category_check check (
    category in (
      'Attendance & Punctuality',
      'Conduct & Discipline',
      'Duty Assignment',
      'Departmental Performance',
      'Training & Development',
      'Welfare & Pastoral Care',
      'Communication',
      'Conflict Resolution',
      'Code of Conduct',
      'Safety & Safeguarding',
      'Financial & Resource Stewardship',
      'Event & Service Operations',
      'Technical & Media',
      'Facilities & Logistics',
      'Other'
    )
  );

create or replace function public.wpcc_can_assign_worker_query(target_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, auth
as $$
  select auth.uid() is not null and exists (
    select 1
    from public.profiles target
    where target.id = target_user_id
      and (
        public.churchmetric_role() = 'globaladmin'
        or (
          public.churchmetric_role() in ('admin', 'directorate')
          and target.branch_id = public.churchmetric_branch_id()
        )
        or exists (
          select 1
          from public.leaders leader
          where leader.user_id = auth.uid()
            and leader.is_active
            and leader.department_id = target.department_id
            and leader.branch_id = target.branch_id
        )
      )
  );
$$;

create or replace function public.wpcc_can_manage_department_attachment(target_department_id uuid, target_branch_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, auth
as $$
  select auth.uid() is not null and (
    public.churchmetric_role() = 'globaladmin'
    or (
      public.churchmetric_role() = 'admin'
      and target_branch_id = public.churchmetric_branch_id()
    )
    or exists (
      select 1
      from public.leaders leader
      where leader.user_id = auth.uid()
        and leader.is_active
        and leader.department_id = target_department_id
        and leader.branch_id = target_branch_id
    )
  );
$$;

create or replace function public.wpcc_can_read_department_attachment(target_department_id uuid, target_branch_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, auth
as $$
  select auth.uid() is not null and (
    public.wpcc_can_manage_department_attachment(target_department_id, target_branch_id)
    or exists (
      select 1
      from public.profile_departments membership
      where membership.profile_id = auth.uid()
        and membership.department_id = target_department_id
        and membership.branch_id = target_branch_id
    )
    or exists (
      select 1
      from public.profiles member
      where member.id = auth.uid()
        and member.department_id = target_department_id
        and member.branch_id = target_branch_id
    )
  );
$$;

revoke all on function public.wpcc_can_assign_worker_query(uuid) from public;
revoke all on function public.wpcc_can_manage_department_attachment(uuid, uuid) from public;
revoke all on function public.wpcc_can_read_department_attachment(uuid, uuid) from public;
grant execute on function public.wpcc_can_assign_worker_query(uuid) to authenticated;
grant execute on function public.wpcc_can_manage_department_attachment(uuid, uuid) to authenticated;
grant execute on function public.wpcc_can_read_department_attachment(uuid, uuid) to authenticated;

drop policy if exists worker_queries_insert_own on public.worker_queries;
create policy worker_queries_privileged_assignment
  on public.worker_queries for insert to authenticated
  with check (
    public.wpcc_can_assign_worker_query(user_id)
    and raised_by_user_id = auth.uid()
    and status = 'open'
  );

revoke update on public.worker_queries from authenticated;
grant update (
  acknowledged_at,
  requires_acknowledgement,
  response_text,
  responded_at,
  requires_response,
  updated_at
) on public.worker_queries to authenticated;

drop policy if exists department_attachments_admin_select on public.department_attachments;
drop policy if exists department_attachments_admin_insert on public.department_attachments;
drop policy if exists department_attachments_admin_update on public.department_attachments;
drop policy if exists department_attachments_admin_delete on public.department_attachments;

create policy department_attachments_department_read
  on public.department_attachments for select to authenticated
  using (public.wpcc_can_read_department_attachment(department_id, branch_id));

create policy department_attachments_department_insert
  on public.department_attachments for insert to authenticated
  with check (public.wpcc_can_manage_department_attachment(department_id, branch_id));

create policy department_attachments_department_update
  on public.department_attachments for update to authenticated
  using (public.wpcc_can_manage_department_attachment(department_id, branch_id))
  with check (public.wpcc_can_manage_department_attachment(department_id, branch_id));

create policy department_attachments_department_delete
  on public.department_attachments for delete to authenticated
  using (public.wpcc_can_manage_department_attachment(department_id, branch_id));
