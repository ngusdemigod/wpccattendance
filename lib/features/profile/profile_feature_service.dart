import 'package:flutter/foundation.dart';

import '../../auth/supabase_auth/auth_util.dart';
import '../../backend/supabase/database/database.dart';

enum ProfileRouteTab { overview, classes, query }

enum ProfileQueryFilter { overview, resolved, needsAttention }

class ProfileClassSummary {
  const ProfileClassSummary({
    required this.completedCount,
    required this.inProgressCount,
    required this.dueSoonCount,
  });

  final int completedCount;
  final int inProgressCount;
  final int dueSoonCount;
}

class ProfileClassItem {
  const ProfileClassItem({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.progressPercent,
    required this.moduleIndex,
    required this.moduleTotal,
    required this.dueAt,
    required this.remainingLessons,
    required this.certificateAvailable,
    required this.category,
    required this.iconKey,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String description;
  final String status;
  final int progressPercent;
  final int? moduleIndex;
  final int? moduleTotal;
  final DateTime? dueAt;
  final int? remainingLessons;
  final bool certificateAvailable;
  final String? category;
  final String? iconKey;
  final DateTime? createdAt;
}

class ProfileClassesPayload {
  const ProfileClassesPayload({
    required this.summary,
    required this.items,
  });

  final ProfileClassSummary summary;
  final List<ProfileClassItem> items;
}

class ProfileQueryItem {
  const ProfileQueryItem({
    required this.id,
    required this.title,
    required this.details,
    required this.status,
    required this.raisedByName,
    required this.raisedByDepartment,
    required this.openedAt,
    required this.updatedAt,
    required this.closedAt,
    required this.escalatesAt,
    required this.requiresAcknowledgement,
    required this.requiresResponse,
    required this.responseText,
    required this.acknowledgedAt,
    required this.respondedAt,
  });

  final String id;
  final String title;
  final String details;
  final String status;
  final String? raisedByName;
  final String? raisedByDepartment;
  final DateTime? openedAt;
  final DateTime? updatedAt;
  final DateTime? closedAt;
  final DateTime? escalatesAt;
  final bool requiresAcknowledgement;
  final bool requiresResponse;
  final String? responseText;
  final DateTime? acknowledgedAt;
  final DateTime? respondedAt;
}

class ProfileFeatureService {
  Future<ProfileClassesPayload> getUserClasses() async {
    final rows = await MyClassesTable().queryRows(
      queryFn: (q) => q.order('assigned_at', ascending: false),
      limit: 200,
    );

    final items = rows
        .map((row) {
          final title = row.title?.trim() ?? '';
          if (title.isEmpty) {
            return null;
          }

          final normalizedStatus = _normalizeClassStatus(
            row.status,
            progressPercent: row.progressPercent,
          );

          return ProfileClassItem(
            id: row.publicationId?.trim() ?? row.courseId?.trim() ?? title,
            title: title,
            description: row.description?.trim() ?? '',
            status: normalizedStatus,
            progressPercent: _clampPercent(row.progressPercent),
            moduleIndex: row.moduleIndex,
            moduleTotal: row.moduleTotal,
            dueAt: row.dueAt,
            remainingLessons: row.remainingLessons,
            certificateAvailable: row.certificateAvailable == true,
            category: row.category?.trim(),
            iconKey: row.iconKey?.trim(),
            createdAt: row.assignedAt,
          );
        })
        .whereType<ProfileClassItem>()
        .toList()
      ..sort(_sortClassItems);

    final now = DateTime.now();
    final soonThreshold = now.add(const Duration(days: 7));
    final completedCount =
        items.where((item) => item.status == 'completed').length;
    final inProgressCount =
        items.where((item) => item.status == 'in_progress').length;
    final dueSoonCount = items
        .where((item) =>
            item.status != 'completed' &&
            item.dueAt != null &&
            !item.dueAt!.isBefore(now) &&
            !item.dueAt!.isAfter(soonThreshold))
        .length;

    return ProfileClassesPayload(
      summary: ProfileClassSummary(
        completedCount: completedCount,
        inProgressCount: inProgressCount,
        dueSoonCount: dueSoonCount,
      ),
      items: items,
    );
  }

  Future<List<ProfileQueryItem>> getUserQueries(
      ProfileQueryFilter filter) async {
    final rows = await MyQueriesTable().queryRows(
      queryFn: (q) => q.order('opened_at', ascending: false),
      limit: 200,
    );

    final items = rows
        .map((row) {
          return ProfileQueryItem(
            id: row.id?.trim() ?? '',
            title: row.title?.trim() ?? '',
            details: row.details?.trim() ?? '',
            status: _normalizeQueryStatus(row.status),
            raisedByName: _firstNonEmpty([row.raisedByName]),
            raisedByDepartment: _firstNonEmpty([row.raisedByDepartment]),
            openedAt: row.openedAt,
            updatedAt: row.updatedAt,
            closedAt: row.closedAt,
            escalatesAt: row.escalatesAt,
            requiresAcknowledgement: row.requiresAcknowledgement == true,
            requiresResponse: row.requiresResponse == true,
            responseText: row.responseText?.trim(),
            acknowledgedAt: row.acknowledgedAt,
            respondedAt: row.respondedAt,
          );
        })
        .where((item) => item.id.isNotEmpty && item.title.isNotEmpty)
        .toList()
      ..sort(_sortQueryItems);

    switch (filter) {
      case ProfileQueryFilter.overview:
        return items;
      case ProfileQueryFilter.resolved:
        return items.where((item) => item.status == 'resolved').toList();
      case ProfileQueryFilter.needsAttention:
        return items.where(_needsAttention).toList();
    }
  }

  Future<ProfileQueryItem?> getQueryDetails(String queryId) async {
    final rows = await MyQueriesTable().queryRows(
      queryFn: (q) => q.eq('id', queryId),
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    final itemList = await getUserQueries(ProfileQueryFilter.overview);
    final direct = itemList.where((item) => item.id == queryId);
    if (direct.isNotEmpty) {
      return direct.first;
    }

    final row = rows.first;
    return ProfileQueryItem(
      id: row.id?.trim() ?? '',
      title: row.title?.trim() ?? '',
      details: row.details?.trim() ?? '',
      status: _normalizeQueryStatus(row.status),
      raisedByName: row.raisedByName?.trim(),
      raisedByDepartment: row.raisedByDepartment?.trim(),
      openedAt: row.openedAt,
      updatedAt: row.updatedAt,
      closedAt: row.closedAt,
      escalatesAt: row.escalatesAt,
      requiresAcknowledgement: row.requiresAcknowledgement == true,
      requiresResponse: row.requiresResponse == true,
      responseText: row.responseText?.trim(),
      acknowledgedAt: row.acknowledgedAt,
      respondedAt: row.respondedAt,
    );
  }

  Future<void> acknowledgeQuery(String queryId) async {
    await WorkerQueriesTable().update(
      data: <String, dynamic>{
        'acknowledged_at': DateTime.now().toUtc().toIso8601String(),
        'requires_acknowledgement': false,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      matchingRows: (q) => q.eq('id', queryId).eq('user_id', currentUserUid),
    );
  }

  Future<void> submitQueryResponse(String queryId, String responseText) async {
    await WorkerQueriesTable().update(
      data: <String, dynamic>{
        'response_text': responseText.trim(),
        'responded_at': DateTime.now().toUtc().toIso8601String(),
        'requires_response': false,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      matchingRows: (q) => q.eq('id', queryId).eq('user_id', currentUserUid),
    );
  }

  static bool _needsAttention(ProfileQueryItem item) {
    if (item.status == 'escalated') {
      return true;
    }
    if (item.status == 'resolved') {
      return false;
    }
    return item.requiresAcknowledgement || item.requiresResponse;
  }

  static int _sortClassItems(ProfileClassItem left, ProfileClassItem right) {
    final rankDiff =
        _classStatusRank(left.status).compareTo(_classStatusRank(right.status));
    if (rankDiff != 0) {
      return rankDiff;
    }

    final leftDue = left.dueAt;
    final rightDue = right.dueAt;
    if (leftDue != null && rightDue != null) {
      final dueDiff = leftDue.compareTo(rightDue);
      if (dueDiff != 0) {
        return dueDiff;
      }
    } else if (leftDue != null) {
      return -1;
    } else if (rightDue != null) {
      return 1;
    }

    final leftCreated = left.createdAt;
    final rightCreated = right.createdAt;
    if (leftCreated != null && rightCreated != null) {
      return rightCreated.compareTo(leftCreated);
    }
    if (leftCreated != null) {
      return -1;
    }
    if (rightCreated != null) {
      return 1;
    }
    return left.title.compareTo(right.title);
  }

  static int _sortQueryItems(ProfileQueryItem left, ProfileQueryItem right) {
    final rankDiff =
        _queryStatusRank(left.status).compareTo(_queryStatusRank(right.status));
    if (rankDiff != 0) {
      return rankDiff;
    }

    final leftDate = left.updatedAt ?? left.openedAt;
    final rightDate = right.updatedAt ?? right.openedAt;
    if (leftDate != null && rightDate != null) {
      return rightDate.compareTo(leftDate);
    }
    if (leftDate != null) {
      return -1;
    }
    if (rightDate != null) {
      return 1;
    }
    return left.title.compareTo(right.title);
  }

  static int _classStatusRank(String status) {
    switch (status) {
      case 'in_progress':
        return 0;
      case 'pending':
        return 1;
      case 'completed':
        return 2;
      default:
        return 3;
    }
  }

  static int _queryStatusRank(String status) {
    switch (status) {
      case 'escalated':
        return 0;
      case 'awaiting_response':
        return 1;
      case 'resolved':
        return 2;
      default:
        return 3;
    }
  }

  static String _normalizeClassStatus(
    String? raw, {
    required int? progressPercent,
  }) {
    final value = raw?.trim().toLowerCase() ?? '';
    if (value == 'pending' || value == 'in_progress' || value == 'completed') {
      return value;
    }
    if ((progressPercent ?? 0) >= 100) {
      return 'completed';
    }
    if ((progressPercent ?? 0) > 0) {
      return 'in_progress';
    }
    return 'pending';
  }

  static String _normalizeQueryStatus(String? raw) {
    final value = raw?.trim().toLowerCase() ?? '';
    if (value == 'resolved' || value == 'escalated') {
      return value;
    }
    return 'awaiting_response';
  }

  static int _clampPercent(int? value) {
    final safeValue = value ?? 0;
    if (safeValue < 0) {
      return 0;
    }
    if (safeValue > 100) {
      return 100;
    }
    return safeValue;
  }

  static String? _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      final trimmed = value?.trim() ?? '';
      if (trimmed.isNotEmpty) {
        return trimmed;
      }
    }
    return null;
  }
}

@visibleForTesting
String describeQueryFilter(ProfileQueryFilter filter) {
  switch (filter) {
    case ProfileQueryFilter.overview:
      return 'Overview';
    case ProfileQueryFilter.resolved:
      return 'Resolved';
    case ProfileQueryFilter.needsAttention:
      return 'Needs attention';
  }
}
