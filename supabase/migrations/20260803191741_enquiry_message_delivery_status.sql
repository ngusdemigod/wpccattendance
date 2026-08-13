alter table public.enquiry_messages
  add column if not exists delivery_status text not null default 'sent'
  check (delivery_status in ('queued','sent','failed'));
