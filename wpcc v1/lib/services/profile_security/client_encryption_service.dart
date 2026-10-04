import 'dart:math';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import 'profile_security_models.dart';

class ClientEncryptionService {
  ClientEncryptionService({
    AesGcm? algorithm,
  }) : _algorithm = algorithm ?? AesGcm.with256bits();

  final AesGcm _algorithm;
  final Random _random = Random.secure();

  static const algorithmName = 'AES-256-GCM';
  static const currentVersion = 1;
  static const _nonceLength = 12;
  static const _macLength = 16;

  Future<EncryptedFieldPayload> encryptString({
    required String value,
    required Uint8List keyBytes,
    required String userId,
    required String table,
    required String field,
  }) async {
    final payload = await encryptBytes(
      bytes: Uint8List.fromList(utf8.encode(value)),
      keyBytes: keyBytes,
      userId: userId,
      table: table,
      field: field,
    );
    return payload;
  }

  Future<String> decryptString({
    required String ciphertext,
    required String nonce,
    required Uint8List keyBytes,
    required String userId,
    required String table,
    required String field,
  }) async {
    final bytes = await decryptBytes(
      ciphertext: ciphertext,
      nonce: nonce,
      keyBytes: keyBytes,
      userId: userId,
      table: table,
      field: field,
    );
    return utf8.decode(bytes, allowMalformed: false);
  }

  Future<EncryptedFieldPayload> encryptBytes({
    required Uint8List bytes,
    required Uint8List keyBytes,
    required String userId,
    required String table,
    required String field,
  }) async {
    final nonce = _randomBytes(_nonceLength);
    final secretKey = SecretKey(keyBytes);
    final secretBox = await _algorithm.encrypt(
      bytes,
      secretKey: secretKey,
      nonce: nonce,
      aad: _buildAad(
        userId: userId,
        table: table,
        field: field,
      ),
    );

    final combined = Uint8List.fromList([
      ...secretBox.cipherText,
      ...secretBox.mac.bytes,
    ]);

    return EncryptedFieldPayload(
      ciphertext: base64Encode(combined),
      nonce: base64Encode(nonce),
      algorithm: algorithmName,
      version: currentVersion,
    );
  }

  Future<Uint8List> decryptBytes({
    required String ciphertext,
    required String nonce,
    required Uint8List keyBytes,
    required String userId,
    required String table,
    required String field,
  }) async {
    final combined = base64Decode(ciphertext);
    if (combined.length < _macLength) {
      throw const FormatException('Encrypted payload is invalid.');
    }

    final cipherBytes = combined.sublist(0, combined.length - _macLength);
    final macBytes = combined.sublist(combined.length - _macLength);
    final secretBox = SecretBox(
      cipherBytes,
      nonce: base64Decode(nonce),
      mac: Mac(macBytes),
    );

    final clearBytes = await _algorithm.decrypt(
      secretBox,
      secretKey: SecretKey(keyBytes),
      aad: _buildAad(
        userId: userId,
        table: table,
        field: field,
      ),
    );

    return Uint8List.fromList(clearBytes);
  }

  Uint8List generateDek() => _randomBytes(32);

  List<int> _buildAad({
    required String userId,
    required String table,
    required String field,
  }) {
    return utf8.encode(
      jsonEncode({
        'user_id': userId,
        'table': table,
        'field': field,
        'version': currentVersion,
      }),
    );
  }

  Uint8List _randomBytes(int length) =>
      Uint8List.fromList(List<int>.generate(length, (_) => _random.nextInt(256)));
}
