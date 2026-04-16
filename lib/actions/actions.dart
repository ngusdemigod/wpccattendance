import '/auth/supabase_auth/auth_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/backend/api_requests/api_manager.dart';
import '/backend/schema/structs/index.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

Future<String?> uploadimage(
  BuildContext context, {
  required String? filename,
  required FFUploadedFile? uploadedfile,
}) async {
  ApiCallResponse? presignuploadurl;
  ApiCallResponse? uploadfile;

  // Generate a unique filename with timestamp to avoid collision and caching issues
  final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
  final String sanitizedFilename =
      (filename ?? 'image').replaceAll(RegExp(r'\s+'), '_');
  
  // Ensure currentUserUid is available, default to "anon" if not
  final String uid = currentUserUid != null && currentUserUid.isNotEmpty ? currentUserUid : 'anon';
  
  final String finalKey = 'pfp/$uid/${timestamp}_$sanitizedFilename';

  // Detect content type based on extension
  String contentType = 'application/octet-stream';
  if (filename != null) {
    String ext = filename.toLowerCase();
    if (ext.endsWith('.jpg') || ext.endsWith('.jpeg')) {
      contentType = 'image/jpeg';
    } else if (ext.endsWith('.png')) {
      contentType = 'image/png';
    } else if (ext.endsWith('.gif')) {
      contentType = 'image/gif';
    } else if (ext.endsWith('.webp')) {
      contentType = 'image/webp';
    }
  }

  // PRESIGN R2 URL
  presignuploadurl = await PresignRtwoStorageCall.call(
    bucket: 'wpcc',
    objectKey: finalKey,
    contentType: contentType,
  );

  if (!(presignuploadurl?.succeeded ?? false)) {
    return null;
  }

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

  if (!(uploadfile?.succeeded ?? false)) {
    return null;
  }

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
  return '${FFAppState().storagpuburl}$finalKey';
}
