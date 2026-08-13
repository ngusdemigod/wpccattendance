-- Active global administrators must always win over branch-scoped assignments.
create or replace function private.churchmetric_current_context()
returns table(role_name text, branch_id uuid, department_id uuid)
language sql
stable
security definer
set search_path = ''
as $$
  select
    lower(r.rolename),
    coalesce(r.branch_id, w.branch_id),
    coalesce(r.department_id, w.department_id)
  from public.roles r
  left join public.workers w on w.user_id = r.memberid
  where r.memberid = auth.uid()
    and auth.uid() is not null
    and r.is_active is true
  order by
    case when lower(r.rolename) = 'globaladmin' then 0 else 1 end,
    r.is_primary desc,
    r.assigned_at desc,
    r.id desc
  limit 1
$$;

revoke all on function private.churchmetric_current_context() from public, anon;
grant execute on function private.churchmetric_current_context() to authenticated;

-- Repair the newly provisioned global administrator's assignment.
update public.roles
set is_primary = false
where memberid = 'f3732027-f05a-423c-a51a-ca2bda86b2f2'::uuid
  and is_active is true
  and lower(rolename) <> 'globaladmin';

update public.roles
set is_primary = true
where memberid = 'f3732027-f05a-423c-a51a-ca2bda86b2f2'::uuid
  and is_active is true
  and lower(rolename) = 'globaladmin';
