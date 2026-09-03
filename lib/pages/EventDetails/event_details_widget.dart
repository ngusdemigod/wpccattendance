import 'package:cached_network_image/cached_network_image.dart';

import '/auth/supabase_auth/auth_util.dart';
import '/backend/supabase/database/tables/attendance_view.dart';
import '/components/attendee_stack2_widget.dart';
import '/components/leaflet_map_widget.dart';
import '/flutter_flow/flutter_flow_choice_chips.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/form_field_controller.dart';
import '/flutter_flow/custom_functions.dart' as functions;
import '/pages/attendance_action/attendance_action_widget.dart';
import '/pages/event_geofence_debug/event_geofence_debug_widget.dart';
import '/shared/widgets/wpcc_shimmer.dart';
import '/services/geolocation_service.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'event_details_model.dart';
export 'event_details_model.dart';

class EventDetailsWidget extends StatefulWidget {
  const EventDetailsWidget({
    super.key,
    required this.eventId,
    required this.title,
    required this.desc,
    required this.indate,
    required this.outdate,
    required this.location,
    this.totalWorkers,
    this.imageUrl,
    this.latitude,
    this.longitude,
    bool? isglobal,
  }) : isglobal = isglobal ?? true;

  final String eventId;
  final String? title;
  final String? desc;
  final DateTime? indate;
  final DateTime? outdate;
  final String? location;
  final int? totalWorkers;
  final String? imageUrl;
  final double? latitude;
  final double? longitude;
  final bool isglobal;

  static String routeName = 'EventDetails';
  static String routePath = '/eventDetails';

  @override
  State<EventDetailsWidget> createState() => _EventDetailsWidgetState();
}

