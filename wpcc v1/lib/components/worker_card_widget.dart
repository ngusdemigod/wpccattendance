import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'worker_card_model.dart';
export 'worker_card_model.dart';

class WorkerCardWidget extends StatefulWidget {
  const WorkerCardWidget({
    super.key,
    this.initials,
    this.avatar_bg,
    this.is_active,
    this.name,
    this.email,
    this.code,
  });

  final String? initials;
  final String? avatar_bg;
  final bool? is_active;
  final String? name;
  final String? email;
  final String? code;

  @override
  State<WorkerCardWidget> createState() => _WorkerCardWidgetState();
}

class _WorkerCardWidgetState extends State<WorkerCardWidget> {
  late WorkerCardModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => WorkerCardModel());

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
          padding: EdgeInsets.all(24.0),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Stack(
                children: [
                  Container(
                    width: 64.0,
                    height: 64.0,
                    decoration: BoxDecoration(
                      color: Color(0xFFFAF7F2),
                      shape: BoxShape.circle,
                    ),
                    alignment: AlignmentDirectional(0.0, 0.0),
                    child: Text(
                      'JD',
                      style: TextStyle(
                        color: FlutterFlowTheme.of(context).primaryText,
                        fontWeight: FontWeight.w600,
                        fontSize: 25.6,
                      ),
                    ),
                  ),
                  Align(
                    alignment: AlignmentDirectional(1.0, 1.0),
                    child: Container(
                      width: 20.0,
                      height: 20.0,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).success,
                        borderRadius: BorderRadius.circular(9999.0),
                        border: Border.all(
                          color:
                              FlutterFlowTheme.of(context).secondaryBackground,
                          width: 2.0,
                        ),
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
                              fontWeight: FontWeight.bold,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .titleMedium
                                  .fontStyle,
                            ),
                            color: FlutterFlowTheme.of(context).primaryText,
                            fontSize: 17.0,
                            letterSpacing: 0.0,
                            fontWeight: FontWeight.bold,
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
                    Padding(
                      padding:
                          EdgeInsetsDirectional.fromSTEB(0.0, 4.0, 0.0, 0.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: FlutterFlowTheme.of(context).primaryBackground,
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                        child: Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(
                              8.0, 4.0, 8.0, 4.0),
                          child: Text(
                            valueOrDefault<String>(
                              widget!.code,
                              'STW-001',
                            ),
                            style: FlutterFlowTheme.of(context)
                                .labelSmall
                                .override(
                                  font: GoogleFonts.nunito(
                                    fontWeight: FontWeight.w600,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .labelSmall
                                        .fontStyle,
                                  ),
                                  color: FlutterFlowTheme.of(context).primary,
                                  fontSize: 10.0,
                                  letterSpacing: 0.0,
                                  fontWeight: FontWeight.w600,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .labelSmall
                                      .fontStyle,
                                  lineHeight: 1.2,
                                ),
                          ),
                        ),
                      ),
                    ),
                  ].divide(SizedBox(height: 4.0)),
                ),
              ),
              FlutterFlowIconButton(
                buttonSize: 40.0,
                icon: Icon(
                  Icons.chevron_right_rounded,
                  color: FlutterFlowTheme.of(context).hint,
                  size: 24.0,
                ),
                onPressed: () {
                  print('IconButton pressed ...');
                },
              ),
            ].divide(SizedBox(width: 16.0)),
          ),
        ),
      ),
    );
  }
}
