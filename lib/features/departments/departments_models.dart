import 'package:flutter/material.dart';

import '../../backend/supabase/database/database.dart';

/// Relationship of the signed-in user to a department.
enum DepartmentRole { primary, leader, member }

/// One department entry on the Departments list screen.
class DepartmentListItem {
  const DepartmentListItem({
    required this.id,
    required this.name,
    this.description,
    required this.memberCount,
    required this.role,
  });

  final String id;
  final String name;
  final String? description;
  final int memberCount;
  final DepartmentRole role;

  bool get isMine => role == DepartmentRole.primary;
  bool get isLeading => role == DepartmentRole.leader;
}

/// Data for the Departments list screen.
class DepartmentsListData {
  const DepartmentsListData({
    required this.departments,
    required this.branchId,
  });

  final List<DepartmentListItem> departments;
  final String branchId;
}

/// A department leader shown on Overview / Members tabs.
class DepartmentLeader {
  const DepartmentLeader({
    required this.userId,
    required this.fullName,
    required this.roleTitle,
    this.avatarUrl,
  });

  final String userId;
  final String fullName;
  final String roleTitle;
  final String? avatarUrl;
}

/// A department member shown on the Members grid and popup.
class DepartmentMember {
  const DepartmentMember({
    required this.userId,
    required this.fullName,
    this.firstName,
    this.lastName,
    this.avatarUrl,
    this.verified = false,
    this.memberSince,
    this.branchName,
    this.departmentName,
    this.roleTitle,
  });

  final String userId;
  final String fullName;
  final String? firstName;
  final String? lastName;
  final String? avatarUrl;
  final bool verified;
  final DateTime? memberSince;
  final String? branchName;
  final String? departmentName;
  final String? roleTitle;

  static DepartmentMember fromWorkerProfile(
    WorkerProfilesRow row, {
    String? roleTitle,
  }) {
    final fullName = _firstNonEmpty([
      row.fullName,
      [row.firstname, row.lastname].whereType<String>().join(' ').trim(),
    ]);
    return DepartmentMember(
      userId: row.userId ?? row.workerId ?? '',
      fullName: fullName,
      firstName: row.firstname?.trim(),
      lastName: row.lastname?.trim(),
      avatarUrl: _urlOrNull(row.avatar),
      verified: row.verified ?? false,
      memberSince: row.dateJoined ?? row.profileCreatedAt,
      branchName: row.branchName,
      departmentName: row.departmentName,
      roleTitle: roleTitle,
    );
  }
}

/// Header + overview information for the Department Detail screen.
class DepartmentDetailData {
  const DepartmentDetailData({
    required this.id,
    required this.name,
    this.description,
    required this.branchId,
    required this.memberCount,
    required this.activeEvents,
    required this.pastEvents,
    required this.leaders,
    required this.isCurrentUserLeader,
  });

  final String id;
  final String name;
  final String? description;
  final String branchId;
  final int memberCount;
  final int activeEvents;
  final int pastEvents;
  final List<DepartmentLeader> leaders;
  final bool isCurrentUserLeader;
}

/// Scope badge on attendance event cards.
enum DepartmentEventScope { departmental, global }

/// A past event shown on the Attendance tab.
class DepartmentPastEvent {
  const DepartmentPastEvent({
    required this.id,
    required this.title,
    required this.scope,
    this.startAt,
    this.location,
    required this.presentCount,
  });

  final String id;
  final String title;
  final DepartmentEventScope scope;
  final DateTime? startAt;
  final String? location;
  final int presentCount;
}

/// One row inside the "Members present" popup, ranked by clock-in time.
class EventAttendanceEntry {
  const EventAttendanceEntry({
    required this.userId,
    required this.fullName,
    this.avatarUrl,
    this.roleTitle,
    this.clockedInAt,
  });

  final String userId;
  final String fullName;
  final String? avatarUrl;
  final String? roleTitle;
  final DateTime? clockedInAt;
}

/// One row of the Attendance Rankings card on the Overview tab.
class AttendanceRankEntry {
  const AttendanceRankEntry({
    required this.userId,
    required this.fullName,
    this.avatarUrl,
    required this.attendedCount,
    required this.scorePercent,
  });

  final String userId;
  final String fullName;
  final String? avatarUrl;
  final int attendedCount;
  final int scorePercent;
}

String _firstNonEmpty(List<String?> values, {String fallback = 'Member'}) {
  for (final value in values) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isNotEmpty) {
      return trimmed;
    }
  }
  return fallback;
}

String? _urlOrNull(String? value) {
  final trimmed = value?.trim() ?? '';
  return trimmed.isEmpty ? null : trimmed;
}

/// Initials from a real name, e.g. "Adeshina Gentry" -> "AG".
String initialsFor(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .take(2)
      .toList();
  if (parts.isEmpty) {
    return '?';
  }
  return parts.map((part) => part[0].toUpperCase()).join();
}

const List<Color> kAvatarPastels = [
  Color(0xFFF3E8E5),
  Color(0xFFD9C0F4),
  Color(0xFFBFEDE3),
  Color(0xFFF5E69C),
  Color(0xFFCDE0FF),
  Color(0xFFF4E59E),
  Color(0xFFFBEAF4),
  Color(0xFFE3F5E9),
];

/// Deterministic soft pastel for initials fallback avatars.
Color avatarPastelFor(String seed) {
  if (seed.isEmpty) {
    return kAvatarPastels.first;
  }
  return kAvatarPastels[seed.codeUnits.fold<int>(0, (a, b) => a + b) %
      kAvatarPastels.length];
}
