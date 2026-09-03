import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

import '../../backend/supabase/database/database.dart';
import '../../shared/widgets/event_card_data.dart';

class HomeFeedData {
  const HomeFeedData({
    required this.displayName,
    required this.fullName,
    required this.avatarInitials,
    required this.queryCount,
    required this.events,
    required this.announcements,
    required this.upcomingEvents,
    required this.connectPeople,
    this.heroEvent,
  });

  final String displayName;
  final String fullName;
  final String avatarInitials;
  final int queryCount;
  final List<HomeEventCard> events;
  final HomeEventCard? heroEvent;
  final List<HomeAnnouncement> announcements;
  final List<HomeUpcomingEventCard> upcomingEvents;
  final List<HomeConnectPerson> connectPeople;

  Map<String, dynamic> toCacheMap() => {
        'displayName': displayName,
        'fullName': fullName,
        'avatarInitials': avatarInitials,
        'queryCount': queryCount,
        'events': events.map((item) => item.toCacheMap()).toList(),
        'heroEvent': heroEvent?.toCacheMap(),
        'announcements':
            announcements.map((item) => item.toCacheMap()).toList(),
        'upcomingEvents':
            upcomingEvents.map((item) => item.toCacheMap()).toList(),
        'connectPeople':
            connectPeople.map((item) => item.toCacheMap()).toList(),
      };

  factory HomeFeedData.fromCacheMap(Map<String, dynamic> map) => HomeFeedData(
        displayName: map['displayName']?.toString() ?? 'Member',
        fullName: map['fullName']?.toString() ?? 'Member',
        avatarInitials: map['avatarInitials']?.toString() ?? 'WP',
        queryCount: _toInt(map['queryCount']),
        events: _jsonList(map['events'])
            .map(HomeEventCard.fromCacheMap)
            .toList(growable: false),
        heroEvent: map['heroEvent'] is Map<String, dynamic>
            ? HomeEventCard.fromCacheMap(
                Map<String, dynamic>.from(map['heroEvent'] as Map),
              )
            : null,
        announcements: _jsonList(map['announcements'])
            .map(HomeAnnouncement.fromCacheMap)
            .toList(growable: false),
        upcomingEvents: _jsonList(map['upcomingEvents'])
            .map(HomeUpcomingEventCard.fromCacheMap)
            .toList(growable: false),
        connectPeople: _jsonList(map['connectPeople'])
            .map(HomeConnectPerson.fromCacheMap)
            .toList(growable: false),
      );
}

enum AnnouncementCardType { text, image, gallery }

enum AnnouncementSourceAvatarKind { admin, media, welfare, standard }

class AnnouncementImage {
  const AnnouncementImage({
    required this.url,
    this.sortOrder = 0,
  });

  final String url;
  final int sortOrder;

  Map<String, dynamic> toCacheMap() => {
        'url': url,
        'sortOrder': sortOrder,
      };

  factory AnnouncementImage.fromCacheMap(Map<String, dynamic> map) =>
      AnnouncementImage(
        url: map['url']?.toString() ?? '',
        sortOrder: _toInt(map['sortOrder']),
      );
}

class AnnouncementAcknowledgementUser {
  const AnnouncementAcknowledgementUser({
    required this.userId,
    required this.fullName,
  });

  final String userId;
  final String fullName;

  String get initials => _initialsFor(fullName);

  Map<String, dynamic> toCacheMap() => {
        'userId': userId,
        'fullName': fullName,
      };

  factory AnnouncementAcknowledgementUser.fromCacheMap(
    Map<String, dynamic> map,
  ) =>
      AnnouncementAcknowledgementUser(
        userId: map['userId']?.toString() ?? '',
        fullName: map['fullName']?.toString() ?? 'Member',
      );
}

