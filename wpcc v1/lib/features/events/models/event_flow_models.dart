import 'package:flutter/material.dart';

enum EventCheckInFailureReason {
  outsideBoundary,
  permissionDenied,
  permissionDeniedForever,
  gpsDisabled,
  missingCoordinates,
  timeout,
  backendRejected,
  unauthenticated,
  alreadyCheckedIn,
  unknown,
}

enum EventAttendanceAction {
  clockIn,
  clockOut,
}

extension EventAttendanceActionX on EventAttendanceAction {
  String get queryValue => this == EventAttendanceAction.clockOut
      ? 'clock_out'
      : 'clock_in';

  static EventAttendanceAction fromQuery(String? value) {
    return value == 'clock_out'
        ? EventAttendanceAction.clockOut
        : EventAttendanceAction.clockIn;
  }

  String get pastTenseLabel =>
      this == EventAttendanceAction.clockOut ? 'checked out' : 'checked in';

  String get title => this == EventAttendanceAction.clockOut
      ? 'You are checked out'
      : 'You are checked in';
}

extension EventCheckInFailureReasonX on EventCheckInFailureReason {
  String get queryValue => name;

  static EventCheckInFailureReason fromQuery(String? value) {
    return EventCheckInFailureReason.values.firstWhere(
      (reason) => reason.name == value,
      orElse: () => EventCheckInFailureReason.unknown,
    );
  }

  String get title {
    switch (this) {
      case EventCheckInFailureReason.permissionDenied:
      case EventCheckInFailureReason.permissionDeniedForever:
      case EventCheckInFailureReason.gpsDisabled:
      case EventCheckInFailureReason.outsideBoundary:
      case EventCheckInFailureReason.missingCoordinates:
      case EventCheckInFailureReason.timeout:
      case EventCheckInFailureReason.backendRejected:
      case EventCheckInFailureReason.unknown:
      case EventCheckInFailureReason.unauthenticated:
      case EventCheckInFailureReason.alreadyCheckedIn:
        return "Sorry, we couldn't find you in church";
    }
  }

  String get message {
    switch (this) {
      case EventCheckInFailureReason.permissionDenied:
        return 'Location permission is required to verify your attendance. Please enable location access and try again.';
      case EventCheckInFailureReason.permissionDeniedForever:
        return 'Location permission has been permanently denied for this app. Enable it in your device settings and try again.';
      case EventCheckInFailureReason.gpsDisabled:
        return 'Your device location service is turned off. Turn on GPS and try again.';
      case EventCheckInFailureReason.outsideBoundary:
        return 'We could not verify that your device is inside the approved event boundary. Move closer to the venue and try again.';
      case EventCheckInFailureReason.missingCoordinates:
        return 'There is no attendance location configured yet for this event. Please contact an administrator.';
      case EventCheckInFailureReason.timeout:
        return 'We could not get your location in time. Check your connection and GPS accuracy, then try again.';
      case EventCheckInFailureReason.backendRejected:
        return 'Your attendance could not be verified. Please try again or contact support.';
      case EventCheckInFailureReason.unauthenticated:
        return 'Your session is no longer active. Sign in again before submitting attendance.';
      case EventCheckInFailureReason.alreadyCheckedIn:
        return 'Your attendance has already been recorded for this event.';
      case EventCheckInFailureReason.unknown:
        return 'We could not complete attendance verification right now. Please try again.';
    }
  }

  String get statusLabel {
    switch (this) {
      case EventCheckInFailureReason.outsideBoundary:
        return 'Outside approved boundary';
      case EventCheckInFailureReason.permissionDenied:
      case EventCheckInFailureReason.permissionDeniedForever:
        return 'Location permission required';
      case EventCheckInFailureReason.gpsDisabled:
        return 'GPS service disabled';
      case EventCheckInFailureReason.missingCoordinates:
        return 'Attendance point unavailable';
      case EventCheckInFailureReason.timeout:
        return 'Location lookup timed out';
      case EventCheckInFailureReason.backendRejected:
        return 'Attendance verification rejected';
      case EventCheckInFailureReason.unauthenticated:
        return 'Authentication required';
      case EventCheckInFailureReason.alreadyCheckedIn:
        return 'Already checked in';
      case EventCheckInFailureReason.unknown:
        return 'Verification unavailable';
    }
  }
}

class EventAttendeePreview {
  const EventAttendeePreview({
    required this.name,
    required this.initials,
    this.avatarUrl,
  });

  final String name;
  final String initials;
  final String? avatarUrl;
}

class EventHostData {
  const EventHostData({
    required this.name,
    required this.initials,
    required this.role,
    required this.isVerified,
    this.avatarUrl,
  });

  final String name;
  final String initials;
  final String role;
  final bool isVerified;
  final String? avatarUrl;
}

