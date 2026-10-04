import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'attendee_stack2_model.dart';
export 'attendee_stack2_model.dart';

class AttendeeStack2Widget extends StatefulWidget {
  const AttendeeStack2Widget({
    super.key,
    this.totalWorkers,
  });

  final int? totalWorkers;

  @override
  State<AttendeeStack2Widget> createState() => _AttendeeStack2WidgetState();
}

class _AttendeeStack2WidgetState extends State<AttendeeStack2Widget> {
  late AttendeeStack2Model _model;

  String _attendingText(int? totalWorkers) {
    if (totalWorkers == null || totalWorkers <= 0) {
      return '0+ Attending';
    }
    if (totalWorkers >= 1000000) {
      final value = totalWorkers / 1000000;
      final formatted = value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
      return '${formatted}M+ Attending';
    }
    if (totalWorkers >= 1000) {
      final value = totalWorkers / 1000;
      final formatted = value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
      return '${formatted}K+ Attending';
    }
    return '$totalWorkers+ Attending';
  }

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AttendeeStack2Model());

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
        Text(
          _attendingText(widget.totalWorkers),
          style: FlutterFlowTheme.of(context).labelMedium.override(
                font: GoogleFonts.instrumentSans(
                  fontWeight: FontWeight.w600,
                  fontStyle: FlutterFlowTheme.of(context).labelMedium.fontStyle,
                ),
                color: const Color(0xFFD5D5D5),
                fontSize: 15,
                letterSpacing: 0.0,
                fontWeight: FontWeight.w600,
                fontStyle: FlutterFlowTheme.of(context).labelMedium.fontStyle,
                lineHeight: 1.3,
              ),
        ),
      ].divide(const SizedBox(width: 8)),
    );
  }
}