class AnnouncementComment {
  const AnnouncementComment({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.body,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String fullName;
  final String body;
  final DateTime createdAt;

  String get initials => _initialsFor(fullName);
}

class HomeAnnouncement {
  const HomeAnnouncement({
    required this.id,
    required this.title,
    required this.body,
    required this.scope,
    required this.sourceName,
    required this.sourceTypeLabel,
    required this.sourceInitials,
    required this.metadataText,
    required this.avatarKind,
    required this.images,
    required this.acknowledgementCount,
    required this.acknowledgedByCurrentUser,
    required this.acknowledgementPreviewUsers,
    required this.commentCount,
    this.createdAt,
    this.isPinned = false,
    this.allowComments = false,
  });

  final String id;
  final String title;
  final String body;
  final String scope;
  final String sourceName;
  final String sourceTypeLabel;
  final String sourceInitials;
  final String metadataText;
  final AnnouncementSourceAvatarKind avatarKind;
  final DateTime? createdAt;
  final bool isPinned;
  final bool allowComments;
  final List<AnnouncementImage> images;
  final int acknowledgementCount;
  final bool acknowledgedByCurrentUser;
  final List<AnnouncementAcknowledgementUser> acknowledgementPreviewUsers;
  final int commentCount;

  bool get isDepartment => scope == 'department';
  bool get isGlobal => scope == 'global';
  AnnouncementCardType get cardType {
    if (images.isEmpty) {
      return AnnouncementCardType.text;
    }
    if (images.length == 1) {
      return AnnouncementCardType.image;
    }
    return AnnouncementCardType.gallery;
  }

  String get deepLinkPath => '/announcements/$id';

  Map<String, dynamic> toCacheMap() => {
        'id': id,
        'title': title,
        'body': body,
        'scope': scope,
        'sourceName': sourceName,
        'sourceTypeLabel': sourceTypeLabel,
        'sourceInitials': sourceInitials,
        'metadataText': metadataText,
        'avatarKind': avatarKind.name,
        'createdAt': createdAt?.toIso8601String(),
        'isPinned': isPinned,
        'allowComments': allowComments,
        'images': images.map((item) => item.toCacheMap()).toList(),
        'acknowledgementCount': acknowledgementCount,
        'acknowledgedByCurrentUser': acknowledgedByCurrentUser,
        'acknowledgementPreviewUsers': acknowledgementPreviewUsers
            .map((item) => item.toCacheMap())
            .toList(),
        'commentCount': commentCount,
      };

  factory HomeAnnouncement.fromCacheMap(Map<String, dynamic> map) =>
      HomeAnnouncement(
        id: map['id']?.toString() ?? '',
        title: map['title']?.toString() ?? '',
        body: map['body']?.toString() ?? '',
        scope: map['scope']?.toString() ?? 'global',
        sourceName: map['sourceName']?.toString() ?? 'Announcement',
        sourceTypeLabel: map['sourceTypeLabel']?.toString() ?? 'General',
        sourceInitials: map['sourceInitials']?.toString() ?? 'AN',
        metadataText: map['metadataText']?.toString() ?? '',
        avatarKind: AnnouncementSourceAvatarKind.values.firstWhere(
          (value) => value.name == map['avatarKind']?.toString(),
          orElse: () => AnnouncementSourceAvatarKind.standard,
        ),
        createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? ''),
        isPinned: map['isPinned'] == true,
        allowComments: map['allowComments'] == true,
        images: _jsonList(map['images'])
            .map(AnnouncementImage.fromCacheMap)
            .where((item) => item.url.isNotEmpty)
            .toList(growable: false),
        acknowledgementCount: _toInt(map['acknowledgementCount']),
        acknowledgedByCurrentUser: map['acknowledgedByCurrentUser'] == true,
        acknowledgementPreviewUsers:
            _jsonList(map['acknowledgementPreviewUsers'])
                .map(AnnouncementAcknowledgementUser.fromCacheMap)
                .toList(growable: false),
        commentCount: _toInt(map['commentCount']),
      );

  factory HomeAnnouncement.fromMap(Map<String, dynamic> row) {
    final createdAt = _toDateTime(row['created_at']);
    final scope = row['scope']?.toString() ?? 'global';
    final sourceName = _sourceNameFor(row, scope);
    final sourceTypeLabel = _sourceTypeFor(
      scope: scope,
      sourceName: sourceName,
    );
    final previewUsers =
        _jsonList(row['acknowledgement_preview_users']).map((entry) {
      final fullName = _firstNonEmpty(
        [entry['full_name']?.toString()],
        fallback: 'Member',
      );
      return AnnouncementAcknowledgementUser(
        userId: entry['user_id']?.toString() ?? fullName,
        fullName: fullName,
      );
    }).toList(growable: false);
    return HomeAnnouncement(
      id: row['id']?.toString() ?? '',
      title: row['title']?.toString() ?? '',
      body: _firstNonEmpty(
        [
          row['content']?.toString(),
          row['body']?.toString(),
        ],
      ),
      scope: scope,
      sourceName: sourceName,
      sourceTypeLabel: sourceTypeLabel,
      sourceInitials: _initialsFor(sourceName),
      metadataText: _metadataText(
        sourceTypeLabel: sourceTypeLabel,
        createdAt: createdAt,
      ),
      avatarKind: _avatarKindFor(
        sourceName: sourceName,
        sourceTypeLabel: sourceTypeLabel,
        scope: scope,
      ),
      createdAt: createdAt,
      isPinned: row['is_pinned'] == true,
      allowComments: row['allow_comments'] == true,
      images: _imagesFrom(row),
      acknowledgementCount: _toInt(row['acknowledgement_count']),
      acknowledgedByCurrentUser: row['acknowledged_by_current_user'] == true,
      acknowledgementPreviewUsers: previewUsers,
      commentCount: _toInt(row['comment_count']),
    );
  }
}

class HomeConnectPerson {
  const HomeConnectPerson({
    required this.id,
    required this.displayName,
    required this.initials,
    required this.subtitle,
    required this.avatarColor,
    this.avatarUrl,
  });

