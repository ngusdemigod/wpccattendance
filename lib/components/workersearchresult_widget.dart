import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'workersearchresult_model.dart';
export 'workersearchresult_model.dart';

class WorkersearchresultWidget extends StatefulWidget {
  const WorkersearchresultWidget({
    super.key,
    this.initials,
    this.name,
    this.email,
    this.role,
    Color? color,
  }) : this.color = color ?? const Color(0x1CFFFFFF);

  final String? initials;
  final String? name;
  final String? email;
  final String? role;
  final Color color;

  @override
  State<WorkersearchresultWidget> createState() =>
      _WorkersearchresultWidgetState();
}

class _WorkersearchresultWidgetState extends State<WorkersearchresultWidget> {
  late WorkersearchresultModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => WorkersearchresultModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Color> avatarColors = [
      FlutterFlowTheme.of(context).primary.withOpacity(0.2),
      FlutterFlowTheme.of(context).secondary.withOpacity(0.2),
      FlutterFlowTheme.of(context).tertiary.withOpacity(0.2),
      FlutterFlowTheme.of(context).alternate.withOpacity(0.5),
      FlutterFlowTheme.of(context).info.withOpacity(0.2),
      FlutterFlowTheme.of(context).success.withOpacity(0.2),
      FlutterFlowTheme.of(context).warning.withOpacity(0.2),
    ];
    final String hashTarget = widget!.name ?? widget!.initials ?? 'U';
    final int colorIndex = hashTarget.hashCode.abs() % avatarColors.length;
    final Color dynamicBgColor = avatarColors[colorIndex];

    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        Container(
          decoration: BoxDecoration(),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: dynamicBgColor,
                  shape: BoxShape.circle,
                ),
                alignment: AlignmentDirectional(0.0, 0.0),
                child: Padding(
                  padding: EdgeInsets.all(14.0),
                  child: AutoSizeText(
                    valueOrDefault<String>(
                      widget!.initials,
                      'oo',
                    ),
                    maxLines: 1,
                    minFontSize: 8.0,
                    style: TextStyle(
                      color: FlutterFlowTheme.of(context).primaryText,
                      fontWeight: FontWeight.w600,
                      fontSize: 10.0,
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AutoSizeText(
                      valueOrDefault<String>(
                        widget!.name,
                        'Lena Hartfield',
                      ),
                      maxLines: 1,
                      minFontSize: 8.0,
                      style: FlutterFlowTheme.of(context).titleMedium.override(
                            font: GoogleFonts.roboto(
                              fontWeight: FlutterFlowTheme.of(context)
                                  .titleMedium
                                  .fontWeight,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .titleMedium
                                  .fontStyle,
                            ),
                            color: FlutterFlowTheme.of(context).primaryText,
                            fontSize: 12.0,
                            letterSpacing: 0.0,
                            fontWeight: FlutterFlowTheme.of(context)
                                .titleMedium
                                .fontWeight,
                            fontStyle: FlutterFlowTheme.of(context)
                                .titleMedium
                                .fontStyle,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${valueOrDefault<String>(
                        widget!.email,
                        '{{input}}',
                      )}',
                      maxLines: 1,
                      style: FlutterFlowTheme.of(context).bodySmall.override(
                            font: GoogleFonts.roboto(
                              fontWeight: FlutterFlowTheme.of(context)
                                  .bodySmall
                                  .fontWeight,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .bodySmall
                                  .fontStyle,
                            ),
                            color: FlutterFlowTheme.of(context).secondaryText,
                            fontSize: 10.0,
                            letterSpacing: 0.0,
                            fontWeight: FlutterFlowTheme.of(context)
                                .bodySmall
                                .fontWeight,
                            fontStyle: FlutterFlowTheme.of(context)
                                .bodySmall
                                .fontStyle,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ].divide(SizedBox(height: 4.0)),
                ),
              ),
              Container(
                width: 50.0,
                height: 40.0,
                decoration: BoxDecoration(
                  color: widget!.color,
                  borderRadius: BorderRadius.circular(18.0),
                  border: Border.all(
                    color: Color(0x002C2B33),
                    width: 1.0,
                  ),
                ),
                alignment: AlignmentDirectional(0.0, 0.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.all(6.0),
                        child: AutoSizeText(
                          valueOrDefault<String>(
                            widget!.role,
                            '{{dept}}',
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          minFontSize: 5.0,
                          style: FlutterFlowTheme.of(context)
                              .bodySmall
                              .override(
                                font: GoogleFonts.roboto(
                                  fontWeight: FlutterFlowTheme.of(context)
                                      .bodySmall
                                      .fontWeight,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .bodySmall
                                      .fontStyle,
                                ),
                                color: FlutterFlowTheme.of(context).primaryText,
                                fontSize: 10.0,
                                letterSpacing: 0.0,
                                fontWeight: FlutterFlowTheme.of(context)
                                    .bodySmall
                                    .fontWeight,
                                fontStyle: FlutterFlowTheme.of(context)
                                    .bodySmall
                                    .fontStyle,
                              ),
                        ),
                      ),
                    ),
                  ].divide(SizedBox(width: 4.0)),
                ),
              ),
            ].divide(SizedBox(width: 16.0)),
          ),
        ),
      ],
    );
  }
}
