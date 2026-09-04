import '/flutter_flow/flutter_flow_util.dart';
import 'login_widget.dart' show LoginWidget;
import 'package:flutter/material.dart';

class LoginModel extends FlutterFlowModel<LoginWidget> {
  TextEditingController? memberCodeTextController;
  FocusNode? memberCodeFocusNode;

  bool isLoading = false;
  String? errorText;

  @override
  void initState(BuildContext context) {
    memberCodeTextController ??= TextEditingController();
    memberCodeFocusNode ??= FocusNode();
  }

  @override
  void dispose() {
    memberCodeTextController?.dispose();
    memberCodeFocusNode?.dispose();
  }
}
