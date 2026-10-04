import 'package:flutter/material.dart';
import '../../core/theme/app_motion.dart';
import '../../core/widgets/member_skeleton.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/widgets/adaptive_layout.dart';
import '../../core/utils/wpcc_time.dart';
import '../../core/widgets/member_components.dart';
import '../../core/widgets/member_sheet.dart';
import '../data/providers.dart';
import '../media/media_repository.dart';
import '../media/media_player_controller.dart';
import '../search/search_filter_sheet.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key, this.loadLatest});
  final Future<List<Map<String, dynamic>>> Function()? loadLatest;
  static final actions = <(String, String, IconData)>[
    ('Departments', '/departments', PhosphorIcons.users()),
    ('Prayer', '/prayer-alerts', PhosphorIcons.bell()),
    ('Devotional', '/devotional', PhosphorIcons.bookOpen()),
    ('Souls', '/souls', PhosphorIcons.heart()),
    ('Give', '/give', PhosphorIcons.gift()),
    ('Classes', '/profile/classes', PhosphorIcons.graduationCap()),
    ('Counselling', '/counselling', PhosphorIcons.chatCircle()),
  ];

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  String filter = 'Upcoming';
  String _searchFilter = 'All';
  late Future<List<Map<String, dynamic>>> latest;
  @override
  void initState() {
    super.initState();
    latest = _latest();
  }

  Future<List<Map<String, dynamic>>> _latest() async =>
      widget.loadLatest != null
          ? widget.loadLatest!()
          : MediaRepository().episodes(limit: 1);

  Future<void> _refresh() async {
    ref.invalidate(currentProfileProvider);
    ref.invalidate(upcomingEventsProvider);
    ref.invalidate(announcementsProvider);
    setState(() => latest = _latest());
    try {
      await Future.wait([
        ref.read(currentProfileProvider.future),
        ref.read(upcomingEventsProvider.future),
        ref.read(announcementsProvider.future),
        latest,
      ]);
    } catch (_) {}
  }

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

  void _appearance() => showMemberAppearanceSheet(context);

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentProfileProvider);
    final events = ref.watch(upcomingEventsProvider);
    final announcements = ref.watch(announcementsProvider);
    final member =
        profile.asData?.value?['full_name']?.toString() ?? 'WPCC Member';
    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: memberPagePadding(context, top: 20, bottom: 124),
          children: [
            Row(children: [
              Image.asset('assets/images/wpcc_logo.png',
                  width: 34,
                  height: 34,
                  fit: BoxFit.contain,
                  semanticLabel: 'WPCC church logo'),
              const SizedBox(width: 8),
              const Expanded(
                  child: Text('WPCC',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600))),
              IconButton(
                  tooltip: 'Change appearance',
                  onPressed: _appearance,
                  style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
                  icon: Icon(PhosphorIcons.sun(), size: 20)),
              Semantics(
                  value: member,
                  child: MemberIconButton(
                      label: 'Profile',
                      icon: PhosphorIcons.user(),
                      onPressed: () => context.go('/profile'))),
            ]),
            const SizedBox(height: 12),
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
                        onFilter: _searchFilters))),
            const SizedBox(height: 12),
            SizedBox(
                height: 48,
                child: ListView(scrollDirection: Axis.horizontal, children: [
                  for (final group in [
                    ('Upcoming', PhosphorIcons.flame()),
                    ('Church', PhosphorIcons.mapPin()),
                    ('Departments', PhosphorIcons.users()),
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
            const SizedBox(height: 14),
            MemberSectionHeader(
                title: 'Church events',
                action: TextButton(
                    onPressed: () => context.go('/events'),
                    style: TextButton.styleFrom(
                        textStyle: GoogleFonts.dmSans(
                            textStyle: Theme.of(context).textTheme.labelLarge,
                            fontWeight: FontWeight.w300)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Text('See all'),
                      const SizedBox(width: 4),
                      Icon(PhosphorIcons.caretRight(), size: 16),
                    ]))),
            events.when(
              data: (items) {
                final visible = items
                    .where((event) =>
                        filter == 'Upcoming' ||
                        (filter == 'Departments'
                            ? event['department_id'] != null
                            : event['department_id'] == null))
                    .toList();
                return visible.isEmpty
                    ? MemberStatus(
                        icon: PhosphorIcons.calendarBlank(),
                        message: 'No upcoming events')
                    : _EventRail(events: visible);
              },
              loading: () => const _LoadingBlock(height: 253),
              error: (_, __) => MemberStatus(
                  icon: PhosphorIcons.warningCircle(),
                  message: 'Events unavailable',
                  onRetry: () => ref.invalidate(upcomingEventsProvider)),
            ),
            const SizedBox(height: 25),
            LayoutBuilder(
                builder: (context, constraints) => AdaptiveSections(
                        gap: constraints.maxWidth >= 900 ? 36 : 25,
                        children: [
                          Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const MemberSectionHeader(title: 'Quick links'),
                                const HomeQuickLinks(),
                              ]),
                          Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const MemberSectionHeader(title: 'Daily Tasks'),
                                announcements.when(
                                  data: (rows) => rows.isEmpty
                                      ? MemberStatus(
                                          icon: PhosphorIcons.megaphone(),
                                          message: 'No announcements yet')
                                      : _AnnouncementRail(rows: rows),
                                  loading: () =>
                                      const _LoadingBlock(height: 154),
                                  error: (_, __) => MemberStatus(
                                      icon: PhosphorIcons.warningCircle(),
                                      message: 'Announcements unavailable',
                                      onRetry: () => ref
                                          .invalidate(announcementsProvider)),
                                ),
                              ]),
                        ])),
            const SizedBox(height: 14),
            MemberSectionHeader(
                title: 'Latest message',
                action: TextButton(
                    onPressed: () => context.go('/media'),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Text('Messages'),
                      const SizedBox(width: 4),
                      Icon(PhosphorIcons.caretRight(), size: 16),
                    ]))),
            FutureBuilder<List<Map<String, dynamic>>>(
                future: latest,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const _LoadingBlock(height: 76);
                  }
                  if (snapshot.hasError) {
                    return MemberStatus(
                        message: 'Message unavailable',
                        onRetry: () => setState(() => latest = _latest()));
                  }
                  final rows = snapshot.data ?? [];
                  if (rows.isEmpty) {
                    return const MemberStatus(message: 'No messages yet');
                  }
                  final episode = rows.first;
                  return MemberListRow(
                      title: episode['title']?.toString() ?? 'Message',
                      subtitle: episode['source_published_at'] == null
                          ? null
                          : WpccTime.compact(episode['source_published_at']),
                      leading: MemberArtwork(
                          imageUrl: episode['artwork_url']?.toString(),
                          icon: PhosphorIcons.microphone(),
                          size: 64,
                          height: 66),
                      trailing: MemberIconButton(
                          icon: PhosphorIcons.play(),
                          label: 'Play latest message',
                          onPressed: () =>
                              MediaPlayerController.instance.play(episode)),
                      onTap: () => context.push('/media/${episode['id']}',
                          extra: episode));
                }),
          ],
        ),
      ),
    );
  }
}

