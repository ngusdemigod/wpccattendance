import '/backend/supabase/supabase.dart';
import '/components/topnav_widget.dart';
import '/components/workersearchresult_widget.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_choice_chips.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/form_field_controller.dart';
import '/loaders/workerssearch_l_o_a_d_e_r/workerssearch_l_o_a_d_e_r_widget.dart';
import '/pages/departmentlist/departmentlist_widget.dart';
import '/pages/departmentlist_loader/departmentlist_loader_widget.dart';
import '/pages/empty_list/empty_list_widget.dart';
import '/pages/profileview/profileview_widget.dart';
import 'dart:math';
import 'dart:ui';
import '/flutter_flow/custom_functions.dart' as functions;
import 'eventview_widget.dart' show EventviewWidget;
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class EventviewModel extends FlutterFlowModel<EventviewWidget> {
  ///  State fields for stateful widgets in this page.

  final shortcutsFocusNode = FocusNode();
  // Model for topnav component.
  late TopnavModel topnavModel;
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode;
  TextEditingController? textController;
  String? Function(BuildContext, String?)? textControllerValidator;
  // State field(s) for ChoiceChips widget.
  FormFieldController<List<String>>? choiceChipsValueController;
  String? get choiceChipsValue =>
      choiceChipsValueController?.value?.firstOrNull;
  set choiceChipsValue(String? val) =>
      choiceChipsValueController?.value = val != null ? [val] : [];

  @override
  void initState(BuildContext context) {
    shortcutsFocusNode.requestFocus();
    topnavModel = createModel(context, () => TopnavModel());
  }

  @override
  void dispose() {
    topnavModel.dispose();
    textFieldFocusNode?.dispose();
    textController?.dispose();
  }
}
