create unique index if not exists church_bank_accounts_scope_target_number_uidx
on public.church_bank_accounts (
  scope,
  coalesce(branch_id, '00000000-0000-0000-0000-000000000000'::uuid),
  coalesce(department_id, '00000000-0000-0000-0000-000000000000'::uuid),
  account_number
);
