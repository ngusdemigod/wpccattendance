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

  String filter = 'all';
  List<Map<String, dynamic>> ongoingRows = [];
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
      final offset = reset ? 0 : upcomingRows.length;
      final eventType = filter == 'prayer' ? 'prayer' : 'all';
      final results = await Future.wait([
        if (reset)
          repo.events(mode: 'ongoing', type: eventType, limit: pageSize),
        repo.events(
          mode: 'upcoming',
          type: eventType,
          limit: pageSize,
          offset: offset,
        ),
      ]);

      if (!mounted) return;
      setState(() {
        if (reset) {
          ongoingRows = results.first;
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

  void _filter(String value) {
    if (value == filter) return;
    setState(() => filter = value);
    _load(reset: true);
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    bottom: false,
    child: RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 110),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Events',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: -.7,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => context.push('/search'),
                icon: Icon(PhosphorIcons.magnifyingGlass(), size: 21),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _chip('all', 'All'),
                _chip('ongoing', 'Ongoing'),
                _chip('upcoming', 'Upcoming'),
                _chip('prayer', 'Prayer'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (loading)
            const SizedBox(
              height: 280,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (error != null)
            SectionEmptyState(
              icon: PhosphorIcons.warningCircle(),
              message: 'Unable to load events',
              height: 220,
            )
          else ...[
            if (filter != 'upcoming')
              Text(
                'Ongoing services',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            if (filter != 'upcoming') const SizedBox(height: 9),
            if (filter != 'upcoming' && ongoingRows.isEmpty)
              SectionEmptyState(
                icon: PhosphorIcons.calendarCheck(),
                message: 'No ongoing service',
                height: 130,
              )
            else if (filter != 'upcoming')
              ...ongoingRows.map((e) => _EventCard(event: e, ongoing: true)),
            if (filter != 'upcoming') const SizedBox(height: 24),
            if (filter != 'ongoing')
              Text(
                filter == 'all' ? 'Recurring events' : 'Upcoming events',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            if (filter != 'ongoing') const SizedBox(height: 9),
            if (filter != 'ongoing' && upcomingRows.isEmpty)
              SectionEmptyState(
                icon: PhosphorIcons.calendarBlank(),
                message: 'No upcoming events',
              )
            else if (filter != 'ongoing') ...[
              ...upcomingRows.map((e) => _EventCard(event: e)),
              if (hasMore)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Center(
                    child: TextButton.icon(
                      onPressed: loadingMore ? null : () => _load(reset: false),
                      icon: loadingMore
                          ? const SizedBox(
                              width: 15,
                              height: 15,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(PhosphorIcons.arrowDown(), size: 15),
                      label: Text(loadingMore ? 'Loading…' : 'Load more'),
                    ),
                  ),
                ),
            ],
          ],
        ],
      ),
    ),
  );

  Widget _chip(String key, String label) => Padding(
    padding: const EdgeInsets.only(right: 7),
    child: ChoiceChip(
      selected: filter == key,
      showCheckmark: false,
      label: Text(label),
      onSelected: (_) => _filter(key),
      selectedColor: WpccColors.ink,
      backgroundColor: Colors.white,
      side: BorderSide.none,
      shape: const StadiumBorder(),
      labelStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
        fontSize: 12,
        color: filter == key ? Colors.white : WpccColors.inkSoft,
      ),
    ),
  );
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event, this.ongoing = false});

  final Map<String, dynamic> event;
  final bool ongoing;

  @override
  Widget build(BuildContext context) {
    final title = event['title']?.toString() ?? 'Event';
    final type = event['event_type']?.toString() ?? 'event';
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () => context.push('/events/${event['event_id']}', extra: event),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: const LinearGradient(
                  colors: [Color(0xFFDDD7EF), Color(0xFFF0E9E4)],
                ),
              ),
              child: Icon(_eventIcon(type), size: 25),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (ongoing)
                    Container(
                      margin: const EdgeInsets.only(bottom: 5),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: WpccColors.ink,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'ONGOING',
                        style: TextStyle(
                          fontSize: 8,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    WpccTime.compact(event['event_start_at']),
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: WpccColors.muted),
                  ),
                  if ((event['location']?.toString() ?? '').isNotEmpty)
                    Text(
                      event['location'].toString(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        color: WpccColors.muted,
                      ),
                    ),
                ],
              ),
            ),
            Icon(PhosphorIcons.caretRight(), size: 16, color: WpccColors.muted),
          ],
        ),
      ),
    );
  }

  static IconData _eventIcon(String type) => switch (type) {
    'service' => PhosphorIcons.church(),
    'meeting' => PhosphorIcons.usersThree(),
    'rehearsal' => PhosphorIcons.microphoneStage(),
    'training' => PhosphorIcons.chalkboardTeacher(),
    'special' => PhosphorIcons.sparkle(),
    _ => PhosphorIcons.calendarDots(),
  };
}
