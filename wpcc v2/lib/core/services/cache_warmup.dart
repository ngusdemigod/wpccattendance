import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/events/event_repository.dart';
import '../../features/media/media_repository.dart';

/// Fills [SwrCache] for the tabs a member is most likely to open next, so the
/// Media and Events tabs render from memory instead of waiting on the network.
///
/// It only calls the same repository methods (with the same arguments and so
/// the same cache keys) those pages use, and only for a signed-in member. It
/// starts after the first screen has had time to load its own data, so it
/// never competes with it, and every failure is ignored: the pages still load
/// normally and show their own error and retry states.
class CacheWarmup {
  const CacheWarmup._();

  /// Matches `EventsPage.pageSize`; a mismatch only means a cache miss.
  static const _eventsPageSize = 20;

  static void schedule({
    Duration delay = const Duration(milliseconds: 2500),
    SupabaseClient? client,
    MediaRepository? media,
    EventRepository? events,
  }) {
    Timer(delay, () {
      final signedIn =
          (client ?? Supabase.instance.client).auth.currentSession != null;
      if (!signedIn) return;
      final mediaRepository = media ?? MediaRepository();
      final eventRepository = events ?? EventRepository();
      // Run one after another so the warm-up never opens a burst of requests.
      unawaited(_run([
        () => mediaRepository.episodes(),
        () => mediaRepository.albums(),
        () => mediaRepository.videos(),
        () => eventRepository.events(mode: 'upcoming', limit: _eventsPageSize),
        () => eventRepository.events(mode: 'ongoing', limit: _eventsPageSize),
        () => eventRepository.recurringEvents(limit: _eventsPageSize),
      ]));
    });
  }

  static Future<void> _run(List<Future<Object?> Function()> steps) async {
    for (final step in steps) {
      try {
        await step();
      } catch (_) {
        // Warm-up is best effort.
      }
    }
  }
}
