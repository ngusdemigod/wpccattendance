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
import 'eventprofile_loading_model.dart';
export 'eventprofile_loading_model.dart';

class EventprofileLoadingWidget extends StatefulWidget {
  const EventprofileLoadingWidget({super.key});

  @override
  State<EventprofileLoadingWidget> createState() =>
      _EventprofileLoadingWidgetState();
}

class _EventprofileLoadingWidgetState extends State<EventprofileLoadingWidget>
    with TickerProviderStateMixin {
  late EventprofileLoadingModel _model;

  final animationsMap = <String, AnimationInfo>{};

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => EventprofileLoadingModel());

    animationsMap.addAll({
      'containerOnPageLoadAnimation1': AnimationInfo(
        loop: true,
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          ShimmerEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 600.0.ms,
            color: Color(0x80131313),
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
            delay: 0.0.ms,
            duration: 600.0.ms,
            color: Color(0x80131313),
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
            delay: 0.0.ms,
            duration: 600.0.ms,
            color: Color(0x80131313),
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
            delay: 0.0.ms,
            duration: 600.0.ms,
            color: Color(0x80131313),
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
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 200.0,
          height: 200.0,
          decoration: BoxDecoration(
            color: FlutterFlowTheme.of(context).primaryBackground,
            shape: BoxShape.circle,
          ),
        ).animateOnPageLoad(animationsMap['containerOnPageLoadAnimation1']!),
        Padding(
          padding: EdgeInsetsDirectional.fromSTEB(0.0, 12.0, 0.0, 0.0),
          child: Container(
            width: 241.2,
            height: 16.3,
            decoration: BoxDecoration(
              color: FlutterFlowTheme.of(context).primaryBackground,
            ),
          ).animateOnPageLoad(animationsMap['containerOnPageLoadAnimation2']!),
        ),
        Padding(
          padding: EdgeInsetsDirectional.fromSTEB(0.0, 12.0, 0.0, 0.0),
          child: Container(
            width: 150.0,
            height: 16.3,
            decoration: BoxDecoration(
              color: FlutterFlowTheme.of(context).primaryBackground,
            ),
          ).animateOnPageLoad(animationsMap['containerOnPageLoadAnimation3']!),
        ),
        Padding(
          padding: EdgeInsetsDirectional.fromSTEB(0.0, 12.0, 0.0, 0.0),
          child: Container(
            width: 291.7,
            height: 52.54,
            decoration: BoxDecoration(
              color: FlutterFlowTheme.of(context).primaryBackground,
              borderRadius: BorderRadius.circular(12.0),
            ),
          ).animateOnPageLoad(animationsMap['containerOnPageLoadAnimation4']!),
        ),
      ],
    );
  }
}
