begin;
create function public.community_report_access()
returns jsonb language sql stable security definer set search_path='' as $$
 select jsonb_build_object('can_review',exists(select 1 from private.community_report_reviewers where reviewer_id=auth.uid()),
   'can_assign',exists(select 1 from public.current_access_scope() s where s.is_global_admin))
$$;
create function public.community_report_reviewers()
returns table(reviewer_id uuid,destination text,branch_id uuid)
language sql stable security definer set search_path='' as $$
 select r.reviewer_id,r.destination,r.branch_id from private.community_report_reviewers r
 where auth.uid() is not null and exists(select 1 from public.current_access_scope() s where s.is_global_admin)
$$;
revoke all on function public.community_report_access(),public.community_report_reviewers() from public,anon;
grant execute on function public.community_report_access(),public.community_report_reviewers() to authenticated;
commit;