  final String id;
  final String displayName;
  final String initials;
  final String subtitle;
  final Color avatarColor;
  final String? avatarUrl;

  Map<String, dynamic> toCacheMap() => {
        'id': id,
        'displayName': displayName,
        'initials': initials,
        'subtitle': subtitle,
        'avatarColor': avatarColor.toARGB32(),
        'avatarUrl': avatarUrl,
      };

  factory HomeConnectPerson.fromCacheMap(Map<String, dynamic> map) =>
      HomeConnectPerson(
        id: map['id']?.toString() ?? '',
        displayName: map['displayName']?.toString() ?? 'Worker',
        initials: map['initials']?.toString() ?? 'WP',
        subtitle: map['subtitle']?.toString() ?? '',
        avatarColor: Color(_toInt(map['avatarColor'])),
        avatarUrl: map['avatarUrl']?.toString(),
      );

  factory HomeConnectPerson.fromRow(WorkerProfilesRow row) {
    final fullName = _firstNonEmpty(
      [
        row.fullName,
        '${row.firstname ?? ''} ${row.lastname ?? ''}'.trim(),
      ],
      fallback: 'Worker',
    );

    return HomeConnectPerson(
      id: row.userId ?? row.workerId ?? fullName,
      displayName: _compactName(
        firstName: row.firstname,
        lastName: row.lastname,
        fallback: fullName,
      ),
      initials: _initialsFor(fullName),
      subtitle: _firstNonEmpty(
        [row.departmentName, row.branchName],
        fallback: '',
      ),
      avatarColor: _avatarColorFor(fullName),
      avatarUrl:
          row.avatar?.trim().isNotEmpty == true ? row.avatar!.trim() : null,
    );
  }
}

class HomeEventCard implements EventCardData {
  const HomeEventCard({
    required this.id,
    required this.title,
    required this.eyebrow,
    required this.dateText,
    required this.timeText,
    required this.eventStartAt,
    required this.eventScope,
    required this.gradientColors,
    this.imageUrl,
    this.description,
    this.location,
    this.eventEndAt,
  });

  final String id;
  @override
  final String title;
  @override
  final String eyebrow;
  @override
  final String dateText;
  @override
  final String timeText;
  final DateTime eventStartAt;
  final DateTime? eventEndAt;
  final String eventScope;
  final String? description;
  final String? location;
  @override
  final String? imageUrl;
  @override
  final List<Color> gradientColors;

