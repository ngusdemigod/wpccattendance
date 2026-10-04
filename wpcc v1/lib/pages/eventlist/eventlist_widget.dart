import '/auth/supabase_auth/auth_util.dart';
import '/backend/supabase/supabase.dart';
import '/components/customprogressbar_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/loaders/a_t_t_eventlist_loader/a_t_t_eventlist_loader_widget.dart';
import '/pages/create_e_v_e_n_t/create_e_v_e_n_t_widget.dart';
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'eventlist_model.dart';
export 'eventlist_model.dart';

class EventlistWidget extends StatefulWidget {
  const EventlistWidget({super.key});

  static String routeName = 'eventlist';
  static String routePath = '/eventlist';

  @override
  State<EventlistWidget> createState() => _EventlistWidgetState();
}

class _EventlistWidgetState extends State<EventlistWidget> {
  late EventlistModel _model;
  late Future<List<EventsAttendanceViewRow>> _activeEventsFuture;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  Map<String, dynamic>? _jwtClaims() {
    final jwt = functions.decodeSupabaseJWT(currentJwtToken);
    if (jwt is Map<String, dynamic>) {
      return jwt;
    }
    return null;
  }

  String _fullNameFromJwt() {
    final claims = _jwtClaims();
    final metadata = claims?['user_metadata'];
    final fullName = metadata is Map<String, dynamic>
        ? metadata['full_name']?.toString().trim() ?? ''
        : '';
    if (fullName.isNotEmpty) {
      return fullName;
    }
    if (currentUserDisplayName.isNotEmpty) {
      return currentUserDisplayName;
    }
    return 'User';
  }

  String _initialsFromJwt() {
    final initials = functions.getInitials(_fullNameFromJwt());
    return initials.isNotEmpty ? initials : 'U';
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => EventlistModel());
    _activeEventsFuture = _loadActiveEvents();

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  Future<List<EventsAttendanceViewRow>> _loadActiveEvents() {
    return FFAppState()
        .listOfEvents(
          uniqueQueryKey: 'active_events',
          requestFn: () => EventsAttendanceViewTable().queryRows(
            queryFn: (q) => q
                .eqOrNull(
                  'is_active',
                  true,
                )
                .order('created_time'),
          ),
        )
        .then((result) {
      _model.requestCompleted3 = true;
      return result;
    });
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  void _openEventDetails(EventsAttendanceViewRow row) {
    final eventTitle = row.title;
    if (eventTitle == null || eventTitle.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This event is missing a title.'),
        ),
      );
      return;
    }

