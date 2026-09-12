alter table public.church_bank_accounts
  add column if not exists bank_logo_url text,
  add column if not exists bank_logo_object_key text;

update public.church_bank_accounts
set
  bank_logo_object_key = case lower(regexp_replace(bank_name, '[^a-z0-9]+', '', 'g'))
    when 'gtbank' then 'assets/banks/gtbank.png'
    when 'accessbank' then 'assets/banks/access-bank.png'
    when 'opay' then 'assets/banks/opay.png'
    when 'zenithbank' then 'assets/banks/zenith-bank.png'
    when 'firstbank' then 'assets/banks/firstbank.png'
  end,
  bank_logo_url = case lower(regexp_replace(bank_name, '[^a-z0-9]+', '', 'g'))
    when 'gtbank' then 'https://pgpihzhvysbadrzjhvxw.supabase.co/functions/v1/bank-assets?bank=gtbank'
    when 'accessbank' then 'https://pgpihzhvysbadrzjhvxw.supabase.co/functions/v1/bank-assets?bank=access-bank'
    when 'opay' then 'https://pgpihzhvysbadrzjhvxw.supabase.co/functions/v1/bank-assets?bank=opay'
    when 'zenithbank' then 'https://pgpihzhvysbadrzjhvxw.supabase.co/functions/v1/bank-assets?bank=zenith-bank'
    when 'firstbank' then 'https://pgpihzhvysbadrzjhvxw.supabase.co/functions/v1/bank-assets?bank=firstbank'
  end
where lower(regexp_replace(bank_name, '[^a-z0-9]+', '', 'g'))
  in ('gtbank', 'accessbank', 'opay', 'zenithbank', 'firstbank');
