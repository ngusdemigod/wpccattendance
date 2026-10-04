import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../app_state.dart';
import '../../auth/supabase_auth/auth_util.dart';
import '../../backend/supabase/supabase.dart';
import '../../features/profile/profile_identity_resolver.dart';
import 'client_encryption_service.dart';
import 'profile_security_models.dart';
import 'secure_storage_key_store.dart';

class SecureProfileRepository {
  SecureProfileRepository({
    ProfileIdentityResolver? identityResolver,
    ClientEncryptionService? encryptionService,
    SecureStorageKeyStore? keyStore,
  })  : _identityResolver = identityResolver ?? ProfileIdentityResolver(),
        _encryptionService = encryptionService ?? ClientEncryptionService(),
        _keyStore = keyStore ?? SecureStorageKeyStore();

  final ProfileIdentityResolver _identityResolver;
  final ClientEncryptionService _encryptionService;
  final SecureStorageKeyStore _keyStore;

  static const _avatarBucket = 'wpcc';
  static const _privateProfileTable = 'worker_private_profiles';

  Future<bool> getSetupStatus() async {
    final identity = await _identityResolver.resolveCurrentUser();

    // profiles_priv_info.profilecomplete is the single source of truth for
    // whether the completion flow should show. FALSE, NULL, or a missing row
    // all count as incomplete.
    final legacyProfile =
        await _loadLegacyPrivateProfile(identity.profileUserId);
    return legacyProfile['profilecomplete'] == true;
  }

  Future<SecureProfileBundle> loadSecureProfileBundle() async {
    final identity = await _identityResolver.resolveCurrentUser();
    final results = await Future.wait<dynamic>([
      _loadPublicProfile(identity.profileUserId),
      _loadLegacyPrivateProfile(identity.profileUserId),
      _loadEncryptedPrivateProfile(identity.profileUserId),
      _keyStore.readUserDek(identity.profileUserId),
    ]);
    final publicProfile = results[0] as Map<String, dynamic>;
    final legacyProfile = results[1] as Map<String, dynamic>;
    final privateProfile = results[2] as Map<String, dynamic>;
    final keyBytes = results[3] as Uint8List?;

    String phoneNumber = '';
    String residentialAddress = '';

    if (privateProfile.isNotEmpty && keyBytes != null) {
      phoneNumber = await _decryptField(
        ciphertext: privateProfile['phone_ciphertext']?.toString(),
        nonce: privateProfile['phone_nonce']?.toString(),
        keyBytes: keyBytes,
        userId: identity.profileUserId,
        table: _privateProfileTable,
        field: 'phone',
      );
      residentialAddress = await _decryptField(
        ciphertext: privateProfile['address_ciphertext']?.toString(),
        nonce: privateProfile['address_nonce']?.toString(),
        keyBytes: keyBytes,
        userId: identity.profileUserId,
        table: _privateProfileTable,
        field: 'address',
      );
    }

    phoneNumber = phoneNumber.isNotEmpty
        ? phoneNumber
        : _firstNonEmpty([
            legacyProfile['phone_number']?.toString() ?? '',
            legacyProfile['phone']?.toString() ?? '',
          ]);
    residentialAddress = residentialAddress.isNotEmpty
        ? residentialAddress
        : _firstNonEmpty([
            legacyProfile['residential_address']?.toString() ?? '',
            legacyProfile['address']?.toString() ?? '',
          ]);

    return SecureProfileBundle(
      phoneNumber: phoneNumber,
      residentialAddress: residentialAddress,
      avatarBytes: _firstNonEmpty([
        publicProfile['avatar']?.toString() ?? '',
      ]).isNotEmpty
          ? null
          : await _loadAvatarBytes(
              userId: identity.profileUserId,
              publicProfile: publicProfile,
              keyBytes: keyBytes,
            ),
      legacyAvatarUrl: _firstNonEmpty([
        publicProfile['avatar']?.toString() ?? '',
        legacyProfile['avatar']?.toString() ?? '',
      ]),
      setupCompleted: legacyProfile['profilecomplete'] == true,
      initials: _deriveInitials(publicProfile, legacyProfile),
      prefix: _firstNonEmpty([
        legacyProfile['prefix']?.toString() ?? '',
        publicProfile['prefix']?.toString() ?? '',
      ]),
      firstName: _firstNonEmpty([
        legacyProfile['firstname']?.toString() ?? '',
        publicProfile['firstname']?.toString() ?? '',
      ]),
      lastName: _firstNonEmpty([
        legacyProfile['lastname']?.toString() ?? '',
        publicProfile['lastname']?.toString() ?? '',
      ]),
      bio: _firstNonEmpty([
        legacyProfile['bio']?.toString() ?? '',
        publicProfile['bio']?.toString() ?? '',
      ]),
      occupation: legacyProfile['occupation']?.toString().trim() ?? '',
      gender: legacyProfile['gender']?.toString().trim() ?? '',
      maritalStatus: legacyProfile['marital_status']?.toString().trim() ?? '',
      emergencyContact:
          legacyProfile['emergency_contact']?.toString().trim() ?? '',
      dateOfBirth: _firstDate([
        legacyProfile['date_of_birth'],
        legacyProfile['dob'],
      ]),
      dateJoinedWpcc: _firstDate([
        legacyProfile['date_joined_wpcc'],
        legacyProfile['date_joined'],
      ]),
      waterBaptismDate: _firstDate([
        legacyProfile['water_baptism_date'],
      ]),
    );
  }

