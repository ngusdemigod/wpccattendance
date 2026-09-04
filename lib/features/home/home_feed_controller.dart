import 'package:flutter/foundation.dart';

import 'home_feed_models.dart';
import 'home_feed_service.dart';

class HomeFeedController extends ChangeNotifier {
  HomeFeedController({
    HomeFeedService? service,
  }) : _service = service ?? HomeFeedService();

  final HomeFeedService _service;

  HomeFeedData? data;
  bool isLoading = true;
  bool isRefreshing = false;
  String? errorText;
  bool _hydrated = false;

  Future<void> hydrate() async {
    if (_hydrated) {
      return;
    }
    _hydrated = true;

    final cached = await _service.loadCachedHomeFeed();
    if (cached != null) {
      data = cached;
      isLoading = false;
      notifyListeners();
    }

    await refresh();
  }

  Future<void> refresh() async {
    final hasCachedData = data != null;
    if (hasCachedData) {
      isRefreshing = true;
    } else {
      isLoading = true;
    }
    errorText = null;
    notifyListeners();

    try {
      data = await _service.fetchAndCacheHomeFeed();
    } catch (_) {
      if (!hasCachedData) {
        errorText = 'Unable to load your home feed right now.';
      }
    } finally {
      isLoading = false;
      isRefreshing = false;
      notifyListeners();
    }
  }
}
