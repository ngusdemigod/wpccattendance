import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'customswitch_model.dart';
export 'customswitch_model.dart';

class CustomswitchWidget extends StatefulWidget {
  const CustomswitchWidget({
    super.key,
    this.active,
    this.variant,
    this.label,
  });

  final bool? active;
  final String? variant;
  final String? label;

  @override
  State<CustomswitchWidget> createState() => _CustomswitchWidgetState();
}

class _CustomswitchWidgetState extends State<CustomswitchWidget> {
  late CustomswitchModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => CustomswitchModel());

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
              widget!.label!,
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
