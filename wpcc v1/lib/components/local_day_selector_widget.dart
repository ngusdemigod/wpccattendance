import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'local_day_selector_model.dart';
export 'local_day_selector_model.dart';

class LocalDaySelectorWidget extends StatefulWidget {
  const LocalDaySelectorWidget({
    super.key,
    this.active,
    this.label,
  });

  final bool? active;
  final String? label;

  @override
  State<LocalDaySelectorWidget> createState() => _LocalDaySelectorWidgetState();
}

class _LocalDaySelectorWidgetState extends State<LocalDaySelectorWidget> {
  late LocalDaySelectorModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => LocalDaySelectorModel());

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
      width: 44.0,
      height: 52.0,
      decoration: BoxDecoration(
        color: widget!.active == true
            ? FlutterFlowTheme.of(context).primaryText
            : FlutterFlowTheme.of(context).secondaryBackground,
        borderRadius: BorderRadius.circular(9999.0),
      ),
      alignment: AlignmentDirectional(0.0, 0.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            valueOrDefault<String>(
              widget!.label,
              'S',
            ),
            style: FlutterFlowTheme.of(context).labelLarge.override(
                  font: GoogleFonts.nunito(
                    fontWeight: FontWeight.bold,
                    fontStyle:
                        FlutterFlowTheme.of(context).labelLarge.fontStyle,
                  ),
                  color: widget!.active == true
                      ? FlutterFlowTheme.of(context).primaryBackground
                      : FlutterFlowTheme.of(context).secondaryText,
                  fontSize: 14.0,
                  letterSpacing: 0.0,
                  fontWeight: FontWeight.bold,
                  fontStyle: FlutterFlowTheme.of(context).labelLarge.fontStyle,
                  lineHeight: 1.3,
                ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 4.0,
                height: 4.0,
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context).secondary,
                  borderRadius: BorderRadius.circular(9999.0),
                ),
              ),
              Container(
                width: 4.0,
                height: 4.0,
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context).primary,
                  borderRadius: BorderRadius.circular(9999.0),
                ),
              ),
            ].divide(SizedBox(width: 2.0)),
          ),
        ].divide(SizedBox(height: 4.0)),
      ),
    );
  }
}
