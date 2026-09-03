import 'package:flutter/foundation.dart';

import '../../../auth/supabase_auth/auth_util.dart';
import '../data/events_repository.dart';
import '../data/location_verification_service.dart';
import '../models/event_flow_models.dart';

class ClockInController extends ChangeNotifier {
  ClockInController({
    required this.eventId,
    EventRepository? repository,
    LocationVerificationService? locationService,
  })  : _repository = repository ?? EventRepository(),
        _locationService = locationService ?? const LocationVerificationService();

  final String eventId;
  final EventRepository _repository;
  final LocationVerificationService _locationService;

  EventDetailsData? data;
  String? errorMessage;
  EventCheckInState state = const EventCheckInState(
    stage: ClockInStage.initial,
  );

  bool _started = false;

  Future<void> start() async {
    if (_started) {
      return;
    }
    _started = true;

    if (currentUserUid.isEmpty) {
      state = const EventCheckInState(
        stage: ClockInStage.failure,
        failureReason: EventCheckInFailureReason.unauthenticated,
      );
      notifyListeners();
      return;
    }

    state = const EventCheckInState(stage: ClockInStage.loadingEvent);
    notifyListeners();

    try {
      data = await _repository.fetchEventDetails(eventId);
      final details = data!;
      final action = details.currentAttendance?.isCheckedIn == true
          ? EventAttendanceAction.clockOut
          : EventAttendanceAction.clockIn;

      state = state.copyWith(action: action);
      notifyListeners();

      if (action == EventAttendanceAction.clockOut && !details.event.hasEnded) {
        state = state.copyWith(
          stage: ClockInStage.failure,
          failureReason: EventCheckInFailureReason.backendRejected,
          failureMessage: 'You cannot clock out until the event has ended.',
        );
        notifyListeners();
        return;
      }

      if (!details.event.hasCoordinates) {
        state = const EventCheckInState(
          stage: ClockInStage.failure,
          failureReason: EventCheckInFailureReason.missingCoordinates,
        );
        notifyListeners();
        return;
      }

      state = const EventCheckInState(stage: ClockInStage.requestingPermission);
      notifyListeners();

      state = const EventCheckInState(stage: ClockInStage.gettingLocation);
      notifyListeners();

      final verification = await _locationService.verify(
        eventLatitude: details.event.latitude!,
        eventLongitude: details.event.longitude!,
      );

      state = EventCheckInState(
        stage: ClockInStage.verifyingBoundary,
        distanceMeters: verification.distanceMeters,
        userLatitude: verification.latitude,
        userLongitude: verification.longitude,
      );
      notifyListeners();

      state = state.copyWith(stage: ClockInStage.submittingCheckIn);
      notifyListeners();

      final result = await _repository.submitAttendanceAction(
        eventId: eventId,
        latitude: verification.latitude,
        longitude: verification.longitude,
      );

      state = state.copyWith(
        stage: ClockInStage.success,
        action: result.action,
      );
      notifyListeners();
    } on LocationVerificationException catch (error) {
      state = EventCheckInState(
        stage: ClockInStage.failure,
        action: state.action,
        failureReason: error.reason,
        failureMessage: error.message,
      );
      notifyListeners();
    } on CheckInSubmissionException catch (error) {
      state = EventCheckInState(
        stage: error.reason == EventCheckInFailureReason.alreadyCheckedIn
            ? ClockInStage.success
            : ClockInStage.failure,
        action: state.action,
        failureReason: error.reason,
        failureMessage: error.message,
      );
      notifyListeners();
    } on EventRepositoryException catch (error) {
      errorMessage = error.message;
      state = EventCheckInState(
        stage: ClockInStage.failure,
        action: state.action,
        failureReason: EventCheckInFailureReason.unknown,
      );
      notifyListeners();
    } catch (_) {
      state = EventCheckInState(
        stage: ClockInStage.failure,
        action: state.action,
        failureReason: EventCheckInFailureReason.unknown,
      );
      notifyListeners();
    }
  }
}
