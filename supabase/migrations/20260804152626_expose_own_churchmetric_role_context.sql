-- Permit each authenticated user to resolve only their own non-sensitive role
-- assignment. RLS prevents directory-style access to other users' roles.
grant select (memberid, rolename, branch_id, department_id, is_active, is_primary, assigned_at)
on public.roles to authenticated;

create policy churchmetric_roles_select_own
on public.roles for select to authenticated
using (memberid = auth.uid());
