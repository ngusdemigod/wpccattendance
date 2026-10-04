-- These views contain the signed-in worker's scoped event feed.
-- Keep them unavailable to unauthenticated Data API callers.
revoke all on table public.my_events from anon;
revoke all on table public.my_recurring_events from anon;

grant select on table public.my_events to authenticated;
grant select on table public.my_recurring_events to authenticated;
