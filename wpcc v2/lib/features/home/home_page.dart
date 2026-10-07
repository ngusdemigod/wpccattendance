import '../../core/widgets/member_photo_backdrop.dart';
import '../../core/widgets/resource_card_pattern.dart';
import '../../core/widgets/member_glass.dart';
import '../../core/theme/member_material.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../../core/theme/app_motion.dart';
import '../../core/widgets/member_skeleton.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/widgets/adaptive_layout.dart';
import '../../core/utils/wpcc_time.dart';
import '../../core/widgets/member_components.dart';
import '../announcements/announcement_palette.dart';
import '../data/providers.dart';
import '../media/media_repository.dart';
import '../media/media_player_controller.dart';
import '../search/search_filter_sheet.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key, this.loadLatest});
  final Future<List<Map<String, dynamic>>> Function()? loadLatest;
  static final actions = <(String, String, IconData)>[
    ('Prayer', '/prayer-alerts', PhosphorIcons.bell()),
    ('Devotional', '/devotional', PhosphorIcons.bookOpen()),
    ('Souls', '/souls', PhosphorIcons.heart()),
    ('Service tools', '/resources/department-tools', PhosphorIcons.listChecks()),
    ('Classes', '/profile/classes', PhosphorIcons.graduationCap()),
  ];

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  String filter = 'Upcoming';
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

  void _openSearch(String section) {
    MemberSearchScope.maybeOf(context)?.value = section;
    context.push(
        Uri(path: '/search', queryParameters: {'filter': section}).toString());
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentProfileProvider);
    final events = ref.watch(upcomingEventsProvider);
    final announcements = ref.watch(announcementsProvider);
    final member =
        profile.asData?.value?['full_name']?.toString() ?? 'WPCC Member';
    final visibleEvents = (events.asData?.value ?? <Map<String, dynamic>>[])
        .where((event) =>
            filter == 'Upcoming' ||
            (filter == 'Departments'
                ? event['department_id'] != null
                : event['department_id'] == null))
        .toList();
    final backdropImage = visibleEvents.isEmpty
        ? ''
        : visibleEvents.first['featured_image']?.toString() ?? '';
    return Stack(fit: StackFit.expand, children: [
      MemberPhotoBackdrop(imageUrl: backdropImage, route: '/home'),
      SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: memberPagePadding(context, top: 20, bottom: 124),
            children: [
              Row(children: [
                ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset('assets/images/wpcc_logo.png',
                        width: 34,
                        height: 34,
                        fit: BoxFit.contain,
                        semanticLabel: 'WPCC church logo')),
                const SizedBox(width: 8),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text('Wisdom Power Christian Centre',
                          style: Theme.of(context).textTheme.titleSmall),
                      if (profile.asData?.value?['branch_name']
                              ?.toString()
                              .trim()
                              .isNotEmpty ??
                          false) ...[
                        const SizedBox(height: 2),
                        Text(profile.asData!.value!['branch_name'].toString(),
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ])),
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
                          hint: 'Search', onTap: () => _openSearch('All')))),
              const SizedBox(height: 12),
              announcements.when(
                data: (rows) => rows.isEmpty
                    ? const SizedBox.shrink()
                    : _AnnouncementStack(rows: rows),
                loading: () => const _LoadingBlock(height: 240),
                error: (_, __) => MemberStatus(
                    message: 'Announcements unavailable',
                    onRetry: () => ref.invalidate(announcementsProvider)),
              ),
              const SizedBox(height: 24),
              const MemberSectionHeader(title: 'Quick links'),
              const HomeQuickLinks(),
              const SizedBox(height: 25),
              MemberSectionHeader(
                  title: 'Church events',
                  action: TextButton(
                      style: TextButton.styleFrom(
                          textStyle:
                              const TextStyle(fontFamily: 'DM Sans', fontWeight: FontWeight.w300)),
                      onPressed: () => context.go('/events'),
                      child: const Text('See all'))),
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
                                  MemberSectionHeader(
                                      title: 'Resources',
                                      action: TextButton(
                                          onPressed: () => _showResources(
                                              context,
                                              announcements.valueOrNull ?? []),
                                          child: const Text('View all'))),
                                  _ResourceCards(
                                      rows: announcements.valueOrNull ?? []),
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
      )
    ]);
  }
}