  Future<DecryptedPrivateProfile?> getOwnPrivateProfile() async {
    final bundle = await loadSecureProfileBundle();
    if (bundle.phoneNumber.isEmpty && bundle.residentialAddress.isEmpty) {
      return null;
    }

    return DecryptedPrivateProfile(
      phoneNumber: bundle.phoneNumber,
      residentialAddress: bundle.residentialAddress,
    );
  }

  Future<Uint8List?> getOwnAvatarBytes() async {
    final bundle = await loadSecureProfileBundle();
    return bundle.avatarBytes;
  }

  Future<void> saveProfileImage(
    Uint8List imageBytes, {
    String? sourcePath,
    void Function(double progress)? onProgress,
  }) async {
    await _saveEncryptedPrivateProfile(
      phone: null,
      address: null,
      avatarBytes: imageBytes,
      avatarSourcePath: sourcePath,
      markSetupComplete: false,
      onAvatarUploadProgress: onProgress,
    );
  }

  Future<void> saveEncryptedPrivateProfile({
    required String phone,
    required String address,
    Uint8List? avatarBytes,
  }) {
    return _saveEncryptedPrivateProfile(
      phone: phone,
      address: address,
      avatarBytes: avatarBytes,
      privateProfileData: {
        'phone': phone,
        'phone_number': phone,
        'address': address,
        'residential_address': address,
      },
      markSetupComplete: false,
    );
  }

  Future<void> saveSetupProfile({
    required String phone,
    required String address,
    Uint8List? avatarBytes,
  }) {
    return _saveEncryptedPrivateProfile(
      phone: phone,
      address: address,
      avatarBytes: avatarBytes,
      privateProfileData: {
        'phone': phone,
        'phone_number': phone,
        'address': address,
        'residential_address': address,
      },
      markSetupComplete: true,
    );
  }

  Future<void> saveCanonicalPrivateProfile({
    required Map<String, Object?> privateProfileData,
    Uint8List? avatarBytes,
    String? avatarSourcePath,
    bool markSetupComplete = false,
  }) {
    return _saveEncryptedPrivateProfile(
      phone: privateProfileData['phone_number']?.toString() ??
          privateProfileData['phone']?.toString(),
      address: privateProfileData['residential_address']?.toString() ??
          privateProfileData['address']?.toString(),
      avatarBytes: avatarBytes,
      avatarSourcePath: avatarSourcePath,
      privateProfileData: privateProfileData,
      markSetupComplete: markSetupComplete,
    );
  }

  Future<void> markSetupComplete() async {
    final identity = await _identityResolver.resolveCurrentUser();
    final now = DateTime.now().toUtc().toIso8601String();

    await Future.wait([
      SupaFlow.client.from('profiles').update({
        'setup_completed': true,
        'setup_completed_at': now,
        'updated_at': now,
      }).eq('id', identity.profileUserId),
      SupaFlow.client.from('profiles_priv_info').update({
        'profilecomplete': true,
      }).eq('id', identity.profileUserId),
    ]);
  }