class HomeQuickLinks extends StatelessWidget {
  const HomeQuickLinks({super.key});
  @override
  Widget build(BuildContext context) {
    final tablet = MediaQuery.sizeOf(context).width >= 600;
    final scale = MediaQuery.textScalerOf(context).scale(12) / 12;
    return SizedBox(
      height: (tablet ? 78 : 70) + 8 + 34 * scale,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: HomePage.actions.length,
        separatorBuilder: (_, __) => SizedBox(width: tablet ? 22 : 12),
        itemBuilder: (_, index) => SizedBox(
            width: (tablet ? 78 : 70) + (scale - 1) * 35,
            child: _Shortcut(action: HomePage.actions[index], tablet: tablet)),
      ),
    );
  }
}

class _Shortcut extends StatelessWidget {
  const _Shortcut({required this.action, required this.tablet});
  final (String, String, IconData) action;
  final bool tablet;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final soon = action.$2 == '/profile/classes' || action.$2 == '/counselling';
    final label = action.$1;
    return Semantics(
      button: true,
      enabled: !soon,
      onTap: soon ? null : () => context.push(action.$2),
      label: soon ? '${action.$1}, coming soon' : action.$1,
      excludeSemantics: true,
      child: Tooltip(
        message: soon ? '${action.$1}: coming soon' : action.$1,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: soon ? null : () => context.push(action.$2),
            child: Column(children: [
              Opacity(
                  opacity: soon ? .45 : 1,
                  child: SizedBox(
                    width: tablet ? 78 : 70,
                    height: tablet ? 78 : 70,
                    child: ClipOval(
                        child: CustomPaint(
                            key: ValueKey('quick-link-pattern:${action.$2}'),
                            painter: _QuickLinkPatternPainter(action.$2),
                            child: Icon(action.$3,
                                size: 30, color: Colors.white))),
                  )),
              const SizedBox(height: 8),
              LayoutBuilder(builder: (context, constraints) {
                final captionWidth = constraints.maxWidth + 12;
                final scale = MediaQuery.textScalerOf(context).scale(12) / 12;
                return SizedBox(
                    height: 34 * scale,
                    child: OverflowBox(
                        maxWidth: captionWidth,
                        alignment: Alignment.topCenter,
                        child: SizedBox(
                            width: captionWidth,
                            child: Text(label,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: tablet ? 13 : 12,
                                    height: 17 / (tablet ? 13 : 12),
                                    color: soon
                                        ? colors.onSurfaceVariant
                                        : colors.onSurface)))));
              }),
            ]),
          ),
        ),
      ),
    );
  }
}

