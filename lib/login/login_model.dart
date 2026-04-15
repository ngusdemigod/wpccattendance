import '/auth/supabase_auth/auth_util.dart';
import '/components/attendanceprogess_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import '/flutter_flow/custom_functions.dart' as functions;
import 'login_widget.dart' show LoginWidget;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class LoginModel extends FlutterFlowModel<LoginWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for attendanceprogess component.
  late AttendanceprogessModel attendanceprogessModel;

  @override
  void initState(BuildContext context) {
    attendanceprogessModel =
        createModel(context, () => AttendanceprogessModel());
  }

  @override
  void dispose() {
    attendanceprogessModel.dispose();
  }
}
