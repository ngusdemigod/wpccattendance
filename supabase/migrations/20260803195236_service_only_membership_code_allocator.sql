create table if not exists public.membership_code_sequences (
  branch_id uuid primary key references public.branches(id) on delete cascade,
  code_prefix text not null default '',
  last_value bigint not null default 0 check(last_value>=0),
  code_width integer not null default 4 check(code_width between 4 and 12),
  updated_at timestamptz not null default now()
);
alter table public.membership_code_sequences enable row level security;
alter table public.membership_code_sequences force row level security;
revoke all on table public.membership_code_sequences from public,anon,authenticated;
grant select,insert,update on table public.membership_code_sequences to service_role;

insert into public.membership_code_sequences(branch_id,code_prefix,last_value,code_width)
select b.id,coalesce(b.prefix,''),
  greatest(coalesce(b.lastmember,0),coalesce(max(case when p.membership_code~'\d+$' then (regexp_match(p.membership_code,'(\d+)$'))[1]::bigint end),0)),
  greatest(4,coalesce(max(case when p.membership_code~'\d+$' then length((regexp_match(p.membership_code,'(\d+)$'))[1]) end),4))
from public.branches b left join public.profiles p on p.branch_id=b.id
group by b.id,b.prefix,b.lastmember
on conflict(branch_id) do update set
  code_prefix=excluded.code_prefix,
  last_value=greatest(public.membership_code_sequences.last_value,excluded.last_value),
  code_width=greatest(public.membership_code_sequences.code_width,excluded.code_width),
  updated_at=now();

create or replace function public.churchmetric_allocate_membership_code(p_branch_id uuid)
returns table(membership_code text,display_code text)
language plpgsql
security invoker
set search_path=''
as $$
declare sequence_row public.membership_code_sequences%rowtype;
begin
  update public.membership_code_sequences
  set last_value=last_value+1,updated_at=now()
  where branch_id=p_branch_id
  returning * into sequence_row;
  if not found then raise exception 'membership_sequence_not_found' using errcode='P0002'; end if;
  update public.branches set lastmember=greatest(lastmember,sequence_row.last_value) where id=p_branch_id;
  membership_code:=lpad(sequence_row.last_value::text,sequence_row.code_width,'0');
  display_code:=sequence_row.code_prefix||membership_code;
  return next;
end $$;
revoke all on function public.churchmetric_allocate_membership_code(uuid) from public,anon,authenticated;
grant execute on function public.churchmetric_allocate_membership_code(uuid) to service_role;