class HomeQuickLinks extends StatelessWidget {
  const HomeQuickLinks({super.key});
  @override
  Widget build(BuildContext context) {
    final tablet = MediaQuery.sizeOf(context).width >= 600;
    final scale = MediaQuery.textScalerOf(context).scale(12) / 12;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          mainAxisExtent: (tablet ? 64 : 54) + 8 + 34 * scale,
          crossAxisSpacing: 8,
          mainAxisSpacing: 16),
      itemCount: HomePage.actions.length,
      itemBuilder: (_, index) =>
          _Shortcut(action: HomePage.actions[index], tablet: tablet),
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
    final soon = action.$2 == '/profile/classes';
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
                  // Keep the circle round: never wider than its grid cell.
                  child: LayoutBuilder(builder: (context, constraints) {
                    final diameter =
                        (tablet ? 64.0 : 54.0).clamp(0.0, constraints.maxWidth);
                    return SizedBox(
                      width: diameter,
                      height: diameter,
                      child: ClipOval(
                          child: MemberGlass(
                              radius: 100,
                              child: CustomPaint(
                                  key: ValueKey(
                                      'quick-link-pattern:${action.$2}'),
                                  painter: _QuickLinkPatternPainter(action.$2,
                                      opacity: 0),
                                  child: Icon(action.$3,
                                      size: 22, color: colors.onSurface)))),
                    );
                  })),
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
  const _QuickLinkPatternPainter(this.route, {required this.opacity});
  final String route;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity == 0) return;
    canvas.saveLayer(Offset.zero & size,
        Paint()..color = Colors.white.withValues(alpha: opacity));
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
    canvas.restore();
  }

  @override
  bool shouldRepaint(_QuickLinkPatternPainter oldDelegate) =>
      route != oldDelegate.route || opacity != oldDelegate.opacity;
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

void _showAnnouncement(BuildContext context, Map<String, dynamic> row) {
  final style = AnnouncementPalette.byKey(row['background_style']);
  final title = row['title']?.toString() ?? 'Announcement';
  final content = (row['content'] ?? row['body'] ?? '').toString();
  showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      sheetAnimationStyle: AppMotion.sheetStyle(context),
      builder: (context) => SafeArea(
          child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: style == null
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                          Text(title,
                              style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 16),
                          Text(content),
                        ])
                  : DecoratedBox(
                      decoration: BoxDecoration(
                          gradient: style.gradient,
                          borderRadius: BorderRadius.circular(20)),
                      child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(title,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                            color: style.foreground,
                                            fontWeight: FontWeight.w700)),
                                const SizedBox(height: 16),
                                Text(content,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        color: style.foreground,
                                        fontSize:
                                            AnnouncementPalette.statusFontSize(
                                                content),
                                        height: 1.3,
                                        fontWeight: FontWeight.w700)),
                              ]))))));
}

class _AnnouncementStack extends StatelessWidget {
  const _AnnouncementStack({required this.rows});
  final List<Map<String, dynamic>> rows;
  @override
  Widget build(BuildContext context) => Center(
      child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: LayoutBuilder(builder: (context, bounds) {
            final height = (bounds.maxWidth * 9 / 16).clamp(190.0, 400.0) +
                (MediaQuery.textScalerOf(context).scale(22) - 22) * 4;
            return SizedBox(
                height: height + 16,
                child: Stack(children: [
                  for (final inset in [12.0, 6.0])
                    Positioned(
                        left: inset,
                        right: inset,
                        top: inset,
                        bottom: 0,
                        child: ExcludeSemantics(
                            child: MemberGlass(
                                outlined: false,
                                radius: 20,
                                child: const SizedBox.expand()))),
                  Positioned.fill(
                      bottom: 16,
                      child: ScrollConfiguration(
                          behavior: ScrollConfiguration.of(context)
                              .copyWith(dragDevices: {
                            PointerDeviceKind.touch,
                            PointerDeviceKind.mouse,
                            PointerDeviceKind.stylus,
                            PointerDeviceKind.trackpad
                          }),
                          child: PageView.builder(
                              key: const PageStorageKey('announcement-stack'),
                              itemCount: rows.length,
                              itemBuilder: (context, index) {
                                final row = rows[index];
                                final style = AnnouncementPalette.byKey(
                                    row['background_style']);
                                final card = Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                        onTap: () =>
                                            _showAnnouncement(context, row),
                                        child: Padding(
                                            padding: const EdgeInsets.all(24),
                                            child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                      row['department_name']
                                                              ?.toString() ??
                                                          'Announcement',
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodySmall
                                                          ?.copyWith(
                                                              color: style
                                                                  ?.mutedForeground)),
                                                  const SizedBox(height: 12),
                                                  Flexible(
                                                      child: Text(
                                                          row['title']
                                                                  ?.toString() ??
                                                              'Announcement',
                                                          textAlign:
                                                              TextAlign.center,
                                                          maxLines: 3,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style: TextStyle(
                                                              color: style
                                                                  ?.foreground,
                                                              fontSize: 22,
                                                              fontWeight: style ==
                                                                      null
                                                                  ? FontWeight
                                                                      .w500
                                                                  : FontWeight
                                                                      .w700))),
                                                  const SizedBox(height: 12),
                                                  Text('Read announcement',
                                                      style: TextStyle(
                                                          color: style
                                                              ?.mutedForeground,
                                                          fontSize: 12)),
                                                ]))));
                                return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 1),
                                    child: style == null
                                        ? MemberGlass(
                                            outlined: false,
                                            frosted: true,
                                            radius: 20,
                                            child: card)
                                        : DecoratedBox(
                                            decoration: BoxDecoration(
                                                gradient: style.gradient,
                                                borderRadius:
                                                    BorderRadius.circular(20)),
                                            child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                child: card)));
                              }))),
                ]));
          })));
}

