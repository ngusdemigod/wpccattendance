create or replace function public.wpcc_clock_out_attendance(
  p_attendance_id uuid,
  p_latitude numeric,
  p_longitude numeric
)
returns table(id uuid, clockout timestamptz)
language plpgsql
security definer
set search_path = ''
as $$
declare v_now timestamptz := now();
begin
  return query
  update public.attendance a
  set clockout=v_now, closedlat=p_latitude, closedlong=p_longitude
  where a.id=p_attendance_id and a.clockout is null
  returning a.id,a.clockout;
end;
$$;
revoke all on function public.wpcc_clock_out_attendance(uuid,numeric,numeric) from public,anon,authenticated;
grant execute on function public.wpcc_clock_out_attendance(uuid,numeric,numeric) to service_role;

revoke all on function public.wpcc_refresh_post_reaction_counts() from public,anon,authenticated;
revoke all on function public.wpcc_refresh_post_comment_count() from public,anon,authenticated;
revoke all on function public.wpcc_preserve_post_creator() from public,anon,authenticated;
revoke all on function public.wpcc_set_comment_author() from public,anon,authenticated;
revoke all on function public.wpcc_set_reaction_author() from public,anon,authenticated;
revoke all on function public.wpcc_prayer_alert_before_write() from public,anon,authenticated;
revoke all on function public.wpcc_push_subscription_before_write() from public,anon,authenticated;
