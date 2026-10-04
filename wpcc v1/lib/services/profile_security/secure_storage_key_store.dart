import 'dart:convert';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';

class SecureStorageKeyStore {
  SecureStorageKeyStore({
    SharedPreferences? preferences,
  }) : _preferences = preferences;

  final SharedPreferences? _preferences;

  static const _keyPrefix = 'profile_user_dek_v1_';

  Future<Uint8List?> readUserDek(String userId) async {
    final prefs = _preferences ?? await SharedPreferences.getInstance();
    final encoded = prefs.getString('$_keyPrefix$userId');
    if (encoded == null || encoded.isEmpty) {
      return null;
    }

    return Uint8List.fromList(base64Decode(encoded));
  }

  Future<void> writeUserDek(String userId, Uint8List keyBytes) async {
    final prefs = _preferences ?? await SharedPreferences.getInstance();
    await prefs.setString('$_keyPrefix$userId', base64Encode(keyBytes));
  }
}
