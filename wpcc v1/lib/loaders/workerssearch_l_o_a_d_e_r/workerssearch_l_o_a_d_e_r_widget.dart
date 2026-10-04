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
import 'workerssearch_l_o_a_d_e_r_model.dart';
export 'workerssearch_l_o_a_d_e_r_model.dart';

class WorkerssearchLOADERWidget extends StatefulWidget {
  const WorkerssearchLOADERWidget({
    super.key,
    this.initials,
    this.name,
    this.email,
    this.role,
    Color? color,
  }) : this.color = color ?? const Color(0x1CFFFFFF);

  final String? initials;
  final String? name;
  final String? email;
  final String? role;
  final Color color;

  @override
  State<WorkerssearchLOADERWidget> createState() =>
      _WorkerssearchLOADERWidgetState();
}

class _WorkerssearchLOADERWidgetState extends State<WorkerssearchLOADERWidget>
    with TickerProviderStateMixin {
  late WorkerssearchLOADERModel _model;

  final animationsMap = <String, AnimationInfo>{};

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => WorkerssearchLOADERModel());

    animationsMap.addAll({
      'containerOnPageLoadAnimation1': AnimationInfo(
        loop: true,
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          ShimmerEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 1000.0.ms,
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
            delay: 0.0.ms,
            duration: 1220.0.ms,
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
            delay: 0.0.ms,
            duration: 1410.0.ms,
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
    return Stack(
      children: [
        Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Container(
              decoration: BoxDecoration(),
              child: Padding(
                padding: EdgeInsetsDirectional.fromSTEB(8.0, 0.0, 8.0, 0.0),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 44.0,
                      height: 44.0,
                      decoration: BoxDecoration(
                        color: Color(0x45717171),
                        shape: BoxShape.circle,
                      ),
                      alignment: AlignmentDirectional(0.0, 0.0),
                    ),
                    Expanded(
                      flex: 1,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 140.0,
                            height: 14.0,
                            decoration: BoxDecoration(
                              color: Color(0x45717171),
                            ),
                          ),
                          Container(
                            width: 50.0,
                            height: 14.0,
                            decoration: BoxDecoration(
                              color: Color(0x45717171),
                            ),
                          ),
                        ].divide(SizedBox(height: 4.0)),
                      ),
                    ),
                    Container(
                      width: 125.0,
                      height: 40.0,
                      decoration: BoxDecoration(
                        color: Color(0x45181818),
                        borderRadius: BorderRadius.circular(18.0),
                        border: Border.all(
                          color: Colors.transparent,
                          width: 1.0,
                        ),
                      ),
                      alignment: AlignmentDirectional(0.0, 0.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[].divide(SizedBox(width: 4.0)),
                      ),
                    ),
                  ].divide(SizedBox(width: 16.0)),
                ),
              ),
            ).animateOnPageLoad(
                animationsMap['containerOnPageLoadAnimation1']!),
            Container(
              decoration: BoxDecoration(),
              child: Padding(
                padding: EdgeInsetsDirectional.fromSTEB(8.0, 0.0, 8.0, 0.0),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 44.0,
                      height: 44.0,
                      decoration: BoxDecoration(
                        color: Color(0x45717171),
                        shape: BoxShape.circle,
                      ),
                      alignment: AlignmentDirectional(0.0, 0.0),
                    ),
                    Expanded(
                      flex: 1,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 140.0,
                            height: 14.0,
                            decoration: BoxDecoration(
                              color: Color(0x45717171),
                            ),
                          ),
                          Container(
                            width: 50.0,
                            height: 14.0,
                            decoration: BoxDecoration(
                              color: Color(0x45717171),
                            ),
                          ),
                        ].divide(SizedBox(height: 4.0)),
                      ),
                    ),
                    Container(
                      width: 125.0,
                      height: 40.0,
                      decoration: BoxDecoration(
                        color: Color(0x45181818),
                        borderRadius: BorderRadius.circular(18.0),
                        border: Border.all(
                          color: Colors.transparent,
                          width: 1.0,
                        ),
                      ),
                      alignment: AlignmentDirectional(0.0, 0.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[].divide(SizedBox(width: 4.0)),
                      ),
                    ),
                  ].divide(SizedBox(width: 16.0)),
                ),
              ),
            ).animateOnPageLoad(
                animationsMap['containerOnPageLoadAnimation2']!),
            Container(
              decoration: BoxDecoration(),
              child: Padding(
                padding: EdgeInsetsDirectional.fromSTEB(8.0, 0.0, 8.0, 0.0),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 44.0,
                      height: 44.0,
                      decoration: BoxDecoration(
                        color: Color(0x45717171),
                        shape: BoxShape.circle,
                      ),
                      alignment: AlignmentDirectional(0.0, 0.0),
                    ),
                    Expanded(
                      flex: 1,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 140.0,
                            height: 14.0,
                            decoration: BoxDecoration(
                              color: Color(0x45717171),
                            ),
                          ),
                          Container(
                            width: 50.0,
                            height: 14.0,
                            decoration: BoxDecoration(
                              color: Color(0x45717171),
                            ),
                          ),
                        ].divide(SizedBox(height: 4.0)),
                      ),
                    ),
                    Container(
                      width: 125.0,
                      height: 40.0,
                      decoration: BoxDecoration(
                        color: Color(0x45181818),
                        borderRadius: BorderRadius.circular(18.0),
                        border: Border.all(
                          color: Colors.transparent,
                          width: 1.0,
                        ),
                      ),
                      alignment: AlignmentDirectional(0.0, 0.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[].divide(SizedBox(width: 4.0)),
                      ),
                    ),
                  ].divide(SizedBox(width: 16.0)),
                ),
              ),
            ).animateOnPageLoad(
                animationsMap['containerOnPageLoadAnimation3']!),
          ].divide(SizedBox(height: 8.0)),
        ),
      ],
    );
  }
}