  Future<void> _saveEncryptedPrivateProfile({
    required String? phone,
    required String? address,
    required Uint8List? avatarBytes,
    String? avatarSourcePath,
    Map<String, Object?> privateProfileData = const {},
    required bool markSetupComplete,
    void Function(double progress)? onAvatarUploadProgress,
  }) async {
    final identity = await _identityResolver.resolveCurrentUser();
    final userId = identity.profileUserId;
    final now = DateTime.now().toUtc().toIso8601String();
    final sanitizedPrivateData =
        _sanitizePrivateProfileData(privateProfileData);

    // Only touch the encryption key store when there is something to encrypt.
    // Avatar-only saves must not fail because secure storage is unavailable.
    EncryptedFieldPayload? phonePayload;
    EncryptedFieldPayload? addressPayload;
    final effectivePhone = _normalizeOptionalText(
          sanitizedPrivateData['phone_number'] ?? sanitizedPrivateData['phone'],
        ) ??
        _normalizeOptionalText(phone);
    final effectiveAddress = _normalizeOptionalText(
          sanitizedPrivateData['residential_address'] ??
              sanitizedPrivateData['address'],
        ) ??
        _normalizeOptionalText(address);
    if (effectivePhone != null || effectiveAddress != null) {
      final keyBytes = await _ensureUserDek(userId);
      if (effectivePhone != null) {
        phonePayload = await _encryptionService.encryptString(
          value: effectivePhone,
          keyBytes: keyBytes,
          userId: userId,
          table: _privateProfileTable,
          field: 'phone',
        );
      }
      if (effectiveAddress != null) {
        addressPayload = await _encryptionService.encryptString(
          value: effectiveAddress,
          keyBytes: keyBytes,
          userId: userId,
          table: _privateProfileTable,
          field: 'address',
        );
      }
    }

    var currentPublicProfile = await _loadPublicProfile(userId);
    if (currentPublicProfile.isEmpty) {
      await _identityResolver.relinkCurrentAuthProfile();
      currentPublicProfile = await _loadPublicProfile(userId);
      if (currentPublicProfile.isEmpty) {
        throw StateError('Own profile row was not found for avatar save.');
      }
    }
    final previousAvatarPath =
        currentPublicProfile['avatar_storage_path']?.toString().trim() ?? '';

    String? uploadedAvatarPath;
    String? publicAvatarUrl;
    try {
      if (avatarBytes != null) {
        uploadedAvatarPath = await _uploadPublicAvatar(
          userId: identity.authUserId,
          imageBytes: avatarBytes,
          sourcePath: avatarSourcePath,
          onProgress: onAvatarUploadProgress,
        );
        publicAvatarUrl = _publicAvatarUrl(uploadedAvatarPath);
      }

      if (phonePayload != null || addressPayload != null) {
        await SupaFlow.client.from(_privateProfileTable).upsert({
          'user_id': userId,
          if (phonePayload != null) 'phone_ciphertext': phonePayload.ciphertext,
          if (phonePayload != null) 'phone_nonce': phonePayload.nonce,
          if (addressPayload != null)
            'address_ciphertext': addressPayload.ciphertext,
          if (addressPayload != null) 'address_nonce': addressPayload.nonce,
          'encryption_algorithm': ClientEncryptionService.algorithmName,
          'encryption_version': ClientEncryptionService.currentVersion,
          'aad_context': {
            'user_id': userId,
            'table': _privateProfileTable,
            'version': ClientEncryptionService.currentVersion,
          },
          'updated_at': now,
        }, onConflict: 'user_id');
      }

      final publicUpdate = <String, dynamic>{
        'updated_at': now,
      };
      if (uploadedAvatarPath != null && publicAvatarUrl != null) {
        publicUpdate.addAll({
          'avatar': publicAvatarUrl,
          'avatar_is_encrypted': false,
          'avatar_storage_path': uploadedAvatarPath,
          'avatar_nonce': null,
          // Keep metadata columns populated to satisfy the secured profile
          // schema even when the stored avatar is intentionally public.
          'avatar_encryption_algorithm': ClientEncryptionService.algorithmName,
          'avatar_encryption_version': ClientEncryptionService.currentVersion,
        });
      }
      if (markSetupComplete) {
        publicUpdate.addAll({
          'setup_completed': true,
          'setup_completed_at': now,
        });
      }

      final resolvedFirstName = _normalizeOptionalText(
            sanitizedPrivateData['firstname'],
          ) ??
          _nullableTrim(currentPublicProfile['firstname']);
      final resolvedLastName = _normalizeOptionalText(
            sanitizedPrivateData['lastname'],
          ) ??
          _nullableTrim(currentPublicProfile['lastname']);
      final resolvedFullName =
          _resolveFullName(sanitizedPrivateData, currentPublicProfile);
      final resolvedEmail = _nullableTrim(currentUserEmail) ??
          _nullableTrim(currentPublicProfile['email']);

      if (effectivePhone != null) {
        sanitizedPrivateData['phone'] = effectivePhone;
        sanitizedPrivateData['phone_number'] = effectivePhone;
      }
      if (effectiveAddress != null) {
        sanitizedPrivateData['address'] = effectiveAddress;
        sanitizedPrivateData['residential_address'] = effectiveAddress;
      }
      if (markSetupComplete) {
        sanitizedPrivateData['profilecomplete'] = true;
      }

      final legacyPrivatePayload = <String, dynamic>{
        'id': userId,
        'branch_id': currentPublicProfile['branch_id'],
        'department_id': currentPublicProfile['department_id'],
        'full_name': resolvedFullName,
        'firstname': resolvedFirstName,
        'lastname': resolvedLastName,
        'email': resolvedEmail,
        if (uploadedAvatarPath != null) 'avatar': publicAvatarUrl,
        ...sanitizedPrivateData,
      };

      final branchId = legacyPrivatePayload['branch_id'];
      final fullName = legacyPrivatePayload['full_name'];
      if (branchId == null || fullName == null) {
        throw StateError(
          'Profile completion could not determine the required branch/name data.',
        );
      }

      await Future.wait([
        SupaFlow.client.from('profiles').update(publicUpdate).eq('id', userId),
        SupaFlow.client
            .from('profiles_priv_info')
            .upsert(legacyPrivatePayload, onConflict: 'id'),
      ]);

      if (onAvatarUploadProgress != null) {
        onAvatarUploadProgress(1);
      }

      if (uploadedAvatarPath != null &&
          previousAvatarPath.isNotEmpty &&
          previousAvatarPath != uploadedAvatarPath) {
        await _removeAvatarObject(previousAvatarPath);
      }
    } catch (_) {
      if (uploadedAvatarPath != null) {
        await _removeAvatarObject(uploadedAvatarPath);
      }
      rethrow;
    }
  }

