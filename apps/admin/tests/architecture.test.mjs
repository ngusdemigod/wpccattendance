import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import test from "node:test";

const root=new URL("../../../",import.meta.url);
const migration=readFileSync(new URL("supabase/migrations/20260803180614_churchmetric_admin_domains.sql",root),"utf8").toLowerCase();
const workerMigration=readFileSync(new URL("supabase/migrations/20260803191104_churchmetric_email_outbox_worker.sql",root),"utf8").toLowerCase();
const emailWorker=readFileSync(new URL("supabase/functions/dispatch-churchmetric-email/index.ts",root),"utf8");
const memberMigration=readFileSync(new URL("supabase/migrations/20260803195920_make_membership_code_allocator_global.sql",root),"utf8").toLowerCase();
const memberAllocatorRename=readFileSync(new URL("supabase/migrations/20260812041529_rename_wpcc_membership_allocator.sql",root),"utf8");
const memberAllocatorFinalRename=readFileSync(new URL("supabase/migrations/20260812063927_rename_wpcc_member_code_allocator.sql",root),"utf8");
const memberFunction=readFileSync(new URL("supabase/functions/create-churchmetric-member/index.ts",root),"utf8");
const privateFilesFunction=readFileSync(new URL("supabase/functions/churchmetric-private-files/index.ts",root),"utf8");
const overviewMigration=readFileSync(new URL("supabase/migrations/20260804144556_churchmetric_overview_activity.sql",root),"utf8").toLowerCase();
const analyticsMigration=readFileSync(new URL("supabase/migrations/20260804160707_churchmetric_analytics_report_v1.sql",root),"utf8").toLowerCase();
const dashboardQueries=readFileSync(new URL("apps/admin/src/features/dashboard/queries.ts",root),"utf8");
const dashboardFilters=readFileSync(new URL("apps/admin/src/features/dashboard/dashboard-filters.tsx",root),"utf8");
const dashboardShell=readFileSync(new URL("apps/admin/src/features/dashboard/dashboard-shell.tsx",root),"utf8");
const analyticsReport=readFileSync(new URL("apps/admin/src/features/dashboard/analytics-report.tsx",root),"utf8");
const pageAction=readFileSync(new URL("apps/admin/src/features/dashboard/page-action.tsx",root),"utf8");
const interactiveDirectory=readFileSync(new URL("apps/admin/src/features/dashboard/interactive-directory.tsx",root),"utf8");
const memberProfileRoute=readFileSync(new URL("apps/admin/src/app/api/members/[memberId]/route.ts",root),"utf8");
const memberExportRoute=readFileSync(new URL("apps/admin/src/app/api/members/export/route.ts",root),"utf8");
const memberActivityMigration=readFileSync(new URL("supabase/migrations/20260810112613_member_activity_status.sql",root),"utf8").toLowerCase();
const memberDepartmentsMigration=readFileSync(new URL("supabase/migrations/20260811181418_member_departments_and_otp_cooldown.sql",root),"utf8").toLowerCase();
const memberSortMigration=readFileSync(new URL("supabase/migrations/20260812082445_members_recent_filter_and_sort.sql",root),"utf8").toLowerCase();
const memberUpdateFunction=readFileSync(new URL("supabase/functions/update-churchmetric-member/index.ts",root),"utf8");
const membersDirectory=readFileSync(new URL("apps/admin/src/features/dashboard/members-directory.tsx",root),"utf8");
const memberEditor=readFileSync(new URL("apps/admin/src/features/dashboard/member-details-editor.tsx",root),"utf8");
const eventsMigration=readFileSync(new URL("supabase/migrations/20260804170522_churchmetric_events_report_v1.sql",root),"utf8").toLowerCase();
const eventAttendanceRoute=readFileSync(new URL("apps/admin/src/app/api/events/[eventId]/attendance/route.ts",root),"utf8");
const eventAttendanceDetail=readFileSync(new URL("apps/admin/src/features/dashboard/event-attendance-detail.tsx",root),"utf8");
const soulWinningMigration=readFileSync(new URL("supabase/migrations/20260804174538_churchmetric_soul_winning_v1.sql",root),"utf8").toLowerCase();
const soulTransitionMigration=readFileSync(new URL("supabase/migrations/20260803201232_soul_followup_status_machine.sql",root),"utf8").toLowerCase();
const eventSoulsRoute=readFileSync(new URL("apps/admin/src/app/api/evangelism-events/[eventId]/souls/route.ts",root),"utf8");
const soulDirectory=readFileSync(new URL("apps/admin/src/features/dashboard/soul-winning-directory.tsx",root),"utf8");
const eventSoulsDetail=readFileSync(new URL("apps/admin/src/features/dashboard/event-souls-detail.tsx",root),"utf8");
const departmentsMigration=readFileSync(new URL("supabase/migrations/20260804181332_churchmetric_departments_report_v1.sql",root),"utf8").toLowerCase();
const departmentGrid=readFileSync(new URL("apps/admin/src/features/dashboard/department-grid.tsx",root),"utf8");
const departmentDetailMigration=readFileSync(new URL("supabase/migrations/20260804184745_churchmetric_department_detail_v1.sql",root),"utf8").toLowerCase();
const departmentAttachments=readFileSync(new URL("apps/admin/src/features/dashboard/department-attachments.tsx",root),"utf8");
const departmentDetailDirectory=readFileSync(new URL("apps/admin/src/features/dashboard/department-detail-directory.tsx",root),"utf8");
const departmentExport=readFileSync(new URL("apps/admin/src/features/dashboard/department-directory-export.tsx",root),"utf8");
const departmentExportRoute=readFileSync(new URL("apps/admin/src/app/api/departments/[departmentId]/members-export/route.ts",root),"utf8");
const enquiriesMigration=readFileSync(new URL("supabase/migrations/20260804210804_churchmetric_enquiries_v1.sql",root),"utf8").toLowerCase();
const enquiryWorkspace=readFileSync(new URL("apps/admin/src/features/dashboard/enquiry-workspace.tsx",root),"utf8");
const qualityReportsMigration=readFileSync(new URL("supabase/migrations/20260804225500_churchmetric_quality_reports_v1.sql",root),"utf8").toLowerCase();
const qualityReportsDirectory=readFileSync(new URL("apps/admin/src/features/dashboard/quality-reports-directory.tsx",root),"utf8");
const qualityQueriesMigration=readFileSync(new URL("supabase/migrations/20260804233000_churchmetric_quality_queries_v1.sql",root),"utf8").toLowerCase();
const qualityQueryAliasMigration=readFileSync(new URL("supabase/migrations/20260804234500_fix_quality_query_assignee_alias.sql",root),"utf8").toLowerCase();
const qualityQueriesDirectory=readFileSync(new URL("apps/admin/src/features/dashboard/quality-queries-directory.tsx",root),"utf8");
const qualityIssuesMigration=readFileSync(new URL("supabase/migrations/20260805000500_churchmetric_quality_issues_v1.sql",root),"utf8").toLowerCase();
const qualityIssuesDirectory=readFileSync(new URL("apps/admin/src/features/dashboard/quality-issues-directory.tsx",root),"utf8");
const academyClassesMigration=readFileSync(new URL("supabase/migrations/20260805013000_churchmetric_academy_classes_v1.sql",root),"utf8").toLowerCase();
const academyClassesDirectory=readFileSync(new URL("apps/admin/src/features/dashboard/academy-classes-directory.tsx",root),"utf8");
const academySessionExport=readFileSync(new URL("apps/admin/src/app/api/academy/classes/[courseId]/session-export/route.ts",root),"utf8");
const academyEnrolmentsMigration=readFileSync(new URL("supabase/migrations/20260805024500_churchmetric_academy_enrolments_v1.sql",root),"utf8").toLowerCase();
const academyEnrolmentsDirectory=readFileSync(new URL("apps/admin/src/features/dashboard/academy-enrolments-directory.tsx",root),"utf8");
const academyInstructorsMigration=readFileSync(new URL("supabase/migrations/20260805040000_churchmetric_academy_instructors_v1.sql",root),"utf8").toLowerCase();
const academyInstructorsDirectory=readFileSync(new URL("apps/admin/src/features/dashboard/academy-instructors-directory.tsx",root),"utf8");
const sessionFilter=readFileSync(new URL("apps/admin/src/features/dashboard/session-filter.tsx",root),"utf8");
const followupsMigration=readFileSync(new URL("supabase/migrations/20260805051500_churchmetric_followups_v1.sql",root),"utf8").toLowerCase();
const followupsScopeFix=readFileSync(new URL("supabase/migrations/20260805053000_fix_churchmetric_followups_branch_scope.sql",root),"utf8").toLowerCase();
const followupComposer=readFileSync(new URL("apps/admin/src/features/dashboard/follow-up-composer.tsx",root),"utf8");
const broadcastHistory=readFileSync(new URL("apps/admin/src/features/dashboard/broadcast-history-panel.tsx",root),"utf8");
const emailScheduler=readFileSync(new URL("cloudflare/churchmetric-email-scheduler/src/index.js",root),"utf8");
const emailSchedulerConfig=readFileSync(new URL("cloudflare/churchmetric-email-scheduler/wrangler.jsonc",root),"utf8");
const targetsMigration=readFileSync(new URL("supabase/migrations/20260805060000_churchmetric_targets_v1.sql",root),"utf8").toLowerCase();
  const targetsDirectory=readFileSync(new URL("apps/admin/src/features/dashboard/targets-directory.tsx",root),"utf8");
  const awardsGallery=readFileSync(new URL("apps/admin/src/features/dashboard/awards-gallery.tsx",root),"utf8");
