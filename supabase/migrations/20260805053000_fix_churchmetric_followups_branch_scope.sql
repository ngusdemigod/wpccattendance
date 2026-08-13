create or replace function public.churchmetric_followups_v1(
  p_branch_id uuid default null,
  p_search text default null,
  p_status text default null,
  p_page integer default 1,
  p_page_size integer default 25
) returns jsonb
language plpgsql
security invoker
set search_path=''
stable
as $$
declare
  page_number integer:=greatest(coalesce(p_page,1),1);
  page_limit integer:=greatest(1,least(coalesce(p_page_size,25),100));
  result jsonb;
begin
  if p_branch_id is not null and not public.churchmetric_can_manage_branch(p_branch_id) then
    raise exception 'not_authorized' using errcode='42501';
  end if;
  with scoped as (
    select c.*,
      count(r.id)::integer total_recipients,
      count(r.id) filter(where r.status in ('sent','delivered'))::integer completed_recipients,
      count(r.id) filter(where r.status='failed')::integer failed_recipients
    from public.broadcast_campaigns c
    left join public.broadcast_recipients r on r.campaign_id=c.id and r.branch_id=c.branch_id
    where (p_branch_id is null or c.branch_id=p_branch_id)
      and (nullif(btrim(p_search),'') is null or c.name ilike '%'||btrim(p_search)||'%' or c.subject ilike '%'||btrim(p_search)||'%')
      and (nullif(btrim(p_status),'') is null or c.status=p_status)
    group by c.id
  ), counted as (select count(*) total from scoped),
  page_rows as (
    select * from scoped order by created_at desc
    offset (page_number-1)*page_limit limit page_limit
  ), all_metrics as (
    select count(*) filter(where status='sent')::integer campaigns_sent,
      coalesce(sum(completed_recipients),0)::integer recipients_reached,
      coalesce(sum(completed_recipients),0)::numeric completed,
      coalesce(sum(total_recipients),0)::numeric total,
      count(*) filter(where channel='call' and status not in ('sent','cancelled','failed'))::integer calls_pending
    from scoped
  )
  select jsonb_build_object(
    'metrics',jsonb_build_object('campaigns_sent',m.campaigns_sent,'recipients_reached',m.recipients_reached,
      'delivery_rate',case when m.total=0 then 0 else round(m.completed*100/m.total) end,'calls_pending',m.calls_pending),
    'items',coalesce((select jsonb_agg(to_jsonb(x) order by x.created_at desc) from page_rows x),'[]'::jsonb),
    'pagination',jsonb_build_object('page',page_number,'page_size',page_limit,'total',(select total from counted))
  ) into result from all_metrics m;
  return result;
end $$;

revoke all on function public.churchmetric_followups_v1(uuid,text,text,integer,integer) from public,anon;
grant execute on function public.churchmetric_followups_v1(uuid,text,text,integer,integer) to authenticated;