  Future<Uint8List> _ensureUserDek(String userId) async {
    final existing = await _keyStore.readUserDek(userId);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    final keyBytes = _encryptionService.generateDek();
    await _keyStore.writeUserDek(userId, keyBytes);
    return keyBytes;
  }

  Future<Map<String, dynamic>> _loadPublicProfile(String userId) async {
    final response = await SupaFlow.client
        .from('profiles')
        .select(
          'id, branch_id, department_id, email, full_name, firstname, lastname, '
          'avatar, avatar_storage_path, avatar_is_encrypted, avatar_nonce, '
          'avatar_encryption_algorithm, avatar_encryption_version, '
          'setup_completed, bio, prefix',
        )
        .eq('id', userId)
        .maybeSingle();
    return _normalizeMap(response);
  }

  Future<Map<String, dynamic>> _loadLegacyPrivateProfile(String userId) async {
    final response = await SupaFlow.client
        .from('profiles_priv_info')
        .select(
          'full_name, firstname, lastname, avatar, prefix, bio, occupation, '
          'gender, marital_status, emergency_contact, phone, phone_number, '
          'address, residential_address, profilecomplete, dob, date_of_birth, '
          'date_joined, date_joined_wpcc, water_baptism_date',
        )
        .eq('id', userId)
        .maybeSingle();
    return _normalizeMap(response);
  }

