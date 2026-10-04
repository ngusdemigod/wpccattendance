import 'package:flutter/material.dart';
import '../../core/widgets/member_skeleton.dart';
import '../../core/widgets/adaptive_layout.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/utils/wpcc_time.dart';
import '../../core/widgets/member_components.dart';
import '../search/search_filter_sheet.dart';
import 'event_repository.dart';

typedef EventsLoader = Future<List<Map<String, dynamic>>> Function({
  required int limit,
  required int offset,
});

class EventsPage extends StatefulWidget {
  const EventsPage({super.key, this.loadEvents, this.loadRecurring});
  final EventsLoader? loadEvents;
  final Future<List<Map<String, dynamic>>> Function()? loadRecurring;

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  static const pageSize = 20;
  late final repo = EventRepository();

  List<Map<String, dynamic>> recurringRows = [];
  List<Map<String, dynamic>> upcomingRows = [];
  List<Map<String, dynamic>> departmentalRows = [];
  bool loading = true;
  bool loadingMore = false;
  bool hasMore = true;
  int loadedEventCount = 0;
  Object? error;
  String filter = 'Upcoming';
  String _searchFilter = 'All';
  DateTimeRange? dateRange;

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  Future<void> _load({required bool reset}) async {
    if (reset) {
      setState(() {
        loading = true;
        error = null;
        hasMore = true;
      });
    } else {
      if (loadingMore || !hasMore) return;
      setState(() => loadingMore = true);
    }

    try {
      final results = await Future.wait([
        if (reset)
          widget.loadRecurring?.call() ?? repo.recurringEvents(limit: pageSize),
        widget.loadEvents
                ?.call(limit: pageSize, offset: reset ? 0 : loadedEventCount) ??
            repo.events(
              mode: 'upcoming',
              type: 'all',
              limit: pageSize,
              offset: reset ? 0 : loadedEventCount,
            ),
      ]);
      if (!mounted) return;
      setState(() {
        if (reset) {
          loadedEventCount = results.last.length;
          recurringRows = results.first;
          departmentalRows = results.last
              .where((event) => event['department_id'] != null)
              .toList();
          upcomingRows = results.last
              .where((event) => event['department_id'] == null)
              .toList();
        } else {
          loadedEventCount += results.last.length;
          departmentalRows = [
            ...departmentalRows,
            ...results.last.where((event) => event['department_id'] != null),
          ];
          upcomingRows = [
            ...upcomingRows,
            ...results.last.where((event) => event['department_id'] == null),
          ];
        }
        hasMore = results.last.length == pageSize;
        error = null;
      });
    } catch (e) {
      if (mounted) setState(() => error = e);
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
          loadingMore = false;
        });
      }
    }
  }

  Future<void> _refresh() => _load(reset: true);

  Future<void> _searchFilters() async {
    final selected =
        await showSearchFilterSheet(context, selected: _currentSearchFilter);
    if (!mounted || selected == null) return;
    _openSearch(selected);
  }

  String get _currentSearchFilter =>
      MemberSearchScope.maybeOf(context)?.value ?? _searchFilter;

  void _openSearch(String section) {
    _searchFilter = section;
    MemberSearchScope.maybeOf(context)?.value = section;
    context.push(
        Uri(path: '/search', queryParameters: {'filter': section}).toString());
  }

  Future<void> _dateFilter() async {
    final chosen = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
        initialDateRange: dateRange);
    if (chosen != null && mounted) setState(() => dateRange = chosen);
  }

  List<Map<String, dynamic>> get visibleRows {
    final rows = switch (filter) {
      'Church' => upcomingRows,
      'Departments' => departmentalRows,
      'Recurring' => recurringRows,
      _ => [...upcomingRows, ...departmentalRows],
    };
    if (dateRange == null || filter == 'Recurring') return rows;
    return rows.where((event) {
      final date = DateTime.tryParse(event['event_start_at']?.toString() ?? '')
          ?.toLocal();
      return date != null &&
          !date.isBefore(dateRange!.start) &&
          date.isBefore(dateRange!.end.add(const Duration(days: 1)));
    }).toList();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: memberPagePadding(context, top: 20, bottom: 124),
          children: [
            Row(children: [
              MemberIconButton(
                  label: 'Back',
                  icon: PhosphorIcons.caretLeft(),
                  onPressed: () => context.go('/home')),
              const SizedBox(width: 10),
              Expanded(
                  child: Text('Events',
                      style: Theme.of(context).textTheme.headlineSmall)),
              MemberIconButton(
                  label: 'Date filter',
                  icon: PhosphorIcons.calendarBlank(),
                  plain: true,
                  onPressed: _dateFilter),
            ]),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                    maxWidth: MediaQuery.sizeOf(context).width >= 900
                        ? 720
                        : double.infinity),
                child: MemberSearchBar(
                    hint: 'Search events, departments, and more',
                    onTap: () => _openSearch(_currentSearchFilter),
                    onFilter: _searchFilters),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
                height: 48,
                child: ListView(scrollDirection: Axis.horizontal, children: [
                  for (final group in [
                    ('Upcoming', PhosphorIcons.flame()),
                    ('Church', PhosphorIcons.mapPin()),
                    ('Departments', PhosphorIcons.users()),
                    ('Recurring', PhosphorIcons.clock()),
                  ])
                    Padding(
                        padding: const EdgeInsets.only(right: 7),
                        child: MemberFilterChip(
                            label: group.$1,
                            icon: group.$2,
                            featured: group.$1 == 'Upcoming',
                            selected: filter == group.$1,
                            onPressed: () =>
                                setState(() => filter = group.$1))),
                ])),
            if (dateRange != null)
              Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    icon: Icon(PhosphorIcons.x(), size: 16),
                    onPressed: () => setState(() => dateRange = null),
                    label: Text(
                        '${WpccTime.eventDate(dateRange!.start.toIso8601String())} / '
                        '${WpccTime.eventDate(dateRange!.end.toIso8601String())}'),
                  )),
            const SizedBox(height: 22),
            Text(filter == 'Upcoming' ? 'Coming up' : filter,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontSize: 27, height: 34 / 27)),
            const SizedBox(height: 14),
            if (loading)
              const SizedBox(height: 220, child: MemberSkeleton())
            else if (error != null)
              MemberStatus(
                  icon: PhosphorIcons.warningCircle(),
                  message: 'Unable to load events',
                  onRetry: _refresh)
            else if (visibleRows.isEmpty)
              MemberStatus(
                  icon: PhosphorIcons.calendarBlank(),
                  message: 'No upcoming events')
            else
              AdaptiveCards(
                  minimumWidth: 420,
                  maximumColumns: 2,
                  gap: 7,
                  children: visibleRows
                      .map((event) => _EventResultRow(
                          event: event, recurring: filter == 'Recurring'))
                      .toList()),
            if (!loading && error == null && hasMore)
              Padding(
                  padding: const EdgeInsets.only(top: 18),
                  child: Center(
                      child: TextButton.icon(
                    onPressed: loadingMore ? null : () => _load(reset: false),
                    icon: loadingMore
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : Icon(PhosphorIcons.arrowDown(), size: 16),
                    label: Text(loadingMore ? 'Loading...' : 'Load more'),
                  ))),
          ],
        ),
      ));
}

