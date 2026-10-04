import '/backend/supabase/supabase.dart';
import '/features/events/screens/event_details_screen.dart';
import '/features/search/screens/global_search_screen.dart';
import '/flutter_flow/custom_functions.dart' as functions;
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/shared/widgets/hamburger_menu_button.dart';
import '/shared/widgets/wpcc_shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'events_listing_model.dart';
export 'events_listing_model.dart';

class EventsListingWidget extends StatefulWidget {
  const EventsListingWidget({super.key});

  static String routeName = 'EventsListing';
  static String routePath = '/eventsListing';

  @override
  State<EventsListingWidget> createState() => _EventsListingWidgetState();
}

class _EventsListingWidgetState extends State<EventsListingWidget> {
  late EventsListingModel _model;

  late Future<List<MyEventsRow>> _ongoingEventsFuture;
  late Future<List<MyRecurringEventsRow>> _recurringEventsFuture;
  late Future<List<MyEventsRow>> _upcomingEventsFuture;
  List<MyEventsRow>? _ongoingEventsCache;
  List<MyRecurringEventsRow>? _recurringEventsCache;
  List<MyEventsRow>? _upcomingEventsCache;
  bool _refreshingHomeData = false;
  late final VoidCallback _appStateListener;

  @override
  void initState() {
    super.initState();
    _model = EventsListingModel();
    _model.initState(context);
    _appStateListener = _handleAppStateChange;
    FFAppState().addListener(_appStateListener);
    _ongoingEventsFuture = _trackOngoingEvents(_loadOngoingEvents());
    _recurringEventsFuture = _trackRecurringEvents(_loadRecurringEvents());
    _upcomingEventsFuture = _trackUpcomingEvents(_loadUpcomingEvents());
    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    FFAppState().removeListener(_appStateListener);
    _model.dispose();
    super.dispose();
  }

  void _handleAppStateChange() {
    if (!mounted || _refreshingHomeData) {
      return;
    }
    _refreshHomeData();
  }

  Future<List<MyEventsRow>> _loadOngoingEvents() {
    return MyEventsTable().queryRows(
      queryFn: (q) => q
          .eq('is_active', true)
          .gte('event_end_at', getCurrentTimestamp)
          .lte('event_start_at', getCurrentTimestamp)
          .order('event_start_at', ascending: false),
      limit: 1,
    );
  }

  Future<List<MyRecurringEventsRow>> _loadRecurringEvents() {
    return MyRecurringEventsTable().queryRows(
      queryFn: (q) =>
          q.eq('is_active', true).order('day_of_week').order('start_time'),
    );
  }

  Future<List<MyEventsRow>> _loadUpcomingEvents() {
    return MyEventsTable().queryRows(
      queryFn: (q) => q
          .eq('is_active', true)
          .gt('event_start_at', getCurrentTimestamp)
          .order(
            'event_start_at',
          ),
      limit: 6,
    );
  }

  Future<List<MyEventsRow>> _trackOngoingEvents(
    Future<List<MyEventsRow>> future,
  ) {
    return future.then((value) {
      if (mounted) {
        setState(() => _ongoingEventsCache = value);
      }
      return value;
    });
  }

  Future<List<MyRecurringEventsRow>> _trackRecurringEvents(
    Future<List<MyRecurringEventsRow>> future,
  ) {
    return future.then((value) {
      if (mounted) {
        setState(() => _recurringEventsCache = value);
      }
      return value;
    });
  }

  Future<List<MyEventsRow>> _trackUpcomingEvents(
    Future<List<MyEventsRow>> future,
  ) {
    return future.then((value) {
      if (mounted) {
        setState(() => _upcomingEventsCache = value);
      }
      return value;
    });
  }

  Future<void> _refreshHomeData() async {
    if (_refreshingHomeData || !mounted) {
      return;
    }

    _refreshingHomeData = true;
    try {
      final ongoingFuture = _trackOngoingEvents(_loadOngoingEvents());
      final recurringFuture = _trackRecurringEvents(_loadRecurringEvents());
      final upcomingFuture = _trackUpcomingEvents(_loadUpcomingEvents());

      if (mounted) {
        setState(() {
          _ongoingEventsFuture = ongoingFuture;
          _recurringEventsFuture = recurringFuture;
          _upcomingEventsFuture = upcomingFuture;
        });
      }

      await Future.wait([
        ongoingFuture,
        recurringFuture,
        upcomingFuture,
      ]);
    } finally {
      _refreshingHomeData = false;
    }
  }