  Future<Map<String, dynamic>> _loadEncryptedPrivateProfile(
      String userId) async {
    final response = await SupaFlow.client
        .from(_privateProfileTable)
        .select(
            'phone_ciphertext, phone_nonce, address_ciphertext, address_nonce')
        .eq('user_id', userId)
        .maybeSingle();
    return _normalizeMap(response);
  }

  Future<Uint8List?> _loadAvatarBytes({
    required String userId,
    required Map<String, dynamic> publicProfile,
    required Uint8List? keyBytes,
  }) async {
    final avatarPath =
        publicProfile['avatar_storage_path']?.toString().trim() ?? '';
    final avatarNonce = publicProfile['avatar_nonce']?.toString().trim() ?? '';
    final avatarIsEncrypted = publicProfile['avatar_is_encrypted'] == true;

    if (!avatarIsEncrypted ||
        avatarPath.isEmpty ||
        avatarNonce.isEmpty ||
        keyBytes == null) {
      return null;
    }

    final avatarLocation = _parseAvatarLocation(avatarPath);
    final uploadedBytes = await SupaFlow.client.storage
        .from(avatarLocation.bucket)
        .download(avatarLocation.path);
    final ciphertext = String.fromCharCodes(uploadedBytes);
    return _encryptionService.decryptBytes(
      ciphertext: ciphertext,
      nonce: avatarNonce,
      keyBytes: keyBytes,
      userId: userId,
      table: 'profiles',
      field: 'avatar_blob',
    );
  }

  Future<String> _decryptField({
    required String? ciphertext,
    required String? nonce,
    required Uint8List keyBytes,
    required String userId,
    required String table,
    required String field,
  }) async {
    if (ciphertext == null ||
        ciphertext.trim().isEmpty ||
        nonce == null ||
        nonce.trim().isEmpty) {
      return '';
    }

    return _encryptionService.decryptString(
      ciphertext: ciphertext,
      nonce: nonce,
      keyBytes: keyBytes,
      userId: userId,
      table: table,
      field: field,
    );
  }