    context.pushNamedAuth(
      EventDetailsScreen.routeName,
      mounted,
      pathParameters: {'eventId': row.eventId ?? ''},
    );
  }

  List<EventsAttendanceViewRow> _sortByStartTime(
    List<EventsAttendanceViewRow> rows,
  ) {
    final sortedRows = [...rows];
    sortedRows.sort((a, b) {
      final aStart = a.eventStartDate ?? a.createdTime;
      final bStart = b.eventStartDate ?? b.createdTime;
      if (aStart == null && bStart == null) return 0;
      if (aStart == null) return 1;
      if (bStart == null) return -1;
      return aStart.compareTo(bStart);
    });
    return sortedRows;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<WorkerProfilesRow>>(
      future: FFAppState()
          .workforce(
        requestFn: () => WorkerProfilesTable().queryRows(
          queryFn: (q) => q,
          limit: 1,
        ),
      )
          .then((result) {
        _model.requestCompleted2 = true;
        return result;
      }),
      builder: (context, snapshot) {
        // Customize what your widget looks like when it's loading.
        if (!snapshot.hasData) {
          return Scaffold(
            backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
            body: const Padding(
              padding: EdgeInsets.all(24.0),
              child: ATTEventlistLoaderWidget(),
            ),
          );
        }
        List<WorkerProfilesRow> eventlistWorkerProfilesRowList = snapshot.data!;

        return Title(
            title: 'eventlist',
            color: FlutterFlowTheme.of(context).primary.withAlpha(0XFF),
            child: GestureDetector(
              onTap: () {
                FocusScope.of(context).unfocus();
                FocusManager.instance.primaryFocus?.unfocus();
              },
              child: Scaffold(
                key: scaffoldKey,
                backgroundColor: const Color(0xFF0F0F0F),
                floatingActionButton: Builder(
                  builder: (context) => FloatingActionButton(
                    onPressed: () async {
                      await showDialog(
                        barrierColor: const Color(0xC1000000),
                        context: context,
                        builder: (dialogContext) {
                          return Dialog(
                            elevation: 0,
                            insetPadding: EdgeInsets.zero,
                            backgroundColor: Colors.transparent,
                            alignment: const AlignmentDirectional(0.0, 0.0)
                                .resolve(Directionality.of(context)),
                            child: GestureDetector(
                              onTap: () {
                                FocusScope.of(dialogContext).unfocus();
                                FocusManager.instance.primaryFocus?.unfocus();
                              },
                              child: const CreateEVENTWidget(),
                            ),
                          );
                        },
                      );
                    },
                    backgroundColor: Colors.white,
                    elevation: 8.0,
                    child: Icon(
                      Icons.add_rounded,
                      color: FlutterFlowTheme.of(context).primaryBackground,
                      size: 24.0,
                    ),
                  ),
                ),
                body: Container(
                  decoration: const BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(0.0, -0.8),
                      radius: 1.1,
                      colors: [
                        Color(0x332C1407),
                        Color(0xFF0F0F0F),
                        Color(0xFF090909),
                      ],
                      stops: [0.0, 0.5, 1.0],
                    ),
                  ),
                  child: Align(
                    alignment: const AlignmentDirectional(0.0, -1.0),
                    child: Container(
                      constraints: const BoxConstraints(
                        maxWidth: 700.0,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: ListView(
                          padding: EdgeInsets.zero,
                          primary: false,
                          shrinkWrap: true,
                          scrollDirection: Axis.vertical,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Align(
                                  alignment: const AlignmentDirectional(-1.0, 0.0),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        dateTimeFormat(
                                            "EEEE dd", getCurrentTimestamp),
                                        style: FlutterFlowTheme.of(context)
                                            .titleSmall
                                            .override(
                                              font: GoogleFonts.instrumentSans(
                                                fontWeight:
                                                    FlutterFlowTheme.of(context)
                                                        .titleSmall
                                                        .fontWeight,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .titleSmall
                                                        .fontStyle,
                                              ),
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .secondaryText,
                                              letterSpacing: 0.0,
                                              fontWeight:
                                                  FlutterFlowTheme.of(context)
                                                      .titleSmall
                                                      .fontWeight,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .titleSmall
                                                      .fontStyle,
                                            ),
                                      ),
                                      Icon(
                                        Icons.circle,
                                        color:
                                            FlutterFlowTheme.of(context).error,
                                        size: 5.0,
                                      ),
                                      Text(
                                        dateTimeFormat(
                                            "jm", getCurrentTimestamp),
                                        style: FlutterFlowTheme.of(context)
                                            .labelLarge
                                            .override(
                                              font: GoogleFonts.nunito(
                                                fontWeight: FontWeight.normal,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .labelLarge
                                                        .fontStyle,
                                              ),
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .secondaryText,
                                              fontSize: 10.0,
                                              letterSpacing: 0.0,
                                              fontWeight: FontWeight.normal,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .labelLarge
                                                      .fontStyle,
                                              lineHeight: 1.3,
                                            ),
                                      ),
                                    ].divide(const SizedBox(width: 4.0)),
                                  ),
                                ),
                                InkWell(
                                  borderRadius: BorderRadius.circular(999),
                                  onTap: () => context.goNamedAuth(
                                    MyProfileWidget.routeName,
                                    mounted,
                                    ignoreRedirect: true,
                                  ),
                                  child: Container(
                                    width: 38,
                                    height: 38,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: [
                                          Color(0xFFC5099C),
                                          Color(0xFFE45AC2),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Color(0x33111111),
                                          blurRadius: 12,
                                          offset: Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      _initialsFromJwt(),
                                      style: FlutterFlowTheme.of(context)
                                          .labelLarge
                                          .override(
                                            font: GoogleFonts.instrumentSans(
                                              fontWeight: FontWeight.w800,
                                            ),
                                            color: Colors.white,
                                            fontSize: 13,
                                            letterSpacing: 0.0,
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Align(
                              alignment: const AlignmentDirectional(-1.0, 0.0),
                              child: Padding(
                                padding: const EdgeInsetsDirectional.fromSTEB(
                                    0.0, 24.0, 0.0, 14.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.max,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      getJsonField(
                                        functions
                                            .decodeSupabaseJWT(currentJwtToken),
                                        r'''$.wpbranch''',
                                      ).toString(),
                                      style: FlutterFlowTheme.of(context)
                                          .labelLarge
                                          .override(
                                            font: GoogleFonts.nunito(
                                              fontWeight: FontWeight.normal,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .labelLarge
                                                      .fontStyle,
                                            ),
                                            color: const Color(0xFF8DCC7A),
                                            fontSize: 10.0,
                                            letterSpacing: 0.0,
                                            fontWeight: FontWeight.normal,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .labelLarge
                                                    .fontStyle,
                                            lineHeight: 1.3,
                                          ),
                                    ),
                                    Text(
                                      getJsonField(
                                        functions
                                            .decodeSupabaseJWT(currentJwtToken),
                                        r'''$.full_name''',
                                      ).toString(),
                                      style: FlutterFlowTheme.of(context)
                                          .headlineMedium
                                          .override(
                                            font: GoogleFonts.instrumentSans(
                                              fontWeight:
                                                  FlutterFlowTheme.of(context)
                                                      .headlineMedium
                                                      .fontWeight,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .headlineMedium
                                                      .fontStyle,
                                            ),
                                            letterSpacing: 0.0,
                                            fontWeight:
                                                FlutterFlowTheme.of(context)
                                                    .headlineMedium
                                                    .fontWeight,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .headlineMedium
                                                    .fontStyle,
                                          ),
                                    ),
                                    Text(
                                      () {
                                        final jwt = functions
                                            .decodeSupabaseJWT(currentJwtToken);
                                        final role =
                                            getJsonField(jwt, r'''$.wprole''')
                                                .toString();
                                        if (role == 'admin' ||
                                            role == 'global admin') {
                                          return 'Admin';
                                        }
                                        return '${getJsonField(jwt, r'''$.wpdept''').toString()} Department';
                                      }(),
                                      style: FlutterFlowTheme.of(context)
                                          .labelLarge
                                          .override(
                                            font: GoogleFonts.nunito(
                                              fontWeight: FontWeight.normal,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .labelLarge
                                                      .fontStyle,
                                            ),
                                            color: FlutterFlowTheme.of(context)
                                                .primaryText,
                                            fontSize: 14.0,
                                            letterSpacing: 0.0,
                                            fontWeight: FontWeight.normal,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .labelLarge
                                                    .fontStyle,
                                            lineHeight: 1.3,
                                          ),
                                    ),
                                  ].divide(const SizedBox(height: 4.0)),
                                ),
                              ),
                            ),
                            FutureBuilder<List<EventsAttendanceViewRow>>(
                              future: _activeEventsFuture,
                              builder: (context, snapshot) {
                                // Customize what your widget looks like when it's loading.
                                if (!snapshot.hasData) {
                                  return const ATTEventlistLoaderWidget();
                                }
                                List<EventsAttendanceViewRow>
                                    listViewEventsAttendanceViewRowList =
                                    snapshot.data!;

                                return ListView.separated(
                                  padding: EdgeInsets.zero,
                                  shrinkWrap: true,
                                  scrollDirection: Axis.vertical,
                                  itemCount: listViewEventsAttendanceViewRowList
                                      .length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 8.0),
                                  itemBuilder: (context, listViewIndex) {
                                    final listViewEventsAttendanceViewRow =
                                        listViewEventsAttendanceViewRowList[
                                            listViewIndex];
                                    return InkWell(
                                      splashColor: Colors.transparent,
                                      focusColor: Colors.transparent,
                                      hoverColor: Colors.transparent,
                                      highlightColor: Colors.transparent,
                                      onTap: () => _openEventDetails(
                                        listViewEventsAttendanceViewRow,
                                      ),
                                      child: ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(16.0),
                                        child: Container(
                                          width: double.infinity,
                                          height: 180.0,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(16.0),
                                            image: DecorationImage(
                                              fit: BoxFit.cover,
                                              image: listViewEventsAttendanceViewRow
                                                              .featuredImage !=
                                                          null &&
                                                      listViewEventsAttendanceViewRow
                                                              .featuredImage !=
                                                          ''
                                                  ? CachedNetworkImageProvider(
                                                      listViewEventsAttendanceViewRow
                                                          .featuredImage!)
                                                  : const AssetImage(
                                                          'assets/images/image-placeholder2.jpg')
                                                      as ImageProvider,
                                            ),
                                          ),
                                          child: Stack(
                                            children: [
                                              Align(
                                                alignment: const AlignmentDirectional(
                                                    0.0, 1.0),
                                                child: Container(
                                                  width: double.infinity,
                                                  height: 120.0,
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      colors: [
                                                        Colors.transparent,
                                                        Colors.black
                                                            .withValues(alpha: 0.8),
                                                        Colors.black
                                                      ],
                                                      stops: const [0.0, 0.7, 1.0],
                                                      begin:
                                                          const AlignmentDirectional(
                                                              0.0, -1.0),
                                                      end: const AlignmentDirectional(
                                                          0, 1.0),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.all(16.0),
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.max,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Row(
                                                      mainAxisSize:
                                                          MainAxisSize.max,
                                                      children: [
                                                        Container(
                                                          width: 32.0,
                                                          height: 32.0,
                                                          decoration:
                                                              BoxDecoration(
                                                            color: FlutterFlowTheme
                                                                    .of(context)
                                                                .primary,
                                                            shape:
                                                                BoxShape.circle,
                                                          ),
                                                          child: Icon(
                                                            FFIcons
                                                                .kcalendarFill,
                                                            color: FlutterFlowTheme
                                                                    .of(context)
                                                                .primaryBackground,
                                                            size: 16.0,
                                                          ),
                                                        ),
                                                        Container(
                                                          decoration:
                                                              BoxDecoration(
                                                            color: FlutterFlowTheme
                                                                    .of(context)
                                                                .primaryBackground,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        20.0),
                                                          ),
                                                          child: Padding(
                                                            padding:
                                                                const EdgeInsetsDirectional
                                                                    .fromSTEB(
                                                                        10.0,
                                                                        6.0,
                                                                        10.0,
                                                                        6.0),
                                                            child: Text(
                                                              dateTimeFormat(
                                                                  "d MMM yyyy",
                                                                  listViewEventsAttendanceViewRow
                                                                      .eventStartDate),
                                                              style: FlutterFlowTheme
                                                                      .of(context)
                                                                  .bodyMedium
                                                                  .override(
                                                                    font: GoogleFonts
                                                                        .roboto(
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                    ),
                                                                    color: FlutterFlowTheme.of(
                                                                            context)
                                                                        .primaryText,
                                                                    fontSize:
                                                                        10.0,
                                                                    letterSpacing:
                                                                        0.0,
                                                                  ),
                                                            ),
                                                          ),
                                                        ),
                                                      ].divide(
                                                          const SizedBox(width: 8.0)),
                                                    ),
                                                    Row(
                                                      mainAxisSize:
                                                          MainAxisSize.max,
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .end,
                                                      children: [
                                                        Expanded(
                                                          child: Column(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Text(
                                                                valueOrDefault<
                                                                    String>(
                                                                  listViewEventsAttendanceViewRow
                                                                      .title,
                                                                  'Event Title',
                                                                ),
                                                                style: FlutterFlowTheme.of(
                                                                        context)
                                                                    .headlineSmall
                                                                    .override(
                                                                      font: GoogleFonts
                                                                          .roboto(
                                                                        fontWeight:
                                                                            FontWeight.bold,
                                                                      ),
                                                                      color: Colors
                                                                          .white,
                                                                      fontSize:
                                                                          18.0,
                                                                      letterSpacing:
                                                                          0.0,
                                                                    ),
                                                              ),
                                                              Text(
                                                                valueOrDefault<
                                                                    String>(
                                                                  listViewEventsAttendanceViewRow
                                                                      .description,
                                                                  'Event Description',
                                                                ),
                                                                maxLines: 1,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                                style: FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodySmall
                                                                    .override(
                                                                      font: GoogleFonts
                                                                          .roboto(),
                                                                      color: const Color(
                                                                          0xFFE0E0E0),
                                                                      fontSize:
                                                                          12.0,
                                                                    ),
                                                              ),
                                                            ].divide(const SizedBox(
                                                                height: 4.0)),
                                                          ),
                                                        ),
                                                        Container(
                                                          width: 44.0,
                                                          height: 44.0,
                                                          decoration:
                                                              const BoxDecoration(
                                                            color: Colors.white,
                                                            shape:
                                                                BoxShape.circle,
                                                          ),
                                                          alignment:
                                                              const AlignmentDirectional(
                                                                  0.0, 0.0),
                                                          child: RichText(
                                                            text: TextSpan(
                                                              children: [
                                                                TextSpan(
                                                                  text:
                                                                      '${listViewEventsAttendanceViewRow.activeWorker}',
                                                                  style:
                                                                      const TextStyle(
                                                                    color: Colors
                                                                        .black,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    fontSize:
                                                                        12.0,
                                                                  ),
                                                                ),
                                                                const TextSpan(
                                                                  text: '/',
                                                                  style:
                                                                      TextStyle(
                                                                    color: Color(
                                                                        0xFF757575),
                                                                    fontSize:
                                                                        14.0,
                                                                  ),
                                                                ),
                                                                TextSpan(
                                                                  text:
                                                                      '${listViewEventsAttendanceViewRow.totalWorkers}',
                                                                  style:
                                                                      const TextStyle(
                                                                    color: Color(
                                                                        0xFF757575),
                                                                    fontSize:
                                                                        8.0,
                                                                  ),
                                                                ),
                                                              ],
                                                              style: FlutterFlowTheme
                                                                      .of(context)
                                                                  .bodyMedium,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                SizedBox(
                                  width: 120.0,
                                  child: Divider(
                                    thickness: 1.0,
                                    color:
                                        FlutterFlowTheme.of(context).alternate,
                                  ),
                                ),
                              ],
                            ),
                            FutureBuilder<List<EventsAttendanceViewRow>>(
                              future: FFAppState()
                                  .listOfEvents(
                                  requestFn: () =>
                                    EventsAttendanceViewTable().queryRows(
                                  queryFn: (q) => q
                                      .eqOrNull(
                                        'is_active',
                                        false,
                                      )
                                      .order('event_start_date'),
                                ),
                              )
                                  .then((result) {
                                _model.requestCompleted1 = true;
                                return result;
                              }),
                              builder: (context, snapshot) {
                                // Customize what your widget looks like when it's loading.
                                if (!snapshot.hasData) {
                                  return const ATTEventlistLoaderWidget();
                                }
                                List<EventsAttendanceViewRow>
                                    listViewEventsAttendanceViewRowList =
                                    _sortByStartTime(snapshot.data!);

                                return RefreshIndicator(
                                  onRefresh: () async {
                                    FFAppState().clearListOfEventsCache();
                                    safeSetState(() {
                                      FFAppState().clearListOfEventsCache();
                                      _model.requestCompleted1 = false;
                                      _model.requestCompleted3 = false;
                                      _activeEventsFuture = _loadActiveEvents();
                                    });
                                    await _model.waitForRequestCompleted1();
                                    await _model.waitForRequestCompleted3();
                                    safeSetState(() {
                                      FFAppState().clearWorkforceCache();
                                      _model.requestCompleted2 = false;
                                    });
                                    await _model.waitForRequestCompleted2();
                                  },
                                  child: ListView.separated(
                                    padding: EdgeInsets.zero,
                                    shrinkWrap: true,
                                    scrollDirection: Axis.vertical,
                                    itemCount:
                                        listViewEventsAttendanceViewRowList
                                            .length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 8.0),
                                    itemBuilder: (context, listViewIndex) {
                                      final listViewEventsAttendanceViewRow =
                                          listViewEventsAttendanceViewRowList[
                                              listViewIndex];
                                      return InkWell(
                                        splashColor: Colors.transparent,
                                        focusColor: Colors.transparent,
                                        hoverColor: Colors.transparent,
                                        highlightColor: Colors.transparent,
                                        onTap: () => _openEventDetails(
                                          listViewEventsAttendanceViewRow,
                                        ),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(16.0),
                                          child: Container(
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              gradient: const LinearGradient(
                                                colors: [
                                                  Color(0xFF242424),
                                                  Color(0xFF181818)
                                                ],
                                                stops: [0.0, 1.0],
                                                begin: AlignmentDirectional(
                                                    0.0, -1.0),
                                                end: AlignmentDirectional(
                                                    0, 1.0),
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(16.0),
                                              border: Border.all(
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .divider,
                                                width: 1.0,
                                              ),
                                            ),
                                            alignment:
                                                const AlignmentDirectional(0.0, 0.0),
                                            child: Align(
                                              alignment: const AlignmentDirectional(
                                                  0.0, 0.0),
                                              child: Padding(
                                                padding: const EdgeInsets.all(12.0),
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.max,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: [
                                                    Row(
                                                      mainAxisSize:
                                                          MainAxisSize.max,
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        Expanded(
                                                          flex: 2,
                                                          child: Row(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .max,
                                                            children: [
                                                              Icon(
                                                                FFIcons
                                                                    .kpieChart,
                                                                color: FlutterFlowTheme.of(
                                                                        context)
                                                                    .primaryText,
                                                                size: 16.0,
                                                              ),
                                                              Expanded(
                                                                child: AutoSizeText(
                                                                  valueOrDefault<
                                                                      String>(
                                                                    listViewEventsAttendanceViewRow
                                                                        .title,
                                                                    '{{event title}}',
                                                                  ),
                                                                  maxLines:
                                                                      2,
                                                                  minFontSize:
                                                                      12.0,
                                                                  style: FlutterFlowTheme.of(
                                                                          context)
                                                                      .labelLarge
                                                                      .override(
                                                                        font:
                                                                            GoogleFonts.nunito(
                                                                          fontWeight: FontWeight.w600,
                                                                          fontStyle: FlutterFlowTheme.of(context).labelLarge.fontStyle,
                                                                        ),
                                                                        color:
                                                                            FlutterFlowTheme.of(context).primaryText,
                                                                        fontSize:
                                                                            14.0,
                                                                        letterSpacing:
                                                                            0.0,
                                                                        fontWeight:
                                                                            FontWeight.w600,
                                                                        fontStyle:
                                                                            FlutterFlowTheme.of(context).labelLarge.fontStyle,
                                                                      ),
                                                                ),
                                                              ),
                                                            ].divide(const SizedBox(
                                                                width: 4.0)),
                                                          ),
                                                        ),
                                                        Container(
                                                          decoration:
                                                              BoxDecoration(
                                                            color: FlutterFlowTheme
                                                                    .of(context)
                                                                .error,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        12.0),
                                                          ),
                                                          child: Padding(
                                                            padding:
                                                                const EdgeInsetsDirectional
                                                                    .fromSTEB(
                                                                        8.0,
                                                                        6.0,
                                                                        8.0,
                                                                        6.0),
                                                            child: Text(
                                                              'Event ended',
                                                              style: FlutterFlowTheme
                                                                      .of(context)
                                                                  .bodyMedium
                                                                  .override(
                                                                    font: GoogleFonts
                                                                        .roboto(
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w400,
                                                                      fontStyle: FlutterFlowTheme.of(
                                                                              context)
                                                                          .bodyMedium
                                                                          .fontStyle,
                                                                    ),
                                                                    color: FlutterFlowTheme.of(
                                                                            context)
                                                                        .primaryText,
                                                                    fontSize:
                                                                        8.0,
                                                                    letterSpacing:
                                                                        0.0,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w400,
                                                                    fontStyle: FlutterFlowTheme.of(
                                                                            context)
                                                                        .bodyMedium
                                                                        .fontStyle,
                                                                  ),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    Divider(
                                                      thickness: 1.0,
                                                      color:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .alternate,
                                                    ),
                                                    Padding(
                                                      padding:
                                                          const EdgeInsetsDirectional
                                                              .fromSTEB(
                                                                  0.0,
                                                                  8.0,
                                                                  0.0,
                                                                  0.0),
                                                      child: Row(
                                                        mainAxisSize:
                                                            MainAxisSize.max,
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        children: [
                                                          Expanded(
                                                            flex: 2,
                                                            child: Column(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .max,
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                Text(
                                                                  valueOrDefault<
                                                                      String>(
                                                                    listViewEventsAttendanceViewRow
                                                                        .description,
                                                                    '{{Event Title}}',
                                                                  ),
                                                                  textAlign:
                                                                      TextAlign
                                                                          .start,
                                                                  maxLines: 2,
                                                                  style: FlutterFlowTheme.of(
                                                                          context)
                                                                      .titleLarge
                                                                      .override(
                                                                        font: GoogleFonts
                                                                            .nunito(
                                                                          fontWeight:
                                                                              FontWeight.normal,
                                                                          fontStyle: FlutterFlowTheme.of(context)
                                                                              .titleLarge
                                                                              .fontStyle,
                                                                        ),
                                                                        color: FlutterFlowTheme.of(context)
                                                                            .primaryText,
                                                                        fontSize:
                                                                            12.0,
                                                                        letterSpacing:
                                                                            0.0,
                                                                        fontWeight:
                                                                            FontWeight.normal,
                                                                        fontStyle: FlutterFlowTheme.of(context)
                                                                            .titleLarge
                                                                            .fontStyle,
                                                                        lineHeight:
                                                                            1.0,
                                                                      ),
                                                                ),
                                                                Text(
                                                                  valueOrDefault<
                                                                      String>(
                                                                    dateTimeFormat(
                                                                        "EE dd MMMM",
                                                                        listViewEventsAttendanceViewRow
                                                                            .eventStartDate),
                                                                    '{{Event Title}}',
                                                                  ),
                                                                  textAlign:
                                                                      TextAlign
                                                                          .center,
                                                                  style: FlutterFlowTheme.of(
                                                                          context)
                                                                      .titleLarge
                                                                      .override(
                                                                        font: GoogleFonts
                                                                            .nunito(
                                                                          fontWeight:
                                                                              FontWeight.normal,
                                                                          fontStyle: FlutterFlowTheme.of(context)
                                                                              .titleLarge
                                                                              .fontStyle,
                                                                        ),
                                                                        color: FlutterFlowTheme.of(context)
                                                                            .secondaryText,
                                                                        fontSize:
                                                                            12.0,
                                                                        letterSpacing:
                                                                            0.0,
                                                                        fontWeight:
                                                                            FontWeight.normal,
                                                                        fontStyle: FlutterFlowTheme.of(context)
                                                                            .titleLarge
                                                                            .fontStyle,
                                                                        lineHeight:
                                                                            1.3,
                                                                      ),
                                                                ),
                                                              ].divide(const SizedBox(
                                                                  height: 4.0)),
                                                            ),
                                                          ),
                                                          Expanded(
                                                            flex: 1,
                                                            child: Container(
                                                              decoration:
                                                                  const BoxDecoration(),
                                                              child: Column(
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .max,
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .end,
                                                                children: [
                                                                  Container(
                                                                    height:
                                                                        25.0,
                                                                    decoration:
                                                                        BoxDecoration(
                                                                      color: FlutterFlowTheme.of(
                                                                              context)
                                                                          .alternate,
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              14.0),
                                                                    ),
                                                                    child:
                                                                        Padding(
                                                                      padding:
                                                                          const EdgeInsets.all(
                                                                              6.0),
                                                                      child:
                                                                          CustomprogressbarWidget(
                                                                        key: Key(
                                                                            'Keyhp0_${listViewIndex}_of_${listViewEventsAttendanceViewRowList.length}'),
                                                                        progress:
                                                                            (int var1,
                                                                                int var2) {
                                                                          return var2 == 0
                                                                              ? 0.0
                                                                              : ((var1 / var2 * 100) * 100).round() / 100;
                                                                        }(listViewEventsAttendanceViewRow.totalWorkers!, listViewEventsAttendanceViewRow.activeWorker!),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  Padding(
                                                                    padding: const EdgeInsetsDirectional
                                                                        .fromSTEB(
                                                                            0.0,
                                                                            0.0,
                                                                            0.0,
                                                                            4.0),
                                                                    child: Text(
                                                                      '${((int var1, int var2) {
                                                                        return var2 ==
                                                                                0
                                                                            ? 0
                                                                            : ((var1 / var2) * 100 * 100).truncate() /
                                                                                100;
                                                                      }(listViewEventsAttendanceViewRow.totalWorkers!, listViewEventsAttendanceViewRow.activeWorker!)).toString()}% attendance',
                                                                      style: FlutterFlowTheme.of(
                                                                              context)
                                                                          .labelLarge
                                                                          .override(
                                                                            font:
                                                                                GoogleFonts.nunito(
                                                                              fontWeight: FontWeight.normal,
                                                                              fontStyle: FlutterFlowTheme.of(context).labelLarge.fontStyle,
                                                                            ),
                                                                            color:
                                                                                FlutterFlowTheme.of(context).secondaryText,
                                                                            fontSize:
                                                                                10.0,
                                                                            letterSpacing:
                                                                                0.0,
                                                                            fontWeight:
                                                                                FontWeight.normal,
                                                                            fontStyle:
                                                                                FlutterFlowTheme.of(context).labelLarge.fontStyle,
                                                                            lineHeight:
                                                                                1.3,
                                                                          ),
                                                                    ),
                                                                  ),
                                                                ].divide(const SizedBox(
                                                                    height:
                                                                        2.0)),
                                                              ),
                                                            ),
                                                          ),
                                                        ].divide(const SizedBox(
                                                            width: 8.0)),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                          ].divide(const SizedBox(height: 16.0)),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ));
      },
    );
  }
}
