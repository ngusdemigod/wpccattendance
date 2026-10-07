import 'package:flutter/material.dart';
import '../../core/widgets/member_photo_backdrop.dart';
import '../../core/theme/app_motion.dart';
import '../../core/widgets/member_skeleton.dart';
import '../../core/theme/member_theme.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/widgets/member_components.dart';
import '../../core/utils/wpcc_time.dart';
import '../../core/widgets/initials_avatar.dart';
import 'event_repository.dart';

class EventDetailPage extends StatefulWidget {
  const EventDetailPage({super.key, required this.eventId, this.seed});
  final String eventId;
  final Map<String, dynamic>? seed;
  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
  late final repo = EventRepository();
  late Future<Map<String, dynamic>?> eventFuture;
  late Future<Map<String, dynamic>?> metaFuture;
  late Future<Map<String, dynamic>?> myAttendanceFuture;
  late Future<List<Map<String, dynamic>>> attendanceFuture;
  int tab = 0;
  bool attendanceBusy = false;
  bool descriptionExpanded = false;
  final ScrollController scrollController = ScrollController();
  bool get isRecurring =>
      widget.seed?['recurring_event_id'] != null ||
      widget.seed?['source_table']?.toString() == 'recurring_events';
  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  void _reload() {
    eventFuture = widget.seed != null
        ? Future.value(widget.seed)
        : repo.event(widget.eventId);
    metaFuture = isRecurring
        ? Future<Map<String, dynamic>?>.value(null)
        : repo.meta(widget.eventId);
    myAttendanceFuture = isRecurring
        ? Future<Map<String, dynamic>?>.value(null)
        : repo.myAttendance(widget.eventId);
    attendanceFuture = isRecurring
        ? Future<List<Map<String, dynamic>>>.value(const [])
        : repo.attendance(widget.eventId);
  }

