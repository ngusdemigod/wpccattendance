begin;
create temp table report_test_context as
select p.id as sender_id, p.branch_id,
  (select reviewer_id from private.community_report_reviewers where destination='central' limit 1) as reviewer_id,
  gen_random_uuid() as retry_key, null::uuid as report_id
from public.profiles p where p.branch_id is not null
  and not exists(select 1 from private.community_report_reviewers r where r.reviewer_id=p.id)
limit 1;
grant select,update on report_test_context to authenticated;
select set_config('request.jwt.claims',jsonb_build_object('sub',sender_id,'role','authenticated')::text,true) from report_test_context;
set local role authenticated;
do $$ declare v_id uuid; v_retry uuid; begin
  select retry_key into v_retry from report_test_context;
  if v_retry is null then raise exception 'Missing test fixture'; end if;
  begin
    perform * from private.community_anonymous_senders;
    raise exception 'Private identity mapping exposed';
  exception when insufficient_privilege then null; end;
  v_id:=public.community_submit_anonymous('central','Disposable rollback-only security test report.',v_retry);
  update report_test_context set report_id=v_id;
  if public.community_submit_anonymous('central','Disposable rollback-only security test report.',v_retry)<>v_id then
    raise exception 'Retry was not idempotent'; end if;
  if not exists(select 1 from public.community_anonymous_reports(false) where id=v_id) then raise exception 'Own report missing'; end if;
  if exists(select 1 from public.community_anonymous_reports(true) where id=v_id) then raise exception 'Sender has reviewer access'; end if;
  begin
    perform public.community_review_anonymous(v_id,'Closed');
    raise exception 'Unauthorized review allowed';
  exception when insufficient_privilege then null; end;
  begin
    perform public.community_assign_report_reviewer((select sender_id from report_test_context),'central');
    raise exception 'Unauthorized assignment allowed';
  exception when insufficient_privilege then null; end;
  perform public.community_submit_anonymous('central','Disposable rollback-only security test report.',gen_random_uuid());
  perform public.community_submit_anonymous('central','Disposable rollback-only security test report.',gen_random_uuid());
  begin
    perform public.community_submit_anonymous('central','Disposable rollback-only security test report.',gen_random_uuid());
    raise exception 'Rate limit failed';
  exception when program_limit_exceeded then null; end;
end $$;
reset role;
select set_config('request.jwt.claims',jsonb_build_object('sub',reviewer_id,'role','authenticated')::text,true) from report_test_context;
set local role authenticated;
do $$ declare v_id uuid; v_row jsonb; begin
  select report_id into v_id from report_test_context;
  select to_jsonb(r) into v_row from public.community_anonymous_reports(true) r where id=v_id;
  if v_row is null then raise exception 'Assigned reviewer cannot read'; end if;
  if v_row ?| array['sender_id','actor_id','profile','retry_key'] then raise exception 'Identity leaked'; end if;
  perform public.community_review_anonymous(v_id,'In review');
  perform public.community_review_anonymous(v_id,'Closed');
end $$;
reset role;
select set_config('request.jwt.claims',jsonb_build_object('sub',reviewer_id,'role','authenticated')::text,true)
from private.community_report_reviewers where destination='branch' limit 1;
set local role authenticated;
do $$ begin
  if exists(select 1 from public.community_anonymous_reports(true) where id=(select report_id from report_test_context)) then
    raise exception 'Central report leaked into branch inbox'; end if;
end $$;
reset role;
rollback;