  Map<String, dynamic> toCacheMap() => {
        'id': id,
        'title': title,
        'eyebrow': eyebrow,
        'dateText': dateText,
        'timeText': timeText,
        'eventStartAt': eventStartAt.toIso8601String(),
        'eventEndAt': eventEndAt?.toIso8601String(),
        'eventScope': eventScope,
        'description': description,
        'location': location,
        'imageUrl': imageUrl,
        'gradientColors':
            gradientColors.map((color) => color.toARGB32()).toList(),
      };

  factory HomeEventCard.fromCacheMap(Map<String, dynamic> map) => HomeEventCard(
        id: map['id']?.toString() ?? '',
        title: map['title']?.toString() ?? 'Upcoming Event',
        eyebrow: map['eyebrow']?.toString() ?? '',
        dateText: map['dateText']?.toString() ?? '',
        timeText: map['timeText']?.toString() ?? '',
        eventStartAt:
            DateTime.tryParse(map['eventStartAt']?.toString() ?? '') ??
                DateTime.now(),
        eventEndAt: DateTime.tryParse(map['eventEndAt']?.toString() ?? ''),
        eventScope: map['eventScope']?.toString() ?? 'global',
        description: map['description']?.toString(),
        location: map['location']?.toString(),
        imageUrl: map['imageUrl']?.toString(),
        gradientColors: _jsonList(map['gradientColors'])
            .map((entry) => Color(_toInt(entry)))
            .toList(growable: false),
      );

  bool get isOngoing {
    final end = eventEndAt;
    if (end == null) {
      return false;
    }
    final now = DateTime.now().toUtc();
    return !eventStartAt.toUtc().isAfter(now) && !end.toUtc().isBefore(now);
  }

  String get heroFooter {
    final detail = _firstNonEmpty([
      location?.trim(),
      switch (eventScope) {
        'department' => 'Department Event',
        'branch' => 'Branch Event',
        _ => 'Global Service',
      },
    ]);
    return '$detail - $timeText';
  }

  factory HomeEventCard.fromRow(MyEventsRow row) {
    final start = row.eventStartAt ?? DateTime.now();
    final scope = row.eventScope ?? 'global';
    return HomeEventCard(
      id: row.eventId ?? '',
      title: row.title?.trim().isNotEmpty == true
          ? row.title!.trim()
          : 'Upcoming Event',
      eyebrow: _resolveEventEyebrow(
        scope: scope,
        location: row.location,
      ),
      dateText: DateFormat('EEE d MMM').format(start),
      timeText: _formatTimeRange(start, row.eventEndAt),
      eventStartAt: start,
      eventEndAt: row.eventEndAt,
      eventScope: scope,
      description: row.description,
      location: row.location,
      imageUrl: row.featuredImage,
      gradientColors: _gradientForScope(scope),
    );
  }
}

class HomeRecurringEventCard implements EventCardData {
  const HomeRecurringEventCard({
    required this.id,
    required this.title,
    required this.eyebrow,
    required this.timeText,
    required this.nextOccurrence,
    required this.gradientColors,
    this.imageUrl,
    this.description,
  });

  final String id;
  @override
  final String title;
  @override
  final String eyebrow;
  @override
  String get dateText => DateFormat('EEE d MMM').format(nextOccurrence);
  @override
  final String timeText;
  final DateTime nextOccurrence;
  final String? description;
  @override
  final String? imageUrl;
  @override
  final List<Color> gradientColors;

