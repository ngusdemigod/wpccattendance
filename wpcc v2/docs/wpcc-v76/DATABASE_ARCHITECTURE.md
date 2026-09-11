# Suggested Database Architecture and Existing-Data Reuse Guide

This is a **decision guide**, not a migration specification. The repository already contains a substantial Supabase model. Codex must inspect actual columns, keys, views, functions, triggers and policies before proposing SQL.

## Existing tables

- `academy_instructor_assignments`
- `academy_instructors`
- `academy_module_attachments`
- `academy_modules`
- `academy_sessions`
- `access_control_audit_log`
- `access_control_verifications`
- `admin_access_assignments`
- `announcement_acknowledgements`
- `announcement_comments`
- `announcement_media`
- `announcements`
- `attendance`
- `attendance_audit_logs`
- `branch_events`
- `branch_recurring_events`
- `branches`
- `broadcast_campaigns`
- `broadcast_delivery_events`
- `broadcast_recipients`
- `churchmetric_audit_events`
- `comments`
- `communication_templates`
- `course_enrollments`
- `course_publications`
- `courses`
- `department_attachments`
- `department_requests`
- `departmental_events`
- `departmental_recurring_events`
- `departments`
- `email_rate_limits`
- `enquiries`
- `enquiry_messages`
- `evangelism_events`
- `events_legacy`
- `global_admins`
- `global_events`
- `global_recurring_events`
- `leaders`
- `leadership_titles`
- `member_deletion_authorizations`
- `member_update_verifications`
- `membership_code_sequences`
- `membershipcode`
- `notification_outbox`
- `otp_cooldowns`
- `penalties`
- `post_reactions`
- `posts`
- `profile_departments`
- `profile_key_recipients`
- `profiles`
- `profiles_priv_info`
- `profileverification`
- `provider_webhook_events`
- `quality_issues`
- `quality_queries`
- `quality_query_assignees`
- `quality_reports`
- `quality_status_history`
- `recurring_events_legacy`
- `roles`
- `roletypes`
- `soul_followups`
- `souls`
- `target_achievements`
- `target_progress_events`
- `targets`
- `worker_private_profiles`
- `worker_queries`
- `workers`

## Feature-to-existing-table preference

| Feature | Prefer inspecting/reusing first | Only if genuinely missing |
|---|---|---|
| Member profile | `profiles`, `profiles_priv_info`, `worker_private_profiles`, `workers` | Safe public-profile view/RPC or missing field, preserving privacy |
| Department memberships | `profile_departments`, `departments`, `workers` | Small relation/index only if required |
| Department leadership | `leaders`, `leadership_titles` | Avoid parallel leadership model |
| Department files | `department_attachments` + existing Storage bucket | Visibility field/policy if absent |
| Events | departmental/branch/global event tables and recurring variants | Unified read view/RPC/adaptor if current repos cannot aggregate |
| Attendance | `attendance`, `attendance_audit_logs` | View/RPC for event counts/time ranking if needed |
| Announcements | `announcements`, `announcement_media`, `announcement_comments`, acknowledgements | Missing scope relation only |
| Devotional | `posts`, `post_reactions`, `comments` | Post type/category discriminator only if absent |
| Classes | course and academy tables | No new learning domain without proof of gap |
| Queries | `worker_queries` | Extend only if workflow cannot be represented |
| Souls | `souls`, `soul_followups` | No new table anticipated |
| Notifications | `notification_outbox`, broadcast tables | Extend provider adapter only if required |
| Paystack webhooks | `provider_webhook_events` if intended for this | New provider ledger only if existing table is not suitable |
| Giving | inspect full schema/code for unlisted tables first | `church_bank_accounts`, `giving_projects`, `giving_transactions`, `recurring_giving_mandates` as minimal suggestions |
| Prayer alerts | inspect notification/calendar code first | `prayer_alerts` only if server/global/cross-device persistence is missing |

## Suggested giving model if no existing model exists

### church_bank_accounts
- id
- branch_id / global scope according to existing branch model
- bank_name
- account_name
- account_number
- display_order
- style_variant (`dark`, `light`, `warm`) or derive in UI
- is_active
- created_at / updated_at

### giving_projects
- id
- branch_id or global scope
- title
- description
- image/storage reference
- status (`draft`, `active`, `closed`)
- optional target amount if product requires it
- starts_at / ends_at

### giving_transactions
- id
- profile_id
- branch_id
- giving_type (`offering`, `tithe`, `prophet_offering`, `project`, `auto_give`)
- project_id nullable
- amount in backend's established money representation
- currency
- internal_reference unique
- paystack_reference / provider transaction id
- status
- payment_channel/source summary
- metadata JSON only for provider extras; do not hide core relational fields in JSON
- initiated_at / paid_at / failed_at / created_at / updated_at

### recurring_giving_mandates
- id
- profile_id
- branch_id
- amount
- giving_type
- selected event-day/rule representation compatible with existing recurrence model
- Paystack customer/authorization references only; no raw card data
- status
- next_charge_at
- last_charge_at
- created_at / updated_at

## Department file access

If `department_attachments` lacks access control, a minimal `visibility` enum is preferred:

- `members` - department members and authorized leaders.
- `leaders` - department leaders / higher authorized roles only.

Storage access must enforce the same rule. Prefer private buckets + signed URLs or existing protected delivery pattern over public bucket URLs for leaders-only assets.

## Public member profile

Do not simply join private tables into a client query. Prefer an existing safe projection. If missing, consider a security-reviewed view/RPC that returns only:

- profile id
- display/full name
- approved public phone
- profile image reference / initials fallback data
- departments visible to the requesting member

## Attendance query shape

For Department Attendance event list, desired output is conceptually:

- event identity + source scope
- event title/start/end
- present count

For event attendee sheet:

- profile id/name/avatar data
- `check_in_at`
- `delta_seconds = check_in_at - event_start_at`
- sorted `check_in_at ASC`

Use an existing query/repository if present. Otherwise a view/RPC may avoid N+1 calls.

## Prayer Alerts

Do not add leaderboard/streak tables. For this phase:

- Personal reminder -> calendar file / local preference as supported.
- Global reminder -> authorized server record only if required + notification outbox.
- Push notification delivery -> existing notification pipeline.
- If `.ics` support does not exist, propose it as the fallback calendar-file format.
