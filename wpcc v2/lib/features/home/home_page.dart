import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/wpcc_time.dart';
import '../../core/widgets/section_empty_state.dart';
import '../../core/widgets/wpcc_logo.dart';
import '../data/providers.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  static const actions = <(String, String, IconData)>[
    ('Prayer alerts', '/prayer-alerts', Icons.notifications_none_outlined),
    ('Wisdom Devotional', '/devotional', Icons.menu_book_outlined),
    ('Events', '/events', Icons.calendar_month_outlined),
    ('Department', '/departments', Icons.group_outlined),
    ('Souls', '/souls', Icons.favorite_border_rounded),
    ('Classes', '/profile/classes', Icons.school_outlined),
    ('Counselling', '/counselling', Icons.question_answer_outlined),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider);
    final events = ref.watch(upcomingEventsProvider);
    final announcements = ref.watch(announcementsProvider);
    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(currentProfileProvider);
          ref.invalidate(upcomingEventsProvider);
          ref.invalidate(announcementsProvider);
          await Future.wait([
            ref.read(currentProfileProvider.future),
            ref.read(upcomingEventsProvider.future),
            ref.read(announcementsProvider.future),
          ]);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 18, 14, 112),
          children: [
            Row(
              children: [
                const WpccLogo(size: 40),
                const SizedBox(width: 10),
                Expanded(
                  child: profile.when(
                    data: (p) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'WPCC, His Glory Expression',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(fontSize: 10, color: WpccColors.muted),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          p?['display_name']?.toString().trim().isNotEmpty ==
                                  true
                              ? p!['display_name'].toString()
                              : p?['full_name']?.toString() ?? 'WPCC Member',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ],
                    ),
                    loading: () => const SizedBox(height: 32),
                    error: (_, __) => const Text('WPCC Community'),
                  ),
                ),
                IconButton(
                  tooltip: 'Search',
                  onPressed: () => context.push('/search'),
                  icon: const Icon(Icons.search_rounded, size: 22),
                ),
              ],
            ),
            const SizedBox(height: 30),
            events.when(
              data: (items) => items.isEmpty
                  ? const SectionEmptyState(
                      icon: Icons.calendar_today_outlined,
                      message: 'No upcoming events',
                      height: 180,
                    )
                  : _EventHero(event: items.first),
              loading: () => const SectionEmptyState(
                icon: Icons.calendar_today_outlined,
                message: 'Loading upcoming event',
                height: 180,
              ),
              error: (_, __) => const SectionEmptyState(
                icon: Icons.error_outline,
                message: 'Unable to load upcoming events',
                height: 180,
              ),
            ),
            const SizedBox(height: 32),
            _SectionCard(
              header: const _SectionHeader(
                title: 'Quick Actions',
                trailing: '7 Actions',
              ),
              child: GridView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: actions.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 9,
                  crossAxisSpacing: 9,
                  mainAxisExtent: 94,
                ),
                itemBuilder: (context, index) {
                  final action = actions[index];
                  final comingSoon =
                      action.$1 == 'Classes' || action.$1 == 'Counselling';
                  return InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: comingSoon ? null : () => context.push(action.$2),
                    child: Ink(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: WpccColors.line),
                      ),
                      child: Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 10),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(action.$3,
                                    size: 22, color: WpccColors.ink),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  child: Text(
                                    action.$1,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          fontSize:
                                              action.$1 == 'Wisdom Devotional'
                                                  ? 9
                                                  : 11,
                                          height: 1.1,
                                          fontWeight: FontWeight.w400,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (comingSoon)
                            Positioned(
                              top: 5,
                              right: 5,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(
                                  color: WpccColors.primarySoft,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text('Coming soon',
                                    style: TextStyle(
                                        fontSize: 7,
                                        fontWeight: FontWeight.w600,
                                        color: WpccColors.primaryDeep)),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
            _SectionCard(
              header: const _SectionHeader(
                title: 'Announcements',
                trailing: 'View all',
              ),
              child: announcements.when(
                data: (rows) => rows.isEmpty
                    ? const SectionEmptyState(
                        icon: Icons.campaign_outlined,
                        message: 'No announcements',
                        height: 128,
                      )
                    : Column(
                        children: rows
                            .take(4)
                            .map((row) => _AnnouncementCard(row: row))
                            .toList(),
                      ),
                loading: () => const SizedBox(height: 128),
                error: (_, __) => const SectionEmptyState(
                  icon: Icons.error_outline,
                  message: 'Unable to load announcements',
                  height: 128,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.header, required this.child});
  final Widget header;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(10, 12, 10, 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .46),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: WpccColors.line),
        ),
        child: Column(children: [header, const SizedBox(height: 11), child]),
      );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.trailing});
  final String title;
  final String trailing;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
            ),
          ),
          Text(
            trailing,
            style: Theme.of(
              context,
            )
                .textTheme
                .labelSmall
                ?.copyWith(fontSize: 10, color: WpccColors.muted),
          ),
        ],
      );
}

class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard({required this.row});
  final Map<String, dynamic> row;

  @override
  Widget build(BuildContext context) {
    final created = DateTime.tryParse(row['created_at']?.toString() ?? '');
    final source =
        row['department_name'] ?? row['source_name'] ?? row['scope_label'];
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: WpccColors.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const WpccLogo(size: 34),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row['title']?.toString() ?? 'Announcement',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                if (source != null) ...[
                  const SizedBox(height: 2),
                  Text(source.toString(), style: _supportStyle(context)),
                ],
                if ((row['content'] ?? row['body']) != null) ...[
                  const SizedBox(height: 7),
                  Text(
                    (row['content'] ?? row['body']).toString(),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 12,
                          color: WpccColors.inkSoft,
                        ),
                  ),
                ],
                if (created != null) ...[
                  const SizedBox(height: 7),
                  Text(
                    WpccTime.compact(created.toIso8601String()),
                    style: _supportStyle(context),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  TextStyle? _supportStyle(BuildContext context) => Theme.of(
        context,
      ).textTheme.labelSmall?.copyWith(fontSize: 10, color: WpccColors.muted);
}

class _EventHero extends StatelessWidget {
  const _EventHero({required this.event});
  final Map<String, dynamic> event;

  @override
  Widget build(BuildContext context) {
    final start = DateTime.tryParse(event['event_start_at']?.toString() ?? '');
    return InkWell(
      borderRadius: BorderRadius.circular(26),
      onTap: () => context.push('/events/${event['event_id']}', extra: event),
      child: Ink(
        height: 180,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          color: const Color(0xFF30323F),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              event['title']?.toString() ?? 'Upcoming event',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 7),
            Text(
              start == null ? '' : WpccTime.compact(start.toIso8601String()),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