  factory HomeRecurringEventCard.fromRow(MyRecurringEventsRow row) {
    final scope = row.eventScope ?? 'global';
    final nextOccurrence = _resolveNextRecurringOccurrence(row);
    final title = row.title?.trim().isNotEmpty == true
        ? row.title!.trim()
        : 'Recurring Event';
    return HomeRecurringEventCard(
      id: row.recurringEventId ?? '',
      title: title,
      eyebrow: switch (scope) {
        'department' => 'DEPARTMENT RECURRING',
        'branch' => 'BRANCH RECURRING',
        _ => 'GLOBAL RECURRING',
      },
      timeText: _formatTimeRange(
        nextOccurrence,
        _resolveRecurringEnd(nextOccurrence, row.endTime),
      ),
      nextOccurrence: nextOccurrence,
      description: row.description,
      imageUrl: row.featuredImage,
      gradientColors: _gradientForScope(scope),
    );
  }
}

class HomeUpcomingEventCard {
  const HomeUpcomingEventCard({
    required this.id,
    required this.title,
    required this.monthLabel,
    required this.dayLabel,
    required this.timeLabel,
    required this.locationLabel,
    required this.badge,
    required this.eventStartAt,
    this.description,
  });

  final String id;
  final String title;
  final String monthLabel;
  final String dayLabel;
  final String timeLabel;
  final String locationLabel;
  final HomeUpcomingBadge badge;
  final DateTime eventStartAt;
  final String? description;

  Map<String, dynamic> toCacheMap() => {
        'id': id,
        'title': title,
        'monthLabel': monthLabel,
        'dayLabel': dayLabel,
        'timeLabel': timeLabel,
        'locationLabel': locationLabel,
        'badgeLabel': badge.label,
        'eventStartAt': eventStartAt.toIso8601String(),
        'description': description,
      };

  factory HomeUpcomingEventCard.fromCacheMap(Map<String, dynamic> map) =>
      HomeUpcomingEventCard(
        id: map['id']?.toString() ?? '',
        title: map['title']?.toString() ?? 'Upcoming Event',
        monthLabel: map['monthLabel']?.toString() ?? '',
        dayLabel: map['dayLabel']?.toString() ?? '',
        timeLabel: map['timeLabel']?.toString() ?? '',
        locationLabel:
            map['locationLabel']?.toString() ?? 'Location unavailable',
        badge: HomeUpcomingBadge.fromCategory(
          map['badgeLabel']?.toString() ?? 'Event',
        ),
        eventStartAt:
            DateTime.tryParse(map['eventStartAt']?.toString() ?? '') ??
                DateTime.now(),
        description: map['description']?.toString(),
      );