void _showResources(BuildContext context, List<Map<String, dynamic>> rows) {
  showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      sheetAnimationStyle: AppMotion.sheetStyle(context),
      builder: (context) => SafeArea(
          child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const MemberSectionHeader(title: 'Resources'),
                _ResourceCards(rows: rows, grid: true),
              ]))));
}

class _ResourceCards extends StatelessWidget {
  const _ResourceCards({required this.rows, this.grid = false});
  final List<Map<String, dynamic>> rows;
  final bool grid;
  @override
  Widget build(BuildContext context) {
    final tools = [
      (
        'Anonymous reports',
        'Report a concern privately',
        '/resources/anonymous-reports'
      ),
      (
        'Department files',
        'Documents from your departments',
        '/resources/department-files'
      ),
      (
        'Service tools',
        'Your department workflows',
        '/resources/department-tools'
      ),
    ];
    Widget card(int index) {
      final tool = tools[index];
      return ResourceCardSurface(
          child: CustomPaint(
              painter: ResourceCardPattern(index: index,
                  dark: Theme.of(context).brightness == Brightness.dark,
                  enabled: !MemberMaterials.solid(context)),
              child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                      onTap: () => context.push(tool.$3),
                      child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(tool.$1,
                                    style: const TextStyle(
                                        fontFamily: 'DM Sans',
                                        fontSize: 14,
                                        height: 1.35,
                                        fontWeight: FontWeight.w600)),
                                const SizedBox(height: 10),
                                Text(tool.$2,
                                    style:
                                        Theme.of(context).textTheme.bodySmall?.copyWith(fontFamily: 'DM Sans', fontSize: 12, height: 1.5)),
                                const SizedBox(height: 10),
                                const Spacer(),
                                Align(
                                    alignment: Alignment.centerRight,
                                    child: Icon(PhosphorIcons.caretRight(),
                                        size: 24)),
                              ]))))));
    }

    double heightFor(double width) {
      var result = 154.0;
      for (final tool in tools) {
        double measure(String value, TextStyle style) {
          final painter = TextPainter(text: TextSpan(text: value, style: style),
              textDirection: Directionality.of(context),
              textScaler: MediaQuery.textScalerOf(context))..layout(maxWidth: width - 42);
          final height = painter.height;
          painter.dispose();
          return height;
        }
        final height = 86 + measure(tool.$1, const TextStyle(fontFamily: 'DM Sans',
            fontSize: 14, height: 1.35, fontWeight: FontWeight.w600)) +
            measure(tool.$2, const TextStyle(fontFamily: 'DM Sans', fontSize: 12, height: 1.5));
        if (height > result) result = height;
      }
      return result;
    }
    if (grid)
      return LayoutBuilder(builder: (context, bounds) {
        final columns = MediaQuery.textScalerOf(context).scale(16) > 22
            ? 1
            : bounds.maxWidth >= 650
                ? 3
                : 2;
        return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                mainAxisExtent: heightFor((bounds.maxWidth - (columns - 1) * 12) / columns),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12),
            itemCount: tools.length,
            itemBuilder: (_, index) => card(index));
      });
    return SizedBox(
        height: heightFor(184),
        child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: tools.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, index) =>
                SizedBox(width: 184, child: card(index))));
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
