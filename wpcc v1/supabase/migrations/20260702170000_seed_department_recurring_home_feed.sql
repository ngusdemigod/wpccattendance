insert into public.departmental_recurring_events (
  id,
  title,
  description,
  recurrence_type,
  day_of_week,
  week_of_month,
  day_of_month,
  month,
  start_time,
  end_time,
  featured_url,
  branch_id,
  department_id,
  is_active,
  created_by,
  created_at,
  updated_at
)
select
  seed.id,
  seed.title,
  seed.description,
  seed.recurrence_type,
  seed.day_of_week,
  seed.week_of_month,
  seed.day_of_month,
  seed.month,
  seed.start_time,
  seed.end_time,
  seed.featured_url,
  seed.branch_id,
  seed.department_id,
  seed.is_active,
  seed.created_by,
  now(),
  now()
from (
  values
    (
      'ccf00d8d-6581-47cf-bacf-1d16fdd81251'::uuid,
      'Media Prayer Charge'::text,
      'Weekly department prayer and planning huddle before service coverage assignments begin.'::text,
      'weekly'::varchar(10),
      4,
      null::integer,
      null::integer,
      null::integer,
      '17:30:00'::time,
      '19:00:00'::time,
      'https://pub-ad39479f015849b38cbe74e76712d1e4.r2.dev/pfp/24f737eb-9001-46a9-89a8-11f8a75b43d7/1776286901899_scaled_659626174_18368307715204822_2743028741766509114_n.jpg'::text,
      'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53'::uuid,
      'dcea05e8-fc39-4851-935c-808643593c73'::uuid,
      true,
      'home_feed_seed'::text
    ),
    (
      'a6c678ec-fddd-4969-b1c6-e0602aadf23f'::uuid,
      'Sunday Broadcast Prep'::text,
      'Departmental recurring prep slot for cameras, graphics, projection, and audio checks.'::text,
      'weekly'::varchar(10),
      0,
      null::integer,
      null::integer,
      null::integer,
      '07:30:00'::time,
      '08:30:00'::time,
      'https://pub-ad39479f015849b38cbe74e76712d1e4.r2.dev/pfp/24f737eb-9001-46a9-89a8-11f8a75b43d7/1776287000713_scaled_656837334_18367733518204822_6430428026206091633_n.jpg'::text,
      'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53'::uuid,
      'dcea05e8-fc39-4851-935c-808643593c73'::uuid,
      true,
      'home_feed_seed'::text
    )
) as seed(
  id,
  title,
  description,
  recurrence_type,
  day_of_week,
  week_of_month,
  day_of_month,
  month,
  start_time,
  end_time,
  featured_url,
  branch_id,
  department_id,
  is_active,
  created_by
)
join public.branches b
  on b.id = seed.branch_id
join public.departments d
  on d.id = seed.department_id
on conflict (id) do update
set
  title = excluded.title,
  description = excluded.description,
  recurrence_type = excluded.recurrence_type,
  day_of_week = excluded.day_of_week,
  week_of_month = excluded.week_of_month,
  day_of_month = excluded.day_of_month,
  month = excluded.month,
  start_time = excluded.start_time,
  end_time = excluded.end_time,
  featured_url = excluded.featured_url,
  branch_id = excluded.branch_id,
  department_id = excluded.department_id,
  is_active = excluded.is_active,
  created_by = excluded.created_by,
  updated_at = now();