  String _deriveInitials(
    Map<String, dynamic> publicProfile,
    Map<String, dynamic> legacyProfile,
  ) {
    final fullName = _firstNonEmpty([
      publicProfile['full_name']?.toString() ?? '',
      legacyProfile['full_name']?.toString() ?? '',
    ]);
    final firstName = _firstNonEmpty([
      publicProfile['firstname']?.toString() ?? '',
      legacyProfile['firstname']?.toString() ?? '',
    ]);
    final lastName = _firstNonEmpty([
      publicProfile['lastname']?.toString() ?? '',
      legacyProfile['lastname']?.toString() ?? '',
    ]);
    final source = _firstNonEmpty([
      '$firstName $lastName'.trim(),
      fullName,
    ], fallback: 'AG');

    final pieces = source
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part.substring(0, 1).toUpperCase())
        .join();
    return pieces.isEmpty ? 'AG' : pieces;
  }

  String _firstNonEmpty(List<String> values, {String fallback = ''}) {
    for (final value in values) {
      if (value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return fallback;
  }

  String? _nullableTrim(Object? value) {
    final trimmed = value?.toString().trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }

  String? _normalizeOptionalText(Object? value) => _nullableTrim(value);

  DateTime? _firstDate(List<Object?> values) {
    for (final value in values) {
      if (value is DateTime) {
        return value;
      }
      final parsed = DateTime.tryParse(value?.toString() ?? '');
      if (parsed != null) {
        return parsed;
      }
    }
    return null;
  }

  Map<String, Object?> _sanitizePrivateProfileData(Map<String, Object?> raw) {
    const dateKeys = {
      'dob',
      'date_of_birth',
      'date_joined',
      'date_joined_wpcc',
      'water_baptism_date',
    };
    const allowedKeys = {
      'full_name',
      'firstname',
      'lastname',
      'prefix',
      'bio',
      'occupation',
      'gender',
      'marital_status',
      'phone',
      'phone_number',
      'address',
      'residential_address',
      'date_of_birth',
      'dob',
      'date_joined',
      'date_joined_wpcc',
      'water_baptism_date',
      'emergency_contact',
      'profilecomplete',
      'avatar',
    };

    final sanitized = <String, Object?>{};
    for (final entry in raw.entries) {
      if (!allowedKeys.contains(entry.key)) {
        continue;
      }
      final value = entry.value;
      if (dateKeys.contains(entry.key)) {
        sanitized[entry.key] = _normalizeDateOnly(value);
      } else if (value is bool) {
        sanitized[entry.key] = value;
      } else {
        sanitized[entry.key] = _nullableTrim(value);
      }
    }
    return sanitized;
  }

  String? _normalizeDateOnly(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is DateTime) {
      final normalized = DateTime.utc(value.year, value.month, value.day);
      return normalized.toIso8601String().split('T').first;
    }
    final parsed = DateTime.tryParse(value.toString());
    if (parsed == null) {
      return null;
    }
    final normalized = DateTime.utc(parsed.year, parsed.month, parsed.day);
    return normalized.toIso8601String().split('T').first;
  }

  String _resolveFullName(
    Map<String, Object?> privateProfileData,
    Map<String, dynamic> currentPublicProfile,
  ) {
    final prefix = _normalizeOptionalText(privateProfileData['prefix']) ??
        _nullableTrim(currentPublicProfile['prefix']);
    final explicit = _normalizeOptionalText(privateProfileData['full_name']);
    if (explicit != null) {
      return _withoutLeadingPrefix(explicit, prefix);
    }

    final firstName = _normalizeOptionalText(privateProfileData['firstname']) ??
        _nullableTrim(currentPublicProfile['firstname']);
    final lastName = _normalizeOptionalText(privateProfileData['lastname']) ??
        _nullableTrim(currentPublicProfile['lastname']);
    final parts = [
      if (firstName != null) firstName,
      if (lastName != null) lastName,
    ];
    if (parts.isNotEmpty) {
      return parts.join(' ');
    }

    return _firstNonEmpty([
      currentPublicProfile['full_name']?.toString() ?? '',
      currentUserDisplayName,
      currentUserEmail,
    ], fallback: 'WPCC Member');
  }

  String _withoutLeadingPrefix(String fullName, String? prefix) {
    if (prefix == null || !fullName.startsWith(prefix)) {
      return fullName;
    }

    final normalized = fullName.substring(prefix.length).trim();
    return normalized.isEmpty ? fullName : normalized;
  }

  Map<String, dynamic> _normalizeMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((key, dynamic rowValue) {
        return MapEntry(key.toString(), rowValue);
      });
    }
    return const {};
  }

  Future<String> _uploadPublicAvatar({
    required String userId,
    required Uint8List imageBytes,
    String? sourcePath,
    void Function(double progress)? onProgress,
  }) async {
    final contentType = _avatarContentType(imageBytes, sourcePath: sourcePath);
    final fileExtension = switch (contentType) {
      'image/png' => 'png',
      'image/webp' => 'webp',
      'image/gif' => 'gif',
      'image/bmp' => 'bmp',
      'image/tiff' => 'tiff',
      'image/heic' => 'heic',
      'image/heif' => 'heif',
      _ => 'jpg',
    };

    final objectPath =
        'profiles/$userId/avatar/avatar-v${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
    final request = http.MultipartRequest(
      'POST',
      Uri.parse(supabaseFunctionUrl('upload-to-r2')),
    )
      ..headers.addAll({
        if (currentJwtToken.trim().isNotEmpty)
          'Authorization': 'Bearer $currentJwtToken',
        'apikey': kSupabaseAnonKey,
      })
      ..fields['bucket'] = _avatarBucket
      ..fields['objectKey'] = objectPath
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: 'avatar.$fileExtension',
          contentType: _avatarUploadMediaType(contentType),
        ),
      );

    final totalBytes = request.contentLength;
    // MultipartRequest only sets its `content-type` (with the multipart
    // boundary) inside finalize(), so it must be called before the headers
    // are copied — otherwise the streamed request goes out with no
    // content-type and the receiving edge function's form-data parser fails
    // with "Missing content type".
    final finalizedStream = request.finalize();
    final streamedRequest = http.StreamedRequest('POST', request.url)
      ..headers.addAll(request.headers)
      ..contentLength = totalBytes;

    var sentBytes = 0;
    final finalizeDone = Completer<void>();
    finalizedStream.listen(
      (chunk) {
        sentBytes += chunk.length;
        if (totalBytes > 0 && onProgress != null) {
          onProgress((sentBytes / totalBytes).clamp(0, 0.98));
        }
        streamedRequest.sink.add(chunk);
      },
      onDone: () {
        streamedRequest.sink.close();
        finalizeDone.complete();
      },
      onError: (Object error, StackTrace stackTrace) {
        streamedRequest.sink.addError(error, stackTrace);
        streamedRequest.sink.close();
        if (!finalizeDone.isCompleted) {
          finalizeDone.completeError(error, stackTrace);
        }
      },
      cancelOnError: true,
    );

    final response = await http.Client().send(streamedRequest);
    await finalizeDone.future;
    final responseBody = await response.stream.bytesToString();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'Avatar upload failed (${response.statusCode}): $responseBody',
      );
    }

    final decoded = jsonDecode(responseBody);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Unexpected avatar upload response');
    }
    if (onProgress != null) {
      onProgress(0.99);
    }
    return objectPath;
  }

  Future<void> _removeAvatarObject(String location) async {
    final parsed = _parseAvatarLocation(location);
    final response = await http.post(
      Uri.parse(supabaseFunctionUrl('delete-r2-object')),
      headers: {
        'Content-Type': 'application/json',
        'apikey': kSupabaseAnonKey,
        if (currentJwtToken.trim().isNotEmpty)
          'Authorization': 'Bearer $currentJwtToken',
      },
      body: jsonEncode({'objectKey': parsed.path}),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'Avatar cleanup failed (${response.statusCode}): ${response.body}',
      );
    }
  }

  _AvatarLocation _parseAvatarLocation(String rawLocation) {
    if (rawLocation.contains('|')) {
      final parts = rawLocation.split('|');
      return _AvatarLocation(bucket: parts.first, path: parts.last);
    }

    return _AvatarLocation(
      bucket: _avatarBucket,
      path: rawLocation
          .replaceFirst(RegExp(r'^https?://[^/]+/wpcc/'), '')
          .replaceFirst(RegExp(r'^/?wpcc/'), '')
          .replaceFirst(RegExp(r'^\Q$_avatarBucket\E\|'), ''),
    );
  }

  String _avatarContentType(
    Uint8List bytes, {
    String? sourcePath,
  }) {
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return 'image/png';
    }
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return 'image/webp';
    }
    if (bytes.length >= 6 &&
        bytes[0] == 0x47 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46) {
      return 'image/gif';
    }
    if (bytes.length >= 2 && bytes[0] == 0x42 && bytes[1] == 0x4D) {
      return 'image/bmp';
    }
    if (bytes.length >= 4 &&
        ((bytes[0] == 0x49 &&
                bytes[1] == 0x49 &&
                bytes[2] == 0x2A &&
                bytes[3] == 0x00) ||
            (bytes[0] == 0x4D &&
                bytes[1] == 0x4D &&
                bytes[2] == 0x00 &&
                bytes[3] == 0x2A))) {
      return 'image/tiff';
    }
    final extension = sourcePath?.split('.').last.toLowerCase().trim() ?? '';
    switch (extension) {
      case 'heic':
        return 'image/heic';
      case 'heif':
        return 'image/heif';
      case 'tif':
      case 'tiff':
        return 'image/tiff';
    }
    return 'image/jpeg';
  }

  MediaType _avatarUploadMediaType(String contentType) {
    final parts = contentType.split('/');
    if (parts.length == 2 && parts.first.isNotEmpty && parts.last.isNotEmpty) {
      return MediaType(parts.first, parts.last);
    }
    return MediaType('application', 'octet-stream');
  }

  String _publicAvatarUrl(String objectPath) {
    final baseUrl =
        FFAppState().storagpuburl.trim().replaceFirst(RegExp(r'/$'), '');
    return '$baseUrl/wpcc/$objectPath';
  }
}

class _AvatarLocation {
  const _AvatarLocation({
    required this.bucket,
    required this.path,
  });

  final String bucket;
  final String path;
}