class _QuickLinkPatternPainter extends CustomPainter {
  const _QuickLinkPatternPainter(this.route);
  final String route;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);
    const bounds = Rect.fromLTWH(0, 0, 100, 100);
    final shades = switch (route) {
      '/departments' => [const Color(0xFFEC4D0C), const Color(0xFFD94308)],
      '/prayer-alerts' => [const Color(0xFF8D61D8), const Color(0xFF7547CB)],
      '/devotional' => [const Color(0xFF30B3F4), const Color(0xFF1595ED)],
      '/souls' => [const Color(0xFF078B46), const Color(0xFF007B3B)],
      '/give' => [const Color(0xFFED76A5), const Color(0xFFCB4480)],
      _ => [const Color(0xFF646066), const Color(0xFF646066)],
    };
    canvas.drawRect(
        bounds,
        Paint()
          ..shader = LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: shades)
              .createShader(bounds));
    final paint = Paint();
    switch (route) {
      case '/departments':
        canvas.drawCircle(
            const Offset(50, 5), 12, paint..color = const Color(0xFFF06B16));
        final wave = Path()
          ..moveTo(-5, 60)
          ..cubicTo(9, 42, 24, 52, 32, 37)
          ..cubicTo(40, 18, 63, 20, 69, 37)
          ..cubicTo(75, 52, 93, 43, 105, 60)
          ..lineTo(105, 105)
          ..lineTo(-5, 105)
          ..close();
        canvas.drawPath(
            wave,
            paint
              ..shader = const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFF39A1C), Color(0xFFEE7610)])
                  .createShader(bounds));
        canvas.drawCircle(
            const Offset(50, 91), 33, Paint()..color = const Color(0xFFE4510A));
      case '/prayer-alerts':
        final ribbon = Path()
          ..moveTo(104, 17)
          ..lineTo(48, 17)
          ..cubicTo(27, 17, 20, 35, 38, 48)
          ..cubicTo(44, 52, 53, 55, 61, 56)
          ..cubicTo(37, 57, 24, 77, 34, 104)
          ..lineTo(104, 104)
          ..close();
        canvas.drawPath(
            ribbon,
            paint
              ..shader = const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF622DEC), Color(0xFF7134EF)])
                  .createShader(bounds));
      case '/devotional':
        paint.color = const Color(0xFF168DE9);
        canvas.drawRRect(
            RRect.fromRectAndRadius(const Rect.fromLTWH(35, -12, 49, 69),
                const Radius.circular(24)),
            paint);
        canvas.drawCircle(const Offset(-1, 59), 24, paint);
        canvas.drawCircle(const Offset(104, 58), 20, paint);
        canvas.drawCircle(
            const Offset(50, 99), 35, paint..color = const Color(0xFF087AE6));
        canvas.drawLine(
            const Offset(29, 0),
            const Offset(29, 36),
            Paint()
              ..color = const Color(0xFF8ADBFF)
              ..strokeWidth = 1.5);
      case '/souls':
        paint.shader = const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF0CC779), Color(0xFF00AE61)])
            .createShader(bounds);
        canvas.drawCircle(const Offset(18, 81), 37, paint);
        canvas.drawCircle(const Offset(84, 82), 38, paint);
        canvas.drawCircle(
            const Offset(50, 5), 8, Paint()..color = const Color(0xFF0CB965));
      case '/give':
        final steps = Path()
          ..moveTo(0, 50)
          ..lineTo(29, 50)
          ..lineTo(29, 87)
          ..lineTo(60, 87)
          ..lineTo(60, 105)
          ..lineTo(0, 105)
          ..close();
        canvas.drawPath(
            steps,
            paint
              ..shader = const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFB93C76), Color(0xFFD75C94)])
                  .createShader(bounds));
    }
    canvas.drawCircle(
        const Offset(50, 50),
        49.5,
        Paint()
          ..color = const Color(0x28FFFFFF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_QuickLinkPatternPainter oldDelegate) =>
      route != oldDelegate.route;
}

