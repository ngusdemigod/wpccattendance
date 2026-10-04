import 'package:flutter/material.dart';

import '../../../flutter_flow/custom_icons.dart';

/// Search sections / filter chips. `all` is only a filter, never a section.
enum SearchFilter { all, people, events, announcements, departments }

extension SearchFilterX on SearchFilter {
  String get label {
    switch (this) {
      case SearchFilter.all:
        return 'All';
      case SearchFilter.people:
        return 'People';
      case SearchFilter.events:
        return 'Events';
      case SearchFilter.announcements:
        return 'Notices';
      case SearchFilter.departments:
        return 'Departments';
    }
  }

  String get sectionTitle {
    switch (this) {
      case SearchFilter.all:
        return 'All';
      case SearchFilter.people:
        return 'People';
      case SearchFilter.events:
        return 'Events';
      case SearchFilter.announcements:
        return 'Announcements';
      case SearchFilter.departments:
        return 'Departments';
    }
  }

  IconData get icon {
    switch (this) {
      case SearchFilter.all:
        return FFIcons.kgridFour;
      case SearchFilter.people:
        return FFIcons.kuserCircle;
      case SearchFilter.events:
        return FFIcons.kcalendarBlank;
      case SearchFilter.announcements:
        return FFIcons.kmegaphone;
      case SearchFilter.departments:
        return FFIcons.kbuildings;
    }
  }

  /// Value sent to the `global_search` RPC and used in `?filter=` deep links.
  String get rpcValue => name;

  static SearchFilter fromQueryParam(String? value) {
    switch (value?.trim().toLowerCase()) {
      case 'people':
        return SearchFilter.people;
      case 'events':
        return SearchFilter.events;
      case 'announcements':
      case 'notices':
        return SearchFilter.announcements;
      case 'departments':
        return SearchFilter.departments;
      default:
        return SearchFilter.all;
    }
  }
}

/// One row returned by the `global_search` RPC.
class GlobalSearchResult {
  const GlobalSearchResult({
    required this.id,
    required this.section,
    required this.title,
    this.subtitle,
    this.body,
    this.imageUrl,
    required this.resultType,
    required this.route,
    required this.rank,
    this.metadata = const {},
  });

  final String id;
  final SearchFilter section;
  final String title;
  final String? subtitle;
  final String? body;
  final String? imageUrl;
  final String resultType;
  final String route;
  final double rank;
  final Map<String, dynamic> metadata;

  /// True total for the section before per-section limiting.
  int get sectionTotal => (metadata['section_total'] as num?)?.toInt() ?? 0;

  bool get isPinned => metadata['is_pinned'] == true;

  bool get isUpcomingEvent => metadata['upcoming'] == true;

  DateTime? get eventStartAt =>
      DateTime.tryParse(metadata['event_start_at'] as String? ?? '');

  DateTime? get createdAt =>
      DateTime.tryParse(metadata['created_at'] as String? ?? '');

  static GlobalSearchResult? fromJson(Map<String, dynamic> json) {
    final section = _sectionFromName(json['section'] as String?);
    final id = json['id'] as String?;
    if (section == null || id == null || id.isEmpty) {
      return null;
    }
    return GlobalSearchResult(
      id: id,
      section: section,
      title: (json['title'] as String?)?.trim().isNotEmpty == true
          ? (json['title'] as String).trim()
          : 'Untitled',
      subtitle: _nullable(json['subtitle']),
      body: _nullable(json['body']),
      imageUrl: _nullable(json['image_url']),
      resultType: json['result_type'] as String? ?? '',
      route: json['route'] as String? ?? '',
      rank: (json['rank'] as num?)?.toDouble() ?? 0,
      metadata: json['metadata'] is Map
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : const {},
    );
  }

  static SearchFilter? _sectionFromName(String? name) {
    switch (name) {
      case 'people':
        return SearchFilter.people;
      case 'events':
        return SearchFilter.events;
      case 'announcements':
        return SearchFilter.announcements;
      case 'departments':
        return SearchFilter.departments;
      default:
        return null;
    }
  }

  static String? _nullable(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
