alter table public.course_enrollments
  add column if not exists session_id uuid references public.academy_sessions(id) on delete set null;
create index if not exists course_enrollments_session_idx on public.course_enrollments(session_id,status);
