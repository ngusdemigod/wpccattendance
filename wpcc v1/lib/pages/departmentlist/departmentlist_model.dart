import '/components/customprogressbar_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/pages/dept_attendance/dept_attendance_widget.dart';
import 'dart:ui';
import 'departmentlist_widget.dart' show DepartmentlistWidget;
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class DepartmentlistModel extends FlutterFlowModel<DepartmentlistWidget> {
  ///  State fields for stateful widgets in this component.

  // Model for customprogressbar component.
  late CustomprogressbarModel customprogressbarModel;

  @override
  void initState(BuildContext context) {
    customprogressbarModel =
        createModel(context, () => CustomprogressbarModel());
  }

  @override
  void dispose() {
    customprogressbarModel.dispose();
  }
}
