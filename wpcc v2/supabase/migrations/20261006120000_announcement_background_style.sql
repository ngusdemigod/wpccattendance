-- Announcement background colours (Facebook-status style).
-- Stores a key from the fixed app palette, never arbitrary CSS.
alter table public.announcements
  add column if not exists background_style text;

alter table public.announcements
  drop constraint if exists announcements_background_style_check;
alter table public.announcements
  add constraint announcements_background_style_check
  check (background_style is null or background_style in
    ('ocean','royal','forest','crimson','sunset','midnight','gold','mint'));

-- Replace the 4-argument version (a second overload would make named-argument
-- RPC calls ambiguous) with one that accepts the optional background style.
drop function if exists public.community_post_department_announcement(uuid,text,text,text);

create or replace function public.community_post_department_announcement(
  p_department_id uuid,
  p_title text,
  p_content text,
  p_media_url text default null,
  p_background_style text default null
)
returns public.announcements
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_branch uuid;
  v_row public.announcements;
  v_style text := nullif(btrim(coalesce(p_background_style,'')),'');
begin
  if auth.uid() is null then raise exception 'Authentication required' using errcode='42501'; end if;
  v_branch := public.churchmetric_branch_id();
  if v_branch is null then select p.branch_id into v_branch from public.profiles p where p.id=auth.uid(); end if;
  if v_branch is null or not public.can_manage_department_scope_content(v_branch,p_department_id) then
    raise exception 'Announcement publishing is not permitted' using errcode='42501';
  end if;
  if length(btrim(coalesce(p_title,''))) < 3 then raise exception 'Announcement title is required'; end if;
  if length(btrim(coalesce(p_content,''))) < 3 then raise exception 'Announcement message is required'; end if;
  if v_style is not null and v_style not in
    ('ocean','royal','forest','crimson','sunset','midnight','gold','mint') then
    raise exception 'Unknown announcement background' using errcode='22023';
  end if;

  insert into public.announcements(
    title,content,scope,branch_id,department_id,created_by,created_at,
    mediaurl,hasmedia,is_pinned,allow_comments,background_style
  ) values (
    btrim(p_title),btrim(p_content),'department',v_branch,p_department_id,auth.uid(),now(),
    nullif(btrim(coalesce(p_media_url,'')),''),
    nullif(btrim(coalesce(p_media_url,'')),'') is not null,false,false,v_style
  ) returning * into v_row;
  return v_row;
end;
$$;
revoke all on function public.community_post_department_announcement(uuid,text,text,text,text) from public, anon;
grant execute on function public.community_post_department_announcement(uuid,text,text,text,text) to authenticated;

notify pgrst, 'reload schema';