  factory HomeUpcomingEventCard.fromRow(MyEventsRow row) {
    final start = row.eventStartAt ?? DateTime.now();
    final scope = row.eventScope ?? 'global';
    return HomeUpcomingEventCard(
      id: row.eventId ?? '',
      title: row.title?.trim().isNotEmpty == true
          ? row.title!.trim()
          : 'Upcoming Event',
      monthLabel: DateFormat('MMM').format(start).toUpperCase(),
      dayLabel: DateFormat('dd').format(start),
      timeLabel: _formatEventDurationLabel(start, row.eventEndAt),
      locationLabel: _resolveUpcomingLocationLabel(row),
      badge: HomeUpcomingBadge.fromCategory(
        _resolveUpcomingCategory(
          title: row.title,
          scope: scope,
        ),
      ),
      eventStartAt: start,
      description: row.description,
    );
  }
}

class HomeUpcomingBadge {
  const HomeUpcomingBadge({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  factory HomeUpcomingBadge.fromCategory(String category) {
    return switch (category) {
      'Prayer' => const HomeUpcomingBadge(
          label: 'Prayer',
          backgroundColor: Color(0xFFE9EEF6),
          foregroundColor: Color(0xFF1F365C),
        ),
      'Activity' => const HomeUpcomingBadge(
          label: 'Activity',
          backgroundColor: Color(0xFFE3F0FF),
          foregroundColor: Color(0xFF3B73C5),
        ),
      'Convention' => const HomeUpcomingBadge(
          label: 'Convention',
          backgroundColor: Color(0xFFF3EFE8),
          foregroundColor: Color(0xFF3F372F),
        ),
      _ => const HomeUpcomingBadge(
          label: 'Event',
          backgroundColor: Color(0xFFF3F4F6),
          foregroundColor: Color(0xFF4B5563),
        ),
    };
  }
}

String _resolveEventEyebrow({
  required String scope,
  required String? location,
}) {
  final normalizedLocation = location?.trim();
  if (normalizedLocation != null && normalizedLocation.isNotEmpty) {
    return normalizedLocation.toUpperCase();
  }
  return switch (scope) {
    'department' => 'DEPARTMENT EVENT',
    'branch' => 'BRANCH EVENT',
    _ => 'WISDOM POWER CHRISTIAN CENTRE',
  };
}

String _resolveUpcomingCategory({
  required String? title,
  required String scope,
}) {
  final normalizedTitle = title?.trim().toLowerCase() ?? '';
  if (normalizedTitle.contains('prayer')) {
    return 'Prayer';
  }
  if (normalizedTitle.contains('convention')) {
    return 'Convention';
  }
  if (normalizedTitle.contains('summit') ||
      normalizedTitle.contains('activity') ||
      normalizedTitle.contains('empowerment')) {
    return 'Activity';
  }
  return switch (scope) {
    'global' => 'Convention',
    _ => 'Event',
  };
}

String _resolveUpcomingLocationLabel(MyEventsRow row) {
  final location = row.location?.trim() ?? '';
  if (location.isNotEmpty) {
    return location;
  }
  return switch (row.eventScope) {
    'department' => 'Department',
    'branch' => 'Branch',
    _ => 'Location unavailable',
  };
}

String _formatTimeRange(DateTime start, DateTime? end) {
  final timeFormat = DateFormat('h:mma');
  final startText = timeFormat.format(start).toLowerCase();
  if (end == null) {
    return startText;
  }
  return '$startText - ${timeFormat.format(end).toLowerCase()}';
}

String _formatEventDurationLabel(DateTime start, DateTime? end) {
  if (end == null) {
    return DateFormat('h:mma').format(start).toLowerCase();
  }

  final duration = end.difference(start);
  if (duration.inHours >= 24 && duration.inHours % 24 == 0) {
    final days = duration.inHours ~/ 24;
    return days == 1 ? '1 day' : '$days days';
  }

  return _formatTimeRange(start, end);
}

DateTime _resolveNextRecurringOccurrence(MyRecurringEventsRow row) {
  final now = DateTime.now();
  final currentDbDay = now.weekday % 7;
  final targetDay = row.dayOfWeek ?? currentDbDay;
  var offset = targetDay - currentDbDay;
  if (offset < 0) {
    offset += 7;
  }

  final baseDate = DateTime(now.year, now.month, now.day).add(
    Duration(days: offset),
  );
  final startTime = row.startTime?.time;
  if (startTime == null) {
    return baseDate;
  }

  final occurrence = DateTime(
    baseDate.year,
    baseDate.month,
    baseDate.day,
    startTime.hour,
    startTime.minute,
    startTime.second,
  );

  if (offset == 0 && occurrence.isBefore(now)) {
    return occurrence.add(const Duration(days: 7));
  }
  return occurrence;
}

DateTime? _resolveRecurringEnd(DateTime occurrence, PostgresTime? endTime) {
  final value = endTime?.time;
  if (value == null) {
    return null;
  }
  final end = DateTime(
    occurrence.year,
    occurrence.month,
    occurrence.day,
    value.hour,
    value.minute,
    value.second,
  );
  if (end.isBefore(occurrence)) {
    return end.add(const Duration(days: 1));
  }
  return end;
}

List<Color> _gradientForScope(String scope) {
  return switch (scope) {
    'department' => const [Color(0xFFF8E3CF), Color(0xFFF3C592)],
    'branch' => const [Color(0xFFF6DEC9), Color(0xFFE8B686)],
    _ => const [Color(0xFFFFF7D7), Color(0xFFF3CF7D)],
  };
}

String _firstNonEmpty(List<String?> values, {String fallback = ''}) {
  for (final value in values) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isNotEmpty) {
      return trimmed;
    }
  }
  return fallback;
}

List<Map<String, dynamic>> _jsonList(dynamic value) {
  if (value is List) {
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }
  if (value is String) {
    try {
      final decoded = jsonDecode(value);
      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList(growable: false);
      }
    } catch (_) {
      return const [];
    }
  }
  return const [];
}

