create temporary table churchmetric_membership_sequence_seed on commit drop as
select
  greatest(
    coalesce((select max(last_value) from public.membership_code_sequences),0),
    coalesce((select max((regexp_match(membership_code,'(\d+)$'))[1]::bigint) from public.profiles where membership_code~'\d+$'),0)
  )::bigint as last_value,
  greatest(
    4,
    coalesce((select max(code_width) from public.membership_code_sequences),4),
    coalesce((select max(length((regexp_match(membership_code,'(\d+)$'))[1])) from public.profiles where membership_code~'\d+$'),4)
  )::integer as code_width;

drop function if exists public.churchmetric_allocate_membership_code(uuid);
drop table public.membership_code_sequences;

create table public.membership_code_sequences (
  sequence_name text primary key check(sequence_name='global'),
  last_value bigint not null default 0 check(last_value>=0),
  code_width integer not null default 4 check(code_width between 4 and 12),
  updated_at timestamptz not null default now()
);
insert into public.membership_code_sequences(sequence_name,last_value,code_width)
select 'global',last_value,code_width from churchmetric_membership_sequence_seed;
alter table public.membership_code_sequences enable row level security;
alter table public.membership_code_sequences force row level security;
revoke all on table public.membership_code_sequences from public,anon,authenticated;
grant select,update on table public.membership_code_sequences to service_role;

create or replace function public.churchmetric_allocate_membership_code()
returns table(membership_code text,display_code text)
language plpgsql
security invoker
set search_path=''
as $$
declare sequence_row public.membership_code_sequences%rowtype;
begin
  update public.membership_code_sequences
  set last_value=last_value+1,updated_at=now()
  where sequence_name='global'
  returning * into sequence_row;
  if not found then raise exception 'membership_sequence_not_found' using errcode='P0002'; end if;
  membership_code:=lpad(sequence_row.last_value::text,sequence_row.code_width,'0');
  display_code:=membership_code;
  return next;
end $$;
revoke all on function public.churchmetric_allocate_membership_code() from public,anon,authenticated;
grant execute on function public.churchmetric_allocate_membership_code() to service_role;