class EventAttendanceData {
  const EventAttendanceData({
    required this.status,
    required this.fullName,
    this.id,
    this.checkedInAt,
    this.checkedOutAt,
    this.latitude,
    this.longitude,
    this.confirmedByName,
  });

  final String? id;
  final String status;
  final String fullName;
  final DateTime? checkedInAt;
  final DateTime? checkedOutAt;
  final double? latitude;
  final double? longitude;
  final String? confirmedByName;

  bool get isCheckedIn => checkedInAt != null && checkedOutAt == null;
}

class EventAttendanceWorker {
  const EventAttendanceWorker({
    required this.userId,
    required this.fullName,
    required this.initials,
    this.avatarUrl,
    this.branchId,
    this.branchName,
    this.departmentName,
    this.checkedInAt,
    this.checkedOutAt,
  });

  final String userId;
  final String fullName;
  final String initials;
  final String? avatarUrl;
  final String? branchId;
  final String? branchName;
  final String? departmentName;
  final DateTime? checkedInAt;
  final DateTime? checkedOutAt;

  bool get isActiveInService => checkedInAt != null && checkedOutAt == null;
}

class EventFlowEvent {
  const EventFlowEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.locationName,
    required this.startsAt,
    required this.endsAt,
    required this.isActive,
    required this.hostUserId,
    this.heroImageUrl,
    this.latitude,
    this.longitude,
    this.scope,
  });

  final String id;
  final String title;
  final String description;
  final String locationName;
  final DateTime startsAt;
  final DateTime? endsAt;
  final bool isActive;
  final String hostUserId;
  final String? heroImageUrl;
  final double? latitude;
  final double? longitude;
  final String? scope;

  bool get hasCoordinates => latitude != null && longitude != null;

  bool get isOpenForCheckIn {
    final now = DateTime.now();
    if (!isActive) {
      return false;
    }
    if (startsAt.isAfter(now)) {
      return false;
    }
    if (endsAt != null && endsAt!.isBefore(now)) {
      return false;
    }
    return true;
  }

  bool get hasEnded {
    final end = endsAt;
    return end != null && !end.isAfter(DateTime.now());
  }
}

class EventDetailsData {
  const EventDetailsData({
    required this.event,
    required this.host,
    required this.attendeeCount,
    required this.attendeePreview,
    required this.attendanceWorkers,
    required this.currentUserName,
    required this.currentUserInitials,
    this.currentUserBranchId,
    this.currentUserAvatarUrl,
    this.currentAttendance,
  });

  final EventFlowEvent event;
  final EventHostData host;
  final int attendeeCount;
  final List<EventAttendeePreview> attendeePreview;
  final List<EventAttendanceWorker> attendanceWorkers;
  final String currentUserName;
  final String currentUserInitials;
  final String? currentUserBranchId;
  final String? currentUserAvatarUrl;
  final EventAttendanceData? currentAttendance;
}

enum ClockInStage {
  initial,
  loadingEvent,
  requestingPermission,
  gettingLocation,
  verifyingBoundary,
  submittingCheckIn,
  success,
  failure,
}

extension ClockInStageX on ClockInStage {
  String get label {
    switch (this) {
      case ClockInStage.initial:
      case ClockInStage.loadingEvent:
        return 'Checking event boundary';
      case ClockInStage.requestingPermission:
        return 'Requesting location permission';
      case ClockInStage.gettingLocation:
        return 'Getting your location';
      case ClockInStage.verifyingBoundary:
        return 'Verifying attendance point';
      case ClockInStage.submittingCheckIn:
        return 'Submitting check-in';
      case ClockInStage.success:
        return 'Check-in verified';
      case ClockInStage.failure:
        return 'Verification failed';
    }
  }
}

@immutable
class EventCheckInState {
  const EventCheckInState({
    required this.stage,
    this.action = EventAttendanceAction.clockIn,
    this.distanceMeters,
    this.failureReason,
    this.failureMessage,
    this.userLatitude,
    this.userLongitude,
  });

  final ClockInStage stage;
  final EventAttendanceAction action;
  final double? distanceMeters;
  final EventCheckInFailureReason? failureReason;
  final String? failureMessage;
  final double? userLatitude;
  final double? userLongitude;

  bool get isFinal =>
      stage == ClockInStage.success || stage == ClockInStage.failure;

  EventCheckInState copyWith({
    ClockInStage? stage,
    EventAttendanceAction? action,
    double? distanceMeters,
    EventCheckInFailureReason? failureReason,
    String? failureMessage,
    double? userLatitude,
    double? userLongitude,
  }) {
    return EventCheckInState(
      stage: stage ?? this.stage,
      action: action ?? this.action,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      failureReason: failureReason ?? this.failureReason,
      failureMessage: failureMessage ?? this.failureMessage,
      userLatitude: userLatitude ?? this.userLatitude,
      userLongitude: userLongitude ?? this.userLongitude,
    );
  }
}
