alter table public.department_attachments
  add column if not exists bucket_name text not null default 'wpcc-private',
  add column if not exists checksum_sha256 text;
alter table public.academy_module_attachments
  add column if not exists bucket_name text not null default 'wpcc-private',
  add column if not exists checksum_sha256 text;
