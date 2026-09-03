insert into public.global_events (
  id,
  title,
  description,
  event_start_at,
  event_end_at,
  featured_url,
  location,
  latitude,
  longitude,
  is_active,
  created_by,
  created_at,
  updated_at
)
values
  (
    '8dc9f7a1-6f3f-4b5b-8fa7-42a2c2d41511'::uuid,
    'Media Command Run-through',
    'Ongoing coordination for cameras, livestream, and projection teams before service.',
    timezone('utc', now()) - interval '45 minutes',
    timezone('utc', now()) + interval '1 hour 15 minutes',
    null,
    'plot 11, road 4, mile 4, rumueme port harcourt',
    4.808408655311953,
    6.9752055478703,
    true,
    'migration_seed',
    timezone('utc', now()),
    timezone('utc', now())
  ),
  (
    'cb4c07b2-f5dd-4ffd-a2e8-9c28ce0d8e12'::uuid,
    'Workers Welfare Stand-up',
    'Ongoing coordination for welfare support, seating, and member assistance coverage.',
    timezone('utc', now()) - interval '30 minutes',
    timezone('utc', now()) + interval '2 hours',
    null,
    'plot 11, road 4, mile 4, rumueme port harcourt',
    4.808408655311953,
    6.9752055478703,
    true,
    'migration_seed',
    timezone('utc', now()),
    timezone('utc', now())
  ),
  (
    '2a8b6f0f-7c03-41db-a61c-0ff6d13af713'::uuid,
    'Dream Team Prayer Circle',
    'Ongoing prayer and response coverage for active workers on site.',
    timezone('utc', now()) - interval '15 minutes',
    timezone('utc', now()) + interval '2 hours 30 minutes',
    null,
    'plot 11, road 4, mile 4, rumueme port harcourt',
    4.808408655311953,
    6.9752055478703,
    true,
    'migration_seed',
    timezone('utc', now()),
    timezone('utc', now())
  )
on conflict (id) do update
set
  title = excluded.title,
  description = excluded.description,
  event_start_at = excluded.event_start_at,
  event_end_at = excluded.event_end_at,
  location = excluded.location,
  latitude = excluded.latitude,
  longitude = excluded.longitude,
  is_active = excluded.is_active,
  updated_at = timezone('utc', now());

insert into public.leaders (
  id,
  user_id,
  department_id,
  branch_id,
  created_at,
  title_id,
  is_active,
  start_date,
  end_date
)
select
  '16e2f57c-43e7-42c4-8454-8d6c5ebfd8f1'::uuid,
  p.id,
  d.id,
  p.branch_id,
  timezone('utc', now()),
  lt.id,
  true,
  timezone('utc', now()),
  null
from public.profiles p
join public.departments d
  on d.name = 'Media & Technical'
join public.leadership_titles lt
  on lt.code = 'department_officer'
where p.id = 'f2462d49-68c2-4e33-88e6-01de6fc62d42'::uuid
on conflict (id) do update
set
  department_id = excluded.department_id,
  branch_id = excluded.branch_id,
  title_id = excluded.title_id,
  is_active = true,
  end_date = null;
