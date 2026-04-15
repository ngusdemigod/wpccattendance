import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'filter_chip_model.dart';
export 'filter_chip_model.dart';

class FilterChipWidget extends StatefulWidget {
  const FilterChipWidget({
    super.key,
    this.selected,
    this.label,
  });

  final bool? selected;
  final String? label;

  @override
  State<FilterChipWidget> createState() => _FilterChipWidgetState();
}

class _FilterChipWidgetState extends State<FilterChipWidget> {
  late FilterChipModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => FilterChipModel());

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
        color: widget!.selected == false
            ? FlutterFlowTheme.of(context).secondaryBackground
            : FlutterFlowTheme.of(context).primary,
        borderRadius: BorderRadius.circular(9999.0),
      ),
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(24.0, 8.0, 24.0, 8.0),
        child: Text(
          valueOrDefault<String>(
            widget!.label,
            'All Workers',
          ),
          style: FlutterFlowTheme.of(context).labelLarge.override(
                font: GoogleFonts.nunito(
                  fontWeight: FontWeight.w500,
                  fontStyle: FlutterFlowTheme.of(context).labelLarge.fontStyle,
                ),
                color: widget!.selected == false
                    ? FlutterFlowTheme.of(context).secondaryText
                    : FlutterFlowTheme.of(context).primaryBackground,
                fontSize: 14.0,
                letterSpacing: 0.0,
                fontWeight: FontWeight.w500,
                fontStyle: FlutterFlowTheme.of(context).labelLarge.fontStyle,
                lineHeight: 1.3,
              ),
        ),
      ),
    );
  }
}
