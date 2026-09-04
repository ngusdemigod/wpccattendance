import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'info_tile3_model.dart';
export 'info_tile3_model.dart';

class InfoTile3Widget extends StatefulWidget {
  const InfoTile3Widget({
    super.key,
    this.icon,
    String? label,
    String? value,
    this.valueColor,
  })  : label = label ?? 'Date & Time',
        value = value ?? 'Sat, 9 Aug - 11:00 AM - 12:00 PM';

  final Widget? icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  State<InfoTile3Widget> createState() => _InfoTile3WidgetState();
}

class _InfoTile3WidgetState extends State<InfoTile3Widget> {
  late InfoTile3Model _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => InfoTile3Model());
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
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: const Color(0x1AC5099C),
            borderRadius: BorderRadius.circular(14),
            shape: BoxShape.rectangle,
          ),
          alignment: const AlignmentDirectional(0, 0),
          child: widget.icon!,
        ),
        const SizedBox(width: 14),
        Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              valueOrDefault<String>(widget.label, 'Date & Time'),
              style: FlutterFlowTheme.of(context).bodySmall.override(
                    font: GoogleFonts.instrumentSans(
                      fontWeight: FontWeight.w400,
                      fontStyle:
                          FlutterFlowTheme.of(context).bodySmall.fontStyle,
                    ),
                    color: const Color(0xFF9E9E9E),
                    fontSize: 12,
                    letterSpacing: 0.0,
                    fontWeight: FontWeight.w400,
                    fontStyle: FlutterFlowTheme.of(context).bodySmall.fontStyle,
                    lineHeight: 1.4,
                  ),
            ),
            Text(
              valueOrDefault<String>(
                  widget.value, 'Sat, 9 Aug - 11:00 AM - 12:00 PM'),
              style: FlutterFlowTheme.of(context).bodyMedium.override(
                    font: GoogleFonts.instrumentSans(
                      fontWeight: FontWeight.w600,
                      fontStyle:
                          FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                    ),
                    color: widget.valueColor ??
                        FlutterFlowTheme.of(context).primaryText,
                    fontSize: 16,
                    letterSpacing: 0.0,
                    fontWeight: FontWeight.w600,
                    fontStyle:
                        FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                    lineHeight: 1.5,
                  ),
            ),
          ].divide(const SizedBox(height: 4)),
        ),
      ].divide(const SizedBox(width: 16)),
    );
  }
}
