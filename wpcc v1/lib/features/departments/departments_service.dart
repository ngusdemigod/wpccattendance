import '../../auth/supabase_auth/auth_util.dart';
import '../../backend/supabase/database/database.dart';
import '../../backend/supabase/supabase.dart';
import 'departments_models.dart';

/// Supabase data access for the Departments feature.
class DepartmentsService {
  Future<DepartmentsListData> fetchDepartmentsList() async {
    final profile = await _loadMyProfile();
    final myDepartmentId = profile?.departmentId?.trim() ?? '';
    if (myDepartmentId.isEmpty) {
      return DepartmentsListData(
        departments: const [],
        branchId: profile?.branchId?.trim() ?? '',
      );
    }

    final departmentsFuture = DepartmentsTable().queryRows(
      queryFn: (q) => q.eq('id', myDepartmentId),
      limit: 1,
    );
    final summariesFuture = DepartmentSummaryViewTable().queryRows(
      queryFn: (q) => q.eq('department_id', myDepartmentId),
      limit: 1,
    );
    final myLeadershipsFuture = _loadMyLeaderships();

    final departments = await departmentsFuture;
    final summaries = await summariesFuture;
    final myLeaderships = await myLeadershipsFuture;

    final countByDept = <String, int>{
      for (final row in summaries)
        if (row.departmentId != null) row.departmentId!: row.personsCount ?? 0,
    };
    final leadingIds = myLeaderships
        .map((row) => row.departmentId)
        .whereType<String>()
        .toSet();
    final items = <DepartmentListItem>[];
    for (final dept in departments) {
      final id = dept.id ?? '';
      if (id.isEmpty) {
        continue;
      }
      final role = leadingIds.contains(id)
          ? DepartmentRole.leader
          : DepartmentRole.primary;
      items.add(DepartmentListItem(
        id: id,
        name: dept.name,
        description: dept.description,
        memberCount: countByDept[id] ?? 0,
        role: role,
      ));
    }

    return DepartmentsListData(
      departments: items,
      branchId: profile?.branchId?.trim() ?? '',
    );
  }

  Future<DepartmentDetailData?> fetchDepartmentDetail(
      String departmentId) async {
    final departmentFuture = DepartmentsTable().queryRows(
      queryFn: (q) => q.eq('id', departmentId),
      limit: 1,
    );
    final summaryFuture = DepartmentSummaryViewTable().queryRows(
      queryFn: (q) => q.eq('department_id', departmentId),
      limit: 1,
    );
    final leadersFuture = DepartmentLeadershipViewTable().queryRows(
      queryFn: (q) => q.eq('department_id', departmentId).eq('is_active', true),
    );
    final profileFuture = _loadMyProfile();

    final departmentRows = await departmentFuture;
    if (departmentRows.isEmpty) {
      return null;
    }
    final department = departmentRows.first;
    final summaryRows = await summaryFuture;
    final leaderRows = await leadersFuture;
    final profile = await profileFuture;

    final summary = summaryRows.isNotEmpty ? summaryRows.first : null;
    final leaderAvatars = await _loadAvatarsFor(
      leaderRows.map((row) => row.userId).whereType<String>().toList(),
    );

    final leaders = leaderRows
        .where((row) => (row.userId ?? '').isNotEmpty)
        .map((row) => DepartmentLeader(
              userId: row.userId!,
              fullName: row.userFullName?.trim().isNotEmpty == true
                  ? row.userFullName!.trim()
                  : 'Member',
              roleTitle: row.titleName?.trim().isNotEmpty == true
                  ? row.titleName!.trim()
                  : 'Leader',
              avatarUrl: leaderAvatars[row.userId],
            ))
        .toList();

    return DepartmentDetailData(
      id: departmentId,
      name: department.name,
      description: department.description,
      branchId: profile?.branchId?.trim() ?? '',
      memberCount: summary?.personsCount ?? 0,
      activeEvents: summary?.activeDepartmentalEvents ?? 0,
      pastEvents: summary?.pastDepartmentalEvents ?? 0,
      leaders: leaders,
      isCurrentUserLeader: currentUserUid.isNotEmpty &&
          leaderRows.any((row) => row.userId == currentUserUid),
    );
  }

