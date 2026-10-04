import '/backend/supabase/database/tables/attendance_view.dart';
import '/backend/supabase/database/tables/department_summary_view.dart';
import '/backend/supabase/database/tables/events_attendance_view.dart';
import '/backend/supabase/database/tables/worker_profiles.dart';
import '/pages/departmentlist/departmentlist_widget.dart';
import '/pages/departmentlist_loader/departmentlist_loader_widget.dart';
import '/pages/empty_list/empty_list_widget.dart';
import '/pages/profileview/profileview_widget.dart';
import '/components/topnav_widget.dart';
import '/loaders/eventprofile_loading/eventprofile_loading_widget.dart';
import '/loaders/workerssearch_l_o_a_d_e_r/workerssearch_l_o_a_d_e_r_widget.dart';
import '/components/workersearchresult_widget.dart';
import '/backend/supabase/database/table.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_choice_chips.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/form_field_controller.dart';
import '/flutter_flow/custom_functions.dart' as functions;
import '/services/geolocation_service.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';

import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'eventview_model.dart';
export 'eventview_model.dart';

class EventviewWidget extends StatefulWidget {
  const EventviewWidget({
    super.key,
    required this.evid,
    required this.evname,
    required this.desc,
  });

  static const String routeName = 'Eventview';
  static const String routePath = '/eventview';

  final String? evid;
  final String? evname;
  final String? desc;

  @override
  State<EventviewWidget> createState() => _EventviewWidgetState();
}