const mutations=readFileSync(new URL("apps/admin/src/features/dashboard/mutations.ts",root),"utf8");
const config=readFileSync(new URL("apps/admin/src/features/dashboard/page-config.ts",root),"utf8");
  const routes=["analytics","members","events","soul-winning","departments","enquiries","quality-control/reports","quality-control/queries","quality-control/issues","academy/classes","academy/enrolments","academy/instructors","follow-ups","targets","awards"];
const branchTables=["evangelism_events","souls","soul_followups","enquiries","enquiry_messages","quality_reports","quality_queries","quality_query_assignees","quality_issues","quality_status_history","department_attachments","academy_modules","academy_module_attachments","academy_sessions","academy_instructors","academy_instructor_assignments","communication_templates","broadcast_campaigns","broadcast_recipients","broadcast_delivery_events","targets","target_progress_events","target_achievements","notification_outbox","churchmetric_audit_events"];

test("all 16 prompt routes resolve through dashboard configuration",()=>{
  assert.match(config,/"":\s*\{/,"overview route is missing");
  for(const route of routes)assert.ok(config.includes(`"${route}"`)||config.includes(`${route}:`),`${route} is missing`);
  assert.match(config,/path\.startswith\("departments\/"\)/i,"dynamic department route is missing");
});

test("every new tenant table carries branch ownership",()=>{
  for(const table of branchTables){
    const match=migration.match(new RegExp(`create table if not exists public\\.${table} \\(([\\s\\S]*?)\\n\\);`));
    assert.ok(match,`${table} definition is missing`);
    assert.match(match[1],/branch_id uuid not null references public\.branches\(id\)/,`${table} is not branch-owned`);
  }
});

test("migration enables RLS and removes anonymous access for domain tables",()=>{
  for(const table of branchTables)assert.ok(migration.includes(`'${table}'`),`${table} is absent from the RLS policy loop`);
  assert.match(migration,/alter table public\.%i enable row level security/);
  assert.match(migration,/revoke all on table public\.%i from anon/);
  assert.match(migration,/churchmetric_can_read_branch\(branch_id\)/);
  assert.match(migration,/churchmetric_can_manage_branch\(branch_id\)/);
});

test("dashboard RPCs never bypass RLS",()=>{
  const rpcNames=["churchmetric_create_quality_query","churchmetric_transition_quality_issue","churchmetric_create_campaign","churchmetric_add_target_progress"];
  for(const name of rpcNames){
    const start=migration.indexOf(`function public.${name}`); assert.ok(start>=0,`${name} is missing`);
    const section=migration.slice(start,start+700); assert.match(section,/security invoker/,`${name} must be security invoker`);
  }
  assert.doesNotMatch(migration,/security definer/);
});

test("idempotent workflows have database uniqueness guards",()=>{
  assert.match(migration,/unique\(provider, provider_event_id\)/);
  assert.match(migration,/idempotency_key text not null unique/);
  assert.match(migration,/unique\(target_id\)/);
  assert.match(migration,/on conflict\(idempotency_key\) do nothing/);
});

test("email delivery claims work atomically and exposes the worker only to service role",()=>{
  assert.match(workerMigration,/for update skip locked/);
  assert.match(workerMigration,/attempts < 5/);
  assert.match(workerMigration,/status = 'processing'/);
  assert.match(workerMigration,/revoke all on function public\.churchmetric_claim_email_outbox\(integer\) from public, anon, authenticated/);
  assert.match(workerMigration,/grant execute on function public\.churchmetric_claim_email_outbox\(integer\) to service_role/);
});

test("email worker is secret-protected, idempotent and avoids sensitive analytics",()=>{
  assert.match(emailWorker,/x-mailer-secret/);
  assert.match(emailWorker,/idempotencyKey:/);
  assert.doesNotMatch(emailWorker,/posthog/i);
  assert.doesNotMatch(emailWorker,/console\.(?:log|error)\([^\n]*destination/);
});

test("follow-up campaigns use one invoker-secured transaction and privacy-safe report",()=>{
  assert.match(followupsMigration,/function public\.churchmetric_create_email_campaign_v1/);
  assert.match(followupsMigration,/security invoker/);
  assert.match(followupsMigration,/on conflict on constraint broadcast_recipients_campaign_id_destination_key do nothing/);
  assert.match(followupsMigration,/broadcast_submitted/);
  assert.match(followupsMigration,/function public\.churchmetric_followups_v1/);
  assert.match(followupsScopeFix,/churchmetric_can_manage_branch/);
  assert.match(followupsScopeFix,/p_branch_id is null or c\.branch_id=p_branch_id/);
  assert.doesNotMatch(followupsMigration,/jsonb_build_object\([^)]*destination/);
  assert.match(mutations,/churchmetric_create_email_campaign_v1/);
});

test("follow-up UI keeps email-only channels explicit and renders compact completion history",()=>{
  assert.match(followupComposer,/Provider not configured/);
  assert.match(followupComposer,/broadcast_submitted/);
  assert.match(followupComposer,/broadcast_audience_category_selected/);
  assert.match(broadcastHistory,/completed \/ total/);
  assert.match(broadcastHistory,/<progress/);
  assert.doesNotMatch(broadcastHistory,/<table/);
});

test("Cloudflare scheduler keeps its token secret and awaits the dispatcher",()=>{
  assert.match(emailSchedulerConfig,/"crons": \["\*\/2 \* \* \* \*"\]/);
  assert.match(emailSchedulerConfig,/"observability"/);
  assert.doesNotMatch(emailSchedulerConfig,/MAILER_SECRET/);
  assert.match(emailScheduler,/ctx\.waitUntil\(/);
  assert.match(emailScheduler,/env\.MAILER_SECRET/);
  assert.doesNotMatch(emailScheduler,/['"](?:[A-Za-z0-9+\/]{40,}={0,2})['"]/);
});

test("targets cap progress and create one auditable achievement with non-blocking notifications",()=>{
  assert.match(targetsMigration,/least\(target_row\.goal_value,greatest\(0,target_row\.current_value\+p_delta\)\)/);
  assert.match(targetsMigration,/where tpe\.idempotency_key=p_idempotency_key/);
  assert.match(targetsMigration,/on conflict\(target_id\)do nothing/);
  assert.match(targetsMigration,/target_progress_updated/);
  assert.match(targetsMigration,/notification_outbox/);
  assert.match(targetsMigration,/security invoker/);
  assert.doesNotMatch(targetsMigration,/security definer/);
});

test("targets and awards expose the structured register and database-backed recognition gallery",()=>{
    assert.match(config,/targets:\s*\{[^\n]*Active targets/);
    assert.match(config,/awards:\s*\{[^\n]*Awards earned/);
    assert.match(targetsDirectory,/Target register/);
    assert.match(targetsDirectory,/<progress/);
    assert.match(targetsDirectory,/idempotency_key/);
    assert.match(targetsDirectory,/target_progress_updated/);
    assert.match(awardsGallery,/award-grid/);
    assert.match(awardsGallery,/details\.metric/);
    assert.match(awardsGallery,/details\.period_label/);
    assert.doesNotMatch(awardsGallery,/membership-growth\.webp|Churchwide/);
    assert.match(awardsGallery,/award_opened/);
  });

test("membership allocator is invoker-secured and service-role only",()=>{
  assert.match(memberMigration,/security invoker/);
  assert.match(memberMigration,/revoke all on table public\.membership_code_sequences from public,anon,authenticated/);
  assert.match(memberMigration,/sequence_name text primary key check\(sequence_name='global'\)/);
  assert.match(memberMigration,/where sequence_name='global'/);
  assert.match(memberMigration,/revoke all on function public\.churchmetric_allocate_membership_code\(\) from public,anon,authenticated/);
  assert.match(memberMigration,/grant execute on function public\.churchmetric_allocate_membership_code\(\) to service_role/);
  assert.match(memberMigration,/set last_value=last_value\+1/);
  assert.doesNotMatch(memberMigration,/branch_id uuid/);
  assert.match(memberAllocatorRename,/rename to "Generate_WPCC_Membership_code"/);
  assert.match(memberAllocatorRename,/grant execute on function public\."Generate_WPCC_Membership_code"\(\) to service_role/);
  assert.match(memberAllocatorFinalRename,/rename to "generate_WPCC_member_code"/);
  assert.match(memberAllocatorFinalRename,/grant execute on function public\."generate_WPCC_member_code"\(\) to service_role/);
});

test("member Edge Function authorises the caller before using service role",()=>{
  const authCheck=memberFunction.indexOf('getAuthenticatedUser(jwt)');
  const serviceClient=memberFunction.indexOf('SUPABASE_SERVICE_ROLE_KEY');
  assert.ok(authCheck>=0&&serviceClient>authCheck);
  assert.match(memberFunction,/cross-branch member creation is forbidden/i);
  assert.match(memberFunction,/generate_WPCC_member_code/);
  assert.match(memberFunction,/sendEmailThroughTransport/);
  assert.match(memberFunction,/Membership code: \$\{membershipCode\}/);
  assert.doesNotMatch(memberFunction,/console\.(?:log|error)\([^\n]*email/);
});

test("private attachments use generated scoped keys and short-lived signed reads",()=>{
  assert.match(privateFilesFunction,/churchmetric\/\$\{branchId\}\/departments\/\$\{department\.id\}/);
  assert.match(privateFilesFunction,/presignR2\(config,"GET",attachment\.object_path,undefined,300\)/);
  assert.match(privateFilesFunction,/cross-branch (?:upload|file access) is forbidden/i);
  assert.match(privateFilesFunction,/deletePrivateObject\(config,key\)/);
  assert.match(privateFilesFunction,/objectStored&&!metadataStored/);
  assert.doesNotMatch(privateFilesFunction,/R2_PUBLIC_URL|r2\.dev/);
});

test("overview uses one invoker-secured aggregate with auditable activity",()=>{
  assert.match(overviewMigration,/security invoker/);
  assert.match(overviewMigration,/churchmetric_audit_events/);
  assert.match(overviewMigration,/membership_trend/);
  assert.match(overviewMigration,/recent_activity/);
  assert.match(overviewMigration,/p_branch_id is null or ae\.branch_id = p_branch_id/);
  assert.doesNotMatch(overviewMigration,/security definer/);
  assert.match(dashboardQueries,/rpc\("churchmetric_membership_overview"/);
  assert.doesNotMatch(dashboardQueries,/souls\s*\/\s*total/);
});

test("overview exposes the required safe analytics and activity columns",()=>{
  for(const event of ["dashboard_overview_viewed","dashboard_range_changed","dashboard_campus_changed"]){
    assert.ok(dashboardFilters.includes(event),`${event} is missing`);
  }
  for(const heading of ["Member","Department","Activity","Status","Date","Completion"]){
    assert.match(interactiveDirectory,new RegExp(`<th(?:\\s+scope="col")?>${heading}</th>`),`${heading} overview column is missing`);
  }
});

test("analytics uses one invoker-secured current/previous snapshot",()=>{
  assert.match(analyticsMigration,/function public\.churchmetric_analytics_report_v1/);
  assert.match(analyticsMigration,/security invoker/);
  assert.doesNotMatch(analyticsMigration,/security definer/);
  assert.match(analyticsMigration,/cross-branch analytics access is forbidden/);
  assert.match(analyticsMigration,/when previous_value = 0 then null/);
  assert.match(dashboardQueries,/rpc\("churchmetric_analytics_report_v1"/);
  assert.doesNotMatch(dashboardQueries,/path === "analytics"[\s\S]{0,900}selectRows\(/);
});

test("analytics filters, table and CSV share the same indicator rows",()=>{
  for(const event of ["analytics_viewed","analytics_period_changed","analytics_category_changed"]){
    assert.ok(dashboardFilters.includes(event),`${event} is missing`);
  }
  assert.match(pageAction,/analytics_exported/);
  assert.match(pageAction,/Category,Indicator,Current,Previous,Change,Status/);
  for(const heading of ["Category","Indicator","Current","Previous","Change","Status"]){
    assert.match(analyticsReport,new RegExp(`<th scope="col">${heading}</th>`),`${heading} analytics column is missing`);
  }
});

test("members directory is paginated, searchable across required fields and loads heavy tabs on demand",()=>{
  assert.match(dashboardQueries,/rpc\("churchmetric_members_report_v3"/);
  assert.match(memberSortMigration,/coalesce\(m\.full_name[\s\S]*coalesce\(m\.email[\s\S]*coalesce\(m\.phone[\s\S]*coalesce\(m\.membership_code/);
  assert.match(memberSortMigration,/limit v_size offset/);
  assert.match(memberSortMigration,/last_login_at[\s\S]*last_clock_in_at[\s\S]*interval '30 days'/);
  assert.match(memberSortMigration,/p_filter[\s\S]*p_sort/);
  assert.match(memberSortMigration,/membership_code_asc[\s\S]*membership_code_desc/);
  assert.match(memberSortMigration,/security invoker/);
  assert.doesNotMatch(dashboardQueries,/path==="members"[\s\S]{0,2400}selectRows\("attendance"/);
  assert.match(interactiveDirectory,/fetch\(`\/api\/members\/\$\{encodeURIComponent\(id\)\}`\)/);
  assert.match(interactiveDirectory,/Copy membership code/);
  assert.match(interactiveDirectory,/WhatsappLogoIcon/);
  assert.doesNotMatch(memberProfileRoute,/service_role|SUPABASE_SERVICE_ROLE_KEY/);
  assert.match(memberProfileRoute,/resolveAdminContext/);
});

test("members table, modal, events and filtered export satisfy the privacy contract",()=>{
  for(const heading of ["Membership code","Member","Phone","Department","Joined","Status"]){
    assert.match(interactiveDirectory,new RegExp(`<th scope="col">${heading}</th>`),`${heading} member column is missing`);
  }
  assert.match(interactiveDirectory,/aria-labelledby="record-dialog-title"/);
  assert.match(interactiveDirectory,/member_profile_opened/);
  assert.match(dashboardFilters,/members_viewed/);
  assert.match(dashboardShell,/members_searched/);
  assert.match(pageAction,/member_created/);
  assert.match(pageAction,/members_exported/);
  assert.match(memberExportRoute,/Membership code,Name,Email,Phone,Department,Joined,Status/);
  assert.match(memberExportRoute,/resolveAdminContext/);
  assert.doesNotMatch(memberExportRoute,/service_role|SUPABASE_SERVICE_ROLE_KEY/);
});

test("v11 members UI keeps exact directory fields and secured update interactions",()=>{
  for(const heading of ["Member code","Member","Phone","Department","Date joined","Last seen","Status"])assert.match(membersDirectory,new RegExp(`<th>${heading}</th>`));
  assert.match(membersDirectory,/Member details/);
  assert.match(membersDirectory,/Queries[\s\S]*Missed services[\s\S]*Attendance rate[\s\S]*Souls won[\s\S]*Classes completed/);
  assert.match(memberEditor,/Authorize profile update/);
  assert.match(memberEditor,/Resend in \$\{cooldown\}s/);
  assert.match(memberEditor,/department-tags/);
  assert.match(pageAction,/DepartmentTags choices=\{choices\}/);
  assert.match(dashboardShell,/badge>0&&<span className="nav-count-badge"/);
  assert.match(memberUpdateFunction,/retryAfter>0/);
  assert.match(memberUpdateFunction,/status:429/);
  assert.match(memberDepartmentsMigration,/create table if not exists public\.profile_departments/);
  assert.match(memberDepartmentsMigration,/enable row level security/);
  assert.match(memberDepartmentsMigration,/security invoker/);
});

test("events reports are paginated, RLS-scoped and load attendance on demand",()=>{
  assert.match(eventsMigration,/function public\.churchmetric_events_report_v1/);
  assert.match(eventsMigration,/function public\.churchmetric_event_attendance_v1/);
  assert.ok((eventsMigration.match(/security invoker/g)||[]).length>=2);
  assert.doesNotMatch(eventsMigration,/security definer/);
  assert.match(eventsMigration,/order by lower\(full_name\),id/);
  assert.match(dashboardQueries,/rpc\("churchmetric_events_report_v1"/);
  assert.doesNotMatch(dashboardQueries,/path === "events"[\s\S]{0,1800}selectRows\("attendance"/);
  assert.match(eventAttendanceDetail,/\/api\/events\/\$\{encodeURIComponent\(eventId\)\}\/attendance/);
  assert.match(eventAttendanceRoute,/resolveAdminContext/);
  assert.doesNotMatch(eventAttendanceRoute,/service_role|SUPABASE_SERVICE_ROLE_KEY/);
});

test("events tables, dialog and analytics preserve the privacy contract",()=>{
  for(const heading of ["Event","Date","Type","Venue","Start time","Attendance"])assert.match(interactiveDirectory,new RegExp(`<th scope="col">${heading}</th>`));
  for(const heading of ["Name","Department","Membership code","Time"])assert.match(eventAttendanceDetail,new RegExp(`<th scope="col">${heading}</th>`));
  assert.ok(dashboardFilters.includes("events_viewed"));
  assert.ok(dashboardShell.includes("events_searched"));
  assert.match(interactiveDirectory,/event_attendance_opened/);
  assert.doesNotMatch(dashboardFilters,/events_searched[^\n]*(query|search):value/);
});

test("soul winning uses transactional creation and reconciled paginated reads",()=>{
  for(const name of ["churchmetric_create_soul_v1","churchmetric_soul_winning_report_v1","churchmetric_event_souls_v1"])assert.match(soulWinningMigration,new RegExp(`function public\\.${name}`));
  assert.doesNotMatch(soulWinningMigration,/security definer/);
  assert.match(soulWinningMigration,/insert into public\.soul_followups/);
  assert.match(soulWinningMigration,/event_branch_mismatch/);
  assert.match(soulWinningMigration,/phone_normalized/);
  assert.match(soulTransitionMigration,/churchmetric_audit_events/);
  assert.match(dashboardQueries,/rpc\("churchmetric_soul_winning_report_v1"/);
  assert.doesNotMatch(dashboardQueries,/path==="soul-winning"[\s\S]{0,1800}selectRows\("souls"/);
  assert.match(eventSoulsRoute,/resolveAdminContext/);
  assert.doesNotMatch(eventSoulsRoute,/service_role|SUPABASE_SERVICE_ROLE_KEY/);
});

test("soul winning exposes exact event/modal columns and privacy-safe events",()=>{
  for(const heading of ["Event","Date","Venue","Team lead","Souls won","Integrated"])assert.match(soulDirectory,new RegExp(`<th scope="col">${heading}</th>`));
  for(const heading of ["Name","Phone","Evangelist","Location","Status","Follow-up"])assert.match(eventSoulsDetail,new RegExp(`<th scope="col">${heading}</th>`));
  for(const event of ["soul_winning_viewed","evangelism_event_opened","soul_created","soul_status_changed"])assert.ok((dashboardFilters+pageAction+soulDirectory+eventSoulsDetail).includes(event));
  assert.doesNotMatch(eventSoulsDetail,/notes[^\n]*posthog|posthog[^\n]*notes/i);
});

test("departments cards use one invoker report without detail payloads",()=>{
  assert.match(departmentsMigration,/function public\.churchmetric_departments_report_v1/);
  assert.match(departmentsMigration,/security invoker/);
  assert.doesNotMatch(departmentsMigration,/security definer/);
  assert.match(departmentsMigration,/cross-branch department access is forbidden/);
  assert.match(dashboardQueries,/rpc\("churchmetric_departments_report_v1"/);
  assert.doesNotMatch(dashboardQueries,/path === "departments"[\s\S]{0,1000}(department_attachments|selectRows\("profiles")/);
});

test("departments cards stay minimal while the report retains authorised fields",()=>{
  for(const field of ["leader","leader_title","member_count","attendance_rate"])assert.ok(!departmentGrid.includes(field));
  assert.match(departmentGrid,/<UsersThreeIcon size=\{21\}\/>.*<h2>\{row\.primary\}<\/h2>/);
  assert.match(pageAction,/Department,Description,Leader,Title,Members,Attendance rate/);
  for(const event of ["departments_viewed","department_opened","leadership_report_exported"])assert.ok((dashboardFilters+departmentGrid+pageAction).includes(event));
  assert.ok(dashboardShell.includes("department_searched"));
  assert.match(departmentGrid,/department_id:row\.id/);
});

test("department detail is one paginated invoker snapshot with explicit branch scope",()=>{
  assert.match(departmentDetailMigration,/function public\.churchmetric_department_detail_v1/);
  assert.match(departmentDetailMigration,/security invoker/);
  assert.doesNotMatch(departmentDetailMigration,/security definer/);
  assert.match(departmentDetailMigration,/cross-branch department access is forbidden/);
  for(const field of ["department","metrics","members","leaders","attachments"])assert.ok(departmentDetailMigration.includes(`'${field}'`));
  assert.match(dashboardQueries,/rpc\("churchmetric_department_detail_v1"/);
});

test("department detail tables, private attachments, export and analytics meet the brief",()=>{
  for(const heading of ["Leader","Title","Tenure","Status","Membership code","Member","Phone","Joined"])assert.match(departmentDetailDirectory,new RegExp(`<th scope="col">${heading}</th>`));
  assert.match(departmentExportRoute,/Membership code,Name,Email,Phone,Joined,Status/);
  assert.match(departmentExportRoute,/resolveAdminContext/);
  assert.doesNotMatch(departmentExportRoute,/service_role|SUPABASE_SERVICE_ROLE_KEY/);
  assert.match(departmentAttachments,/branch_id/);
  assert.match(departmentAttachments,/Sentry\.captureException/);
  for(const event of ["department_detail_viewed","department_attachment_uploaded","department_attachment_opened","department_attachment_deleted","department_directory_exported"]){
    assert.ok((dashboardFilters+departmentAttachments+departmentExport).includes(event),`${event} is missing`);
  }
});

test("enquiries use paginated invoker reads and transactional audited mutations",()=>{
  for(const name of ["churchmetric_enquiries_inbox_v1","churchmetric_enquiry_thread_v1","churchmetric_reply_to_enquiry_v1","churchmetric_set_enquiry_status_v1","churchmetric_assign_enquiry_v1"]){
    assert.match(enquiriesMigration,new RegExp(`function public\\.${name}`));
  }
  assert.ok((enquiriesMigration.match(/security invoker/g)||[]).length>=5);
  assert.match(enquiriesMigration,/limit v_page_size offset/);
  assert.match(enquiriesMigration,/insert into public\.enquiry_messages/);
  assert.match(enquiriesMigration,/insert into public\.notification_outbox/);
  assert.match(enquiriesMigration,/insert into public\.churchmetric_audit_events/);
  assert.match(dashboardQueries,/rpc\("churchmetric_enquiries_inbox_v1"/);
  assert.match(dashboardQueries,/rpc\("churchmetric_enquiry_thread_v1"/);
  assert.doesNotMatch(dashboardQueries,/path==="enquiries"[\s\S]{0,1800}selectRows\("enquiry_messages"/);
});

test("enquiry inbox is keyboard accessible and analytics exclude sensitive content",()=>{
  for(const event of ["enquiries_viewed","enquiry_opened","enquiry_response_sent","enquiry_status_changed"])assert.ok((dashboardFilters+enquiryWorkspace).includes(event),`${event} is missing`);
  assert.match(enquiryWorkspace,/role="listbox"/);
  assert.match(enquiryWorkspace,/role="option"/);
  assert.match(enquiryWorkspace,/ArrowDown/);
  assert.match(enquiryWorkspace,/deliveryStatus/);
  assert.match(mutations,/churchmetric_reply_to_enquiry_v1/);
  assert.match(mutations,/Sentry\.startSpan/);
  assert.doesNotMatch(enquiryWorkspace,/posthog\.capture\([^\n]*(body|message|email|phone)/i);
});

test("QC reports use paginated summary and separately authorised detail RPCs",()=>{
  for(const name of ["churchmetric_quality_reports_inbox_v1","churchmetric_quality_report_detail_v1","churchmetric_transition_quality_report","churchmetric_assign_quality_report"])assert.match(qualityReportsMigration,new RegExp(`function public\\.${name}`));
  assert.ok((qualityReportsMigration.match(/security invoker/g)||[]).length>=4);
  assert.match(qualityReportsMigration,/offset \(v_page - 1\) \* v_page_size limit v_page_size/);
  assert.match(qualityReportsMigration,/resolved_at/);
  assert.match(qualityReportsMigration,/invalid_status_transition/);
  assert.match(qualityReportsMigration,/insert into public\.quality_status_history/);
  assert.match(qualityReportsMigration,/insert into public\.churchmetric_audit_events/);
  assert.match(dashboardQueries,/rpc\("churchmetric_quality_reports_inbox_v1"/);
  assert.match(dashboardQueries,/rpc\("churchmetric_quality_report_detail_v1"/);
  assert.doesNotMatch(dashboardQueries,/path==="quality-control\/reports"[\s\S]{0,1500}selectRows\("quality_reports","\*"/);
});

test("QC reports table, modal, transitions and safe analytics meet the brief",()=>{
  for(const heading of ["Report","Reporter","Source","Category","Priority","Date","Status"])assert.match(qualityReportsDirectory,new RegExp(`<th scope="col">${heading}</th>`));
  for(const action of ["resolve","escalate","reopen"])assert.ok((qualityReportsDirectory+mutations+qualityReportsMigration).includes(action));
  for(const event of ["qc_reports_viewed","qc_report_opened","qc_report_resolved","qc_report_escalated"])assert.ok((dashboardFilters+qualityReportsDirectory).includes(event),`${event} is missing`);
  assert.match(qualityReportsDirectory,/showModal/);
  assert.match(qualityReportsDirectory,/aria-labelledby="qc-report-title"/);
  assert.match(qualityReportsDirectory,/onKeyDown/);
  assert.doesNotMatch(qualityReportsDirectory,/posthog\.capture\([^\n]*(description|email|phone)/i);
});

test("QC queries use relational assignees, server-time overdue state and transactional creation",()=>{
  assert.match(qualityQueriesMigration,/function public\.churchmetric_quality_queries_v1/);
  assert.match(qualityQueriesMigration,/function public\.churchmetric_create_quality_query_v3/);
  assert.ok((qualityQueriesMigration.match(/security invoker/g)||[]).length>=2);
  assert.match(qualityQueriesMigration,/quality_query_assignees/);
  assert.match(qualityQueriesMigration,/q\.due_at<now\(\)/);
  assert.match(qualityQueriesMigration,/assignee_required/);
  assert.match(qualityQueriesMigration,/due_date_before_issue_date/);
  assert.match(qualityQueryAliasMigration,/candidate\(assignee_id\)/);
  assert.match(dashboardQueries,/rpc\("churchmetric_quality_queries_v1"/);
  assert.match(mutations,/rpc\("churchmetric_create_quality_query_v3"/);
});

test("QC queries CTA, accessible tags, exact table and safe analytics meet the brief",()=>{
  for(const heading of ["Query","Assigned members","Priority","Issued","Due","Status"])assert.match(qualityQueriesDirectory,new RegExp(`<th scope="col">${heading}</th>`));
  assert.match(pageAction,/aria-label={`Remove \$\{member\?\.primary\|\|"assignee"\}`}/);
  assert.match(pageAction,/min={issued\|\|undefined}/);
  for(const event of ["qc_queries_viewed","qc_query_dialog_opened","qc_query_assignee_added","qc_query_created"])assert.ok((dashboardFilters+pageAction).includes(event),`${event} is missing`);
  assert.doesNotMatch(pageAction,/posthog\.capture\("qc_query_[^"]+",\{[^}]+(body|details|email|phone)/i);
});

test("QC issues use RLS-scoped summary/private-detail reads and the audited state machine",()=>{
  assert.match(qualityIssuesMigration,/function public\.churchmetric_quality_issues_v1/);
  assert.match(qualityIssuesMigration,/function public\.churchmetric_quality_issue_detail_v1/);
  assert.ok((qualityIssuesMigration.match(/security invoker/g)||[]).length>=2);
  assert.doesNotMatch(qualityIssuesMigration,/select i\.id,i\.branch_id,i\.title,i\.description[\s\S]*into v_items/);
  assert.match(dashboardQueries,/rpc\("churchmetric_quality_issues_v1"/);
  assert.match(dashboardQueries,/rpc\("churchmetric_quality_issue_detail_v1"/);
  assert.match(migration,/open['"]?\s*,?\s*['"]?investigating/);
  assert.match(migration,/insert into public\.quality_status_history/);
  assert.match(migration,/insert into public\.churchmetric_audit_events/);
});

test("QC issues exact table, critical treatment, accessible modal and safe analytics meet the brief",()=>{
  for(const heading of ["Issue","Reported by","Area","Priority","Owner","Age","Status"])assert.match(qualityIssuesDirectory,new RegExp(`<th scope="col">${heading}</th>`));
  for(const event of ["qc_issues_viewed","qc_issue_opened","qc_issue_status_advanced","qc_issue_resolved"])assert.ok((dashboardFilters+qualityIssuesDirectory).includes(event),`${event} is missing`);
  assert.match(qualityIssuesDirectory,/critical-issue/);
  assert.match(qualityIssuesDirectory,/showModal/);
  assert.match(qualityIssuesDirectory,/aria-labelledby="qc-issue-title"/);
  assert.match(qualityIssuesDirectory,/onKeyDown/);
  assert.doesNotMatch(qualityIssuesDirectory,/posthog\.capture\([^\n]*(description|email|phone)/i);
});

test("academy classes use separate RLS-scoped summary and selected-session detail RPCs",()=>{
  assert.match(academyClassesMigration,/function public\.churchmetric_academy_classes_v1/);
  assert.match(academyClassesMigration,/function public\.churchmetric_academy_class_detail_v1/);
  assert.ok((academyClassesMigration.match(/security invoker/g)||[]).length>=2);
  assert.match(academyClassesMigration,/session_not_in_class/);
  assert.match(dashboardQueries,/rpc\("churchmetric_academy_classes_v1"/);
  assert.match(dashboardQueries,/rpc\("churchmetric_academy_class_detail_v1"/);
  assert.doesNotMatch(dashboardQueries,/path==="academy\/classes"[\s\S]{0,1800}selectRows\("course_enrollments","\*"/);
  assert.match(academySessionExport,/p_session_id:sessionId/);
  for(const heading of ["Course","Session","Member code","Name","Email","Department","Progress","Status"])assert.ok(academySessionExport.includes(`"${heading}"`));
});

test("academy class table, dialog, private attachments and safe analytics meet the brief",()=>{
  for(const heading of ["Class","Track","Facilitator","Delivery","Assigned through","Enrolled","Completion","Status"])assert.match(academyClassesDirectory,new RegExp(`<th scope="col">${heading}</th>`));
  for(const event of ["academy_classes_viewed","academy_class_opened","academy_class_tab_changed","academy_module_expanded","academy_attachment_opened","academy_session_students_exported"])assert.ok((dashboardFilters+academyClassesDirectory).includes(event),`${event} is missing`);
  assert.match(academyClassesDirectory,/attachment_type:"academy_module"/);
  assert.match(academyClassesDirectory,/showModal/);
  assert.match(academyClassesDirectory,/onKeyDown/);
  assert.match(academyClassesDirectory,/\?"Completed":"In progress"/);
  assert.doesNotMatch(academyClassesDirectory,/posthog\.capture\([^\n]*(email|description|phone)/i);
});

test("academy enrolments use a paginated RLS-scoped full-dataset report with boundary status mapping",()=>{
  assert.match(academyEnrolmentsMigration,/function public\.churchmetric_academy_enrolments_v1/);
  assert.match(academyEnrolmentsMigration,/security invoker/);
  assert.match(academyEnrolmentsMigration,/offset\(v_page-1\)\*v_size limit v_size/);
  for(const value of ["finished","unfinished","yet_to_attend"])assert.ok(academyEnrolmentsMigration.includes(value));
  assert.match(academyEnrolmentsMigration,/progress_percent=100/);
  assert.match(dashboardQueries,/rpc\("churchmetric_academy_enrolments_v1"/);
  assert.doesNotMatch(dashboardQueries,/path==="academy\/enrolments"[\s\S]{0,1200}selectRows\("course_enrollments","\*"/);
});

test("academy enrolments exact table, labelled progress, deep links and analytics meet the brief",()=>{
  for(const heading of ["Member","Membership code","Class","Assignment source","Progress","Last activity","Status"])assert.match(academyEnrolmentsDirectory,new RegExp(`<th scope="col">${heading}</th>`));
  assert.match(academyEnrolmentsDirectory,/aria-label={`\$\{row\.primary\} learning progress`}/);
  assert.match(academyEnrolmentsDirectory,/\/dashboard\/members\?q=/);
  assert.match(academyEnrolmentsDirectory,/\/dashboard\/academy\/classes\?selected=/);
  for(const event of ["academy_enrolments_viewed","academy_enrolments_filtered","academy_enrolment_opened"])assert.ok((dashboardFilters+academyEnrolmentsDirectory).includes(event),`${event} is missing`);
  assert.doesNotMatch(academyEnrolmentsDirectory,/posthog\.capture\([^\n]*(email|phone)/i);
});

test("academy instructors use relational session scope, distinct learners and documented row weighting",()=>{
  assert.match(academyInstructorsMigration,/function public\.churchmetric_academy_instructors_v1/);
  assert.match(academyInstructorsMigration,/security invoker/);
  assert.match(academyInstructorsMigration,/count\(distinct e\.user_id\)/);
  assert.match(academyInstructorsMigration,/round\(avg\(e\.progress_percent\)\)/);
  assert.match(academyInstructorsMigration,/each learner-class enrolment contributes one equally weighted progress value/);
  assert.match(academyInstructorsMigration,/e\.session_id=p_session_id/);
  assert.match(dashboardQueries,/rpc\("churchmetric_academy_instructors_v1"/);
  assert.doesNotMatch(dashboardQueries,/path==="academy\/instructors"[\s\S]{0,1400}selectRows\("academy_instructors","\*"/);
});

test("academy instructor session control, exact table, labelled completion and analytics meet the brief",()=>{
  for(const heading of ["Instructor","Expertise","Classes","Unique learners","Weighted completion","Status"])assert.match(academyInstructorsDirectory,new RegExp(`<th scope="col">${heading}</th>`));
  assert.match(academyInstructorsDirectory,/aria-label={`\$\{row\.primary\} weighted completion`}/);
  assert.match(academyInstructorsDirectory,/\/dashboard\/academy\/classes\?selected=/);
  for(const event of ["academy_instructors_viewed","academy_instructor_session_changed","academy_instructors_filtered"])assert.ok((dashboardFilters+sessionFilter).includes(event),`${event} is missing`);
  assert.doesNotMatch((dashboardFilters+sessionFilter),/posthog\.capture\([^\n]*(email|phone)/i);
});
