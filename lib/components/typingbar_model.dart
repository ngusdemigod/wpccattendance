import '/auth/supabase_auth/auth_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/upload_data.dart';
import 'dart:ui';
import 'typingbar_widget.dart' show TypingbarWidget;
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class TypingbarModel extends FlutterFlowModel<TypingbarWidget> {
  ///  Local state fields for this component.
  /// temprarily store files
  List<String> tempupload = [];
  void addToTempupload(String item) => tempupload.add(item);
  void removeFromTempupload(String item) => tempupload.remove(item);
  void removeAtIndexFromTempupload(int index) => tempupload.removeAt(index);
  void insertAtIndexInTempupload(int index, String item) =>
      tempupload.insert(index, item);
  void updateTempuploadAtIndex(int index, Function(String) updateFn) =>
      tempupload[index] = updateFn(tempupload[index]);

  ///  State fields for stateful widgets in this component.

  bool isDataUploading_uploadDataOn8 = false;
  FFUploadedFile uploadedLocalFile_uploadDataOn8 =
      FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');

  // Stores action output result for [Backend Call - API (presign Rtwo Storage)] action in Icon widget.
  ApiCallResponse? presignURL;
  // Stores action output result for [Backend Call - API (Upload to storage)] action in Icon widget.
  ApiCallResponse? apiResultg9r;
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode;
  TextEditingController? textController;
  String? Function(BuildContext, String?)? textControllerValidator;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    textFieldFocusNode?.dispose();
    textController?.dispose();
  }
}