class _EventDetailsWidgetState extends State<EventDetailsWidget> {
  late EventDetailsModel _model;
  late Future<AttendanceViewRow?> _attendanceFuture;
  Future<List<AttendanceViewRow>>? _attendeesFuture;
  AttendanceViewRow? _attendanceCache;
  bool _attendanceRefreshing = false;
  bool _attendanceBusy = false;
  bool _attendanceHovered = false;
  late final VoidCallback _appStateListener;
  Timer? _titleTapResetTimer;
  int _titleTapCount = 0;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => EventDetailsModel());
    _appStateListener = _handleAppStateChange;
    FFAppState().addListener(_appStateListener);
    _attendanceFuture = _trackAttendanceFuture(_loadAttendance());
    _model.choiceChipsValueController = FormFieldController<List<String>>(
      const ['Details'],
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _titleTapResetTimer?.cancel();
    FFAppState().removeListener(_appStateListener);
    _model.dispose();
    super.dispose();
  }

  String _safeText(String? value, String fallback) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return fallback;
    }
    return trimmed;
  }

  String _eventTitle() => _safeText(widget.title, 'Event details');

  String _eventDescription() =>
      _safeText(widget.desc, 'Description unavailable');

  bool _isUpcomingEvent() =>
      widget.indate?.isAfter(getCurrentTimestamp) ?? false;

  bool _isAttendeesSection() =>
      !_isUpcomingEvent() && _model.choiceChipsValue == 'Attendees';

  bool _isDarkMode(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  Color _pageBackground(BuildContext context) {
    return _isDarkMode(context)
        ? const Color(0xFF0F1112)
        : const Color(0xFFFCFBF9);
  }

  Color _surfaceColor(BuildContext context) {
    return _isDarkMode(context) ? const Color(0xFF191C1E) : Colors.white;
  }

  Color _secondarySurfaceColor(BuildContext context) {
    return _isDarkMode(context)
        ? const Color(0xFF222527)
        : const Color(0xFFF4EFE6);
  }

  Color _hairlineColor(BuildContext context) {
    return _isDarkMode(context)
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0x14171312);
  }

  Color _mutedColor(BuildContext context) {
    return _isDarkMode(context)
        ? const Color(0xFFA5ABAE)
        : const Color(0xFF8D7D70);
  }

  Widget _eventHeroImage() {
    final imageUrl = widget.imageUrl?.trim() ?? '';
    if (imageUrl.isEmpty) {
      return Image.asset(
        'assets/images/images.jpg',
        fit: BoxFit.cover,
        alignment: const Alignment(0, 0),
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      alignment: const Alignment(0, 0),
      errorWidget: (context, url, error) {
        return Image.asset(
          'assets/images/images.jpg',
          fit: BoxFit.cover,
          alignment: const Alignment(0, 0),
        );
      },
    );
  }

  String _eventLocation() {
    final explicitLocation = widget.location?.trim() ?? '';
    if (explicitLocation.isNotEmpty) {
      return explicitLocation;
    }
    return _userBranchName();
  }

  double _eventLatitude() =>
      widget.latitude ?? GeolocationService.churchLatitude;

  double _eventLongitude() =>
      widget.longitude ?? GeolocationService.churchLongitude;

  void _openGeofenceDebug() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EventGeofenceDebugWidget(
          title: _eventTitle(),
          location: _eventLocation(),
          latitude: _eventLatitude(),
          longitude: _eventLongitude(),
          radiusMeters: 30,
        ),
      ),
    );
  }

  void _handleTitleTap() {
    _titleTapCount += 1;
    _titleTapResetTimer?.cancel();
    _titleTapResetTimer = Timer(const Duration(milliseconds: 500), () {
      _titleTapCount = 0;
    });

    if (_titleTapCount >= 3) {
      _titleTapResetTimer?.cancel();
      _titleTapCount = 0;
      _openGeofenceDebug();
    }
  }

  String _userBranchName() {
    final jwt = functions.decodeSupabaseJWT(currentJwtToken);
    final branch = getJsonField(jwt, r'''$.wpbranch''').toString().trim();
    if (branch.isEmpty || branch == 'null') {
      return 'Branch unavailable';
    }
    return branch;
  }

  String _hostName() {
    return 'Adeshina Gentry';
  }

  String _hostSubtitle() {
    return 'Event Host/Organizer';
  }

  String _dateLabel() {
    final start = widget.indate ?? getCurrentTimestamp;
    return dateTimeFormat('MMMEd', start);
  }

  String _timeRangeLabel() {
    final start = widget.indate ?? getCurrentTimestamp;
    final end = widget.outdate ?? start.add(const Duration(hours: 2));
    return '${dateTimeFormat("jm", start)} - ${dateTimeFormat("jm", end)} (GMT+1)';
  }

  Future<AttendanceViewRow?> _loadAttendance() async {
    if (widget.eventId.trim().isEmpty || currentUserUid.isEmpty) {
      return null;
    }

    final rows = await AttendanceViewTable().queryRows(
      queryFn: (q) => q
          .eq('event_id', widget.eventId)
          .eq('user_id', currentUserUid)
          .order('attendance_created_at', ascending: false),
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return rows.first;
  }

  Future<AttendanceViewRow?> _trackAttendanceFuture(
    Future<AttendanceViewRow?> future,
  ) {
    return future.then((value) {
      if (mounted) {
        setState(() {
          _attendanceCache = value;
        });
      }
      return value;
    });
  }

  void _handleAppStateChange() {
    if (!mounted || _attendanceRefreshing) {
      return;
    }
    _refreshAttendance();
  }

  Future<void> _refreshAttendance() async {
    if (!mounted || _attendanceRefreshing) {
      return;
    }
    _attendanceRefreshing = true;
    try {
      setState(() {
        _attendanceFuture = _trackAttendanceFuture(_loadAttendance());
        _attendeesFuture = null;
      });
      await _attendanceFuture;
    } finally {
      _attendanceRefreshing = false;
    }
  }

  String _timeText(DateTime? value) {
    if (value == null) {
      return 'N/A';
    }
    return dateTimeFormat('jm', value);
  }

  String _checkInText(AttendanceViewRow? row) {
    if (row == null) {
      return 'N/A';
    }
    return _timeText(row.attendanceCreatedAt);
  }

  String _checkOutText(AttendanceViewRow? row) {
    if (row == null) {
      return 'N/A';
    }
    if (row.clockout == null) {
      return 'Pending';
    }
    return _timeText(row.clockout);
  }

  String _attendanceButtonText(AttendanceViewRow? row) {
    if (row == null) {
      return 'Mark Present';
    }
    if (row.clockout == null) {
      return 'Clock Out';
    }
    return 'Send Reviews';
  }

  Future<void> _openAttendanceAction({
    required bool clockOut,
  }) async {
    if (_attendanceBusy || !mounted) {
      return;
    }

    setState(() {
      _attendanceBusy = true;
    });

    try {
      await context.pushNamed(
        AttendanceActionWidget.routeName,
        queryParameters: {
          'eventId': widget.eventId,
          'clockOut': clockOut.toString(),
        },
      );
      if (mounted) {
        await _refreshAttendance();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open attendance action: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _attendanceBusy = false;
        });
      }
    }
  }

  Widget _actionButton({
    required BuildContext context,
    required String label,
    required bool selected,
    required bool hovered,
    required ValueChanged<bool> onHover,
    required VoidCallback onTap,
  }) {
    final backgroundColor = selected
        ? (hovered ? const Color(0xFFE45AC2) : const Color(0xFFC5099C))
        : (hovered ? const Color(0xFF3A3A3A) : const Color(0xFF2B2B2B));
    final textColor = selected
        ? Colors.white
        : (hovered ? const Color(0xFFF2F2F2) : const Color(0xFFB0B0B0));

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => onHover(true),
      onExit: (_) => onHover(false),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        onHover: onHover,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: FlutterFlowTheme.of(context).bodyMedium.override(
                  font: GoogleFonts.instrumentSans(
                    fontWeight: FontWeight.w700,
                    fontStyle:
                        FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                  ),
                  color: textColor,
                  fontSize: 14,
                  letterSpacing: 0.0,
                  fontWeight: FontWeight.w700,
                  fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                ),
          ),
        ),
      ),
    );
  }

  Widget _timeColumn(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: FlutterFlowTheme.of(context).bodySmall.override(
                font: GoogleFonts.instrumentSans(
                  fontWeight: FontWeight.w400,
                  fontStyle: FlutterFlowTheme.of(context).bodySmall.fontStyle,
                ),
                color: _mutedColor(context),
                fontSize: 10,
                letterSpacing: 0.0,
                fontWeight: FontWeight.w400,
                fontStyle: FlutterFlowTheme.of(context).bodySmall.fontStyle,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: FlutterFlowTheme.of(context).bodyMedium.override(
                font: GoogleFonts.instrumentSans(
                  fontWeight: FontWeight.w600,
                  fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                ),
                color: FlutterFlowTheme.of(context).primaryText,
                fontSize: 18,
                letterSpacing: 0.0,
                fontWeight: FontWeight.w600,
                fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
              ),
        ),
      ],
    );
  }

  Future<List<AttendanceViewRow>> _fetchAttendees() async {
    if (widget.eventId.trim().isEmpty) {
      return [];
    }
    return AttendanceViewTable().queryRows(
      queryFn: (q) => q
          .eq('event_id', widget.eventId)
          .order('attendance_created_at', ascending: false),
      limit: 100,
    );
  }

  Future<List<AttendanceViewRow>> _attendeesOnce() =>
      _attendeesFuture ??= _fetchAttendees();

  Widget _buildAttendeeCard(BuildContext context, AttendanceViewRow attendee) {
    final checkInTime = _timeText(attendee.attendanceCreatedAt);
    final isClockingIn =
        attendee.attendanceCreatedAt != null && attendee.clockout == null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _secondarySurfaceColor(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _hairlineColor(context)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _hairlineColor(context), width: 2),
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/logo.jpg',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    attendee.profileFullName ??
                        attendee.attendanceFullname ??
                        'Unknown',
                    style: FlutterFlowTheme.of(context).bodyLarge.override(
                          font: GoogleFonts.instrumentSans(
                            fontWeight: FontWeight.w600,
                            fontStyle:
                                FlutterFlowTheme.of(context).bodyLarge.fontStyle,
                          ),
                          color: FlutterFlowTheme.of(context).primaryText,
                          fontSize: 14,
                          letterSpacing: 0.0,
                          fontWeight: FontWeight.w600,
                          fontStyle:
                              FlutterFlowTheme.of(context).bodyLarge.fontStyle,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    attendee.departmentName ?? 'No Department',
                    style: FlutterFlowTheme.of(context).bodySmall.override(
                          font: GoogleFonts.instrumentSans(
                            fontWeight: FontWeight.w400,
                            fontStyle:
                                FlutterFlowTheme.of(context).bodySmall.fontStyle,
                          ),
                          color: _mutedColor(context),
                          fontSize: 12,
                          letterSpacing: 0.0,
                          fontWeight: FontWeight.w400,
                          fontStyle:
                              FlutterFlowTheme.of(context).bodySmall.fontStyle,
                        ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  checkInTime,
                  style: FlutterFlowTheme.of(context).bodyLarge.override(
                        font: GoogleFonts.instrumentSans(
                          fontWeight: FontWeight.w600,
                          fontStyle:
                              FlutterFlowTheme.of(context).bodyLarge.fontStyle,
                        ),
                        color: const Color(0xFFFFA941),
                        fontSize: 14,
                        letterSpacing: 0.0,
                        fontWeight: FontWeight.w600,
                        fontStyle:
                            FlutterFlowTheme.of(context).bodyLarge.fontStyle,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  isClockingIn ? 'Clocked In' : 'Clocked Out',
                  style: FlutterFlowTheme.of(context).bodySmall.override(
                        font: GoogleFonts.instrumentSans(
                          fontWeight: FontWeight.w400,
                          fontStyle:
                              FlutterFlowTheme.of(context).bodySmall.fontStyle,
                        ),
                        color: isClockingIn
                            ? const Color(0xFF41FF88)
                            : _mutedColor(context),
                        fontSize: 11,
                        letterSpacing: 0.0,
                        fontWeight: FontWeight.w400,
                        fontStyle:
                            FlutterFlowTheme.of(context).bodySmall.fontStyle,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopActionButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: _surfaceColor(context).withValues(alpha: 0.86),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _hairlineColor(context)),
        ),
        child: Icon(
          icon,
          color: _isDarkMode(context) ? Colors.white : const Color(0xFF201A16),
          size: 20,
        ),
      ),
    );
  }

  Widget _buildMetaRow(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String actionLabel,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: _isDarkMode(context) ? Colors.white : const Color(0xFF201A16),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            value,
            style: FlutterFlowTheme.of(context).bodyLarge.override(
                  font: GoogleFonts.instrumentSans(
                    fontWeight: FontWeight.w400,
                    fontStyle: FlutterFlowTheme.of(context).bodyLarge.fontStyle,
                  ),
                  color: FlutterFlowTheme.of(context).primaryText,
                  fontSize: 18,
                  letterSpacing: 0.0,
                  fontWeight: FontWeight.w400,
                  fontStyle: FlutterFlowTheme.of(context).bodyLarge.fontStyle,
                ),
          ),
        ),
        Text(
          actionLabel,
          style: FlutterFlowTheme.of(context).bodyMedium.override(
                font: GoogleFonts.instrumentSans(
                  fontWeight: FontWeight.w400,
                  fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                ),
                color: _mutedColor(context),
                fontSize: 15,
                letterSpacing: 0.0,
                fontWeight: FontWeight.w400,
                fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
              ),
        ),
      ],
    );
  }

  Widget _buildAttendanceSummary(
    BuildContext context,
    AttendanceViewRow? attendanceRow,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: _secondarySurfaceColor(context),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: _timeColumn(
              context,
              label: 'Check-in Time',
              value: _checkInText(attendanceRow),
            ),
          ),
          Container(
            width: 1,
            height: 52,
            color: _hairlineColor(context),
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                wrapWithModel(
                  model: _model.attendeeStackModel,
                  updateCallback: () => safeSetState(() {}),
                  child: AttendeeStack2Widget(
                    totalWorkers: widget.totalWorkers,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Attendees',
                  style: FlutterFlowTheme.of(context).bodySmall.override(
                        font: GoogleFonts.instrumentSans(
                          fontWeight: FontWeight.w400,
                          fontStyle:
                              FlutterFlowTheme.of(context).bodySmall.fontStyle,
                        ),
                        color: _mutedColor(context),
                        letterSpacing: 0.0,
                        fontWeight: FontWeight.w400,
                        fontStyle:
                            FlutterFlowTheme.of(context).bodySmall.fontStyle,
                      ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 52,
            color: _hairlineColor(context),
          ),
          Expanded(
            child: _timeColumn(
              context,
              label: 'Check-out Time',
              value: _checkOutText(attendanceRow),
            ),
          ),
        ].divide(const SizedBox(width: 12)),
      ),
    );
  }

  Widget _buildHostCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surfaceColor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _hairlineColor(context)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              'assets/images/logo.jpg',
              width: 56,
              height: 56,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _hostName(),
                        style: FlutterFlowTheme.of(context).bodyLarge.override(
                              font: GoogleFonts.instrumentSans(
                                fontWeight: FontWeight.w600,
                                fontStyle: FlutterFlowTheme.of(context)
                                    .bodyLarge
                                    .fontStyle,
                              ),
                              color: FlutterFlowTheme.of(context).primaryText,
                              letterSpacing: 0.0,
                              fontWeight: FontWeight.w600,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .bodyLarge
                                  .fontStyle,
                            ),
                      ),
                    ),
                    const Icon(
                      Icons.verified_rounded,
                      color: Color(0xFFC5099C),
                      size: 18,
                    ),
                  ],
                ),
                Text(
                  _hostSubtitle(),
                  style: FlutterFlowTheme.of(context).bodySmall.override(
                        font: GoogleFonts.instrumentSans(
                          fontWeight:
                              FlutterFlowTheme.of(context).bodySmall.fontWeight,
                          fontStyle:
                              FlutterFlowTheme.of(context).bodySmall.fontStyle,
                        ),
                        color: _mutedColor(context),
                        letterSpacing: 0.0,
                        fontWeight:
                            FlutterFlowTheme.of(context).bodySmall.fontWeight,
                        fontStyle:
                            FlutterFlowTheme.of(context).bodySmall.fontStyle,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendancePrimaryButton(
    BuildContext context,
    AttendanceViewRow? row,
  ) {
    return SizedBox(
      width: double.infinity,
      child: _actionButton(
        context: context,
        label: _attendanceButtonText(row),
        selected: true,
        hovered: _attendanceHovered,
        onHover: (value) => safeSetState(() {
          _attendanceHovered = value;
        }),
        onTap: _attendanceBusy
            ? () {}
            : () {
                if (row == null) {
                  _openAttendanceAction(clockOut: false);
                } else if (row.clockout == null) {
                  _openAttendanceAction(clockOut: true);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Review submitted.')),
                  );
                }
              },
      ),
    );
  }

  Widget _buildAttendeesSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${widget.totalWorkers ?? 0} Total Attendees',
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                      font: GoogleFonts.instrumentSans(
                        fontWeight: FontWeight.w400,
                        fontStyle:
                            FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                      ),
                      color: _mutedColor(context),
                      fontSize: 12,
                      letterSpacing: 0.0,
                      fontWeight: FontWeight.w400,
                      fontStyle:
                          FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                    ),
              ),
              FutureBuilder<List<AttendanceViewRow>>(
                future: _attendeesOnce(),
                builder: (context, snapshot) {
                  final attendees = snapshot.data ?? [];
                  final checkedInCount = attendees
                      .where((a) =>
                          a.attendanceCreatedAt != null && a.clockout == null)
                      .length;
                  return Text(
                    '$checkedInCount Checked In',
                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                          font: GoogleFonts.instrumentSans(
                            fontWeight: FontWeight.w400,
                            fontStyle:
                                FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                          ),
                          color: _mutedColor(context),
                          fontSize: 12,
                          letterSpacing: 0.0,
                          fontWeight: FontWeight.w400,
                          fontStyle:
                              FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                        ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 18),
          FutureBuilder<List<AttendanceViewRow>>(
            future: _attendeesOnce(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: WpccShimmerCard(
                    height: 160,
                    radius: 30,
                    child: SizedBox.expand(),
                  ),
                );
              }
              final attendees = snapshot.data ?? [];
              if (attendees.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text(
                      'No attendees yet',
                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                            color: _mutedColor(context),
                          ),
                    ),
                  ),
                );
              }
              return ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                primary: false,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: attendees.length,
                itemBuilder: (context, index) {
                  return _buildAttendeeCard(context, attendees[index]);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsSection(
    BuildContext context,
    AttendanceViewRow? attendanceRow,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _handleTitleTap,
            child: Text(
              _eventTitle(),
              textAlign: TextAlign.center,
              style: FlutterFlowTheme.of(context).headlineMedium.override(
                    font: GoogleFonts.instrumentSans(
                      fontWeight: FontWeight.w600,
                      fontStyle:
                          FlutterFlowTheme.of(context).headlineMedium.fontStyle,
                    ),
                    color: FlutterFlowTheme.of(context).primaryText,
                    fontSize: 22,
                    letterSpacing: 0.0,
                    fontWeight: FontWeight.w600,
                    fontStyle:
                        FlutterFlowTheme.of(context).headlineMedium.fontStyle,
                  ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _eventDescription(),
            textAlign: TextAlign.center,
            style: FlutterFlowTheme.of(context).bodyMedium.override(
                  font: GoogleFonts.instrumentSans(
                    fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                    fontStyle:
                        FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                  ),
                  color: _mutedColor(context),
                  fontSize: 15,
                  letterSpacing: 0.0,
                  fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                  fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                  lineHeight: 1.5,
                ),
          ),
          const SizedBox(height: 22),
          _buildMetaRow(
            context,
            icon: Icons.calendar_today_outlined,
            value: _dateLabel(),
            actionLabel: 'Add',
          ),
          const SizedBox(height: 18),
          _buildMetaRow(
            context,
            icon: Icons.schedule_outlined,
            value: _timeRangeLabel(),
            actionLabel: 'Add',
          ),
          const SizedBox(height: 18),
          _buildMetaRow(
            context,
            icon: Icons.location_on_outlined,
            value: _eventLocation(),
            actionLabel: 'Find',
          ),
          const SizedBox(height: 24),
          _buildAttendanceSummary(context, attendanceRow),
          const SizedBox(height: 18),
          _buildHostCard(context),
          if (!_isUpcomingEvent()) ...[
            const SizedBox(height: 20),
            _buildAttendancePrimaryButton(context, attendanceRow),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                color: _secondarySurfaceColor(context),
                borderRadius: BorderRadius.circular(18),
              ),
              padding: const EdgeInsets.all(4),
              child: FlutterFlowChoiceChips(
                options: const [
                  ChipData('Details'),
                  ChipData('Attendees'),
                ],
                onChanged: (val) => safeSetState(() {
                  _model.choiceChipsValue = val?.firstOrNull;
                }),
                selectedChipStyle: ChipStyle(
                  backgroundColor: const Color(0xFFC5099C),
                  textStyle: FlutterFlowTheme.of(context).bodyMedium.override(
                        font: GoogleFonts.instrumentSans(
                          fontWeight: FontWeight.w600,
                        ),
                        color: Colors.white,
                        letterSpacing: 0.0,
                      ),
                  iconColor: Colors.white,
                  iconSize: 10.0,
                  elevation: 0.0,
                  borderRadius: BorderRadius.circular(14.0),
                ),
                unselectedChipStyle: ChipStyle(
                  backgroundColor: Colors.transparent,
                  textStyle: FlutterFlowTheme.of(context).bodyMedium.override(
                        font: GoogleFonts.instrumentSans(
                          fontWeight: FontWeight.w400,
                        ),
                        color: _mutedColor(context),
                        letterSpacing: 0.0,
                      ),
                  iconColor: _mutedColor(context),
                  iconSize: 10.0,
                  elevation: 0.0,
                  borderRadius: BorderRadius.circular(14.0),
                ),
                chipSpacing: 8.0,
                rowSpacing: 8.0,
                multiselect: false,
                initialized: _model.choiceChipsValue != null,
                alignment: WrapAlignment.center,
                controller: _model.choiceChipsValueController!,
                wrapped: true,
              ),
            ),
            const SizedBox(height: 24),
          ],
          Text(
            'Directions on the map',
            style: FlutterFlowTheme.of(context).titleMedium.override(
                  font: GoogleFonts.instrumentSans(
                    fontWeight: FontWeight.w600,
                    fontStyle: FlutterFlowTheme.of(context).titleMedium.fontStyle,
                  ),
                  color: FlutterFlowTheme.of(context).primaryText,
                  letterSpacing: 0.0,
                  fontWeight: FontWeight.w600,
                  fontStyle: FlutterFlowTheme.of(context).titleMedium.fontStyle,
                ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Container(
              height: 320,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: _hairlineColor(context)),
              ),
              child: IgnorePointer(
                child: LeafletMapWidget(
                  height: 320,
                  title: _eventTitle(),
                  location: _eventLocation(),
                  latitude: _eventLatitude(),
                  longitude: _eventLongitude(),
                  radiusMeters: 30,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentCard(
    BuildContext context,
    AttendanceViewRow? attendanceRow,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: _surfaceColor(context),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: _isAttendeesSection()
          ? _buildAttendeesSection(context)
          : _buildDetailsSection(context, attendanceRow),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Title(
      title: 'EventDetails',
      color: FlutterFlowTheme.of(context).primary.withAlpha(0XFF),
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
          FocusManager.instance.primaryFocus?.unfocus();
        },
        child: Scaffold(
          key: scaffoldKey,
          backgroundColor: _pageBackground(context),
          body: FutureBuilder<AttendanceViewRow?>(
            future: _attendanceFuture,
            builder: (context, snapshot) {
              final attendanceRow = snapshot.data ?? _attendanceCache;
              return SingleChildScrollView(
                primary: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: 380,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(36),
                              bottomRight: Radius.circular(36),
                            ),
                            child: _eventHeroImage(),
                          ),
                          Container(
                            decoration: const BoxDecoration(
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(36),
                                bottomRight: Radius.circular(36),
                              ),
                              gradient: LinearGradient(
                                colors: [
                                  Color(0x22000000),
                                  Color(0x14000000),
                                  Color(0x3D000000),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                          SafeArea(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildTopActionButton(
                                    context,
                                    icon: Icons.arrow_back_ios_new_rounded,
                                    onTap: () => context.safePop(),
                                  ),
                                  Expanded(
                                    child: Column(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(10),
                                          child: Image.asset(
                                            'assets/images/logo.jpg',
                                            width: 52,
                                            height: 52,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'WISDOM POWER\nCHRISTIAN CENTRE',
                                          textAlign: TextAlign.center,
                                          style: FlutterFlowTheme.of(context)
                                              .labelSmall
                                              .override(
                                                font: GoogleFonts.instrumentSans(
                                                  fontWeight: FontWeight.w700,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(context)
                                                          .labelSmall
                                                          .fontStyle,
                                                ),
                                                color: Colors.white,
                                                fontSize: 10,
                                                letterSpacing: 0.0,
                                                fontWeight: FontWeight.w700,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .labelSmall
                                                        .fontStyle,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      _buildTopActionButton(
                                        context,
                                        icon: Icons.ios_share_outlined,
                                        onTap: () {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Share is not configured yet.',
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      const SizedBox(width: 10),
                                      _buildTopActionButton(
                                        context,
                                        icon: Icons.favorite_border_rounded,
                                        onTap: () {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Favorites are not available yet.',
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Transform.translate(
                      offset: const Offset(0, -28),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: _buildContentCard(context, attendanceRow),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