class _EventviewWidgetState extends State<EventviewWidget>
    with TickerProviderStateMixin {
  late EventviewModel _model;
  bool _isCheckingLocation = true;
  bool _isLocationAllowed = false;
  String _locationMessage = 'Checking location...';
  late final Future<List<EventsAttendanceViewRow>> _eventHeaderFuture;
  late final Future<List<AttendanceViewRow>> _attendanceListFuture;
  Future<List<WorkerProfilesRow>>? _workerSearchFuture;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  final animationsMap = <String, AnimationInfo>{};

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => EventviewModel());

    _model.textController ??= TextEditingController();
    _model.textFieldFocusNode ??= FocusNode();

    _eventHeaderFuture = EventsAttendanceViewTable().queryRows(
      queryFn: (q) => q.eqOrNull('event_id', widget.evid),
    );
    _attendanceListFuture = AttendanceViewTable().queryRows(
      queryFn: (q) => q.eqOrNull('event_id', widget.evid),
    );

    animationsMap.addAll({
      'workersearchresultOnPageLoadAnimation': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          FadeEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 600.0.ms,
            begin: 0.0,
            end: 1.0,
          ),
          MoveEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 600.0.ms,
            begin: const Offset(0.0, 20.0),
            end: const Offset(0.0, 0.0),
          ),
        ],
      ),
    });

    _checkLocation();
    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  Future<void> _checkLocation() async {
    setState(() {
      _isCheckingLocation = true;
      _locationMessage = 'Verifying your location...';
    });

    final isWithinLocation = await GeolocationService.isUserWithinAllowedLocation();
    
    setState(() {
      _isCheckingLocation = false;
      _isLocationAllowed = isWithinLocation;
      if (isWithinLocation) {
        _locationMessage = 'Location verified. Event details are now accessible.';
      } else {
        _locationMessage = 'You are outside the allowed area. Please come within 40km of the church location to view event details.';
      }
    });
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

    return GestureDetector(
      onTap: () {
        if (_model.textFieldFocusNode!.canRequestFocus) {
          FocusScope.of(context).requestFocus(_model.textFieldFocusNode);
        } else {
          FocusScope.of(context).unfocus();
        }
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        body: SafeArea(
          top: true,
          child: Align(
            alignment: const AlignmentDirectional(0.0, -1.0),
            child: Container(
              constraints: const BoxConstraints(
                maxWidth: 700.0,
              ),
              width: double.infinity,
              decoration: BoxDecoration(
                color: FlutterFlowTheme.of(context).secondaryBackground,
              ),
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(24.0, 16.0, 24.0, 0.0),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Geolocation Status Indicator
                    if (_isCheckingLocation)
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: FlutterFlowTheme.of(context).primaryBackground,
                          borderRadius: BorderRadius.circular(12.0),
                          border: Border.all(
                            color: FlutterFlowTheme.of(context).primary,
                            width: 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 20.0,
                              height: 20.0,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.0,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  FlutterFlowTheme.of(context).primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16.0),
                            Text(
                              _locationMessage,
                              style: FlutterFlowTheme.of(context).bodyMedium,
                            ),
                          ],
                        ),
                      )
                    else if (!_isLocationAllowed)
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(12.0),
                          border: Border.all(
                            color: const Color(0xFFEF5350),
                            width: 1.0,
                          ),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.location_off,
                              color: Color(0xFFEF5350),
                              size: 48.0,
                            ),
                            const SizedBox(height: 16.0),
                            Text(
                              'Location Not Allowed',
                              style: FlutterFlowTheme.of(context).titleLarge.copyWith(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFEF5350),
                              ),
                            ),
                            const SizedBox(height: 8.0),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24.0),
                              child: Text(
                                _locationMessage,
                                textAlign: TextAlign.center,
                                style: FlutterFlowTheme.of(context).bodyMedium,
                              ),
                            ),
                            const SizedBox(height: 16.0),
                            ElevatedButton.icon(
                              onPressed: _checkLocation,
                              icon: const Icon(Icons.refresh, color: Colors.white),
                              label: const Text('Retry Location Check'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFEF5350),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24.0,
                                  vertical: 12.0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      wrapWithModel(
                        model: _model.topnavModel,
                        updateCallback: () => safeSetState(() {}),
                        child: const TopnavWidget(
                          title: 'Event Details',
                        ),
                      ),
                    const SizedBox(height: 16.0),
                    Expanded(
                      child: SingleChildScrollView(
                        primary: false,
                        child: Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 32.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                    FutureBuilder<List<EventsAttendanceViewRow>>(
                      future: _eventHeaderFuture,
                      builder: (context, snapshot) {
                        // Customize what your widget looks like when it's loading.
                        if (!snapshot.hasData) {
                          return const EventprofileLoadingWidget();
                        }
                        List<EventsAttendanceViewRow>
                            headerEventsAttendanceViewRowList = snapshot.data!;
                        final headerEventsAttendanceViewRow =
                            headerEventsAttendanceViewRowList.isNotEmpty
                                ? headerEventsAttendanceViewRowList.first
                                : null;

                        return ClipRRect(
                          borderRadius: BorderRadius.circular(24.0),
                          child: Container(
                            width: double.infinity,
                            height: 180.0,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24.0),
                              image: DecorationImage(
                                fit: BoxFit.cover,
                                image: headerEventsAttendanceViewRow
                                                ?.featuredImage !=
                                            null &&
                                        headerEventsAttendanceViewRow!
                                                .featuredImage !=
                                            ''
                                    ? CachedNetworkImageProvider(
                                        headerEventsAttendanceViewRow
                                            .featuredImage!)
                                    : const AssetImage(
                                            'assets/images/image-placeholder2.jpg')
                                        as ImageProvider,
                              ),
                            ),
                            child: Stack(
                              children: [
                                Align(
                                  alignment: const AlignmentDirectional(0.0, 1.0),
                                  child: Container(
                                    width: double.infinity,
                                    height: 140.0,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.transparent,
                                          Colors.black.withValues(alpha: 0.8),
                                          Colors.black
                                        ],
                                        stops: const [0.0, 0.6, 1.0],
                                        begin: const AlignmentDirectional(0.0, -1.0),
                                        end: const AlignmentDirectional(0, 1.0),
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(18.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.max,
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      AutoSizeText(
                                        valueOrDefault<String>(
                                          widget.evname,
                                          '{{Event Name}}',
                                        ),
                                        maxLines: 2,
                                        minFontSize: 18.0,
                                        style: FlutterFlowTheme.of(context)
                                            .headlineLarge
                                            .override(
                                              font: GoogleFonts.instrumentSans(
                                                fontWeight: FontWeight.bold,
                                              ),
                                              color: Colors.white,
                                              fontSize: 24.0,
                                              letterSpacing: 0.0,
                                              lineHeight: 1.1,
                                            ),
                                      ),
                                      Text(
                                        valueOrDefault<String>(
                                          widget.desc,
                                          '{{description}}',
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: FlutterFlowTheme.of(context)
                                            .titleSmall
                                            .override(
                                              font: GoogleFonts.instrumentSans(
                                                fontWeight: FontWeight.normal,
                                              ),
                                              color: const Color(0xFFE0E0E0),
                                              letterSpacing: 0.0,
                                              fontSize: 14.0,
                                              lineHeight: 1.2,
                                            ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsetsDirectional.fromSTEB(
                                            0.0, 8.0, 0.0, 0.0),
                                        child: Container(
                                          height: 44.0,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(12.0),
                                          ),
                                          child: Padding(
                                            padding:
                                                const EdgeInsetsDirectional.fromSTEB(
                                                    12.0, 0.0, 12.0, 0.0),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.max,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                const Icon(
                                                  Icons.qr_code_scanner_rounded,
                                                  color: Colors.black,
                                                  size: 20.0,
                                                ),
                                                Expanded(
                                                  child: SizedBox(
                                                    width: 200.0,
                                                    child: TextFormField(
                                                      controller:
                                                          _model.textController,
                                                      focusNode: _model
                                                          .textFieldFocusNode,
                                                      onChanged: (_) =>
                                                          EasyDebounce.debounce(
                                                        '_model.textController',
                                                        const Duration(
                                                            milliseconds: 350),
                                                        () {
                                                          final query = _model
                                                              .textController
                                                              .text
                                                              .trim();
                                                          safeSetState(() {
                                                            _workerSearchFuture =
                                                                query.length >=
                                                                        2
                                                                    ? WorkerProfilesTable()
                                                                        .queryRows(
                                                                        queryFn: (q) =>
                                                                            q.or(
                                                                          'full_name.ilike.%$query%, profile_membership_code.ilike.%$query%',
                                                                        ),
                                                                        limit:
                                                                            20,
                                                                      )
                                                                    : null;
                                                          });
                                                        },
                                                      ),
                                                      autofocus: true,
                                                      enabled: true,
                                                      obscureText: false,
                                                      decoration:
                                                          InputDecoration(
                                                        isDense: true,
                                                        labelStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .labelMedium
                                                                .override(
                                                                  font:
                                                                      GoogleFonts
                                                                          .roboto(),
                                                                  color: Colors
                                                                      .black,
                                                                  letterSpacing:
                                                                      0.0,
                                                                ),
                                                        hintText:
                                                            'Search by membercode or name',
                                                        hintStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .labelMedium
                                                                .override(
                                                                  font:
                                                                      GoogleFonts
                                                                          .roboto(),
                                                                  color: const Color(
                                                                      0xFF757575),
                                                                  fontSize:
                                                                      12.0,
                                                                  letterSpacing:
                                                                      0.0,
                                                                ),
                                                        enabledBorder:
                                                            OutlineInputBorder(
                                                          borderSide:
                                                              const BorderSide(
                                                            color: Colors
                                                                .transparent,
                                                            width: 1.0,
                                                          ),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      8.0),
                                                        ),
                                                        focusedBorder:
                                                            OutlineInputBorder(
                                                          borderSide:
                                                              const BorderSide(
                                                            color: Colors
                                                                .transparent,
                                                            width: 1.0,
                                                          ),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      8.0),
                                                        ),
                                                        errorBorder:
                                                            OutlineInputBorder(
                                                          borderSide:
                                                              BorderSide(
                                                            color: FlutterFlowTheme
                                                                    .of(context)
                                                                .error,
                                                            width: 1.0,
                                                          ),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      8.0),
                                                        ),
                                                        focusedErrorBorder:
                                                            OutlineInputBorder(
                                                          borderSide:
                                                              BorderSide(
                                                            color: FlutterFlowTheme
                                                                    .of(context)
                                                                .error,
                                                            width: 1.0,
                                                          ),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      8.0),
                                                        ),
                                                      ),
                                                      style: FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMedium
                                                          .override(
                                                            font: GoogleFonts
                                                                .roboto(),
                                                            color: Colors.black,
                                                            letterSpacing: 0.0,
                                                          ),
                                                      cursorColor:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .primaryText,
                                                      enableInteractiveSelection:
                                                          true,
                                                      validator: _model
                                                          .textControllerValidator
                                                          .asValidator(context),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ].divide(const SizedBox(height: 4.0)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    if (_model.textController.text.trim().length >= 2)
                      Container(
                        constraints: const BoxConstraints(
                          maxHeight: 200.0,
                        ),
                        decoration: BoxDecoration(
                          color: FlutterFlowTheme.of(context).tertiary,
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: FutureBuilder<List<WorkerProfilesRow>>(
                            future: _workerSearchFuture,
                            builder: (context, snapshot) {
                              // Customize what your widget looks like when it's loading.
                              if (!snapshot.hasData) {
                                return const WorkerssearchLOADERWidget();
                              }
                              List<WorkerProfilesRow>
                                  listViewWorkerProfilesRowList =
                                  snapshot.data!;

                              if (listViewWorkerProfilesRowList.isEmpty) {
                                return const EmptyListWidget();
                              }

                              return ListView.separated(
                                padding: EdgeInsets.zero,
                                primary: false,
                                shrinkWrap: true,
                                scrollDirection: Axis.vertical,
                                itemCount: listViewWorkerProfilesRowList.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 4.0),
                                itemBuilder: (context, listViewIndex) {
                                  final listViewWorkerProfilesRow =
                                      listViewWorkerProfilesRowList[
                                          listViewIndex];
                                  return Builder(
                                    builder: (context) => InkWell(
                                      splashColor: Colors.transparent,
                                      focusColor: Colors.transparent,
                                      hoverColor: Colors.transparent,
                                      highlightColor: Colors.transparent,
                                      onTap: () async {
                                        await showDialog(
                                          context: context,
                                          builder: (dialogContext) {
                                            return Dialog(
                                              elevation: 0,
                                              insetPadding: EdgeInsets.zero,
                                              backgroundColor:
                                                  Colors.transparent,
                                              alignment: const AlignmentDirectional(
                                                      0.0, 0.0)
                                                  .resolve(Directionality.of(
                                                      context)),
                                              child: ProfileviewWidget(
                                                name: listViewWorkerProfilesRow
                                                    .fullName,
                                                id: listViewWorkerProfilesRow
                                                    .userId,
                                                evid: widget.evid,
                                                department:
                                                    listViewWorkerProfilesRow
                                                        .departmentName,
                                                branch:
                                                    listViewWorkerProfilesRow
                                                        .branchName,
                                                code: listViewWorkerProfilesRow
                                                    .workerMembershipcode,
                                                url: listViewWorkerProfilesRow
                                                    .avatar,
                                                deptid:
                                                    listViewWorkerProfilesRow
                                                        .departmentId,
                                                branchid:
                                                    listViewWorkerProfilesRow
                                                        .branchId,
                                              ),
                                            );
                                          },
                                        );
                                      },
                                      child: Hero(
                                        tag: 'profile',
                                        transitionOnUserGestures: true,
                                        child: Material(
                                          color: Colors.transparent,
                                          child: WorkersearchresultWidget(
                                            key: Key(
                                                'Key3qi_${listViewIndex}_of_${listViewWorkerProfilesRowList.length}'),
                                            initials: functions.getInitials(
                                                listViewWorkerProfilesRow
                                                    .fullName),
                                            name: listViewWorkerProfilesRow
                                                .fullName,
                                            email: listViewWorkerProfilesRow
                                                .departmentName,
                                            role: listViewWorkerProfilesRow
                                                .profileMembershipCode,
                                            color: const Color(0x21000000),
                                          ),
                                        ),
                                      ),
                                    ).animateOnPageLoad(animationsMap[
                                        'workersearchresultOnPageLoadAnimation']!),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Active members',
                          style: FlutterFlowTheme.of(context)
                              .labelLarge
                              .override(
                                font: GoogleFonts.instrumentSans(
                                  fontWeight: FlutterFlowTheme.of(context)
                                      .labelLarge
                                      .fontWeight,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .labelLarge
                                      .fontStyle,
                                ),
                                color: FlutterFlowTheme.of(context)
                                    .secondaryText,
                                fontSize: 12.0,
                                letterSpacing: 0.0,
                                fontWeight: FlutterFlowTheme.of(context)
                                    .labelLarge
                                    .fontWeight,
                                fontStyle: FlutterFlowTheme.of(context)
                                    .labelLarge
                                    .fontStyle,
                              ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: FlutterFlowTheme.of(context).alternate,
                            borderRadius: BorderRadius.circular(16.0),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(6.0),
                            child: FlutterFlowChoiceChips(
                              options: const [
                                ChipData('Dream Team'),
                                ChipData('Department')
                              ],
                              onChanged: (val) => safeSetState(() =>
                                  _model.choiceChipsValue = val?.firstOrNull),
                              selectedChipStyle: ChipStyle(
                                backgroundColor:
                                    FlutterFlowTheme.of(context).primary,
                                textStyle: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      font: GoogleFonts.instrumentSans(
                                        fontWeight: FontWeight.w400,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontStyle,
                                      ),
                                      color: FlutterFlowTheme.of(context)
                                          .primaryBackground,
                                      fontSize: 14.0,
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.w400,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                                iconColor: FlutterFlowTheme.of(context).info,
                                iconSize: 10.0,
                                elevation: 0.0,
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              unselectedChipStyle: ChipStyle(
                                backgroundColor: Colors.transparent,
                                textStyle: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      font: GoogleFonts.instrumentSans(
                                        fontWeight: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontWeight,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontStyle,
                                      ),
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryText,
                                      letterSpacing: 0.0,
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                                iconColor: FlutterFlowTheme.of(context)
                                    .secondaryText,
                                iconSize: 12.0,
                                elevation: 0.0,
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              chipSpacing: 8.0,
                              rowSpacing: 8.0,
                              multiselect: false,
                              initialized: _model.choiceChipsValue != null,
                              alignment: WrapAlignment.start,
                              controller: _model.choiceChipsValueController ??=
                                  FormFieldController<List<String>>(
                                ['Dream Team'],
                              ),
                              wrapped: true,
                            ),
                          ),
                        ),
                        FutureBuilder<List<AttendanceViewRow>>(
                          future: _attendanceListFuture,
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return _model.choiceChipsValue == 'Dream Team'
                                  ? const WorkerssearchLOADERWidget()
                                  : const DepartmentlistLoaderWidget();
                            }
                            final attendanceData = snapshot.data!;

                            if (_model.choiceChipsValue == 'Dream Team') {
                              if (attendanceData.isEmpty) {
                                return const EmptyListWidget();
                              }

                              // Sort for Dream Team (Latest check-ins first)
                              final dreamTeamList =
                                  List<AttendanceViewRow>.from(attendanceData);
                              dreamTeamList.sort((a, b) =>
                                  (b.attendanceCreatedAt ?? DateTime(0))
                                      .compareTo(a.attendanceCreatedAt ??
                                          DateTime(0)));

                              return ListView.separated(
                                padding: EdgeInsets.zero,
                                primary: false,
                                shrinkWrap: true,
                                scrollDirection: Axis.vertical,
                                itemCount: dreamTeamList.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 8.0),
                                itemBuilder: (context, listViewIndex) {
                                  final row = dreamTeamList[listViewIndex];
                                  return WorkersearchresultWidget(
                                    key: Key('Dream_$listViewIndex'),
                                    initials: functions
                                        .getInitials(row.profileFullName),
                                    name: row.profileFullName,
                                    email: row.departmentName,
                                    role: dateTimeFormat(
                                        "jm", row.attendanceCreatedAt),
                                    color: const Color(0x44333333),
                                  );
                                },
                              );
                            } else {
                              // Department List logic (Sort by check-in count)
                              final departments = FFAppState().allDepartments;
                              if (departments.isEmpty) {
                                return const EmptyListWidget();
                              }

                              final sortedDepartments =
                                  List<DepartmentSummaryViewRow>.from(
                                      departments);
                              sortedDepartments.sort((a, b) {
                                final countA = attendanceData
                                    .where((e) =>
                                        e.departmentId == a.departmentId)
                                    .length;
                                final countB = attendanceData
                                    .where((e) =>
                                        e.departmentId == b.departmentId)
                                    .length;
                                int cmp = countB.compareTo(countA);
                                return cmp != 0
                                    ? cmp
                                    : (a.departmentName ?? '')
                                        .compareTo(b.departmentName ?? '');
                              });

                              return ListView.separated(
                                padding: EdgeInsets.zero,
                                primary: false,
                                shrinkWrap: true,
                                scrollDirection: Axis.vertical,
                                itemCount: sortedDepartments.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 8.0),
                                itemBuilder: (context, listViewIndex) {
                                  final dept =
                                      sortedDepartments[listViewIndex];
                                  final activeCount = attendanceData
                                      .where((e) =>
                                          e.departmentId == dept.departmentId)
                                      .length;

                                  return DepartmentlistWidget(
                                    key: Key('Dept_$listViewIndex'),
                                    noofworkersinDept: dept.personsCount,
                                    activeDeptMembers: activeCount,
                                    deptname: dept.departmentName,
                                    eventid: widget.evid!,
                                    deptid: dept.departmentId,
                                  );
                                },
                              );
                            }
                          },
                        ),
                      ].divide(const SizedBox(height: 16.0)),
                    ),
                    Container(
                      height: 32.0,
                    ),
                  ].divide(const SizedBox(height: 24.0)),
                ),
              ),
            ),
          ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
