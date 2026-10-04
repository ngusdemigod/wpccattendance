import 'dart:math';
import 'dart:convert';

import '../../auth/supabase_auth/auth_util.dart';
import '../../backend/supabase/database/database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../announcements/announcement_repository.dart';
import 'home_feed_models.dart';

class HomeFeedService {
  static const _cacheKey = 'home_feed_cache_v1';
  static const _cacheSavedAtKey = 'home_feed_cache_saved_at_v1';
  static const _cacheTtl = Duration(minutes: 5);
  static HomeFeedData? _memoryCache;
  static DateTime? _memoryCacheSavedAt;

  final AnnouncementRepository _announcementRepository =
      AnnouncementRepository();

  Future<HomeFeedData?> loadCachedHomeFeed() async {
    final now = DateTime.now();
    if (_memoryCache != null && _memoryCacheSavedAt != null) {
      if (now.difference(_memoryCacheSavedAt!) <= _cacheTtl) {
        return _memoryCache;
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey);
    final savedAtRaw = prefs.getString(_cacheSavedAtKey);
    if (raw == null ||
        raw.isEmpty ||
        savedAtRaw == null ||
        savedAtRaw.isEmpty) {
      return null;
    }

    final savedAt = DateTime.tryParse(savedAtRaw);
    if (savedAt == null || now.difference(savedAt) > _cacheTtl) {
      return null;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      final data = HomeFeedData.fromCacheMap(decoded);
      _memoryCache = data;
      _memoryCacheSavedAt = savedAt;
      return data;
    } catch (_) {
      return null;
    }
  }

  Future<HomeFeedData> fetchAndCacheHomeFeed() async {
    final data = await fetchHomeFeed();
    await _persistCache(data);
    return data;
  }

  Future<HomeFeedData> fetchHomeFeed() async {
    if (currentUserUid.isEmpty) {
      final fallbackName = _firstNonEmpty(
        [currentUserDisplayName, currentUserEmail],
        fallback: 'Member',
      );
      return HomeFeedData(
        displayName: fallbackName.split(RegExp(r'\s+')).first,
        fullName: fallbackName,
        avatarInitials: _initialsFor(fallbackName),
        queryCount: 0,
        events: const [],
        announcements: const [],
        upcomingEvents: const [],
        connectPeople: const [],
      );
    }

    final results = await Future.wait<dynamic>([
      _loadProfileSafe(),
      _loadRelevantEventsSafe(),
      _loadAnnouncementsSafe(),
      _loadQueryCountSafe(),
    ]);
    final profileRows = results[0] as List<ProfileViewRow>;
    final eventRows = results[1] as List<MyEventsRow>;
    final announcements = results[2] as List<HomeAnnouncement>;
    final queryCount = results[3] as int;

    final profile = profileRows.isNotEmpty ? profileRows.first : null;
    final profileFullName = _firstNonEmpty([
      profile?.fullName,
      [
        profile?.firstname,
        profile?.lastname,
      ].whereType<String>().join(' ').trim(),
    ], fallback: '');
    final fallbackAuthName = _firstNonEmpty(
      [
        currentUserDisplayName.contains('@') ? '' : currentUserDisplayName,
        currentUserEmail.split('@').first,
      ],
      fallback: 'Member',
    );
    final fullName =
        profileFullName.isNotEmpty ? profileFullName : fallbackAuthName;
    final displayName = _preferredDisplayName(
      profile: profile,
      fallbackName: fullName,
    );

    final events = _filterRelevantEvents(
      eventRows.map(HomeEventCard.fromRow).toList(),
    );
    final heroEvent = _selectHeroEvent(events);
    final upcomingRows = eventRows.where(_isUpcomingRow).toList()
      ..sort((a, b) {
        final left = a.eventStartAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final right = b.eventStartAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return left.compareTo(right);
      });
    final upcomingEvents = upcomingRows
        .map(HomeUpcomingEventCard.fromRow)
        .where((event) => event.id.isNotEmpty)
        .toList();
    final connectPeople = await _loadConnectPeopleSafe(profile);

    return HomeFeedData(
      displayName: displayName,
      fullName: fullName,
      avatarInitials: _initialsFor(fullName),
      queryCount: queryCount,
      events: events.take(12).toList(growable: false),
      heroEvent: heroEvent,
      announcements: announcements.take(2).toList(),
      upcomingEvents: upcomingEvents.take(3).toList(),
      connectPeople: connectPeople,
    );
  }

  Future<List<ProfileViewRow>> _loadProfile() {
    return ProfileViewTable().queryRows(
      queryFn: (q) => q.eq('user_id', currentUserUid),
      limit: 1,
    );
  }

  Future<List<ProfileViewRow>> _loadProfileSafe() async {
    try {
      return await _loadProfile();
    } catch (_) {
      return const <ProfileViewRow>[];
    }
  }

  Future<List<MyEventsRow>> _loadRelevantEvents() {
    return MyEventsTable().queryRows(
      queryFn: (q) =>
          q.eq('is_active', true).order('event_start_at', ascending: true),
      // Filtering happens after row mapping so rows without an end date
      // remain eligible. Include older rows without starving future events.
      limit: 100,
    );
  }

  Future<List<MyEventsRow>> _loadRelevantEventsSafe() async {
    try {
      return await _loadRelevantEvents();
    } catch (_) {
      return const <MyEventsRow>[];
    }
  }

  Future<List<HomeAnnouncement>> _loadAnnouncementsSafe() async {
    try {
      return await _announcementRepository.fetchHomeAnnouncements();
    } catch (_) {
      return const <HomeAnnouncement>[];
    }
  }

  Future<int> _loadQueryCountSafe() async {
    try {
      return await SupaFlow.client
          .from('worker_queries')
          .count()
          .eq('user_id', currentUserUid);
    } catch (_) {
      return 0;
    }
  }

  Future<List<HomeConnectPerson>> _loadConnectPeople(
      ProfileViewRow? profile) async {
    final departmentId = profile?.departmentId?.trim() ?? '';
    if (departmentId.isEmpty) {
      return const [];
    }

    final rows = await WorkerProfilesTable().queryRows(
      queryFn: (q) => q
          .eq('department_id', departmentId)
          .neq('user_id', currentUserUid)
          .order('profile_created_at', ascending: false),
      limit: 24,
    );

    final shuffledRows = [...rows]..shuffle(Random());
    final seen = <String>{};
    final people = <HomeConnectPerson>[];
    for (final row in shuffledRows) {
      final id = row.userId ?? row.workerId ?? '';
      if (id.isEmpty || !seen.add(id)) {
        continue;
      }
      people.add(HomeConnectPerson.fromRow(row));
      if (people.length == 5) {
        break;
      }
    }
    return people;
  }

  Future<List<HomeConnectPerson>> _loadConnectPeopleSafe(
    ProfileViewRow? profile,
  ) async {
    try {
      return await _loadConnectPeople(profile);
    } catch (_) {
      return const <HomeConnectPerson>[];
    }
  }

  HomeEventCard? _selectHeroEvent(List<HomeEventCard> events) {
    for (final event in events) {
      if (event.isOngoing) {
        return event;
      }
    }
    return events.isNotEmpty ? events.first : null;
  }

  List<HomeEventCard> _filterRelevantEvents(List<HomeEventCard> events) {
    final now = DateTime.now().toUtc();
    return events.where((event) {
      final start = event.eventStartAt.toUtc();
      final end = event.eventEndAt?.toUtc();
      if (end != null) {
        return !end.isBefore(now);
      }
      return !start.isBefore(now);
    }).toList();
  }

  bool _isUpcomingRow(MyEventsRow row) {
    final now = DateTime.now().toUtc();
    final start = row.eventStartAt?.toUtc();
    final end = row.eventEndAt?.toUtc();
    if (end != null) {
      return !end.isBefore(now);
    }
    if (start == null) {
      return false;
    }
    return !start.isBefore(now);
  }

  String _firstNonEmpty(List<String?> values, {required String fallback}) {
    for (final value in values) {
      final trimmed = value?.trim() ?? '';
      if (trimmed.isNotEmpty) {
        return trimmed;
      }
    }
    return fallback;
  }

  String _initialsFor(String name) {
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

  String _preferredDisplayName({
    required ProfileViewRow? profile,
    required String fallbackName,
  }) {
    final surname = profile?.lastname?.trim() ?? '';
    if (surname.isNotEmpty) {
      return surname;
    }

    final firstName = profile?.firstname?.trim() ?? '';
    if (firstName.isNotEmpty) {
      return firstName;
    }

    final trimmed = fallbackName.trim();
    if (trimmed.isEmpty) {
      return 'Member';
    }
    return trimmed.split(RegExp(r'\s+')).first;
  }

  Future<void> _persistCache(HomeFeedData data) async {
    _memoryCache = data;
    _memoryCacheSavedAt = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, jsonEncode(data.toCacheMap()));
    await prefs.setString(
      _cacheSavedAtKey,
      _memoryCacheSavedAt!.toIso8601String(),
    );
  }
}