  DateTime _nextRecurringDateTime(int? dayOfWeek, PostgresTime? time) {
    final now = getCurrentTimestamp;
    final currentDbDay = now.weekday % 7;
    var offset = (dayOfWeek ?? currentDbDay) - currentDbDay;
    if (offset < 0) {
      offset += 7;
    }

    final baseDate = DateTime(now.year, now.month, now.day).add(
      Duration(days: offset),
    );
    final timeValue = time?.time;
    if (timeValue == null) {
      return baseDate;
    }

    final combined = DateTime(
      baseDate.year,
      baseDate.month,
      baseDate.day,
      timeValue.hour,
      timeValue.minute,
      timeValue.second,
    );

    if (offset == 0 && combined.isBefore(now)) {
      return combined.add(const Duration(days: 7));
    }

    return combined;
  }

  String _ordinalDay(int day) {
    if (day >= 11 && day <= 13) {
      return '${day}th';
    }
    switch (day % 10) {
      case 1:
        return '${day}st';
      case 2:
        return '${day}nd';
      case 3:
        return '${day}rd';
      default:
        return '${day}th';
    }
  }

  String _formatEventDateTime(DateTime? date) {
    if (date == null) {
      return 'Date unavailable';
    }
    final weekday = DateFormat('EEE').format(date);
    final month = DateFormat('MMM').format(date);
    final time = DateFormat('h:mma').format(date).toLowerCase();
    return '$weekday ${_ordinalDay(date.day)} $month, $time';
  }

  String _weekdayLabel(int? dayOfWeek) {
    switch (dayOfWeek) {
      case 0:
        return 'Sunday';
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      default:
        return 'Recurring service';
    }
  }

  String _supportingRecurringText(MyRecurringEventsRow event) {
    final description = event.description?.trim() ?? '';
    if (description.isNotEmpty) {
      return description;
    }
    return '${_weekdayLabel(event.dayOfWeek)} service';
  }

  Color _pageColor(BuildContext context) => Colors.white;

  Color _primaryTextColor(BuildContext context) => const Color(0xFF111827);

  Color _secondaryTextColor(BuildContext context) => const Color(0xFF4B5563);

  Color _searchIconColor(BuildContext context) => const Color(0xFF334155);

  Color _emptyStateSurface(BuildContext context) => const Color(0xFFFCFBF9);

  void _openAttendanceEventDetails(
    BuildContext context,
    MyEventsRow row,
  ) {
    context.pushNamedAuth(
      EventDetailsScreen.routeName,
      mounted,
      pathParameters: {'eventId': row.eventId ?? ''},
    );
  }

