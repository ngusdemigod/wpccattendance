import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'statpillb86510c8_model.dart';
export 'statpillb86510c8_model.dart';

class Statpillb86510c8Widget extends StatefulWidget {
  const Statpillb86510c8Widget({
    super.key,
    this.color,
    this.label,
    this.value,
  });

  final Color? color;
  final String? label;
  final double? value;

  @override
  State<Statpillb86510c8Widget> createState() => _Statpillb86510c8WidgetState();
}

class _Statpillb86510c8WidgetState extends State<Statpillb86510c8Widget> {
  late Statpillb86510c8Model _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => Statpillb86510c8Model());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
        borderRadius: BorderRadius.circular(9999.0),
        border: Border.all(
          color: FlutterFlowTheme.of(context).divider,
          width: 1.0,
        ),
      ),
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(24.0, 8.0, 24.0, 8.0),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 8.0,
              height: 8.0,
              decoration: BoxDecoration(
                color: valueOrDefault<Color>(
                  widget!.color,
                  Color(0x00000000),
                ),
                borderRadius: BorderRadius.circular(9999.0),
              ),
            ),
            Text(
              '${widget!.label}: ${widget!.value?.toString()}',
              style: FlutterFlowTheme.of(context).labelMedium.override(
                    font: GoogleFonts.nunito(
                      fontWeight: FontWeight.bold,
                      fontStyle:
                          FlutterFlowTheme.of(context).labelMedium.fontStyle,
                    ),
                    color: FlutterFlowTheme.of(context).primaryText,
                    fontSize: 12.0,
                    letterSpacing: 0.0,
                    fontWeight: FontWeight.bold,
                    fontStyle:
                        FlutterFlowTheme.of(context).labelMedium.fontStyle,
                    lineHeight: 1.3,
                  ),
            ),
          ].divide(SizedBox(width: 8.0)),
        ),
      ),
    );
  }
}
