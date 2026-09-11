import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/wpcc_time.dart';
import '../../core/widgets/initials_avatar.dart';
import '../../core/widgets/section_empty_state.dart';
import 'event_repository.dart';

class EventDetailPage extends StatefulWidget {
  const EventDetailPage({super.key, required this.eventId, this.seed});
  final String eventId;
  final Map<String, dynamic>? seed;
  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
  final repo = EventRepository();
  late Future<Map<String, dynamic>?> eventFuture;
  late Future<Map<String, dynamic>?> metaFuture;
  late Future<Map<String, dynamic>?> myAttendanceFuture;
  late Future<List<Map<String, dynamic>>> attendanceFuture;
  int tab = 0;
  bool attendanceBusy = false;
  final ScrollController scrollController = ScrollController();
  bool headerFrosted = false;
  @override
  void initState() {
    super.initState();
    _reload();
    scrollController.addListener(() {
      final next = scrollController.offset > 195;
      if (next != headerFrosted && mounted) {
        setState(() => headerFrosted = next);
      }
    });
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
    metaFuture = repo.meta(widget.eventId);
    myAttendanceFuture = repo.myAttendance(widget.eventId);
    attendanceFuture = repo.attendance(widget.eventId);
  }

  Future<void> _attendanceAction() async {
    setState(() => attendanceBusy = true);
    try {
      final result = await repo.checkInOrOut(widget.eventId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:
                Text(result['message']?.toString() ?? 'Attendance updated')));
        setState(_reload);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Unable to update attendance. Please try again.')));
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
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Text('Unable to load event'),
                  const SizedBox(height: 12),
                  OutlinedButton(
                      onPressed: () => setState(_reload),
                      child: const Text('Try again'))
                ]));
              }
              final event = snapshot.data;
              if (event == null) {
                return const Center(child: Text('Event not available'));
              }
              return CustomScrollView(controller: scrollController, slivers: [
                SliverAppBar(
                  pinned: true,
                  expandedHeight: 292,
                  backgroundColor: headerFrosted
                      ? Colors.white.withValues(alpha: .9)
                      : Colors.transparent,
                  foregroundColor:
                      headerFrosted ? WpccColors.ink : Colors.white,
                  surfaceTintColor: Colors.transparent,
                  leading: IconButton(
                      onPressed: () => context.pop(),
                      icon: Icon(PhosphorIcons.caretLeft(),
                          size: 20,
                          color:
                              headerFrosted ? WpccColors.ink : Colors.white)),
                  title: Text('Event details',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color:
                              headerFrosted ? WpccColors.ink : Colors.white)),
                  flexibleSpace: FlexibleSpaceBar(
                      background: Stack(fit: StackFit.expand, children: [
                    if ((event['featured_image']?.toString() ?? '').isNotEmpty)
                      Image.network(event['featured_image'].toString(),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _heroFallback())
                    else
                      _heroFallback(),
                    const DecoratedBox(
                        decoration: BoxDecoration(
                            gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                          Colors.transparent,
                          Color(0xA0000000)
                        ]))),
                  ])),
                ),
                SliverToBoxAdapter(
                    child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 18, 18, 110),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                _tabChip('Overview', 0),
                                const SizedBox(width: 8),
                                _tabChip('Attendance', 1)
                              ]),
                              const SizedBox(height: 18),
                              AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 210),
                                  child: tab == 0
                                      ? _overview(event)
                                      : _attendance(event,
                                          key: const ValueKey('attendance'))),
                            ]))),
              ]);
            }),
      );
  Widget _heroFallback() => const DecoratedBox(
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
            Color(0xFFE5D5F4),
            Color(0xFFD7DEEF),
            Color(0xFFF2E8DF)
          ])));
  Widget _tabChip(String label, int index) => ChoiceChip(
      selected: tab == index,
      showCheckmark: false,
      label: Text(label),
      onSelected: (_) => setState(() => tab = index),
      selectedColor: WpccColors.ink,
      backgroundColor: Colors.white,
      side: BorderSide.none,
      labelStyle: TextStyle(
          fontSize: 12,
          color: tab == index ? Colors.white : WpccColors.inkSoft));
  Widget _overview(Map<String, dynamic> event) => Column(
          key: const ValueKey('overview'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(event['title']?.toString() ?? 'Event',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600, letterSpacing: -.6)),
            if ((event['description']?.toString() ?? '').isNotEmpty) ...[
              const SizedBox(height: 7),
              Text(event['description'].toString(),
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: WpccColors.inkSoft, height: 1.5))
            ],
            const SizedBox(height: 18),
            Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24)),
                child: Column(children: [
                  _fact(PhosphorIcons.calendarBlank(), 'Date',
                      WpccTime.eventDate(event['event_start_at'])),
                  _fact(
                      PhosphorIcons.clock(),
                      'Time',
                      WpccTime.eventTime(
                          event['event_start_at'], event['event_end_at'])),
                  _fact(
                      PhosphorIcons.mapPin(),
                      'Location',
                      (event['location']?.toString() ?? '').isEmpty
                          ? 'Location unavailable'
                          : event['location'].toString(),
                      trailing: (event['location']?.toString() ?? '').isEmpty
                          ? null
                          : 'Find'),
                ])),
            const SizedBox(height: 12),
            FutureBuilder<Map<String, dynamic>?>(
                future: myAttendanceFuture,
                builder: (context, s) {
                  final row = s.data;
                  final checked = row != null;
                  final clockedOut = row?['clockout'] != null;
                  return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24)),
                      child: Row(children: [
                        Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                                color: const Color(0xFFF2F3F7),
                                borderRadius: BorderRadius.circular(14)),
                            child: Icon(
                                checked
                                    ? PhosphorIcons.check()
                                    : PhosphorIcons.signIn(),
                                size: 19)),
                        const SizedBox(width: 11),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text(
                                  clockedOut
                                      ? 'Attendance complete'
                                      : checked
                                          ? 'Checked in'
                                          : 'Check in',
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500)),
                              Text(
                                  checked
                                      ? (clockedOut
                                          ? 'You have checked out.'
                                          : 'You are marked present.')
                                      : 'Check in when you arrive at the event.',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: WpccColors.muted))
                            ])),
                        if (!clockedOut)
                          FilledButton(
                              onPressed:
                                  attendanceBusy ? null : _attendanceAction,
                              style: FilledButton.styleFrom(
                                  backgroundColor: WpccColors.ink,
                                  minimumSize: const Size(88, 48)),
                              child: attendanceBusy
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white))
                                  : Text(checked ? 'Check out' : 'Check in',
                                      style: const TextStyle(fontSize: 12))),
                      ]));
                }),
            const SizedBox(height: 18),
            Text('Organizer',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            FutureBuilder<Map<String, dynamic>?>(
                future: metaFuture,
                builder: (context, s) {
                  final m = s.data;
                  return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22)),
                      child: Row(children: [
                        InitialsAvatar(
                            initials: m?['host_initials']?.toString() ?? 'WP',
                            imageUrl: m?['host_avatar']?.toString(),
                            size: 42),
                        const SizedBox(width: 10),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text(m?['host_name']?.toString() ?? 'WPCC',
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500)),
                              Text('Event organizer',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: WpccColors.muted))
                            ]))
                      ]));
                }),
            const SizedBox(height: 18),
            Text('Directions to the event',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            if ((event['location']?.toString() ?? '').isEmpty &&
                event['latitude'] == null)
              SectionEmptyState(
                  icon: PhosphorIcons.mapPinLine(),
                  message: 'Directions unavailable',
                  height: 120)
            else
              Semantics(
                  button: true,
                  label: 'Open directions to ${event['location'] ?? 'event'}',
                  child: InkWell(
                      onTap: () => _openDirections(event),
                      borderRadius: BorderRadius.circular(22),
                      child: Container(
                          height: 92,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                              color: const Color(0xFFF0F1F5),
                              borderRadius: BorderRadius.circular(22)),
                          child: Row(children: [
                            Icon(PhosphorIcons.navigationArrow(), size: 23),
                            const SizedBox(width: 12),
                            Expanded(
                                child: Text(
                                    event['location']?.toString() ??
                                        'Open location',
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500))),
                            Icon(PhosphorIcons.arrowSquareOut(), size: 17)
                          ])))),
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
          return SectionEmptyState(
              icon: PhosphorIcons.lockKey(),
              message: 'Attendance roster is not available to your role',
              height: 180);
        }
        final rows = s.data ?? const [];
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(event['title']?.toString() ?? 'Event',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 14),
          FutureBuilder<Map<String, dynamic>?>(
              future: metaFuture,
              builder: (context, meta) {
                final expected =
                    (meta.data?['expected_count'] as num?)?.toInt();
                final present = (meta.data?['present_count'] as num?)?.toInt();
                if (expected == null || present == null) {
                  return const SizedBox.shrink();
                }
                return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22)),
                    child: Row(children: [
                      Expanded(child: _metric('$expected', 'Expected')),
                      Expanded(child: _metric('$present', 'Present')),
                      Expanded(
                          child: _metric(
                              expected == 0
                                  ? '0%'
                                  : '${((present / expected) * 100).round()}%',
                              'Attendance rate'))
                    ]));
              }),
          const SizedBox(height: 16),
          Text('Present members',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          if (rows.isEmpty)
            SectionEmptyState(
                icon: PhosphorIcons.users(),
                message: 'No attendance records available',
                height: 150)
          else
            Container(
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24)),
                child: Column(
                    children: rows
                        .map((r) => Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            child: Row(children: [
                              InitialsAvatar(
                                  initials: r['initials']?.toString() ?? '--',
                                  imageUrl: r['avatar']?.toString(),
                                  size: 38),
                              const SizedBox(width: 10),
                              Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                    Text(r['full_name']?.toString() ?? '',
                                        style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500)),
                                    Text(
                                        _relative(
                                            (r['minutes_from_start'] as num?)
                                                ?.toInt()),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(color: WpccColors.muted))
                                  ])),
                              Text(WpccTime.eventTime(r['checked_in_at'], null),
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600))
                            ])))
                        .toList())),
        ]);
      });
  Widget _metric(String value, String label) => Column(children: [
        Text(value,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 3),
        Text(label,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(fontSize: 9, color: WpccColors.muted))
      ]);
  Widget _fact(IconData icon, String label, String value, {String? trailing}) =>
      Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Row(children: [
            Icon(icon, size: 19, color: WpccColors.inkSoft),
            const SizedBox(width: 11),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(label,
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: WpccColors.muted)),
                  const SizedBox(height: 2),
                  Text(value,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w500))
                ])),
            if (trailing != null)
              Text(trailing,
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w600))
          ]));
  String _relative(int? minutes) {
    if (minutes == null) return '';
    if (minutes == 0) return 'On time';
    return minutes < 0 ? '${minutes.abs()} min early' : '$minutes min late';
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