class _EventResultRow extends StatelessWidget {
  const _EventResultRow({required this.event, required this.recurring});
  final Map<String, dynamic> event;
  final bool recurring;
  @override
  Widget build(BuildContext context) {
    final id =
        (event['event_id'] ?? event['recurring_event_id'])?.toString() ?? '';
    final colors = Theme.of(context).colorScheme;
    final date = event['event_start_at'] == null
        ? ''
        : WpccTime.compact(event['event_start_at']);
    final location = event['location']?.toString().trim() ?? '';
    final image = event['featured_image']?.toString();
    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: colors.outlineVariant)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap:
            id.isEmpty ? null : () => context.push('/events/$id', extra: event),
        child: Padding(
          padding: const EdgeInsets.all(11),
          child: Row(children: [
            if (recurring)
              _RecurringDate(event: event)
            else
              Hero(
                  tag: 'event-image:$id',
                  child: MemberArtwork(
                      imageUrl: image,
                      size: 64,
                      height: 66,
                      icon: PhosphorIcons.calendarDots())),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                  Text(event['title']?.toString() ?? 'Event',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontSize: 15,
                          height: 21 / 15,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  if (recurring)
                    Text(_EventTile.recurrenceLabel(event),
                        style: Theme.of(context).textTheme.bodySmall)
                  else
                    Wrap(spacing: 8, runSpacing: 3, children: [
                      if (date.isNotEmpty)
                        _Metadata(
                            icon: PhosphorIcons.calendarBlank(), text: date),
                      if (location.isNotEmpty)
                        _Metadata(icon: PhosphorIcons.mapPin(), text: location),
                    ]),
                ])),
            const SizedBox(width: 8),
            Icon(PhosphorIcons.caretRight(),
                size: 16, color: colors.onSurfaceVariant),
          ]),
        ),
      ),
    );
  }
}

class _Metadata extends StatelessWidget {
  const _Metadata({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon,
            size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: 5),
        Flexible(
            child: Text(text,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(fontSize: 12, height: 1.5))),
      ]);
}

class _RecurringDate extends StatelessWidget {
  const _RecurringDate({required this.event});
  final Map<String, dynamic> event;
  @override
  Widget build(BuildContext context) {
    const days = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];
    final day = int.tryParse(event['day_of_week']?.toString() ?? '');
    final scale = MediaQuery.textScalerOf(context).scale(11) / 11;
    return Container(
        width: 50 + (scale - 1) * 20,
        height: 50 + (scale - 1) * 20,
        decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12)),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (day != null && day >= 0 && day < 7)
            Text(days[day],
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(fontSize: 11)),
          Icon(PhosphorIcons.clock(), size: 20),
        ]));
  }
}

class _EventTile {
  static String recurrenceLabel(Map<String, dynamic> event) {
    const days = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
    ];
    final dayIndex = int.tryParse(event['day_of_week']?.toString() ?? '');
    final day = dayIndex != null && dayIndex >= 0 && dayIndex < days.length
        ? days[dayIndex]
        : 'Recurring';
    final rawTime = event['start_time']?.toString() ?? '';
    final parts = rawTime.split(':');
    if (parts.length < 2) return day;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return day;
    final suffix = hour >= 12 ? 'pm' : 'am';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;
    return '$day, $displayHour:${minute.toString().padLeft(2, '0')}$suffix';
  }
}
