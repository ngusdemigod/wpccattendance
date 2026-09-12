import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/wpcc_time.dart';
import '../../core/widgets/section_empty_state.dart';
import 'event_repository.dart';

class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  static const pageSize = 20;
  final repo = EventRepository();

  List<Map<String, dynamic>> recurringRows = [];
  List<Map<String, dynamic>> upcomingRows = [];
  bool loading = true;
  bool loadingMore = false;
  bool hasMore = true;
  Object? error;

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
        if (reset) repo.recurringEvents(limit: pageSize),
        repo.events(
          mode: 'upcoming',
          type: 'all',
          limit: pageSize,
          offset: reset ? 0 : upcomingRows.length,
        ),
      ]);
      if (!mounted) return;
      setState(() {
        if (reset) {
          recurringRows = results.first;
          upcomingRows = results.last;
        } else {
          upcomingRows = [...upcomingRows, ...results.last];
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

  @override
  Widget build(BuildContext context) => SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(26, 18, 26, 110),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Events',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontSize: 30,
                                fontFamily: 'serif',
                                fontWeight: FontWeight.w400,
                                letterSpacing: -1.2,
                              ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Search',
                    onPressed: () => context.push('/search'),
                    icon: Icon(PhosphorIcons.magnifyingGlass(), size: 25),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (loading)
                const SizedBox(
                  height: 300,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (error != null)
                SectionEmptyState(
                  icon: PhosphorIcons.warningCircle(),
                  message: 'Unable to load events',
                  height: 220,
                )
              else ...[
                _EventSection(
                  title: 'Recurring Events',
                  events: recurringRows,
                  emptyMessage: 'No recurring events',
                ),
                const SizedBox(height: 28),
                _EventSection(
                  title: 'Upcoming Events',
                  events: upcomingRows,
                  emptyMessage: 'No upcoming events',
                ),
                if (hasMore)
                  Padding(
                    padding: const EdgeInsets.only(top: 18),
                    child: Center(
                      child: TextButton.icon(
                        onPressed:
                            loadingMore ? null : () => _load(reset: false),
                        icon: loadingMore
                            ? const SizedBox(
                                width: 15,
                                height: 15,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Icon(PhosphorIcons.arrowDown(), size: 15),
                        label: Text(loadingMore ? 'Loading…' : 'Load more'),
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      );
}

class _EventSection extends StatelessWidget {
  const _EventSection({
    required this.title,
    required this.events,
    required this.emptyMessage,
  });

  final String title;
  final List<Map<String, dynamic>> events;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                      ),
                ),
              ),
              Text(
                'View more',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: WpccColors.inkSoft,
                    ),
              ),
              const SizedBox(width: 10),
              Icon(
                PhosphorIcons.caretRight(),
                size: 17,
                color: WpccColors.inkSoft,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (events.isEmpty)
            SectionEmptyState(
              icon: PhosphorIcons.calendarBlank(),
              message: emptyMessage,
              height: 176,
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                const gap = 24.0;
                final width = (constraints.maxWidth - gap) / 2;
                return Wrap(
                  spacing: gap,
                  runSpacing: 24,
                  children: events
                      .take(2)
                      .map(
                        (event) => SizedBox(
                          width: width,
                          child: _EventTile(event: event),
                        ),
                      )
                      .toList(),
                );
              },
            ),
        ],
      );
}

class _EventTile extends StatelessWidget {
  const _EventTile({required this.event});

  final Map<String, dynamic> event;

  @override
  Widget build(BuildContext context) {
    final imageUrl = event['featured_image']?.toString().trim() ?? '';
    final description = event['description']?.toString().trim() ?? '';
    final location = event['location']?.toString().trim() ?? '';
    final eventId = event['event_id']?.toString();
    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: eventId == null
          ? null
          : () => context.push('/events/$eventId', extra: event),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: .88,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const _EventPlaceholder(),
                    )
                  : const _EventPlaceholder(),
            ),
          ),
          const SizedBox(height: 13),
          Text(
            event['title']?.toString() ?? 'Event',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                  letterSpacing: -.35,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            event['event_start_at'] != null
                ? WpccTime.compact(event['event_start_at'])
                : _recurrenceLabel(event),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: WpccColors.inkSoft,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            description.isNotEmpty
                ? description
                : location.isNotEmpty
                    ? location
                    : 'Location unavailable',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: WpccColors.inkSoft,
                ),
          ),
        ],
      ),
    );
  }

  static String _recurrenceLabel(Map<String, dynamic> event) {
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

class _EventPlaceholder extends StatelessWidget {
  const _EventPlaceholder();

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: const Color(0xFFFAF9F7),
        child: Center(
          child: Icon(
            PhosphorIcons.imageBroken(),
            size: 30,
            color: const Color(0xFFB7A58F),
          ),
        ),
      );
}
