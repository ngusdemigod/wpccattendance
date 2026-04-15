import '/backend/supabase/supabase.dart';
import '/components/workersearchresult_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import '/flutter_flow/custom_functions.dart' as functions;
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dept_attendance_model.dart';
export 'dept_attendance_model.dart';

class DeptAttendanceWidget extends StatefulWidget {
  const DeptAttendanceWidget({
    super.key,
    required this.deptname,
    this.eventid,
    this.deptid,
  });

  final String? deptname;
  final String? eventid;
  final String? deptid;

  @override
  State<DeptAttendanceWidget> createState() => _DeptAttendanceWidgetState();
}

class _DeptAttendanceWidgetState extends State<DeptAttendanceWidget> {
  late DeptAttendanceModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => DeptAttendanceModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional(0.0, -1.0),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 700.0,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
        Container(
          width: MediaQuery.sizeOf(context).width * 1.0,
          height: 41.17,
          decoration: BoxDecoration(
            color: FlutterFlowTheme.of(context).primary,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(
                  FlutterFlowTheme.of(context).designToken.radius.sm),
              topRight: Radius.circular(
                  FlutterFlowTheme.of(context).designToken.radius.sm),
            ),
          ),
          child: Stack(
            alignment: AlignmentDirectional(0.0, 0.0),
            children: [
              Align(
                alignment: AlignmentDirectional(0.0, 0.0),
                child: AutoSizeText(
                  valueOrDefault<String>(
                    widget!.deptname,
                    '{{department}}',
                  ),
                  maxLines: 1,
                  minFontSize: 10.0,
                  style: FlutterFlowTheme.of(context).titleSmall.override(
                        font: GoogleFonts.roboto(
                          fontWeight: FlutterFlowTheme.of(context)
                              .titleSmall
                              .fontWeight,
                          fontStyle:
                              FlutterFlowTheme.of(context).titleSmall.fontStyle,
                        ),
                        color: FlutterFlowTheme.of(context).primaryBackground,
                        letterSpacing: 0.0,
                        fontWeight: FlutterFlowTheme.of(context)
                            .titleSmall
                            .fontWeight,
                        fontStyle:
                            FlutterFlowTheme.of(context).titleSmall.fontStyle,
                      ),
                ),
              ),
              Align(
                alignment: AlignmentDirectional(1.0, 0.0),
                child: Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 8.0, 0.0),
                  child: IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: FlutterFlowTheme.of(context).primaryBackground,
                      size: 20.0,
                    ),
                    onPressed: () async {
                      Navigator.pop(context);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          width: MediaQuery.sizeOf(context).width * 1.0,
          decoration: BoxDecoration(
            color: FlutterFlowTheme.of(context).secondaryBackground,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(
                  FlutterFlowTheme.of(context).designToken.radius.sm),
              bottomRight: Radius.circular(
                  FlutterFlowTheme.of(context).designToken.radius.sm),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(14.0),
            child: FutureBuilder<List<AttendanceViewRow>>(
              future: AttendanceViewTable().queryRows(
                queryFn: (q) => q
                    .eqOrNull(
                      'event_id',
                      widget!.eventid,
                    )
                    .eqOrNull(
                      'department_id',
                      widget!.deptid,
                    ),
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
                List<AttendanceViewRow> listViewAttendanceViewRowList =
                    snapshot.data!;

                return ListView.separated(
                  padding: EdgeInsets.fromLTRB(
                    0,
                    12.0,
                    0,
                    12.0,
                  ),
                  shrinkWrap: true,
                  scrollDirection: Axis.vertical,
                  itemCount: listViewAttendanceViewRowList.length,
                  separatorBuilder: (_, __) => SizedBox(height: 8.0),
                  itemBuilder: (context, listViewIndex) {
                    final listViewAttendanceViewRow =
                        listViewAttendanceViewRowList[listViewIndex];
                    return Container(
                      decoration: BoxDecoration(),
                      child: WorkersearchresultWidget(
                        key: Key(
                            'Keyzio_${listViewIndex}_of_${listViewAttendanceViewRowList.length}'),
                        initials: functions.getInitials(
                            listViewAttendanceViewRow.profileFullName),
                        name: listViewAttendanceViewRow.profileFullName,
                        email: listViewAttendanceViewRow.departmentName,
                        role: functions.getShortCode(
                            listViewAttendanceViewRow.profileMembershipCode),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    ),
  ),
);
  }
}
