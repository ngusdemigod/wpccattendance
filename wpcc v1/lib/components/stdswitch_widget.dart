import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'stdswitch_model.dart';
export 'stdswitch_model.dart';

class StdswitchWidget extends StatefulWidget {
  const StdswitchWidget({
    super.key,
    this.active,
    this.variant,
    this.label,
  });

  final bool? active;
  final String? variant;
  final String? label;

  @override
  State<StdswitchWidget> createState() => _StdswitchWidgetState();
}

class _StdswitchWidgetState extends State<StdswitchWidget> {
  late StdswitchModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => StdswitchModel());

    _model.switchValue = false;
    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Switch(
          value: _model.switchValue!,
          onChanged: (newValue) async {
            safeSetState(() => _model.switchValue = newValue!);
          },
          activeColor: FlutterFlowTheme.of(context).primary,
          activeTrackColor: FlutterFlowTheme.of(context).accent1,
          inactiveTrackColor: FlutterFlowTheme.of(context).secondaryBackground,
          inactiveThumbColor: FlutterFlowTheme.of(context).secondaryText,
        ),
        Container(
          decoration: BoxDecoration(
            color: widget!.active == true
                ? FlutterFlowTheme.of(context).primary
                : FlutterFlowTheme.of(context).divider,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: widget!.active == true
                  ? FlutterFlowTheme.of(context).primaryBackground
                  : FlutterFlowTheme.of(context).primaryBackground,
            ),
          ),
        ),
        Container(
          child: Padding(
            padding: EdgeInsetsDirectional.fromSTEB(8.0, 0.0, 0.0, 0.0),
            child: Text(
              valueOrDefault<String>(
                widget!.label,
                'Allow late clock-in',
              ),
              style: FlutterFlowTheme.of(context).bodyMedium.override(
                    font: GoogleFonts.dmSans(
                      fontWeight: FontWeight.normal,
                      fontStyle:
                          FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                    ),
                    color: FlutterFlowTheme.of(context).primaryText,
                    fontSize: 14.0,
                    letterSpacing: 0.0,
                    fontWeight: FontWeight.normal,
                    fontStyle:
                        FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                    lineHeight: 1.5,
                  ),
            ),
          ),
        ),
      ],
    );
  }
}
