-- Auto Give is scheduled by the wpcc-auto-give-cron Cloudflare Worker.
-- Keep this migration idempotent for installations where pg_cron was never enabled.
do $$
declare
  target_job_id bigint;
begin
  if to_regclass('cron.job') is null then
    return;
  end if;

  for target_job_id in
    select jobid from cron.job where jobname = 'wpcc-process-auto-give'
  loop
    perform cron.unschedule(target_job_id);
  end loop;
end
$$;