  // Recurring events are schedule templates, not materialized event
  // instances, so they have no row in `events`/`events_attendance_view` to
  // open a full EventDetailsScreen (attendance/clock-in) against. Show the
  // schedule info in a sheet instead of routing into that screen.
  void _openRecurringEventDetails(
    BuildContext context,
    MyRecurringEventsRow row,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => _buildRecurringEventSheet(sheetContext, row),
    );
  }

  Widget _buildRecurringEventSheet(
    BuildContext context,
    MyRecurringEventsRow event,
  ) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(17, 24, 39, 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            _EventImage(
              imageUrl: functions.safeImage(event.featuredImage),
              width: double.infinity,
              height: 180,
              borderRadius: 20,
            ),
            const SizedBox(height: 16),
            Text(
              valueOrDefault(event.title, 'Untitled event'),
              style: _instrumentSerif(context, size: 24, height: 1.1),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  FFIcons.krepeat,
                  size: 16,
                  color: _secondaryTextColor(context),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _formatEventDateTime(
                      _nextRecurringDateTime(event.dayOfWeek, event.startTime),
                    ),
                    style: _supportTextStyle(
                      context,
                      weight: FontWeight.w600,
                      color: _primaryTextColor(context),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _supportingRecurringText(event),
              style: _supportTextStyle(context),
            ),
            if ((event.description ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                event.description!.trim(),
                style: _instrumentSans(context, size: 12, height: 16 / 12),
              ),
            ],
            const SizedBox(height: 20),
            Text(
              'This is a recurring service. Check-in opens once the next occurrence begins.',
              style: _supportTextStyle(context),
            ),
          ],
        ),
      ),
    );
  }

  TextStyle _instrumentSans(
    BuildContext context, {
    double size = 15,
    FontWeight weight = FontWeight.w400,
    Color? color,
    double height = 1.2,
    double letterSpacing = -0.5,
  }) {
    return GoogleFonts.instrumentSans(
      textStyle: FlutterFlowTheme.of(context).bodyMedium.override(
            fontFamily: 'Instrument Sans',
            fontSize: size,
            color: color ?? _primaryTextColor(context),
            letterSpacing: letterSpacing,
            fontWeight: weight,
            lineHeight: height,
          ),
    );
  }

  TextStyle _supportTextStyle(
    BuildContext context, {
    double size = 12,
    FontWeight weight = FontWeight.w400,
    Color? color,
    double height = 1.333,
    double letterSpacing = -0.5,
  }) {
    return GoogleFonts.instrumentSans(
      textStyle: FlutterFlowTheme.of(context).bodySmall.override(
            fontFamily: 'Instrument Sans',
            fontSize: size,
            color: color ?? _secondaryTextColor(context),
            letterSpacing: letterSpacing,
            fontWeight: weight,
            lineHeight: height,
          ),
    );
  }

  TextStyle _instrumentSerif(
    BuildContext context, {
    double size = 36,
    FontWeight weight = FontWeight.w400,
    Color? color,
    double height = 1.305,
    double letterSpacing = -0.364919,
  }) {
    return GoogleFonts.instrumentSerif(
      textStyle: FlutterFlowTheme.of(context).displaySmall.override(
            fontFamily: 'Instrument Serif',
            fontSize: size,
            color: color ?? _primaryTextColor(context),
            letterSpacing: letterSpacing,
            fontWeight: weight,
            lineHeight: height,
          ),
    );
  }

  Widget _buildDiscoverCategories(BuildContext context) {
    const labels = [
      'All',
      'Ongoing',
      'Upcoming',
      'Prayer',
      'Activities',
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(labels.length, (index) {
          final isActive = index == 0;
          return Padding(
            padding: EdgeInsets.only(right: index == labels.length - 1 ? 0 : 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFF111113) : Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: isActive
                      ? const Color(0xFF111113)
                      : const Color.fromRGBO(17, 24, 39, 0.14),
                ),
              ),
              child: Text(
                labels[index],
                style: _instrumentSans(
                  context,
                  size: 12,
                  weight: FontWeight.w600,
                  color: isActive ? Colors.white : const Color(0xFF374151),
                  height: 1,
                  letterSpacing: 0,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context, MyEventsRow event) {
    return InkWell(
      onTap: () => _openAttendanceEventDetails(context, event),
      borderRadius: BorderRadius.circular(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _EventImage(
            imageUrl: functions.safeImage(event.featuredImage),
            width: double.infinity,
            height: 239,
            borderRadius: 24,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  valueOrDefault<String>(event.title, 'Untitled event'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _instrumentSans(
                    context,
                    size: 20,
                    height: 24 / 20,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatEventDateTime(event.eventStartAt),
                  style: _instrumentSans(
                    context,
                    size: 12,
                    color: _secondaryTextColor(context),
                    height: 15 / 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: _instrumentSans(
            context,
            size: 15,
            height: 18 / 15,
          ),
        ),
        InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'View more',
                  style: _supportTextStyle(context),
                ),
                const SizedBox(width: 8),
                Icon(
                  FFIcons.kcaretRight,
                  size: 16,
                  color: _secondaryTextColor(context),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewGrid<T>({
    required BuildContext context,
    required List<T> items,
    required Widget Function(T item) itemBuilder,
  }) {
    final previewItems = items.take(2).toList();
    if (previewItems.isEmpty) {
      return _buildEmptySectionCard(context);
    }

    return GridView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: previewItems.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 20,
        mainAxisSpacing: 12,
        mainAxisExtent: 210,
      ),
      itemBuilder: (context, index) => itemBuilder(previewItems[index]),
    );
  }

  Widget _buildRecurringCard(
    BuildContext context,
    MyRecurringEventsRow recurringEvent,
  ) {
    return InkWell(
      onTap: () => _openRecurringEventDetails(context, recurringEvent),
      borderRadius: BorderRadius.circular(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _EventImage(
            imageUrl: functions.safeImage(recurringEvent.featuredImage),
            width: double.infinity,
            height: 144,
            borderRadius: 24,
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  valueOrDefault(recurringEvent.title, 'Untitled event'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _instrumentSans(
                    context,
                    size: 15,
                    height: 18 / 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatEventDateTime(
                    _nextRecurringDateTime(
                      recurringEvent.dayOfWeek,
                      recurringEvent.startTime,
                    ),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _supportTextStyle(context),
                ),
                const SizedBox(height: 2),
                Text(
                  _supportingRecurringText(recurringEvent),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _supportTextStyle(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingCard(
    BuildContext context,
    MyEventsRow event,
  ) {
    final location = (event.location?.trim().isNotEmpty ?? false)
        ? event.location!.trim()
        : 'Location unavailable';

    return InkWell(
      onTap: () => _openAttendanceEventDetails(context, event),
      borderRadius: BorderRadius.circular(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _EventImage(
            imageUrl: functions.safeImage(event.featuredImage),
            width: double.infinity,
            height: 144,
            borderRadius: 24,
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  valueOrDefault<String>(event.title, 'Untitled event'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _instrumentSans(
                    context,
                    size: 15,
                    height: 18 / 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatEventDateTime(event.eventStartAt),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _supportTextStyle(context),
                ),
                const SizedBox(height: 2),
                Text(
                  location,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _supportTextStyle(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySectionCard(BuildContext context) {
    return Container(
      height: 144,
      decoration: BoxDecoration(
        color: _emptyStateSurface(context),
        borderRadius: BorderRadius.circular(24),
      ),
      alignment: Alignment.center,
      child: Text(
        'No events yet',
        style: _instrumentSans(
          context,
          size: 14,
          color: _secondaryTextColor(context),
          height: 18 / 14,
        ),
      ),
    );
  }

  Widget _animatedLoadState(BuildContext context, Widget child) {
    return AnimatedSwitcher(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 240),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: child,
    );
  }

  Widget _buildScreen(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: Future.wait<dynamic>([
        _ongoingEventsFuture,
        _recurringEventsFuture,
        _upcomingEventsFuture,
      ]),
      builder: (context, snapshot) {
        final ongoingEvents = _ongoingEventsCache;
        final recurringEvents = _recurringEventsCache;
        final upcomingEvents = _upcomingEventsCache;

        if (!snapshot.hasData &&
            (ongoingEvents == null ||
                recurringEvents == null ||
                upcomingEvents == null)) {
          return _animatedLoadState(
            context,
            const KeyedSubtree(
              key: ValueKey('events-loading'),
              child: _EventsListingLoadingView(),
            ),
          );
        }

        if (snapshot.hasError &&
            ongoingEvents == null &&
            recurringEvents == null &&
            upcomingEvents == null) {
          return _animatedLoadState(
            context,
            KeyedSubtree(
              key: const ValueKey('events-error'),
              child: _EventsListingErrorView(onRetry: _refreshHomeData),
            ),
          );
        }

        final ongoing = (snapshot.data?[0] as List<MyEventsRow>?) ??
            ongoingEvents ??
            const <MyEventsRow>[];
        final recurring = (snapshot.data?[1] as List<MyRecurringEventsRow>?) ??
            recurringEvents ??
            const <MyRecurringEventsRow>[];
        final upcoming = (snapshot.data?[2] as List<MyEventsRow>?) ??
            upcomingEvents ??
            const <MyEventsRow>[];

        final featuredEvent = ongoing.isNotEmpty ? ongoing.first : null;

        return _animatedLoadState(
          context,
          KeyedSubtree(
            key: const ValueKey('events-content'),
            child: Column(
              children: [
                _buildStickyHeader(context),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDiscoverCategories(context),
                              const SizedBox(height: 24),
                              Text(
                                'Ongoing Services',
                                style: _instrumentSans(
                                  context,
                                  size: 15,
                                  weight: FontWeight.w600,
                                  color: _primaryTextColor(context),
                                  height: 1.2,
                                  letterSpacing: 0,
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (featuredEvent != null)
                                _buildHeroCard(context, featuredEvent)
                              else
                                _buildEmptySectionCard(context),
                              const SizedBox(height: 24),
                              _buildSectionHeader(
                                context,
                                title: 'Recurring Events',
                              ),
                              const SizedBox(height: 12),
                              _buildPreviewGrid<MyRecurringEventsRow>(
                                context: context,
                                items: recurring,
                                itemBuilder: (event) =>
                                    _buildRecurringCard(context, event),
                              ),
                              const SizedBox(height: 24),
                              _buildSectionHeader(
                                context,
                                title: 'Upcoming Events',
                              ),
                              const SizedBox(height: 12),
                              _buildPreviewGrid<MyEventsRow>(
                                context: context,
                                items: upcoming,
                                itemBuilder: (event) =>
                                    _buildUpcomingCard(context, event),
                              ),
                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStickyHeader(BuildContext context) {
    return ColoredBox(
      color: _pageColor(context),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const HamburgerMenuButton(),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Events',
                style: _instrumentSerif(
                  context,
                  size: 28,
                  color: _primaryTextColor(context),
                  height: 1.02,
                  letterSpacing: -0.84,
                ),
              ),
            ),
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => context.pushNamed(
                GlobalSearchScreen.routeName,
                queryParameters: {'filter': 'events'},
              ),
              child: SizedBox(
                width: 24,
                height: 24,
                child: Icon(
                  FFIcons.kmagnifyingGlass,
                  size: 24,
                  color: _searchIconColor(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Title(
      title: 'EventsListing',
      color: FlutterFlowTheme.of(context).primary.withAlpha(0XFF),
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
          FocusManager.instance.primaryFocus?.unfocus();
        },
        child: Material(
          color: _pageColor(context),
          child: SafeArea(
            top: true,
            bottom: false,
            child: _buildScreen(context),
          ),
        ),
      ),
    );
  }
}

class _EventImage extends StatelessWidget {
  const _EventImage({
    required this.imageUrl,
    required this.width,
    required this.height,
    required this.borderRadius,
  });

  final String imageUrl;
  final double width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: BoxFit.cover,
        fadeInDuration: Duration.zero,
        fadeOutDuration: Duration.zero,
        errorWidget: (_, __, ___) => Container(
          width: width,
          height: height,
          color: const Color(0xFFFCFBF9),
          alignment: Alignment.center,
          child: const Icon(
            FFIcons.kimageBroken,
            size: 28,
            color: Color(0xFFB9A58D),
          ),
        ),
      ),
    );
  }
}

class _EventsListingLoadingView extends StatelessWidget {
  const _EventsListingLoadingView();

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      physics: NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 43),
          Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                WpccShimmerBlock(width: 78, height: 47, radius: 10),
                WpccShimmerCircle(size: 24),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                WpccShimmerBlock(width: 114, height: 18, radius: 8),
                SizedBox(height: 8),
                WpccShimmerCard(
                  height: 239,
                  radius: 24,
                  padding: EdgeInsets.zero,
                  child: SizedBox.expand(),
                ),
                SizedBox(height: 12),
                WpccShimmerBlock(width: 220, height: 24, radius: 8),
                SizedBox(height: 4),
                WpccShimmerBlock(width: 140, height: 15, radius: 8),
                SizedBox(height: 24),
                WpccShimmerBlock(width: 132, height: 18, radius: 8),
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _EventCardSkeleton()),
                    SizedBox(width: 20),
                    Expanded(child: _EventCardSkeleton()),
                  ],
                ),
                SizedBox(height: 24),
                WpccShimmerBlock(width: 126, height: 18, radius: 8),
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _EventCardSkeleton()),
                    SizedBox(width: 20),
                    Expanded(child: _EventCardSkeleton()),
                  ],
                ),
                SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EventCardSkeleton extends StatelessWidget {
  const _EventCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        WpccShimmerCard(
          height: 144,
          radius: 24,
          padding: EdgeInsets.zero,
          child: SizedBox.expand(),
        ),
        SizedBox(height: 12),
        WpccShimmerBlock(width: 122, height: 16, radius: 8),
        SizedBox(height: 6),
        WpccShimmerBlock(width: 98, height: 12, radius: 7),
        SizedBox(height: 5),
        WpccShimmerBlock(width: 78, height: 12, radius: 7),
      ],
    );
  }
}

class _EventsListingErrorView extends StatelessWidget {
  const _EventsListingErrorView({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              FFIcons.kcloudSlash,
              size: 38,
              color: Color(0xFF6B7280),
            ),
            const SizedBox(height: 14),
            Text(
              'Events could not be loaded',
              textAlign: TextAlign.center,
              style: GoogleFonts.instrumentSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Check your connection and try again.',
              textAlign: TextAlign.center,
              style: GoogleFonts.instrumentSans(
                fontSize: 13,
                color: const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () => onRetry(),
              icon: const Icon(FFIcons.karrowClockwise, size: 16),
              label: Text(
                'Try again',
                style: GoogleFonts.instrumentSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
