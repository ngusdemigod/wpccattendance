import 'dart:convert';
import 'dart:typed_data';
import '../schema/structs/index.dart';

import 'package:flutter/foundation.dart';

import '/flutter_flow/flutter_flow_util.dart';
import 'api_manager.dart';

export 'api_manager.dart' show ApiCallResponse;

const _kPrivateApiFunctionName = 'ffPrivateApiCall';

class PresignRtwoStorageCall {
  static Future<ApiCallResponse> call({
    String? bucket = '',
    String? objectKey = '',
    String? jwt = '',
  }) async {
    return ApiManager.instance.makeApiCall(
      callName: 'presign Rtwo Storage',
      apiUrl:
          'https://pgpihzhvysbadrzjhvxw.supabase.co/functions/v1/presign-r2-upload',
      callType: ApiCallType.GET,
      headers: {
        'Authorization':
            'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBncGloemh2eXNiYWRyempodnh3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzIzNTc5ODcsImV4cCI6MjA4NzkzMzk4N30.rO-wc44xJhnDgAak_ltlcs6W0Eo77r2MPCRtqpR-g_w',
      },
      params: {
        'bucket': bucket,
        'objectKey': objectKey,
      },
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  static String? url(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.url''',
      ));
}

class UploadToStorageCall {
  static Future<ApiCallResponse> call({
    String? url = '',
    FFUploadedFile? file,
    String? jwt = '',
  }) async {
    return ApiManager.instance.makeApiCall(
      callName: 'Upload to storage',
      apiUrl:
          'https://pgpihzhvysbadrzjhvxw.supabase.co/functions/v1/Deploy-to-R2-bucket',
      callType: ApiCallType.POST,
      headers: {
        'Authorization':
            'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBncGloemh2eXNiYWRyempodnh3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzIzNTc5ODcsImV4cCI6MjA4NzkzMzk4N30.rO-wc44xJhnDgAak_ltlcs6W0Eo77r2MPCRtqpR-g_w',
      },
      params: {
        'uploadUrl': url,
        'file': file,
      },
      bodyType: BodyType.MULTIPART,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  static dynamic uploadURL(dynamic response) => getJsonField(
        response,
        r'''$.uploadUrl''',
      );
  static dynamic message(dynamic response) => getJsonField(
        response,
        r'''$.message''',
      );
}

class ApiPagingParams {
  int nextPageNumber = 0;
  int numItems = 0;
  dynamic lastResponse;

  ApiPagingParams({
    required this.nextPageNumber,
    required this.numItems,
    required this.lastResponse,
  });

  @override
  String toString() =>
      'PagingParams(nextPageNumber: $nextPageNumber, numItems: $numItems, lastResponse: $lastResponse,)';
}

String _toEncodable(dynamic item) {
  return item;
}

String _serializeList(List? list) {
  list ??= <String>[];
  try {
    return json.encode(list, toEncodable: _toEncodable);
  } catch (_) {
    if (kDebugMode) {
      print("List serialization failed. Returning empty list.");
    }
    return '[]';
  }
}

String _serializeJson(dynamic jsonVar, [bool isList = false]) {
  jsonVar ??= (isList ? [] : {});
  try {
    return json.encode(jsonVar, toEncodable: _toEncodable);
  } catch (_) {
    if (kDebugMode) {
      print("Json serialization failed. Returning empty json.");
    }
    return isList ? '[]' : '{}';
  }
}
