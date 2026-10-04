import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/foundation.dart';

import '../data/global_search_repository.dart';
import '../models/global_search_models.dart';

enum GlobalSearchStatus { idle, loading, success, empty, error }

/// A quick action shortcut derived from live results.
class SearchQuickAction {
  const SearchQuickAction({
    required this.title,
    required this.subtitle,
    required this.badgeLabel,
    required this.targetFilter,
  });

  final String title;
  final String subtitle;
  final String badgeLabel;
  final SearchFilter targetFilter;
}

class GlobalSearchController extends ChangeNotifier {
  GlobalSearchController({GlobalSearchRepository? repository})
      : _repository = repository ?? GlobalSearchRepository();

  static const _debounceTag = 'global_search';
  static const _minQueryLength = 2;

  final GlobalSearchRepository _repository;

  GlobalSearchStatus status = GlobalSearchStatus.idle;
  String query = '';
  SearchFilter filter = SearchFilter.all;
  List<GlobalSearchResult> results = const [];

  int _requestId = 0;
  bool _disposed = false;

  static const List<SearchFilter> sectionOrder = [
    SearchFilter.people,
    SearchFilter.announcements,
    SearchFilter.events,
    SearchFilter.departments,
  ];

  bool get hasQuery => query.trim().length >= _minQueryLength;

  /// Best ranked row overall — only shown on the All filter.
  GlobalSearchResult? get topResult {
    if (filter != SearchFilter.all || results.isEmpty) return null;
    return results.reduce((a, b) => b.rank > a.rank ? b : a);
  }

  /// Results grouped by section in display order, top result excluded
  /// from its own section to avoid duplication.
  Map<SearchFilter, List<GlobalSearchResult>> get groupedSections {
    final top = topResult;
    final grouped = <SearchFilter, List<GlobalSearchResult>>{};
    for (final section in sectionOrder) {
      final rows = results
          .where((r) => r.section == section && !identical(r, top))
          .toList()
        ..sort((a, b) => b.rank.compareTo(a.rank));
      if (rows.isNotEmpty) {
        grouped[section] = rows;
      }
    }
    return grouped;
  }

  int sectionTotal(SearchFilter section) {
    for (final r in results) {
      if (r.section == section) return r.sectionTotal;
    }
    return 0;
  }

  int get totalMatches {
    var total = 0;
    for (final section in sectionOrder) {
      total += sectionTotal(section);
    }
    return total;
  }

  List<SearchQuickAction> get quickActions {
    if (filter != SearchFilter.all || status != GlobalSearchStatus.success) {
      return const [];
    }
    final actions = <SearchQuickAction>[];
    final upcomingEvents =
        results.where((r) => r.section == SearchFilter.events && r.isUpcomingEvent);
    if (upcomingEvents.isNotEmpty) {
      actions.add(SearchQuickAction(
        title: 'View upcoming ${query.trim().toLowerCase()} events',
        subtitle: '${sectionTotal(SearchFilter.events)} matches',
        badgeLabel: 'Event',
        targetFilter: SearchFilter.events,
      ));
    }
    final peopleTotal = sectionTotal(SearchFilter.people);
    if (peopleTotal > 0) {
      actions.add(SearchQuickAction(
        title: 'Find workers and members',
        subtitle: '$peopleTotal matches',
        badgeLabel: 'People',
        targetFilter: SearchFilter.people,
      ));
    }
    return actions;
  }

  void onQueryChanged(String value) {
    query = value;
    if (!hasQuery) {
      EasyDebounce.cancel(_debounceTag);
      _requestId++;
      status = GlobalSearchStatus.idle;
      results = const [];
      notifyListeners();
      return;
    }
    status = GlobalSearchStatus.loading;
    notifyListeners();
    EasyDebounce.debounce(
      _debounceTag,
      const Duration(milliseconds: 350),
      _run,
    );
  }

  void setFilter(SearchFilter value) {
    if (filter == value) return;
    filter = value;
    if (hasQuery) {
      EasyDebounce.cancel(_debounceTag);
      status = GlobalSearchStatus.loading;
      notifyListeners();
      _run();
    } else {
      notifyListeners();
    }
  }

  void clear() {
    onQueryChanged('');
  }

  Future<void> retry() async {
    if (!hasQuery) return;
    status = GlobalSearchStatus.loading;
    notifyListeners();
    await _run();
  }

  Future<void> search(String value) async {
    query = value;
    if (!hasQuery) return;
    status = GlobalSearchStatus.loading;
    notifyListeners();
    await _run();
  }

  Future<void> _run() async {
    final id = ++_requestId;
    final term = query.trim();
    try {
      final rows = await _repository.search(
        query: term,
        filter: filter,
        limitPerSection: filter == SearchFilter.all ? 5 : 20,
      );
      if (_disposed || id != _requestId) return;
      results = rows;
      status =
          rows.isEmpty ? GlobalSearchStatus.empty : GlobalSearchStatus.success;
    } catch (_) {
      if (_disposed || id != _requestId) return;
      results = const [];
      status = GlobalSearchStatus.error;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    EasyDebounce.cancel(_debounceTag);
    super.dispose();
  }
}
