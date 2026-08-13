do $$
declare
  relationship record;
  delete_action text;
begin
  for relationship in
    select fk.conname, fk.conrelid, fk.confrelid, a.attname column_name
    from pg_constraint fk
    join lateral unnest(fk.conkey) k(attnum) on true
    join pg_attribute a on a.attrelid=fk.conrelid and a.attnum=k.attnum
    where fk.contype='f'
      and fk.confrelid in ('public.profiles'::regclass,'auth.users'::regclass)
      and fk.confdeltype in ('a','r')
  loop
    delete_action := case
      when relationship.conrelid in (
        'public.attendance'::regclass,
        'public.course_enrollments'::regclass,
        'public.membershipcode'::regclass,
        'public.profileverification'::regclass,
        'public.roles'::regclass,
        'public.quality_query_assignees'::regclass,
        'public.academy_instructors'::regclass,
        'public.broadcast_recipients'::regclass
      ) and relationship.column_name in (
        'user_id','memberid','assignee_id','profile_id'
      ) then 'CASCADE'
      when relationship.conrelid='public.penalties'::regclass and relationship.column_name='user_id' then 'CASCADE'
      else 'SET NULL'
    end;

    if delete_action='SET NULL' then
      execute format('alter table %s alter column %I drop not null',relationship.conrelid::regclass,relationship.column_name);
    end if;
    execute format('alter table %s drop constraint %I',relationship.conrelid::regclass,relationship.conname);
    execute format(
      'alter table %s add constraint %I foreign key (%I) references %s(id) on delete %s',
      relationship.conrelid::regclass,
      relationship.conname,
      relationship.column_name,
      relationship.confrelid::regclass,
      delete_action
    );
  end loop;
end $$;