  Future<List<DepartmentMember>> fetchMembers(String departmentId) async {
    final rowsFuture = WorkerProfilesTable().queryRows(
      queryFn: (q) => q
          .eq('department_id', departmentId)
          .order('full_name', ascending: true),
    );
    final leadersFuture = DepartmentLeadershipViewTable().queryRows(
      queryFn: (q) => q.eq('department_id', departmentId).eq('is_active', true),
    );

    final rows = await rowsFuture;
    final leaderRows = await leadersFuture;
    final roleByUser = <String, String>{
      for (final row in leaderRows)
        if ((row.userId ?? '').isNotEmpty)
          row.userId!: row.titleName?.trim().isNotEmpty == true
              ? row.titleName!.trim()
              : 'Leader',
    };

    final seen = <String>{};
    final members = <DepartmentMember>[];
    for (final row in rows) {
      final member = DepartmentMember.fromWorkerProfile(
        row,
        roleTitle: roleByUser[row.userId],
      );
      if (member.userId.isEmpty || !seen.add(member.userId)) {
        continue;
      }
      members.add(member);
    }
    return members;
  }

  Future<List<DepartmentPastEvent>> fetchPastEvents(String departmentId) async {
    final nowIso = DateTime.now().toUtc().toIso8601String();
    final departmentalFuture = DepartmentalEventsTable().queryRows(
      queryFn: (q) => q
          .eq('department_id', departmentId)
          .lt('event_start_at', nowIso)
          .order('event_start_at', ascending: false),
      limit: 20,
    );
    final globalFuture = GlobalEventsTable().queryRows(
      queryFn: (q) => q
          .lt('event_start_at', nowIso)
          .order('event_start_at', ascending: false),
      limit: 20,
    );

    final departmental = await departmentalFuture;
    final global = await globalFuture;

    final events = <DepartmentPastEvent>[
      ...departmental.map((row) => DepartmentPastEvent(
            id: row.id ?? '',
            title: row.title,
            scope: DepartmentEventScope.departmental,
            startAt: row.eventStartAt,
            location: row.location,
            presentCount: 0,
          )),
      ...global.map((row) => DepartmentPastEvent(
            id: row.id ?? '',
            title: row.title,
            scope: DepartmentEventScope.global,
            startAt: row.eventStartAt,
            location: row.location,
            presentCount: 0,
          )),
    ]..removeWhere((event) => event.id.isEmpty);

    events.sort((a, b) {
      final aTime = a.startAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.startAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });

    final presentByEvent =
        await _countDepartmentAttendance(departmentId, events);
    return events
        .map((event) => DepartmentPastEvent(
              id: event.id,
              title: event.title,
              scope: event.scope,
              startAt: event.startAt,
              location: event.location,
              presentCount: presentByEvent[event.id] ?? 0,
            ))
        .toList();
  }

  Future<List<EventAttendanceEntry>> fetchEventAttendance(
    String eventId,
    String departmentId,
  ) async {
    final rows = await AttendanceTable().queryRows(
      queryFn: (q) => q
          .eq('event_id', eventId)
          .eq('department_id', departmentId)
          .order('created_at', ascending: true),
    );

    final userIds = rows.map((row) => row.userId).whereType<String>().toList();
    final avatars = await _loadAvatarsFor(userIds);
    final leaderRows = await DepartmentLeadershipViewTable().queryRows(
      queryFn: (q) => q.eq('department_id', departmentId).eq('is_active', true),
    );
    final roleByUser = <String, String>{
      for (final row in leaderRows)
        if ((row.userId ?? '').isNotEmpty && (row.titleName ?? '').isNotEmpty)
          row.userId!: row.titleName!.trim(),
    };

    final entries = rows
        .map((row) => EventAttendanceEntry(
              userId: row.userId ?? '',
              fullName: row.fullname,
              avatarUrl: avatars[row.userId],
              roleTitle: roleByUser[row.userId],
              clockedInAt: row.createdAt,
            ))
        .toList();

    entries.sort((a, b) {
      final aTime = a.clockedInAt;
      final bTime = b.clockedInAt;
      if (aTime == null && bTime == null) {
        return a.fullName.compareTo(b.fullName);
      }
      if (aTime == null) return 1;
      if (bTime == null) return -1;
      final byTime = aTime.compareTo(bTime);
      return byTime != 0 ? byTime : a.fullName.compareTo(b.fullName);
    });
    return entries;
  }

