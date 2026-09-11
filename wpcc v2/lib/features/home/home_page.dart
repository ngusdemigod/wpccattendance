import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/wpcc_time.dart';
import '../../core/widgets/section_empty_state.dart';
import '../../core/widgets/wpcc_logo.dart';
import '../data/providers.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider);
    final events = ref.watch(upcomingEventsProvider);
    final announcements = ref.watch(announcementsProvider);
    final actions = <(String, IconData, String)>[
      ('Prayer alerts', PhosphorIcons.bellRinging(), '/prayer-alerts'),
      ('Wisdom Devotional', PhosphorIcons.bookOpenText(), '/devotional'),
      ('Events', PhosphorIcons.calendarDots(), '/events'),
      ('Department', PhosphorIcons.usersThree(), '/departments'),
      ('Souls', PhosphorIcons.heart(), '/souls'),
      ('Classes', PhosphorIcons.graduationCap(), '/profile/classes'),
      ('Counselling', PhosphorIcons.chatsCircle(), '/counselling'),
      ('Query', PhosphorIcons.question(), '/profile/query'),
    ];

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(currentProfileProvider);
          ref.invalidate(upcomingEventsProvider);
          ref.invalidate(announcementsProvider);
          await Future.wait([ref.read(currentProfileProvider.future), ref.read(upcomingEventsProvider.future)]);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 110),
          children: [
            Row(children: [
              const WpccLogo(size: 42),
              const SizedBox(width: 10),
              Expanded(child: profile.when(
                data: (p) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('His Glory Expression', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: WpccColors.muted)),
                  Text(p?['display_name']?.toString().trim().isNotEmpty == true ? p!['display_name'].toString() : p?['full_name']?.toString() ?? 'WPCC Member', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                ]),
                loading: () => const SizedBox(height: 32),
                error: (_, __) => const Text('WPCC Community'),
              )),
              IconButton(onPressed: () => context.push('/search'), icon: Icon(PhosphorIcons.magnifyingGlass(), size: 22)),
            ]),
            const SizedBox(height: 26),
            _SectionTitle(title: 'Upcoming Events'),
            const SizedBox(height: 10),
            events.when(
              data: (items) => items.isEmpty ? SectionEmptyState(icon: PhosphorIcons.calendarBlank(), message: 'No upcoming events', height: 168) : _EventHero(event: items.first),
              loading: () => const SectionEmptyState(icon: Icons.circle_outlined, message: 'Loading upcoming event', height: 168),
              error: (_, __) => SectionEmptyState(icon: PhosphorIcons.warningCircle(), message: 'Unable to load upcoming events', height: 168),
            ),
            const SizedBox(height: 28),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const _SectionTitle(title: 'Quick Actions'),
              Text('8 Actions', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: WpccColors.muted)),
            ]),
            const SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: actions.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: .92),
              itemBuilder: (context, i) {
                final a = actions[i];
                return InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => context.push(a.$3),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFF0F1F5))),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(a.$2, size: 21, color: WpccColors.ink),
                      const SizedBox(height: 8),
                      Text(a.$1, maxLines: 1, overflow: TextOverflow.fade, softWrap: false, textAlign: TextAlign.center, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: a.$1 == 'Wisdom Devotional' ? 9 : 10.5, fontWeight: FontWeight.w500)),
                    ]),
                  ),
                );
              },
            ),
            const SizedBox(height: 28),
            const _SectionTitle(title: 'Announcements'),
            const SizedBox(height: 10),
            announcements.when(
              data: (rows) => rows.isEmpty ? SectionEmptyState(icon: PhosphorIcons.megaphone(), message: 'No announcements') : Column(children: rows.take(4).map((row) => Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(row['title']?.toString() ?? 'Announcement', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontSize: 14, fontWeight: FontWeight.w500)),
                  if ((row['content'] ?? row['body']) != null) ...[const SizedBox(height: 5), Text((row['content'] ?? row['body']).toString(), maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: WpccColors.muted))],
                ]),
              )).toList()),
              loading: () => const SizedBox(height: 120),
              error: (_, __) => SectionEmptyState(icon: PhosphorIcons.warningCircle(), message: 'Unable to load announcements'),
            ),
          ],
        ),
      ),
    );
  }

}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title}); final String title;
  @override Widget build(BuildContext context) => Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontSize: 14, fontWeight: FontWeight.w500));
}

class _EventHero extends StatelessWidget {
  const _EventHero({required this.event}); final Map<String, dynamic> event;
  @override Widget build(BuildContext context) {
    final start = DateTime.tryParse(event['event_start_at']?.toString() ?? '');
    return InkWell(
      borderRadius: BorderRadius.circular(26),
      onTap: () => context.push('/events/${event['event_id']}', extra: event),
      child: Container(
        height: 168,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF252632), Color(0xFF55586A)]),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, children: [
          Text(event['title']?.toString() ?? 'Upcoming event', maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
          const SizedBox(height: 7),
          Text(start == null ? '' : WpccTime.compact(start.toIso8601String()), style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70)),
        ]),
      ),
    );
  }
}