class _EventRail extends StatelessWidget {
  const _EventRail({required this.events});
  final List<Map<String, dynamic>> events;
  @override
  Widget build(BuildContext context) {
    final tablet = MediaQuery.sizeOf(context).width >= 600;
    final extra = (MediaQuery.textScalerOf(context).scale(17) - 17) * 3.6;
    return SizedBox(
      height: (tablet ? 294 : 253) + extra,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: events.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final event = events[index];
          final id = event['event_id']?.toString() ?? '';
          final start =
              DateTime.tryParse(event['event_start_at']?.toString() ?? '');
          return MemberPosterCard(
            width: tablet ? 235 : 202,
            height: tablet ? 294 : 253,
            title: event['title']?.toString() ?? 'Upcoming event',
            metadata:
                start == null ? '' : WpccTime.compact(start.toIso8601String()),
            imageUrl: event['featured_image']?.toString(),
            heroTag: 'event-image:$id',
            onTap: id.isEmpty
                ? null
                : () => context.push('/events/$id', extra: event),
          );
        },
      ),
    );
  }
}

class _AnnouncementRail extends StatelessWidget {
  const _AnnouncementRail({required this.rows});
  final List<Map<String, dynamic>> rows;
  @override
  Widget build(BuildContext context) {
    final tablet = MediaQuery.sizeOf(context).width >= 600;
    final extra = (MediaQuery.textScalerOf(context).scale(14) - 14) * 4;
    return SizedBox(
      height: (tablet ? 184 : 154) + extra,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: rows.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final row = rows[index];
          final image =
              (row['featured_image'] ?? row['image_url'])?.toString() ?? '';
          final title = row['title']?.toString() ?? 'Announcement';
          final source = (row['department_name'] ??
                      row['source_name'] ??
                      row['scope_label'])
                  ?.toString() ??
              '';
          return SizedBox(
            width: tablet ? 180 : 150,
            child: Material(
              color: Theme.of(context).colorScheme.surface,
              clipBehavior: Clip.antiAlias,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                onTap: () => showModalBottomSheet<void>(
                    sheetAnimationStyle: AppMotion.sheetStyle(context),
                    context: context,
                    showDragHandle: true,
                    isScrollControlled: true,
                    builder: (context) => SafeArea(
                        child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                            child: SingleChildScrollView(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                  Text(title,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge),
                                  if (source.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(source)
                                  ],
                                  const SizedBox(height: 16),
                                  Text((row['content'] ?? row['body'] ?? '')
                                      .toString()),
                                ]))))),
                child: Stack(fit: StackFit.expand, children: [
                  if (image.isNotEmpty)
                    Image.network(image,
                        fit: BoxFit.cover,
                        excludeFromSemantics: true,
                        errorBuilder: (_, __, ___) => const SizedBox()),
                  if (image.isNotEmpty)
                    const DecoratedBox(
                        decoration: BoxDecoration(
                            gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                          Color(0xCC000000),
                          Color(0x99000000),
                          Colors.transparent
                        ]))),
                  Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 14,
                                    height: 19 / 14,
                                    fontWeight: FontWeight.w500,
                                    color:
                                        image.isEmpty ? null : Colors.white)),
                            if (source.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(source,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: image.isEmpty
                                          ? Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant
                                          : const Color(0xFFE5DFE2))),
                            ],
                          ])),
                ]),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LoadingBlock extends StatelessWidget {
  const _LoadingBlock({required this.height});
  final double height;
  @override
  Widget build(BuildContext context) => SizedBox(
      height: height,
      child: ClipRect(
          child: MemberSkeleton(
              rows: height < 100
                  ? 1
                  : height < 200
                      ? 2
                      : 3)));
}
