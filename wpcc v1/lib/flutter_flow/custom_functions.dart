import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'lat_lng.dart';
import 'place.dart';
import 'uploaded_file.dart';
import '/backend/schema/structs/index.dart';
import '/backend/supabase/supabase.dart';
import '/auth/supabase_auth/auth_util.dart';

dynamic decodeSupabaseJWT(String? token) {
  if (token == null || token.isEmpty) {
    return null;
  }

  try {
    // 1. Split the token into its 3 parts (Header.Payload.Signature)
    final parts = token.split('.');
    if (parts.length != 3) {
      return null;
    }

    // 2. The payload is the second part
    final payload = parts[1];

    // 3. Normalize the Base64URL string (add padding if necessary)
    var normalized = base64Url.normalize(payload);

    // 4. Decode the Base64 string and parse the JSON
    final String decoded = utf8.decode(base64Url.decode(normalized));
    final Map<String, dynamic> claims = json.decode(decoded);

    // 5. Return the claims map
    return claims;
  } catch (e) {
    return null;
  }
}

String safeString(String? value) {
  return value ?? '';
}

int safeInt(int? value) {
  return value ?? 0;
}

double safeDouble(double? value) {
  return value ?? 0.0;
}

String safeImage(String? url) {
  return url ??
      'https://storage.googleapis.com/flutterflow-io-6f20.appspot.com/projects/wpcc-3nsm23/assets/qrooxoy1wlrd/istockphoto-1288129985-612x612.jpg';
}

String getInitials(String? name) {
  if (name == null || name.trim().isEmpty) {
    return '';
  }

  // Split name into parts and remove empty parts
  List<String> parts =
      name.trim().split(' ').where((p) => p.isNotEmpty).toList();

  if (parts.isEmpty) {
    return '';
  }

  // If only one name → return first letter
  if (parts.length == 1) {
    return parts[0][0].toUpperCase();
  }

  // If multiple names → take first letter of first and second name
  String firstInitial = parts[0][0];
  String secondInitial = parts[1][0];

  return (firstInitial + secondInitial).toUpperCase();
}

String getShortCode(String? code) {
  if (code == null || code.isEmpty) {
    return '';
  }
  return code.split('/').last;
}
