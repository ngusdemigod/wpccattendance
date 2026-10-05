begin;
-- One-time user-authorized assignment; future admin roles do not inherit access.
alter table private.community_report_audit alter column actor_id drop not null;
with candidates as (
  select distinct r.memberid as reviewer_id, 'branch'::text as destination,r.branch_id
  from public.roles r join public.profiles p on p.id=r.memberid
  where coalesce(r.is_active,true) and lower(r.rolename)='admin'
    and lower(r.scope_type)='branch' and r.branch_id is not null
  union
  select distinct r.memberid,'central',null::uuid from public.roles r
  join public.profiles p on p.id=r.memberid
  where coalesce(r.is_active,true) and lower(r.rolename)='globaladmin' and lower(r.scope_type)='global'
  union
  select ga.id,'central',null::uuid from public.global_admins ga
  join public.profiles p on p.id=ga.id where coalesce(ga.is_active,true)
), inserted as (
  insert into private.community_report_reviewers(reviewer_id,destination,branch_id)
  select reviewer_id,destination,branch_id from candidates on conflict do nothing returning *
)
insert into private.community_report_audit(action,details)
select 'reviewer_assigned',jsonb_build_object('reviewer',reviewer_id,'destination',destination,
  'branch',branch_id,'source','User-authorized initial admin assignment') from inserted;
commit;
