import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../auth/supabase_auth/auth_util.dart';
import '../../../backend/supabase/database/database.dart';
import '../../../backend/supabase/supabase.dart';
import '../models/event_flow_models.dart';

class EventRepositoryException implements Exception {
  const EventRepositoryException(this.message);

  final String message;
}

class CheckInSubmissionException implements Exception {
  const CheckInSubmissionException(this.reason, this.message);

  final EventCheckInFailureReason reason;
  final String message;
}

class AttendanceSubmissionResult {
  const AttendanceSubmissionResult({
    required this.action,
    required this.message,
  });

  final EventAttendanceAction action;
  final String message;
}

class EventRepository {
  static const double boundaryMeters = 100;
  static final RegExp _uuidPattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
  );

  Future<EventDetailsData> fetchEventDetails(String eventId) async {
    if (eventId.trim().isEmpty) {
      throw const EventRepositoryException('Missing event id.');
    }

    final eventRows = await EventsTable().queryRows(
      queryFn: (q) => q.eq('id', eventId),
      limit: 1,
    );
    if (eventRows.isEmpty) {
      throw const EventRepositoryException('Event not found.');
    }

    final event = eventRows.first;
    final hostId = (event.createdBy).trim();

    final eventViewFuture = EventsAttendanceViewTable().queryRows(
      queryFn: (q) => q.eq('event_id', eventId),
      limit: 1,
    );
    final hostFuture = _isUuid(hostId)
        ? ProfilesTable().queryRows(
            queryFn: (q) => q.eq('id', hostId),
            limit: 1,
          )
        : Future.value(<ProfilesRow>[]);
    final currentProfileFuture = _isUuid(currentUserUid)
        ? ProfilesTable().queryRows(
            queryFn: (q) => q.eq('id', currentUserUid),
            limit: 1,
          )
        : Future.value(<ProfilesRow>[]);
    final attendeeFuture = AttendanceViewTable().queryRows(
      queryFn: (q) => q.eq('event_id', eventId).order(
            'attendance_created_at',
            ascending: false,
          ),
    );

    final results = await Future.wait<dynamic>([
      eventViewFuture,
      hostFuture,
      currentProfileFuture,
      attendeeFuture,
    ]);

    final eventViewRows = results[0] as List<EventsAttendanceViewRow>;
    final eventView = eventViewRows.isEmpty ? null : eventViewRows.first;

    final hostRows = results[1] as List<ProfilesRow>;
    final hostProfile = hostRows.isEmpty ? null : hostRows.first;

    final currentProfileRows = results[2] as List<ProfilesRow>;
    final currentProfile =
        currentProfileRows.isEmpty ? null : currentProfileRows.first;

    final attendeeRows = results[3] as List<AttendanceViewRow>;

    final currentAttendance = attendeeRows
        .where((row) => row.userId == currentUserUid)
        .cast<AttendanceViewRow?>()
        .firstWhere((row) => row != null, orElse: () => null);

    return EventDetailsData(
      event: EventFlowEvent(
        id: event.id ?? eventId,
        title: _nonEmpty(event.title, fallback: 'Event details'),
        description: _nonEmpty(
          event.description,
          fallback: 'Description unavailable',
        ),
        locationName: _nonEmpty(
          event.location ?? eventView?.eventBranchId,
          fallback: 'Unavailable',
        ),
        startsAt: event.eventDate ??
            eventView?.eventStartDate ??
            event.createdAt ??
            DateTime.now(),
        endsAt: event.endtime ?? eventView?.eventEndTime,
        isActive: event.isactive ?? eventView?.isActive ?? false,
        hostUserId: hostId,
        heroImageUrl: _normalizedUrl(event.featuredUrl ?? eventView?.featuredImage),
        latitude: event.latitude ?? eventView?.eventLatitude,
        longitude: event.longitude ?? eventView?.eventLongitude,
        scope: event.scope,
      ),
      host: EventHostData(
        name: _nonEmpty(hostProfile?.fullName, fallback: 'Unavailable'),
        initials: _initialsFor(hostProfile?.fullName ?? 'Unavailable'),
        role: 'Event Host/Organizer',
        isVerified: hostProfile?.verified ?? false,
        avatarUrl: _normalizedUrl(hostProfile?.avatar),
      ),
      attendeeCount: attendeeRows.length,
      attendeePreview: attendeeRows.take(4).map((row) {
        final name = _nonEmpty(
          row.profileFullName ?? row.attendanceFullname,
          fallback: 'Unavailable',
        );
        return EventAttendeePreview(
          name: name,
          initials: _initialsFor(name),
          avatarUrl: null,
        );
      }).toList(growable: false),
      attendanceWorkers: attendeeRows.map((row) {
        final name = _nonEmpty(
          row.profileFullName ?? row.attendanceFullname,
          fallback: 'Unavailable',
        );
        return EventAttendanceWorker(
          userId: _nonEmpty(row.userId, fallback: name),
          fullName: name,
          initials: _initialsFor(name),
          branchId: row.branchId,
          branchName: row.branchName,
          departmentName: row.departmentName,
          checkedInAt: row.attendanceCreatedAt,
          checkedOutAt: row.clockout,
        );
      }).toList(growable: false),
      currentUserName: _nonEmpty(
        currentProfile?.fullName.isNotEmpty == true
            ? currentProfile?.fullName
            : currentUserDisplayName,
        fallback: 'Member',
      ),
      currentUserInitials: _initialsFor(
        currentProfile?.fullName.isNotEmpty == true
            ? currentProfile!.fullName
            : currentUserDisplayName,
      ),
      currentUserBranchId: currentProfile?.branchId,
      currentUserAvatarUrl: _normalizedUrl(currentProfile?.avatar ?? currentUserPhoto),
      currentAttendance: currentAttendance == null
          ? null
          : EventAttendanceData(
              id: currentAttendance.attendanceId,
              status: _nonEmpty(
                currentAttendance.attendanceStatus,
                fallback: 'present',
              ),
              fullName: _nonEmpty(
                currentAttendance.attendanceFullname ??
                    currentAttendance.profileFullName,
                fallback: 'Member',
              ),
              checkedInAt: currentAttendance.attendanceCreatedAt,
              checkedOutAt: currentAttendance.clockout,
              latitude: currentAttendance.latitude,
              longitude: currentAttendance.longitude,
              confirmedByName: currentAttendance.confirmedbyName,
            ),
    );
  }

  Future<EventAttendanceData?> fetchCurrentAttendance(String eventId) async {
    if (eventId.trim().isEmpty || currentUserUid.isEmpty) {
      return null;
    }
    final rows = await AttendanceViewTable().queryRows(
      queryFn: (q) => q
          .eq('event_id', eventId)
          .eq('user_id', currentUserUid)
          .order('attendance_created_at', ascending: false),
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    final row = rows.first;
    return EventAttendanceData(
      id: row.attendanceId,
      status: _nonEmpty(row.attendanceStatus, fallback: 'present'),
      fullName: _nonEmpty(
        row.attendanceFullname ?? row.profileFullName,
        fallback: 'Member',
      ),
      checkedInAt: row.attendanceCreatedAt,
      checkedOutAt: row.clockout,
      latitude: row.latitude,
      longitude: row.longitude,
      confirmedByName: row.confirmedbyName,
    );
  }

  Future<AttendanceSubmissionResult> submitAttendanceAction({
    required String eventId,
    required double latitude,
    required double longitude,
  }) async {
    if (currentJwtToken.trim().isEmpty) {
      throw const CheckInSubmissionException(
        EventCheckInFailureReason.unauthenticated,
        'You must be signed in to submit attendance.',
      );
    }

    final response = await http.post(
      Uri.parse(supabaseFunctionUrl('attendance-geofence')),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $currentJwtToken',
      },
      body: jsonEncode({
        'event_id': eventId,
        'user_location': {
          'latitude': latitude,
          'longitude': longitude,
        },
      }),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final action = _extractAction(response.body);
      return AttendanceSubmissionResult(
        action: action,
        message: _extractMessage(response.body),
      );
    }

    final rawMessage = _extractMessage(response.body);
    final normalized = rawMessage.toLowerCase();
    if (normalized.contains('already been clocked out')) {
      throw CheckInSubmissionException(
        EventCheckInFailureReason.backendRejected,
        rawMessage,
      );
    }
    if (normalized.contains('already been clocked') ||
        normalized.contains('already checked')) {
      throw CheckInSubmissionException(
        EventCheckInFailureReason.alreadyCheckedIn,
        rawMessage,
      );
    }
    if (normalized.contains('within the event location') ||
        normalized.contains('not at location')) {
      throw CheckInSubmissionException(
        EventCheckInFailureReason.outsideBoundary,
        rawMessage,
      );
    }
    if (normalized.contains('unauthorized')) {
      throw CheckInSubmissionException(
        EventCheckInFailureReason.unauthenticated,
        rawMessage,
      );
    }

    throw CheckInSubmissionException(
      EventCheckInFailureReason.backendRejected,
      rawMessage,
    );
  }

  EventAttendanceAction _extractAction(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final action = decoded['action']?.toString().trim();
        if (action == 'clock_out') {
          return EventAttendanceAction.clockOut;
        }
      }
    } catch (_) {
      // Fall back to default action.
    }
    return EventAttendanceAction.clockIn;
  }

  String _extractMessage(String body) {
    if (body.trim().isEmpty) {
      return 'We could not complete the request. Please try again.';
    }
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final message = decoded['message']?.toString().trim();
        if (message != null && message.isNotEmpty) {
          return message;
        }
        final error = decoded['error']?.toString().trim();
        if (error != null && error.isNotEmpty) {
          return error;
        }
      }
    } catch (_) {
      // Fall back to raw body.
    }
    return body;
  }

  static String _nonEmpty(String? value, {required String fallback}) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return fallback;
    }
    return trimmed;
  }

  static String? _normalizedUrl(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  static String _initialsFor(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .toList();
    if (parts.isEmpty) {
      return 'WP';
    }
    return parts.map((part) => part[0].toUpperCase()).join();
  }

  static bool _isUuid(String value) {
    final trimmed = value.trim();
    return trimmed.isNotEmpty && _uuidPattern.hasMatch(trimmed);
  }
}
