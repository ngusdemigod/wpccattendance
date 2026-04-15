import '/backend/supabase/supabase.dart';
import '/components/topnav_widget.dart';
import '/components/workersearchresult_widget.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_choice_chips.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/form_field_controller.dart';
import '/loaders/workerssearch_l_o_a_d_e_r/workerssearch_l_o_a_d_e_r_widget.dart';
import '/pages/departmentlist/departmentlist_widget.dart';
import '/pages/departmentlist_loader/departmentlist_loader_widget.dart';
import '/pages/empty_list/empty_list_widget.dart';
import '/pages/profileview/profileview_widget.dart';
import 'dart:math';
import 'dart:ui';
import '/flutter_flow/custom_functions.dart' as functions;
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'eventview_model.dart';
export 'eventview_model.dart';

class EventviewWidget extends StatefulWidget {
  const EventviewWidget({
    super.key,
    this.evname,
    required this.evid,
    required this.desc,
  });

  final String? evname;
  final String? evid;
  final String? desc;

  static String routeName = 'eventview';
  static String routePath = '/eventview';

  @override
  State<EventviewWidget> createState() => _EventviewWidgetState();
}

class _EventviewWidgetState extends State<EventviewWidget>
    with TickerProviderStateMixin {
  late EventviewModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  final animationsMap = <String, AnimationInfo>{};

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => EventviewModel());

    _model.textController ??= TextEditingController();
    _model.textFieldFocusNode ??= FocusNode();
    _model.textFieldFocusNode!.addListener(() => safeSetState(() {}));
    animationsMap.addAll({
      'workersearchresultOnPageLoadAnimation': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          FadeEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 220.0.ms,
            begin: 0.0,
            end: 1.0,
          ),
          MoveEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 260.0.ms,
            begin: Offset(0.0, 18.0),
            end: Offset(0.0, 0.0),
          ),
        ],
      ),
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (FFAppState().eventid == null || FFAppState().eventid == '') {
        context.goNamed('eventlist');
      }
      safeSetState(() {});
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

    return Shortcuts(
      shortcuts: {},
      child: Actions(
        actions: {
          VoidCallbackIntent: CallbackAction<VoidCallbackIntent>(
            onInvoke: (intent) => intent.callback(),
          ),
        },
        child: Focus(
            autofocus: isShortcutsSupported,
            focusNode: _model.shortcutsFocusNode,
            child: Title(
                title: 'eventview',
                color: FlutterFlowTheme.of(context).primary.withAlpha(0XFF),
                child: GestureDetector(
                  onTap: () {
                    if (isShortcutsSupported &&
                        _model.shortcutsFocusNode.canRequestFocus) {
                      FocusScope.of(context)
                          .requestFocus(_model.shortcutsFocusNode);
                    } else {
                      FocusScope.of(context).unfocus();
                      FocusManager.instance.primaryFocus?.unfocus();
                    }
                  },
                  child: Scaffold(
                    key: scaffoldKey,
                    backgroundColor:
                        FlutterFlowTheme.of(context).primaryBackground,
                    body: FutureBuilder<List<WorkerProfilesRow>>(
                      future: WorkerProfilesTable().queryRows(
                        queryFn: (q) => q,
                      ),
                      builder: (context, snapshot) {
                        // Customize what your widget looks like when it's loading.
                        if (!snapshot.hasData) {
                          return Center(
                            child: SizedBox(
                              width: 20.0,
                              height: 20.0,
                              child: SpinKitFoldingCube(
                                color: FlutterFlowTheme.of(context).primary,
                                size: 20.0,
                              ),
                            ),
                          );
                        }
                        List<WorkerProfilesRow> containerWorkerProfilesRowList =
                            snapshot.data!;

                        return Align(
                          alignment: AlignmentDirectional(0.0, -1.0),
                          child: Container(
                            constraints: BoxConstraints(
                              maxWidth: 700.0,
                            ),
                            width: MediaQuery.sizeOf(context).width * 1.0,
                            height: MediaQuery.sizeOf(context).height * 1.0,
                          decoration: BoxDecoration(
                            color: FlutterFlowTheme.of(context)
                                .secondaryBackground,
                          ),
                          child: Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                                24.0, 32.0, 24.0, 32.0),
                            child: SingleChildScrollView(
                              primary: false,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  wrapWithModel(
                                    model: _model.topnavModel,
                                    updateCallback: () => safeSetState(() {}),
                                    child: TopnavWidget(
                                      title: 'Event Details',
                                    ),
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: FlutterFlowTheme.of(context)
                                          .alternate,
                                      borderRadius: BorderRadius.circular(24.0),
                                      border: Border.all(
                                        color: FlutterFlowTheme.of(context)
                                            .divider,
                                        width: 1.0,
                                      ),
                                    ),
                                    child: Padding(
                                      padding: EdgeInsets.all(18.0),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.max,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            valueOrDefault<String>(
                                              widget!.evname,
                                              '{{Event Name}}',
                                            ),
                                            maxLines: 2,
                                            style: FlutterFlowTheme.of(context)
                                                .headlineLarge
                                                .override(
                                                  font: GoogleFonts.roboto(
                                                    fontWeight: FontWeight.w500,
                                                    fontStyle:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .headlineLarge
                                                            .fontStyle,
                                                  ),
                                                  letterSpacing: 0.0,
                                                  fontWeight: FontWeight.w500,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .headlineLarge
                                                          .fontStyle,
                                                  lineHeight: 1.0,
                                                ),
                                          ),
                                          Text(
                                            valueOrDefault<String>(
                                              widget!.desc,
                                              '{{description}}',
                                            ),
                                            maxLines: 2,
                                            style: FlutterFlowTheme.of(context)
                                                .titleSmall
                                                .override(
                                                  font: GoogleFonts.roboto(
                                                    fontWeight:
                                                        FontWeight.normal,
                                                    fontStyle:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .titleSmall
                                                            .fontStyle,
                                                  ),
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .secondaryText,
                                                  letterSpacing: 0.0,
                                                  fontWeight: FontWeight.normal,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .titleSmall
                                                          .fontStyle,
                                                  lineHeight: 1.0,
                                                ),
                                          ),
                                          Padding(
                                            padding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    0.0, 8.0, 0.0, 0.0),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .secondaryText,
                                                borderRadius:
                                                    BorderRadius.circular(12.0),
                                              ),
                                              child: Padding(
                                                padding: EdgeInsetsDirectional
                                                    .fromSTEB(
                                                        12.0, 0.0, 12.0, 0.0),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.max,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons
                                                          .qr_code_scanner_rounded,
                                                      color: FlutterFlowTheme
                                                              .of(context)
                                                          .primaryBackground,
                                                      size: 20.0,
                                                    ),
                                                    Expanded(
                                                      child: Container(
                                                        width: 200.0,
                                                        child: TextFormField(
                                                          controller: _model
                                                              .textController,
                                                          focusNode: _model
                                                              .textFieldFocusNode,
                                                          onChanged: (_) =>
                                                              EasyDebounce
                                                                  .debounce(
                                                            '_model.textController',
                                                            Duration(
                                                                milliseconds:
                                                                    50),
                                                            () => safeSetState(
                                                                () {}),
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
                                                                      font: GoogleFonts
                                                                          .roboto(
                                                                        fontWeight: FlutterFlowTheme.of(context)
                                                                            .labelMedium
                                                                            .fontWeight,
                                                                        fontStyle: FlutterFlowTheme.of(context)
                                                                            .labelMedium
                                                                            .fontStyle,
                                                                      ),
                                                                      color: FlutterFlowTheme.of(
                                                                              context)
                                                                          .secondaryBackground,
                                                                      letterSpacing:
                                                                          0.0,
                                                                      fontWeight: FlutterFlowTheme.of(
                                                                              context)
                                                                          .labelMedium
                                                                          .fontWeight,
                                                                      fontStyle: FlutterFlowTheme.of(
                                                                              context)
                                                                          .labelMedium
                                                                          .fontStyle,
                                                                    ),
                                                            hintText:
                                                                'Search by membercode or name',
                                                            hintStyle:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .labelMedium
                                                                    .override(
                                                                      font: GoogleFonts
                                                                          .roboto(
                                                                        fontWeight:
                                                                            FontWeight.normal,
                                                                        fontStyle: FlutterFlowTheme.of(context)
                                                                            .labelMedium
                                                                            .fontStyle,
                                                                      ),
                                                                      color: FlutterFlowTheme.of(
                                                                              context)
                                                                          .alternate,
                                                                      fontSize:
                                                                          12.0,
                                                                      letterSpacing:
                                                                          0.0,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .normal,
                                                                      fontStyle: FlutterFlowTheme.of(
                                                                              context)
                                                                          .labelMedium
                                                                          .fontStyle,
                                                                    ),
                                                            enabledBorder:
                                                                OutlineInputBorder(
                                                              borderSide:
                                                                  BorderSide(
                                                                color: Color(
                                                                    0x00000000),
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
                                                                  BorderSide(
                                                                color: Color(
                                                                    0x00000000),
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
                                                                color: FlutterFlowTheme.of(
                                                                        context)
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
                                                                color: FlutterFlowTheme.of(
                                                                        context)
                                                                    .error,
                                                                width: 1.0,
                                                              ),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          8.0),
                                                            ),
                                                          ),
                                                          style: FlutterFlowTheme
                                                                  .of(context)
                                                              .bodyMedium
                                                              .override(
                                                                font:
                                                                    GoogleFonts
                                                                        .roboto(
                                                                  fontWeight: FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodyMedium
                                                                      .fontWeight,
                                                                  fontStyle: FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodyMedium
                                                                      .fontStyle,
                                                                ),
                                                                color: FlutterFlowTheme.of(
                                                                        context)
                                                                    .primaryBackground,
                                                                letterSpacing:
                                                                    0.0,
                                                                fontWeight: FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontWeight,
                                                                fontStyle: FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontStyle,
                                                              ),
                                                          cursorColor:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .primaryText,
                                                          enableInteractiveSelection:
                                                              true,
                                                          validator: _model
                                                              .textControllerValidator
                                                              .asValidator(
                                                                  context),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                          if (_model.textController.text ==
                                                      null ||
                                                  _model.textController.text ==
                                                      ''
                                              ? false
                                              : true)
                                            Container(
                                              constraints: BoxConstraints(
                                                maxHeight: 200.0,
                                              ),
                                              decoration: BoxDecoration(
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .tertiary,
                                                borderRadius:
                                                    BorderRadius.circular(12.0),
                                              ),
                                              child: Padding(
                                                padding: EdgeInsets.all(8.0),
                                                child: FutureBuilder<
                                                    List<WorkerProfilesRow>>(
                                                  future: WorkerProfilesTable()
                                                      .queryRows(
                                                    queryFn: (q) => q.or(
                                                        "full_name.ilike.${'%${_model.textController.text}%'}, profile_membership_code.ilike.${'%${_model.textController.text}%'}"),
                                                  ),
                                                  builder: (context, snapshot) {
                                                    // Customize what your widget looks like when it's loading.
                                                    if (!snapshot.hasData) {
                                                      return WorkerssearchLOADERWidget();
                                                    }
                                                    List<WorkerProfilesRow>
                                                        listViewWorkerProfilesRowList =
                                                        snapshot.data!;

                                                    if (listViewWorkerProfilesRowList
                                                        .isEmpty) {
                                                      return EmptyListWidget();
                                                    }

                                                    return ListView.separated(
                                                      padding: EdgeInsets.zero,
                                                      primary: false,
                                                      shrinkWrap: true,
                                                      scrollDirection:
                                                          Axis.vertical,
                                                      itemCount:
                                                          listViewWorkerProfilesRowList
                                                              .length,
                                                      separatorBuilder: (_,
                                                              __) =>
                                                          SizedBox(height: 4.0),
                                                      itemBuilder: (context,
                                                          listViewIndex) {
                                                        final listViewWorkerProfilesRow =
                                                            listViewWorkerProfilesRowList[
                                                                listViewIndex];
                                                        return Builder(
                                                          builder: (context) =>
                                                              InkWell(
                                                            splashColor: Colors
                                                                .transparent,
                                                            focusColor: Colors
                                                                .transparent,
                                                            hoverColor: Colors
                                                                .transparent,
                                                            highlightColor:
                                                                Colors
                                                                    .transparent,
                                                            onTap: () async {
                                                              await showDialog(
                                                                context:
                                                                    context,
                                                                builder:
                                                                    (dialogContext) {
                                                                  return Dialog(
                                                                    elevation:
                                                                        0,
                                                                    insetPadding:
                                                                        EdgeInsets
                                                                            .zero,
                                                                    backgroundColor:
                                                                        Colors
                                                                            .transparent,
                                                                    alignment: AlignmentDirectional(
                                                                            0.0,
                                                                            0.0)
                                                                        .resolve(
                                                                            Directionality.of(context)),
                                                                    child:
                                                                        ProfileviewWidget(
                                                                      name: listViewWorkerProfilesRow
                                                                          .fullName,
                                                                      id: listViewWorkerProfilesRow
                                                                          .userId,
                                                                      evid: widget!
                                                                          .evid,
                                                                      department:
                                                                          listViewWorkerProfilesRow
                                                                              .departmentName,
                                                                      branch: listViewWorkerProfilesRow
                                                                          .branchName,
                                                                      code: listViewWorkerProfilesRow
                                                                          .workerMembershipcode,
                                                                      url: listViewWorkerProfilesRow
                                                                          .avatar,
                                                                      deptid: listViewWorkerProfilesRow
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
                                                              transitionOnUserGestures:
                                                                  true,
                                                              child: Material(
                                                                color: Colors
                                                                    .transparent,
                                                                child:
                                                                    WorkersearchresultWidget(
                                                                  key: Key(
                                                                      'Key3qi_${listViewIndex}_of_${listViewWorkerProfilesRowList.length}'),
                                                                  initials: functions
                                                                      .getInitials(
                                                                          listViewWorkerProfilesRow
                                                                              .fullName),
                                                                  name: listViewWorkerProfilesRow
                                                                      .fullName,
                                                                  email: listViewWorkerProfilesRow
                                                                      .departmentName,
                                                                  role: listViewWorkerProfilesRow
                                                                      .profileMembershipCode,
                                                                  color: Color(
                                                                      0x21000000),
                                                                ),
                                                              ),
                                                            ),
                                                          ).animateOnPageLoad(
                                                                  animationsMap[
                                                                      'workersearchresultOnPageLoadAnimation']!),
                                                        );
                                                      },
                                                    );
                                                  },
                                                ),
                                              ),
                                            ),
                                        ]
                                            .divide(SizedBox(height: 8.0))
                                            .addToStart(SizedBox(height: 24.0)),
                                      ),
                                    ),
                                  ),
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Active members',
                                        style: FlutterFlowTheme.of(context)
                                            .labelLarge
                                            .override(
                                              font: GoogleFonts.roboto(
                                                fontWeight: FlutterFlowTheme.of(
                                                        context)
                                                    .labelLarge
                                                    .fontWeight,
                                                fontStyle: FlutterFlowTheme.of(
                                                        context)
                                                    .labelLarge
                                                    .fontStyle,
                                              ),
                                              color: FlutterFlowTheme.of(context)
                                                  .secondaryText,
                                              fontSize: 12.0,
                                              letterSpacing: 0.0,
                                              fontWeight: FlutterFlowTheme.of(
                                                      context)
                                                  .labelLarge
                                                  .fontWeight,
                                              fontStyle: FlutterFlowTheme.of(
                                                      context)
                                                  .labelLarge
                                                  .fontStyle,
                                            ),
                                      ),
                                      Container(
                                        decoration: BoxDecoration(
                                          color: FlutterFlowTheme.of(context)
                                              .alternate,
                                          borderRadius:
                                              BorderRadius.circular(16.0),
                                        ),
                                        child: Padding(
                                          padding: EdgeInsets.all(6.0),
                                          child: FlutterFlowChoiceChips(
                                            options: [
                                              ChipData('Dream Team'),
                                              ChipData('Department')
                                            ],
                                            onChanged: (val) => safeSetState(
                                                () => _model.choiceChipsValue =
                                                    val?.firstOrNull),
                                            selectedChipStyle: ChipStyle(
                                              backgroundColor:
                                                  FlutterFlowTheme.of(context)
                                                      .primary,
                                              textStyle: FlutterFlowTheme.of(
                                                      context)
                                                  .bodyMedium
                                                  .override(
                                                    font: GoogleFonts.roboto(
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      fontStyle:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .bodyMedium
                                                              .fontStyle,
                                                    ),
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .primaryBackground,
                                                    fontSize: 14.0,
                                                    letterSpacing: 0.0,
                                                    fontWeight: FontWeight.w500,
                                                    fontStyle:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .bodyMedium
                                                            .fontStyle,
                                                  ),
                                              iconColor:
                                                  FlutterFlowTheme.of(context)
                                                      .info,
                                              iconSize: 10.0,
                                              elevation: 0.0,
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                            unselectedChipStyle: ChipStyle(
                                              backgroundColor:
                                                  Colors.transparent,
                                              textStyle: FlutterFlowTheme.of(
                                                      context)
                                                  .bodyMedium
                                                  .override(
                                                    font: GoogleFonts.roboto(
                                                      fontWeight:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .bodyMedium
                                                              .fontWeight,
                                                      fontStyle:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .bodyMedium
                                                              .fontStyle,
                                                    ),
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .secondaryText,
                                                    letterSpacing: 0.0,
                                                    fontWeight:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .bodyMedium
                                                            .fontWeight,
                                                    fontStyle:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .bodyMedium
                                                            .fontStyle,
                                                  ),
                                              iconColor:
                                                  FlutterFlowTheme.of(context)
                                                      .secondaryText,
                                              iconSize: 12.0,
                                              elevation: 0.0,
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                            chipSpacing: 8.0,
                                            rowSpacing: 8.0,
                                            multiselect: false,
                                            initialized:
                                                _model.choiceChipsValue != null,
                                            alignment: WrapAlignment.start,
                                            controller: _model
                                                    .choiceChipsValueController ??=
                                                FormFieldController<
                                                    List<String>>(
                                              ['Dream Team'],
                                            ),
                                            wrapped: true,
                                          ),
                                        ),
                                      ),
                                      FutureBuilder<List<AttendanceViewRow>>(
                                        future: AttendanceViewTable().queryRows(
                                          queryFn: (q) => q.eqOrNull(
                                            'event_id',
                                            widget!.evid,
                                          ),
                                        ),
                                        builder: (context, snapshot) {
                                          if (!snapshot.hasData) {
                                            return _model.choiceChipsValue ==
                                                    'Dream Team'
                                                ? WorkerssearchLOADERWidget()
                                                : DepartmentlistLoaderWidget();
                                          }
                                          final attendanceData = snapshot.data!;

                                          if (_model.choiceChipsValue ==
                                              'Dream Team') {
                                            if (attendanceData.isEmpty) {
                                              return EmptyListWidget();
                                            }

                                            // Sort for Dream Team (Latest check-ins first)
                                            final dreamTeamList =
                                                List<AttendanceViewRow>.from(
                                                    attendanceData);
                                            dreamTeamList.sort((a, b) =>
                                                (b.attendanceCreatedAt ??
                                                        DateTime(0))
                                                    .compareTo(
                                                        a.attendanceCreatedAt ??
                                                            DateTime(0)));

                                            return ListView.separated(
                                              padding: EdgeInsets.zero,
                                              primary: false,
                                              shrinkWrap: true,
                                              scrollDirection: Axis.vertical,
                                              itemCount: dreamTeamList.length,
                                              separatorBuilder: (_, __) =>
                                                  SizedBox(height: 8.0),
                                              itemBuilder:
                                                  (context, listViewIndex) {
                                                final row =
                                                    dreamTeamList[listViewIndex];
                                                return WorkersearchresultWidget(
                                                  key: Key(
                                                      'Dream_${listViewIndex}'),
                                                  initials: functions
                                                      .getInitials(
                                                          row.profileFullName),
                                                  name: row.profileFullName,
                                                  email: row.departmentName,
                                                  role: dateTimeFormat("jm",
                                                      row.attendanceCreatedAt),
                                                  color: Color(0x44333333),
                                                );
                                              },
                                            );
                                          } else {
                                            // Department List logic (Sort by check-in count)
                                            final departments =
                                                FFAppState().allDepartments;
                                            if (departments.isEmpty) {
                                              return EmptyListWidget();
                                            }

                                            final sortedDepartments =
                                                List<DepartmentSummaryViewRow>.from(
                                                    departments);
                                            sortedDepartments.sort((a, b) {
                                              final countA = attendanceData
                                                  .where((e) =>
                                                      e.departmentId ==
                                                      a.departmentId)
                                                  .length;
                                              final countB = attendanceData
                                                  .where((e) =>
                                                      e.departmentId ==
                                                      b.departmentId)
                                                  .length;
                                              int cmp =
                                                  countB.compareTo(countA);
                                              return cmp != 0
                                                  ? cmp
                                                  : (a.departmentName ?? '')
                                                      .compareTo(
                                                          b.departmentName ??
                                                              '');
                                            });

                                            return ListView.separated(
                                              padding: EdgeInsets.zero,
                                              primary: false,
                                              shrinkWrap: true,
                                              scrollDirection: Axis.vertical,
                                              itemCount:
                                                  sortedDepartments.length,
                                              separatorBuilder: (_, __) =>
                                                  SizedBox(height: 8.0),
                                              itemBuilder:
                                                  (context, listViewIndex) {
                                                final dept = sortedDepartments[
                                                    listViewIndex];
                                                final activeCount =
                                                    attendanceData
                                                        .where((e) =>
                                                            e.departmentId ==
                                                            dept.departmentId)
                                                        .length;

                                                return DepartmentlistWidget(
                                                  key: Key(
                                                      'Dept_${listViewIndex}'),
                                                  noofworkersinDept:
                                                      dept.personsCount,
                                                  activeDeptMembers:
                                                      activeCount,
                                                  deptname: dept.departmentName,
                                                  eventid: widget!.evid!,
                                                  deptid: dept.departmentId,
                                                );
                                              },
                                            );
                                          }
                                        },
                                      ),
                                    ].divide(SizedBox(height: 16.0)),
                                  ),
                                  Container(
                                    height: 32.0,
                                  ),
                                ].divide(SizedBox(height: 24.0)),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    ),
                  ),
                ))),
      ),
    );
  }
}
