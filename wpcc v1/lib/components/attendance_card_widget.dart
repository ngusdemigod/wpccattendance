import '/flutter_flow/flutter_flow_choice_chips.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/form_field_controller.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'attendance_card_model.dart';
export 'attendance_card_model.dart';

class AttendanceCardWidget extends StatefulWidget {
  const AttendanceCardWidget({
    super.key,
    this.initials,
    this.avatar_bg,
    this.name,
    this.email,
    this.time,
    this.role,
  });

  final String? initials;
  final String? avatar_bg;
  final String? name;
  final String? email;
  final String? time;
  final String? role;

  @override
  State<AttendanceCardWidget> createState() => _AttendanceCardWidgetState();
}

class _AttendanceCardWidgetState extends State<AttendanceCardWidget> {
  late AttendanceCardModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AttendanceCardModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 16.0),
      child: Container(
        decoration: BoxDecoration(
          color: FlutterFlowTheme.of(context).secondaryBackground,
          boxShadow: [
            BoxShadow(
              blurRadius: 2.0,
              color: Color(0x1A000000),
              offset: Offset(
                0.0,
                1.0,
              ),
              spreadRadius: 0.0,
            )
          ],
          border: Border.all(
            color: FlutterFlowTheme.of(context).divider,
            width: 1.0,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Stack(
                children: [
                  Container(
                    width: 52.0,
                    height: 52.0,
                    decoration: BoxDecoration(
                      color: Color(0xFFD4A5A5),
                      shape: BoxShape.circle,
                    ),
                    alignment: AlignmentDirectional(0.0, 0.0),
                    child: Text(
                      'JD',
                      style: TextStyle(
                        color: FlutterFlowTheme.of(context).primaryText,
                        fontWeight: FontWeight.w600,
                        fontSize: 20.8,
                      ),
                    ),
                  ),
                  Align(
                    alignment: AlignmentDirectional(1.0, 1.0),
                    child: Container(
                      width: 18.0,
                      height: 18.0,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).success,
                        borderRadius: BorderRadius.circular(9999.0),
                        border: Border.all(
                          color:
                              FlutterFlowTheme.of(context).secondaryBackground,
                          width: 2.0,
                        ),
                      ),
                      alignment: AlignmentDirectional(0.0, 0.0),
                      child: Icon(
                        Icons.check_rounded,
                        color: FlutterFlowTheme.of(context).primaryText,
                        size: 12.0,
                      ),
                    ),
                  ),
                ],
              ),
              Expanded(
                flex: 1,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      valueOrDefault<String>(
                        widget!.name,
                        'Jane Doe',
                      ),
                      maxLines: 1,
                      style: FlutterFlowTheme.of(context).titleMedium.override(
                            font: GoogleFonts.dmSans(
                              fontWeight: FontWeight.w600,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .titleMedium
                                  .fontStyle,
                            ),
                            color: FlutterFlowTheme.of(context).primaryText,
                            fontSize: 17.0,
                            letterSpacing: 0.0,
                            fontWeight: FontWeight.w600,
                            fontStyle: FlutterFlowTheme.of(context)
                                .titleMedium
                                .fontStyle,
                            lineHeight: 1.4,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      valueOrDefault<String>(
                        widget!.email,
                        'jane.doe@church.org',
                      ),
                      maxLines: 1,
                      style: FlutterFlowTheme.of(context).bodySmall.override(
                            font: GoogleFonts.dmSans(
                              fontWeight: FontWeight.normal,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .bodySmall
                                  .fontStyle,
                            ),
                            color: FlutterFlowTheme.of(context).secondaryText,
                            fontSize: 12.0,
                            letterSpacing: 0.0,
                            fontWeight: FontWeight.normal,
                            fontStyle: FlutterFlowTheme.of(context)
                                .bodySmall
                                .fontStyle,
                            lineHeight: 1.4,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ].divide(SizedBox(height: 4.0)),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    valueOrDefault<String>(
                      widget!.time,
                      '08:45 AM',
                    ),
                    style: FlutterFlowTheme.of(context).labelSmall.override(
                          font: GoogleFonts.nunito(
                            fontWeight: FontWeight.bold,
                            fontStyle: FlutterFlowTheme.of(context)
                                .labelSmall
                                .fontStyle,
                          ),
                          color: FlutterFlowTheme.of(context).primary,
                          fontSize: 10.0,
                          letterSpacing: 0.0,
                          fontWeight: FontWeight.bold,
                          fontStyle:
                              FlutterFlowTheme.of(context).labelSmall.fontStyle,
                          lineHeight: 1.2,
                        ),
                  ),
                  FlutterFlowChoiceChips(
                    options: [ChipData('Choir')],
                    onChanged: (val) => safeSetState(
                        () => _model.choiceChipsValue = val?.firstOrNull),
                    selectedChipStyle: ChipStyle(
                      backgroundColor: Color(0x33A8B5A0),
                      textStyle: TextStyle(
                        color: FlutterFlowTheme.of(context).primaryText,
                      ),
                      iconColor: FlutterFlowTheme.of(context).primaryText,
                      iconSize: 18.0,
                      labelPadding:
                          EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                      elevation: 0.0,
                      borderWidth: 0.0,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    unselectedChipStyle: ChipStyle(
                      backgroundColor: Color(0x33A8B5A0),
                      textStyle: TextStyle(
                        color: FlutterFlowTheme.of(context).primaryText,
                      ),
                      iconColor: FlutterFlowTheme.of(context).primaryText,
                      iconSize: 18.0,
                      labelPadding:
                          EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                      elevation: 0.0,
                      borderWidth: 0.0,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    chipSpacing: 0.0,
                    multiselect: false,
                    controller: _model.choiceChipsValueController ??=
                        FormFieldController<List<String>>(
                      [],
                    ),
                    wrapped: false,
                  ),
                ].divide(SizedBox(height: 4.0)),
              ),
            ].divide(SizedBox(width: 16.0)),
          ),
        ),
      ),
    );
  }
}
