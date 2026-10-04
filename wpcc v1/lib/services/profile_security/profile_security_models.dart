import 'dart:typed_data';

class EncryptedFieldPayload {
  const EncryptedFieldPayload({
    required this.ciphertext,
    required this.nonce,
    required this.algorithm,
    required this.version,
  });

  final String ciphertext;
  final String nonce;
  final String algorithm;
  final int version;
}

class DecryptedPrivateProfile {
  const DecryptedPrivateProfile({
    required this.phoneNumber,
    required this.residentialAddress,
  });

  final String phoneNumber;
  final String residentialAddress;
}

class SecureProfileBundle {
  const SecureProfileBundle({
    required this.phoneNumber,
    required this.residentialAddress,
    required this.avatarBytes,
    required this.legacyAvatarUrl,
    required this.setupCompleted,
    required this.initials,
    this.prefix = '',
    this.firstName = '',
    this.lastName = '',
    this.bio = '',
    this.occupation = '',
    this.gender = '',
    this.maritalStatus = '',
    this.emergencyContact = '',
    this.dateOfBirth,
    this.dateJoinedWpcc,
    this.waterBaptismDate,
  });

  final String phoneNumber;
  final String residentialAddress;
  final Uint8List? avatarBytes;
  final String legacyAvatarUrl;
  final bool setupCompleted;
  final String initials;
  final String prefix;
  final String firstName;
  final String lastName;
  final String bio;
  final String occupation;
  final String gender;
  final String maritalStatus;
  final String emergencyContact;
  final DateTime? dateOfBirth;
  final DateTime? dateJoinedWpcc;
  final DateTime? waterBaptismDate;
}
