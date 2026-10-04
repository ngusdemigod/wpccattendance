import 'package:flutter/foundation.dart';

import '../data/events_repository.dart';
import '../models/event_flow_models.dart';

class EventDetailsController extends ChangeNotifier {
  EventDetailsController({
    required this.eventId,
    EventRepository? repository,
  }) : _repository = repository ?? EventRepository();

  final String eventId;
  final EventRepository _repository;

  bool isLoading = true;
  bool isRefreshing = false;
  String? errorMessage;
  EventDetailsData? data;

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      data = await _repository.fetchEventDetails(eventId);
    } on EventRepositoryException catch (error) {
      errorMessage = error.message;
    } catch (_) {
      errorMessage = 'Unable to load this event right now.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    if (isRefreshing) {
      return;
    }
    isRefreshing = true;
    notifyListeners();
    try {
      data = await _repository.fetchEventDetails(eventId);
      errorMessage = null;
    } on EventRepositoryException catch (error) {
      errorMessage = error.message;
    } catch (_) {
      errorMessage = 'Unable to refresh event details right now.';
    } finally {
      isRefreshing = false;
      notifyListeners();
    }
  }
}