  Future<List<AttendanceRankEntry>> fetchAttendanceRankings(
    String departmentId,
    int pastEventsCount,
  ) async {
    final rows = await AttendanceTable().queryRows(
      queryFn: (q) => q
          .eq('department_id', departmentId)
          .order('created_at', ascending: false),
      limit: 2000,
    );

    final eventsByUser = <String, Set<String>>{};
    final nameByUser = <String, String>{};
    for (final row in rows) {
      final userId = row.userId ?? '';
      final eventId = row.eventId ?? '';
      if (userId.isEmpty || eventId.isEmpty) {
        continue;
      }
      eventsByUser.putIfAbsent(userId, () => <String>{}).add(eventId);
      nameByUser.putIfAbsent(userId, () => row.fullname);
    }

    final ranked = eventsByUser.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));
    final top = ranked.take(5).toList();
    final avatars =
        await _loadAvatarsFor(top.map((entry) => entry.key).toList());

    final totalEvents = pastEventsCount > 0 ? pastEventsCount : 1;
    return top
        .map((entry) => AttendanceRankEntry(
              userId: entry.key,
              fullName: nameByUser[entry.key] ?? 'Member',
              avatarUrl: avatars[entry.key],
              attendedCount: entry.value.length,
              scorePercent: ((entry.value.length / totalEvents) * 100)
                  .round()
                  .clamp(0, 100),
            ))
        .toList();
  }

  /// Files a query against [targetUserId] through a secure RPC. The database
  /// validates that the caller holds an active leadership role for the
  /// target's department before inserting.
  Future<void> fileQueryAgainstMember({
    required String targetUserId,
    required String title,
    required String details,
  }) async {
    await SupaFlow.client.rpc('file_department_query', params: {
      'target_user_id': targetUserId,
      'query_title': title,
      'query_details': details,
    });
  }

  Future<ProfileViewRow?> _loadMyProfile() async {
    if (currentUserUid.isEmpty) {
      return null;
    }
    final rows = await ProfileViewTable().queryRows(
      queryFn: (q) => q.eq('user_id', currentUserUid),
      limit: 1,
    );
    return rows.isNotEmpty ? rows.first : null;
  }

  Future<List<DepartmentLeadershipViewRow>> _loadMyLeaderships() async {
    if (currentUserUid.isEmpty) {
      return const [];
    }
    return DepartmentLeadershipViewTable().queryRows(
      queryFn: (q) => q.eq('user_id', currentUserUid).eq('is_active', true),
    );
  }

  Future<Map<String, String>> _loadAvatarsFor(List<String> userIds) async {
    final ids = userIds.where((id) => id.isNotEmpty).toSet().toList();
    if (ids.isEmpty) {
      return const {};
    }
    final rows = await ProfilesTable().queryRows(
      queryFn: (q) => q.inFilter('id', ids),
    );
    return <String, String>{
      for (final row in rows)
        if ((row.id ?? '').isNotEmpty && (row.avatar?.trim() ?? '').isNotEmpty)
          row.id!: row.avatar!.trim(),
    };
  }

  Future<Map<String, int>> _countDepartmentAttendance(
    String departmentId,
    List<DepartmentPastEvent> events,
  ) async {
    if (events.isEmpty) {
      return const {};
    }
    final eventIds = events.map((event) => event.id).toList();
    final rows = await AttendanceTable().queryRows(
      queryFn: (q) =>
          q.inFilter('event_id', eventIds).eq('department_id', departmentId),
      limit: 4000,
    );
    final counts = <String, int>{};
    for (final row in rows) {
      final eventId = row.eventId ?? '';
      if (eventId.isEmpty) {
        continue;
      }
      counts[eventId] = (counts[eventId] ?? 0) + 1;
    }
    return counts;
  }
}
