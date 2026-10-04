update public.church_bank_accounts
set
  bank_logo_object_key = case regexp_replace(lower(bank_name), '[^a-z0-9]+', '', 'g')
    when 'gtbank' then 'assets/banks/gtbank.png'
    when 'accessbank' then 'assets/banks/access-bank.png'
    when 'opay' then 'assets/banks/opay.png'
    when 'zenithbank' then 'assets/banks/zenith-bank.png'
    when 'firstbank' then 'assets/banks/firstbank.png'
  end,
  bank_logo_url = case regexp_replace(lower(bank_name), '[^a-z0-9]+', '', 'g')
    when 'gtbank' then 'https://api.wisdompowercc.org/functions/v1/bank-assets?bank=gtbank'
    when 'accessbank' then 'https://api.wisdompowercc.org/functions/v1/bank-assets?bank=access-bank'
    when 'opay' then 'https://api.wisdompowercc.org/functions/v1/bank-assets?bank=opay'
    when 'zenithbank' then 'https://api.wisdompowercc.org/functions/v1/bank-assets?bank=zenith-bank'
    when 'firstbank' then 'https://api.wisdompowercc.org/functions/v1/bank-assets?bank=firstbank'
  end
where regexp_replace(lower(bank_name), '[^a-z0-9]+', '', 'g')
  in ('gtbank', 'accessbank', 'opay', 'zenithbank', 'firstbank');
