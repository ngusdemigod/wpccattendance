import '/components/worker_search_result_widget.dart';
import '/flutter_flow/flutter_flow_choice_chips.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/form_field_controller.dart';
import 'dart:ui';
import 'attendance_list_widget.dart' show AttendanceListWidget;
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:provider/provider.dart';

class AttendanceListModel extends FlutterFlowModel<AttendanceListWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for worker_search_result component.
  late WorkerSearchResultModel workerSearchResultModel1;
  // Model for worker_search_result component.
  late WorkerSearchResultModel workerSearchResultModel2;
  // Model for worker_search_result component.
  late WorkerSearchResultModel workerSearchResultModel3;
  // State field(s) for ChoiceChips widget.
  FormFieldController<List<String>>? choiceChipsValueController;
  String? get choiceChipsValue =>
      choiceChipsValueController?.value?.firstOrNull;
  set choiceChipsValue(String? val) =>
      choiceChipsValueController?.value = val != null ? [val] : [];

  @override
  void initState(BuildContext context) {
    workerSearchResultModel1 =
        createModel(context, () => WorkerSearchResultModel());
    workerSearchResultModel2 =
        createModel(context, () => WorkerSearchResultModel());
    workerSearchResultModel3 =
        createModel(context, () => WorkerSearchResultModel());
  }

  @override
  void dispose() {
    workerSearchResultModel1.dispose();
    workerSearchResultModel2.dispose();
    workerSearchResultModel3.dispose();
  }
}