DateTime? _toDateTime(dynamic value) {
  if (value is DateTime) {
    return value;
  }
  return DateTime.tryParse(value?.toString() ?? '');
}

List<AnnouncementImage> _imagesFrom(Map<String, dynamic> row) {
  final images = _jsonList(row['images'])
      .map((entry) {
        final url = entry['url']?.toString().trim() ?? '';
        if (url.isEmpty) {
          return null;
        }
        return AnnouncementImage(
          url: url,
          sortOrder: _toInt(entry['sort_order']),
        );
      })
      .whereType<AnnouncementImage>()
      .toList(growable: false)
    ..sort((left, right) => left.sortOrder.compareTo(right.sortOrder));
  if (images.isNotEmpty) {
    return images;
  }
  final legacyUrl = row['mediaurl']?.toString().trim() ?? '';
  if (legacyUrl.isEmpty) {
    return const [];
  }
  return [AnnouncementImage(url: legacyUrl)];
}

String _sourceNameFor(Map<String, dynamic> row, String scope) {
  switch (scope) {
    case 'department':
      return _firstNonEmpty(
        [row['department_name']?.toString()],
        fallback: 'Department Update',
      );
    case 'branch':
      return _firstNonEmpty(
        [row['branch_name']?.toString()],
        fallback: 'Branch Update',
      );
    default:
      return _firstNonEmpty(
        [row['creator_full_name']?.toString()],
        fallback: 'Global Admin',
      );
  }
}

String _sourceTypeFor({
  required String scope,
  required String sourceName,
}) {
  final normalized = sourceName.toLowerCase();
  if (normalized.contains('media')) {
    return 'Media';
  }
  if (normalized.contains('welfare') || normalized.contains('outreach')) {
    return 'Outreach';
  }
  if (scope == 'global') {
    return 'General';
  }
  if (scope == 'branch') {
    return 'Branch';
  }
  return 'Department';
}

String _metadataText({
  required String sourceTypeLabel,
  required DateTime? createdAt,
}) {
  if (createdAt == null) {
    return sourceTypeLabel;
  }
  final local = createdAt.toLocal();
  final now = DateTime.now();
  final sameDay = local.year == now.year &&
      local.month == now.month &&
      local.day == now.day;
  final timeText = DateFormat('h:mm a').format(local);
  final dateText =
      sameDay ? 'Today $timeText' : DateFormat('EEEE h:mm a').format(local);
  return '$sourceTypeLabel • $dateText';
}

AnnouncementSourceAvatarKind _avatarKindFor({
  required String sourceName,
  required String sourceTypeLabel,
  required String scope,
}) {
  final normalized = '$sourceName $sourceTypeLabel'.toLowerCase();
  if (normalized.contains('media')) {
    return AnnouncementSourceAvatarKind.media;
  }
  if (normalized.contains('welfare') || normalized.contains('outreach')) {
    return AnnouncementSourceAvatarKind.welfare;
  }
  if (scope == 'global' ||
      normalized.contains('admin') ||
      normalized.contains('general')) {
    return AnnouncementSourceAvatarKind.admin;
  }
  return AnnouncementSourceAvatarKind.standard;
}

int _toInt(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
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

String _compactName({
  required String? firstName,
  required String? lastName,
  required String fallback,
}) {
  final first = firstName?.trim() ?? '';
  final last = lastName?.trim() ?? '';
  if (first.isNotEmpty && last.isNotEmpty) {
    return '$first ${last[0].toUpperCase()}.';
  }
  if (first.isNotEmpty) {
    return first;
  }
  final parts =
      fallback.split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
  if (parts.length >= 2) {
    return '${parts.first} ${parts[1][0].toUpperCase()}.';
  }
  return fallback;
}

Color _avatarColorFor(String seed) {
  const palette = [
    Color(0xFFE4F0FB),
    Color(0xFFF1EADD),
    Color(0xFFE5F3E8),
    Color(0xFFF8E3CF),
    Color(0xFFEDE7FB),
  ];
  final index =
      seed.codeUnits.fold<int>(0, (sum, char) => sum + char) % palette.length;
  return palette[index];
}
