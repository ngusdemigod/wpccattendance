import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'customprogressbar_model.dart';
export 'customprogressbar_model.dart';

class CustomprogressbarWidget extends StatefulWidget {
  const CustomprogressbarWidget({
    super.key,
    required this.progress,
  });

  final double? progress;

  @override
  State<CustomprogressbarWidget> createState() =>
      _CustomprogressbarWidgetState();
}

class _CustomprogressbarWidgetState extends State<CustomprogressbarWidget> {
  late CustomprogressbarModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => CustomprogressbarModel());

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
      width: 70.0,
      decoration: BoxDecoration(),
      child: Stack(
        children: [
          Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                width: 5.0,
                height: 100.0,
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context).tertiary,
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              Container(
                width: 5.0,
                height: 100.0,
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context).tertiary,
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              Container(
                width: 5.0,
                height: 100.0,
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context).tertiary,
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              Container(
                width: 5.0,
                height: 100.0,
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context).tertiary,
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              Container(
                width: 5.0,
                height: 100.0,
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context).tertiary,
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              Container(
                width: 5.0,
                height: 100.0,
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context).tertiary,
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              Container(
                width: 5.0,
                height: 100.0,
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context).tertiary,
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              Container(
                width: 5.0,
                height: 100.0,
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context).tertiary,
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              Container(
                width: 5.0,
                height: 100.0,
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context).tertiary,
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              Container(
                width: 5.0,
                height: 100.0,
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context).tertiary,
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
            ].divide(SizedBox(width: 2.0)),
          ),
          Builder(
            builder: (context) {
              if (widget!.progress! <= 10.0) {
                return Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Container(
                      width: 5.0,
                      height: 100.0,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).error,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                  ].divide(SizedBox(width: 2.0)),
                );
              } else if (widget!.progress! <= 20.0) {
                return Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Container(
                      width: 5.0,
                      height: 100.0,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).error,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    Container(
                      width: 5.0,
                      height: 100.0,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).error,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                  ].divide(SizedBox(width: 2.0)),
                );
              } else if (widget!.progress! <= 30.0) {
                return Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Container(
                      width: 5.0,
                      height: 100.0,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).error,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    Container(
                      width: 5.0,
                      height: 100.0,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).error,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    Container(
                      width: 5.0,
                      height: 100.0,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).error,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                  ].divide(SizedBox(width: 2.0)),
                );
              } else if (widget!.progress! <= 40.0) {
                return Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Container(
                      width: 5.0,
                      height: 100.0,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).accent1,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    Container(
                      width: 5.0,
                      height: 100.0,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).warning,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    Container(
                      width: 5.0,
                      height: 100.0,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).warning,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    Container(
                      width: 5.0,
                      height: 100.0,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).warning,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                  ].divide(SizedBox(width: 2.0)),
                );
              } else if (widget!.progress! <= 50.0) {
                return Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Container(
                      width: 5.0,
                      height: 100.0,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).accent1,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    Container(
                      width: 5.0,
                      height: 100.0,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).accent1,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    Container(
                      width: 5.0,
                      height: 100.0,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).warning,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    Container(
                      width: 5.0,
                      height: 100.0,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).warning,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    Container(
                      width: 5.0,
                      height: 100.0,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).warning,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                  ].divide(SizedBox(width: 2.0)),
                );
              } else if (widget!.progress! <= 60.0) {
                return Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Container(
                      width: 5.0,
                      height: 100.0,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).accent1,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    Container(
                      width: 5.0,
                      height: 100.0,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).accent1,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    Container(
                      width: 5.0,
                      height: 100.0,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).accent1,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    Container(
                      width: 5.0,
                      height: 100.0,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).warning,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    Container(
                      width: 5.0,
                      height: 100.0,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).warning,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    Container(
                      width: 5.0,
                      height: 100.0,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).warning,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                  ].divide(SizedBox(width: 2.0)),
                );
              } else if (widget!.progress! <= 70.0) {
                return Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Container(
                      width: 5.0,
                      height: 100.0,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).accent1,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    Container(
                      width: 5.0,
                      height: 100.0,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).accent1,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    Container(
                      width: 5.0,
                      height: 100.0,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).accent1,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    Container(
                      width: 5.0,
                      height: 100.0,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).warning,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    Container(
                      width: 5.0,
                      height: 100.0,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).warning,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    Container(
                      width: 5.0,
                      height: 100.0,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).warning,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    Container(
                      width: 5.0,
                      height: 100.0,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).warning,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                  ].divide(SizedBox(width: 2.0)),
                );
              } else if (widget!.progress! <= 80.0) {
                return Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Container(
                      width: 5.0,
                      height: 100.0,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).success,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    Container(
                      width: 5.0,
                      height: 100.0,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).success,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    Container(
                      width: 5.0,
                      height: 100.0,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).success,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    Container(
                      width: 5.0,
                      height: 100.0,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).success,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    Container(
                      width: 5.0,
                      height: 100.0,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).success,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    Container(
                      width: 5.0,
                      height: 100.0,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).success,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    Container(
                      width: 5.0,
                      height: 100.0,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).success,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    Container(
                      width: 5.0,
                      height: 100.0,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).success,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                  ].divide(SizedBox(width: 2.0)),
                );
              } else if (widget!.progress! <= 90.0) {
                return Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Container(
                      width: 5.0,
                      height: 100.0,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).success,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    Container(
                      width: 5.0,
                      height: 100.0,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).success,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    Container(
                      width: 5.0,
                      height: 100.0,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).success,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    Container(
                      width: 5.0,
                      height: 100.0,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).success,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    Container(
                      width: 5.0,
                      height: 100.0,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).success,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    Container(
                      width: 5.0,
                      height: 100.0,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).success,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    Container(
                      width: 5.0,
                      height: 100.0,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).success,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    Container(
                      width: 5.0,
                      height: 100.0,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).success,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    Container(
                      width: 5.0,
                      height: 100.0,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).success,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                  ].divide(SizedBox(width: 2.0)),
                );
              } else {
                return Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Container(
                      width: 5.0,
                      height: 100.0,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).success,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    Container(
                      width: 5.0,
                      height: 100.0,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).success,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    Container(
                      width: 5.0,
                      height: 100.0,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).success,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    Container(
                      width: 5.0,
                      height: 100.0,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).success,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    Container(
                      width: 5.0,
                      height: 100.0,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).success,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    Container(
                      width: 5.0,
                      height: 100.0,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).success,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    Container(
                      width: 5.0,
                      height: 100.0,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).success,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    Container(
                      width: 5.0,
                      height: 100.0,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).success,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    Container(
                      width: 5.0,
                      height: 100.0,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).success,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    Container(
                      width: 5.0,
                      height: 100.0,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).success,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                  ].divide(SizedBox(width: 2.0)),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