  Future<void> _attendanceAction(Map<String, dynamic> event) async {
    final startsAt = DateTime.tryParse(
      event['event_start_at']?.toString() ?? '',
    )?.toLocal();
    if (startsAt != null && DateTime.now().isBefore(startsAt)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This event has not started yet.')),
      );
      return;
    }
    setState(() => attendanceBusy = true);
    try {
      final result = await repo.checkInOrOut(widget.eventId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:
                Text(result['message']?.toString() ?? 'Attendance updated')));
        setState(_reload);
      }
    } catch (error) {
      if (mounted) {
        final raw = error.toString().replaceFirst('Bad state: ', '');
        final lower = raw.toLowerCase();
        final message = lower.contains('geofence') ||
                lower.contains('outside') ||
                lower.contains('not within') ||
                lower.contains('location')
            ? 'You are not in church.'
            : raw.isEmpty
                ? 'Unable to update attendance. Please try again.'
                : raw;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) setState(() => attendanceBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: FutureBuilder<Map<String, dynamic>?>(
            future: eventFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const SingleChildScrollView(
                    padding: EdgeInsets.all(24),
                    child: MemberSkeleton(hero: true));
              }
              if (snapshot.hasError) {
                return SafeArea(
                    child: Column(children: [
                  _backHeader(),
                  Expanded(
                      child: Center(
                          child: MemberStatus(
                              message: 'Unable to load event',
                              icon: PhosphorIcons.warningCircle(),
                              onRetry: () => setState(_reload)))),
                ]));
              }
              final event = snapshot.data;
              if (event == null) {
                return SafeArea(
                    child: Column(children: [
                  _backHeader(),
                  const Expanded(
                      child: Center(
                          child: MemberStatus(message: 'Event not available'))),
                ]));
              }
              final image = event['featured_image']?.toString().trim() ?? '';
              return MemberPhotoBackdrop(
                  imageUrl: image,
                  route: '/events',
                  child: SafeArea(
                    bottom: false,
                    child: Center(
                        child: ConstrainedBox(
                      constraints: BoxConstraints(
                          maxWidth: MediaQuery.sizeOf(context).width >= 900
                              ? 820
                              : 1180),
                      child: ListView(
                        controller: scrollController,
                        padding:
                            memberPagePadding(context, top: 20, bottom: 124),
                        children: [
                          Row(children: [
                            MemberIconButton(
                                label: 'Back',
                                icon: PhosphorIcons.caretLeft(),
                                onPressed: _back),
                            const SizedBox(width: 10),
                            Expanded(
                                child: Text('Event',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall)),
                            if (image.isNotEmpty)
                              MemberIconButton(
                                  label: 'View full flyer',
                                  icon: PhosphorIcons.arrowsOut(),
                                  plain: true,
                                  onPressed: () => _showFlyer(image)),
                          ]),
                          const SizedBox(height: 20),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 680),
                              child: Semantics(
                                button: image.isNotEmpty,
                                label: 'View full event flyer',
                                onTap: image.isEmpty
                                    ? null
                                    : () => _showFlyer(image),
                                excludeSemantics: true,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: LayoutBuilder(
                                    builder: (context, box) => SizedBox(
                                      width: box.maxWidth,
                                      height: (box.maxWidth * .75)
                                          .clamp(0.0, 430.0),
                                      child: InkWell(
                                        onTap: image.isEmpty
                                            ? null
                                            : () => _showFlyer(image),
                                        child: Hero(
                                            tag:
                                                'event-image:${widget.eventId}',
                                            child: image.isEmpty
                                                ? _heroFallback()
                                                : Image.network(image,
                                                    fit: BoxFit.contain,
                                                    excludeFromSemantics: true,
                                                    errorBuilder:
                                                        (_, __, ___) =>
                                                            _heroFallback())),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),
                          Text(
                              isRecurring
                                  ? 'Recurring'
                                  : event['department_id'] != null
                                      ? 'Department'
                                      : 'Church',
                              style: Theme.of(context).textTheme.bodySmall),
                          const SizedBox(height: 9),
                          AnimatedSwitcher(
                              duration: MediaQuery.disableAnimationsOf(context)
                                  ? Duration.zero
                                  : const Duration(milliseconds: 180),
                              child: tab == 0
                                  ? _overview(event)
                                  : _attendance(event,
                                      key: const ValueKey('attendance'))),
                          if (!isRecurring) ...[
                            const SizedBox(height: 20),
                            TextButton.icon(
                                onPressed: () =>
                                    setState(() => tab = tab == 0 ? 1 : 0),
                                icon: Icon(
                                    tab == 0
                                        ? PhosphorIcons.users()
                                        : PhosphorIcons.arrowLeft(),
                                    size: 20),
                                label: Text(tab == 0
                                    ? 'View attendance'
                                    : 'Event overview')),
                          ],
                        ],
                      ),
                    )),
                  ));
            }),
      );

  Widget _backHeader() => Align(
      alignment: Alignment.centerLeft,
      child: MemberIconButton(
          icon: PhosphorIcons.caretLeft(), label: 'Back', onPressed: _back));

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/events');
    }
  }

  Widget _heroFallback() => ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Center(
          child: Icon(PhosphorIcons.calendarDots(),
              size: 56,
              color: Theme.of(context).colorScheme.onSurfaceVariant)));

  Future<void> _showFlyer(String image) => showMotionDialog<void>(
      animationStyle: AppMotion.dialogStyle(context),
      context: context,
      builder: (context) => Dialog.fullscreen(
            child: Scaffold(
              appBar: AppBar(
                title: const Text('Event flyer'),
                leading: IconButton(
                    tooltip: 'Close flyer',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(PhosphorIcons.x())),
              ),
              body: SafeArea(
                  child: LayoutBuilder(
                      builder: (context, box) => InteractiveViewer(
                            minScale: 1,
                            maxScale: 5,
                            child: SizedBox(
                                width: box.maxWidth,
                                height: box.maxHeight,
                                child: Image.network(image,
                                    fit: BoxFit.contain,
                                    semanticLabel: 'Full event flyer',
                                    errorBuilder: (_, __, ___) => MemberStatus(
                                        message: 'Flyer unavailable',
                                        icon: PhosphorIcons.imageBroken()))),
                          ))),
            ),
          ));

  Widget _overview(Map<String, dynamic> event) => Column(
          key: const ValueKey('overview'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(event['title']?.toString() ?? 'Event',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontSize: 26,
                    height: 1.2,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0)),
            const SizedBox(height: 24),
            Divider(
                height: 1, color: Theme.of(context).colorScheme.outlineVariant),
            const SizedBox(height: 8),
            _fact(
                PhosphorIcons.calendarBlank(),
                isRecurring
                    ? _recurrenceLabel(event)
                    : WpccTime.eventDate(event['event_start_at']),
                subtitle: isRecurring
                    ? _recurringTime(event)
                    : WpccTime.eventTime(
                        event['event_start_at'], event['event_end_at'])),
            _fact(PhosphorIcons.mapPin(), 'Venue',
                subtitle: (event['location']?.toString() ?? '').isEmpty
                    ? 'Location unavailable'
                    : event['location'].toString()),
            if ((event['location']?.toString() ?? '').isNotEmpty ||
                event['latitude'] != null)
              Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => _openDirections(event),
                    icon: Icon(PhosphorIcons.arrowUpRight(), size: 18),
                    label: const Text('Directions'),
                    style:
                        TextButton.styleFrom(minimumSize: const Size(48, 48)),
                  ))
            else
              const Text('Directions unavailable'),
            const SizedBox(height: 8),
            Divider(
                height: 1, color: Theme.of(context).colorScheme.outlineVariant),
            if (!isRecurring) ...[
              const SizedBox(height: 20),
              FutureBuilder<Map<String, dynamic>?>(
                  future: myAttendanceFuture,
                  builder: (context, s) {
                    if (s.connectionState != ConnectionState.done) {
                      return const LinearProgressIndicator();
                    }
                    if (s.hasError) {
                      return MemberStatus(
                          message: 'Attendance unavailable',
                          icon: PhosphorIcons.warningCircle(),
                          onRetry: () => setState(() {
                                myAttendanceFuture =
                                    repo.myAttendance(widget.eventId);
                              }));
                    }
                    final row = s.data;
                    final checked = row != null;
                    final clockedOut = row?['clockout'] != null;
                    return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (checked)
                            Text(
                                clockedOut
                                    ? 'Attendance complete'
                                    : 'Checked in',
                                style: Theme.of(context).textTheme.bodySmall),
                          if (!clockedOut) ...[
                            const SizedBox(height: 10),
                            FilledButton(
                                style: FilledButton.styleFrom(
                                    backgroundColor:
                                        Theme.of(context).colorScheme.onSurface,
                                    foregroundColor:
                                        MemberVisuals.page(context)),
                                onPressed: attendanceBusy
                                    ? null
                                    : () => _attendanceAction(event),
                                child: attendanceBusy
                                    ? SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: MemberVisuals.page(context)))
                                    : Text(checked ? 'Check out' : 'Check in')),
                          ],
                        ]);
                  }),
            ],
            if ((event['description']?.toString() ?? '').isNotEmpty) ...[
              const SizedBox(height: 28),
              const MemberSectionHeader(title: 'About this event'),
              Text(event['description'].toString(),
                  maxLines: descriptionExpanded ? null : 5,
                  overflow: descriptionExpanded
                      ? TextOverflow.visible
                      : TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.6)),
              LayoutBuilder(builder: (context, box) {
                final painter = TextPainter(
                  text: TextSpan(
                      text: event['description'].toString(),
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(height: 1.6)),
                  maxLines: 5,
                  textDirection: Directionality.of(context),
                  textScaler: MediaQuery.textScalerOf(context),
                )..layout(maxWidth: box.maxWidth);
                final expandable = painter.didExceedMaxLines;
                painter.dispose();
                if (!expandable) return const SizedBox.shrink();
                return TextButton(
                  onPressed: () => setState(
                      () => descriptionExpanded = !descriptionExpanded),
                  child: Text(descriptionExpanded ? 'Show less' : 'Read more'),
                );
              }),
            ],
            const SizedBox(height: 28),
            const MemberSectionHeader(title: 'Organizer'),
            FutureBuilder<Map<String, dynamic>?>(
                future: metaFuture,
                builder: (context, s) {
                  final m = s.data;
                  return MemberListRow(
                      plain: true,
                      title: m?['host_name']?.toString() ?? 'WPCC',
                      subtitle: 'Event organizer',
                      leading: InitialsAvatar(
                          memberStyle: true,
                          initials: m?['host_initials']?.toString() ?? 'WP',
                          imageUrl: m?['host_avatar']?.toString(),
                          size: 48));
                }),
          ]);

  Widget _attendance(Map<String, dynamic> event, {Key? key}) => FutureBuilder<
          List<Map<String, dynamic>>>(
      key: key,
      future: attendanceFuture,
      builder: (context, s) {
        if (s.connectionState != ConnectionState.done) {
          return const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()));
        }
        if (s.hasError) {
          return MemberStatus(
              icon: PhosphorIcons.lockKey(),
              message: 'Attendance roster is not available to your role');
        }
        final rows = s.data ?? const [];
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(event['title']?.toString() ?? 'Event',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 24),
          FutureBuilder<Map<String, dynamic>?>(
              future: metaFuture,
              builder: (context, meta) {
                final expected =
                    (meta.data?['expected_count'] as num?)?.toInt();
                final present = (meta.data?['present_count'] as num?)?.toInt();
                if (expected == null || present == null) {
                  return const SizedBox.shrink();
                }
                return LayoutBuilder(builder: (context, box) {
                  final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
                  final columns = box.maxWidth < 400 && scale > 1.5 ? 1 : 3;
                  final width = (box.maxWidth - 12 * (columns - 1)) / columns;
                  return Wrap(spacing: 12, runSpacing: 12, children: [
                    for (final metric in [
                      ('$expected', 'Expected'),
                      ('$present', 'Present'),
                      (
                        expected == 0
                            ? '0%'
                            : '${((present / expected) * 100).round()}%',
                        'Attendance rate'
                      ),
                    ])
                      SizedBox(
                          width: width, child: _metric(metric.$1, metric.$2)),
                  ]);
                });
              }),
          const SizedBox(height: 28),
          const MemberSectionHeader(title: 'Present members'),
          if (rows.isEmpty)
            MemberStatus(
                icon: PhosphorIcons.users(),
                message: 'No attendance records available')
          else
            for (final r in rows)
              Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: MemberListRow(
                      title: r['full_name']?.toString() ?? '',
                      subtitle: [
                        _relative((r['minutes_from_start'] as num?)?.toInt()),
                        WpccTime.eventTime(r['checked_in_at'], null),
                      ].where((value) => value.isNotEmpty).join(' / '),
                      leading: InitialsAvatar(
                          memberStyle: true,
                          initials: r['initials']?.toString() ?? '--',
                          imageUrl: r['avatar']?.toString(),
                          size: 48))),
        ]);
      });

  Widget _metric(String value, String label) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(children: [
        Text(value, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall),
      ]));

  Widget _fact(IconData icon, String value, {String? subtitle}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12)),
            child: Icon(icon,
                size: 22, color: Theme.of(context).colorScheme.onSurface)),
        const SizedBox(width: 14),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: 14, fontWeight: FontWeight.w600, height: 1.4)),
          if (subtitle != null && subtitle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.5)),
          ],
        ])),
      ]));
  String _relative(int? minutes) {
    if (minutes == null) return '';
    if (minutes == 0) return 'On time';
    return minutes < 0 ? '${minutes.abs()} min early' : '$minutes min late';
  }

  String _recurrenceLabel(Map<String, dynamic> event) {
    const days = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
    ];
    final index = int.tryParse(event['day_of_week']?.toString() ?? '');
    final day = index != null && index >= 0 && index < days.length
        ? days[index]
        : (event['recurrence_type']?.toString() ?? 'Recurring');
    final parts = (event['start_time']?.toString() ?? '').split(':');
    if (parts.length < 2) return day;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return day;
    final suffix = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;
    return '$day at $displayHour:${minute.toString().padLeft(2, '0')} $suffix';
  }

  String _recurringTime(Map<String, dynamic> event) {
    String format(dynamic value) {
      final parts = (value?.toString() ?? '').split(':');
      if (parts.length < 2) return '';
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour == null || minute == null) return '';
      final suffix = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour % 12 == 0 ? 12 : hour % 12;
      return '$displayHour:${minute.toString().padLeft(2, '0')} $suffix';
    }

    final start = format(event['start_time']);
    final end = format(event['end_time']);
    if (start.isEmpty) return 'Time unavailable';
    return end.isEmpty ? start : '$start – $end';
  }

  Future<void> _openDirections(Map<String, dynamic> event) async {
    final lat = event['latitude'], lng = event['longitude'];
    final q = lat != null && lng != null
        ? '$lat,$lng'
        : Uri.encodeComponent(event['location']?.toString() ?? '');
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$q');
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened) throw StateError('not opened');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Unable to open directions. Please try again.')));
      }
    }
  }
}
