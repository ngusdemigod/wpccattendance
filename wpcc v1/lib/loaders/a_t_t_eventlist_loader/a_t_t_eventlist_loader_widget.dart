import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'a_t_t_eventlist_loader_model.dart';
export 'a_t_t_eventlist_loader_model.dart';

class ATTEventlistLoaderWidget extends StatefulWidget {
  const ATTEventlistLoaderWidget({super.key});

  @override
  State<ATTEventlistLoaderWidget> createState() =>
      _ATTEventlistLoaderWidgetState();
}

class _ATTEventlistLoaderWidgetState extends State<ATTEventlistLoaderWidget>
    with TickerProviderStateMixin {
  late ATTEventlistLoaderModel _model;

  final animationsMap = <String, AnimationInfo>{};

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ATTEventlistLoaderModel());

    animationsMap.addAll({
      'containerOnPageLoadAnimation1': AnimationInfo(
        loop: true,
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          ShimmerEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 960.0.ms,
            color: Color(0x80FFFFFF),
            angle: 0.524,
          ),
        ],
      ),
      'containerOnPageLoadAnimation2': AnimationInfo(
        loop: true,
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          ShimmerEffect(
            curve: Curves.easeInOut,
            delay: 140.0.ms,
            duration: 960.0.ms,
            color: Color(0x80FFFFFF),
            angle: 0.524,
          ),
        ],
      ),
      'containerOnPageLoadAnimation3': AnimationInfo(
        loop: true,
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          ShimmerEffect(
            curve: Curves.easeInOut,
            delay: 200.0.ms,
            duration: 960.0.ms,
            color: Color(0x80FFFFFF),
            angle: 0.524,
          ),
        ],
      ),
      'containerOnPageLoadAnimation4': AnimationInfo(
        loop: true,
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          ShimmerEffect(
            curve: Curves.easeInOut,
            delay: 250.0.ms,
            duration: 960.0.ms,
            color: Color(0x80FFFFFF),
            angle: 0.524,
          ),
        ],
      ),
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Color(0xFF1F1E27),
                borderRadius: BorderRadius.circular(28.0),
                border: Border.all(
                  color: FlutterFlowTheme.of(context).divider,
                  width: 1.0,
                ),
              ),
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16.0),
                      child: Container(
                        width: 80.0,
                        height: 62.2,
                        decoration: BoxDecoration(
                          color: FlutterFlowTheme.of(context).alternate,
                          borderRadius: BorderRadius.circular(16.0),
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
                          Container(
                            width: 100.0,
                            height: 16.7,
                            decoration: BoxDecoration(
                              color: FlutterFlowTheme.of(context).alternate,
                            ),
                          ),
                          Container(
                            width: MediaQuery.sizeOf(context).width * 0.7,
                            height: 16.7,
                            decoration: BoxDecoration(
                              color: FlutterFlowTheme.of(context).alternate,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                                0.0, 4.0, 0.0, 0.0),
                            child: Container(
                              width: MediaQuery.sizeOf(context).width * 0.3,
                              height: 16.7,
                              decoration: BoxDecoration(
                                color: FlutterFlowTheme.of(context).alternate,
                              ),
                            ),
                          ),
                        ].divide(SizedBox(height: 4.0)),
                      ),
                    ),
                  ].divide(SizedBox(width: 16.0)),
                ),
              ),
            ),
            Container(
              width: MediaQuery.sizeOf(context).width * 1.0,
              height: 94.7,
              decoration: BoxDecoration(
                color: Color(0x340F0E13),
                borderRadius: BorderRadius.circular(28.0),
                border: Border.all(
                  color: FlutterFlowTheme.of(context).divider,
                  width: 1.0,
                ),
              ),
            ).animateOnPageLoad(
                animationsMap['containerOnPageLoadAnimation1']!),
          ],
        ),
        Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Color(0xFF1F1E27),
                borderRadius: BorderRadius.circular(28.0),
                border: Border.all(
                  color: FlutterFlowTheme.of(context).divider,
                  width: 1.0,
                ),
              ),
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16.0),
                      child: Container(
                        width: 80.0,
                        height: 62.2,
                        decoration: BoxDecoration(
                          color: FlutterFlowTheme.of(context).alternate,
                          borderRadius: BorderRadius.circular(16.0),
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
                          Container(
                            width: 100.0,
                            height: 16.7,
                            decoration: BoxDecoration(
                              color: FlutterFlowTheme.of(context).alternate,
                            ),
                          ),
                          Container(
                            width: MediaQuery.sizeOf(context).width * 0.7,
                            height: 16.7,
                            decoration: BoxDecoration(
                              color: FlutterFlowTheme.of(context).alternate,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                                0.0, 4.0, 0.0, 0.0),
                            child: Container(
                              width: MediaQuery.sizeOf(context).width * 0.3,
                              height: 16.7,
                              decoration: BoxDecoration(
                                color: FlutterFlowTheme.of(context).alternate,
                              ),
                            ),
                          ),
                        ].divide(SizedBox(height: 4.0)),
                      ),
                    ),
                  ].divide(SizedBox(width: 16.0)),
                ),
              ),
            ),
            Container(
              width: MediaQuery.sizeOf(context).width * 1.0,
              height: 94.7,
              decoration: BoxDecoration(
                color: Color(0x340F0E13),
                borderRadius: BorderRadius.circular(28.0),
                border: Border.all(
                  color: FlutterFlowTheme.of(context).divider,
                  width: 1.0,
                ),
              ),
            ).animateOnPageLoad(
                animationsMap['containerOnPageLoadAnimation2']!),
          ],
        ),
        Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Color(0xFF1F1E27),
                borderRadius: BorderRadius.circular(28.0),
                border: Border.all(
                  color: FlutterFlowTheme.of(context).divider,
                  width: 1.0,
                ),
              ),
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16.0),
                      child: Container(
                        width: 80.0,
                        height: 62.2,
                        decoration: BoxDecoration(
                          color: FlutterFlowTheme.of(context).alternate,
                          borderRadius: BorderRadius.circular(16.0),
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
                          Container(
                            width: 100.0,
                            height: 16.7,
                            decoration: BoxDecoration(
                              color: FlutterFlowTheme.of(context).alternate,
                            ),
                          ),
                          Container(
                            width: MediaQuery.sizeOf(context).width * 0.7,
                            height: 16.7,
                            decoration: BoxDecoration(
                              color: FlutterFlowTheme.of(context).alternate,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                                0.0, 4.0, 0.0, 0.0),
                            child: Container(
                              width: MediaQuery.sizeOf(context).width * 0.3,
                              height: 16.7,
                              decoration: BoxDecoration(
                                color: FlutterFlowTheme.of(context).alternate,
                              ),
                            ),
                          ),
                        ].divide(SizedBox(height: 4.0)),
                      ),
                    ),
                  ].divide(SizedBox(width: 16.0)),
                ),
              ),
            ),
            Container(
              width: MediaQuery.sizeOf(context).width * 1.0,
              height: 94.7,
              decoration: BoxDecoration(
                color: Color(0x340F0E13),
                borderRadius: BorderRadius.circular(28.0),
                border: Border.all(
                  color: FlutterFlowTheme.of(context).divider,
                  width: 1.0,
                ),
              ),
            ).animateOnPageLoad(
                animationsMap['containerOnPageLoadAnimation3']!),
          ],
        ),
        Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Color(0xFF1F1E27),
                borderRadius: BorderRadius.circular(28.0),
                border: Border.all(
                  color: FlutterFlowTheme.of(context).divider,
                  width: 1.0,
                ),
              ),
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16.0),
                      child: Container(
                        width: 80.0,
                        height: 62.2,
                        decoration: BoxDecoration(
                          color: FlutterFlowTheme.of(context).alternate,
                          borderRadius: BorderRadius.circular(16.0),
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
                          Container(
                            width: 100.0,
                            height: 16.7,
                            decoration: BoxDecoration(
                              color: FlutterFlowTheme.of(context).alternate,
                            ),
                          ),
                          Container(
                            width: MediaQuery.sizeOf(context).width * 0.7,
                            height: 16.7,
                            decoration: BoxDecoration(
                              color: FlutterFlowTheme.of(context).alternate,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                                0.0, 4.0, 0.0, 0.0),
                            child: Container(
                              width: MediaQuery.sizeOf(context).width * 0.3,
                              height: 16.7,
                              decoration: BoxDecoration(
                                color: FlutterFlowTheme.of(context).alternate,
                              ),
                            ),
                          ),
                        ].divide(SizedBox(height: 4.0)),
                      ),
                    ),
                  ].divide(SizedBox(width: 16.0)),
                ),
              ),
            ),
            Container(
              width: MediaQuery.sizeOf(context).width * 1.0,
              height: 94.7,
              decoration: BoxDecoration(
                color: Color(0x340F0E13),
                borderRadius: BorderRadius.circular(28.0),
                border: Border.all(
                  color: FlutterFlowTheme.of(context).divider,
                  width: 1.0,
                ),
              ),
            ).animateOnPageLoad(
                animationsMap['containerOnPageLoadAnimation4']!),
          ],
        ),
      ].divide(SizedBox(height: 8.0)),
    );
  }
}
