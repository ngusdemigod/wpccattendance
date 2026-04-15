import '/auth/supabase_auth/auth_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/backend/api_requests/api_manager.dart';
import '/backend/schema/structs/index.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

Future<String> uploadimage(
  BuildContext context, {
  required String? filename,
  required FFUploadedFile? uploadedfile,
}) async {
  ApiCallResponse? presignuploadurl;
  ApiCallResponse? uploadfile;

  // PRESIGN R2 URL
  presignuploadurl = await PresignRtwoStorageCall.call(
    bucket: 'wpcc',
    objectKey: 'pfp/${currentUserUid}/${filename}.jpg',
  );

  ScaffoldMessenger.of(context).clearSnackBars();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        'signed',
        style: TextStyle(),
      ),
      duration: Duration(milliseconds: 4000),
      backgroundColor: FlutterFlowTheme.of(context).secondary,
    ),
  );
  uploadfile = await UploadToStorageCall.call(
    url: PresignRtwoStorageCall.url(
      (presignuploadurl?.jsonBody ?? ''),
    ),
    file: uploadedfile,
    jwt: currentJwtToken,
  );

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        'uploaded',
        style: TextStyle(),
      ),
      duration: Duration(milliseconds: 4000),
      backgroundColor: FlutterFlowTheme.of(context).secondary,
    ),
  );
  return UploadToStorageCall.uploadURL(
    (uploadfile?.jsonBody ?? ''),
  ).toString();
}
