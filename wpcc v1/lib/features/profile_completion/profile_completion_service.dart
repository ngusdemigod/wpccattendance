import '../../auth/supabase_auth/auth_util.dart';
import '../../services/profile_security/secure_profile_repository.dart';
import '../../services/profile_security/profile_security_models.dart';
import 'profile_completion_models.dart';

enum ProfileCompletionStatus {
  unknown,
  unauthenticated,
  incomplete,
  complete,
}

class ProfileCompletionService {
  ProfileCompletionService({
    SecureProfileRepository? repository,
  }) : _repository = repository ?? SecureProfileRepository();

  final SecureProfileRepository _repository;

  Future<ProfileCompletionStatus> fetchStatus() async {
    if (currentUserUid.isEmpty) {
      return ProfileCompletionStatus.unauthenticated;
    }

    final setupComplete = await _repository.getSetupStatus();
    return setupComplete
        ? ProfileCompletionStatus.complete
        : ProfileCompletionStatus.incomplete;
  }

  Future<ProfileCompletionDraft> loadDraft() async {
    final bundle = await _repository.loadSecureProfileBundle();
    return ProfileCompletionDraft(
      bundle: bundle,
      missingRequirements: _missingRequirementsFor(bundle),
    );
  }

  List<ProfileCompletionRequirement> _missingRequirementsFor(
    SecureProfileBundle bundle,
  ) {
    return kProfileCompletionRequirements
        .where((requirement) => _isMissing(requirement.field, bundle))
        .toList(growable: false);
  }

  bool _isMissing(
    ProfileCompletionField field,
    SecureProfileBundle bundle,
  ) {
    switch (field) {
      case ProfileCompletionField.avatar:
        return bundle.legacyAvatarUrl.trim().isEmpty && bundle.avatarBytes == null;
      case ProfileCompletionField.prefix:
        return bundle.prefix.trim().isEmpty;
      case ProfileCompletionField.firstName:
        return bundle.firstName.trim().isEmpty;
      case ProfileCompletionField.lastName:
        return bundle.lastName.trim().isEmpty;
      case ProfileCompletionField.phoneNumber:
        return bundle.phoneNumber.trim().isEmpty;
      case ProfileCompletionField.residentialAddress:
        return bundle.residentialAddress.trim().isEmpty;
      case ProfileCompletionField.dateOfBirth:
        return bundle.dateOfBirth == null;
      case ProfileCompletionField.gender:
        return bundle.gender.trim().isEmpty;
      case ProfileCompletionField.maritalStatus:
        return bundle.maritalStatus.trim().isEmpty;
      case ProfileCompletionField.occupation:
        return bundle.occupation.trim().isEmpty;
      case ProfileCompletionField.emergencyContact:
        return bundle.emergencyContact.trim().isEmpty;
      case ProfileCompletionField.dateJoinedWpcc:
        return bundle.dateJoinedWpcc == null;
      case ProfileCompletionField.waterBaptismDate:
        return bundle.waterBaptismDate == null;
      case ProfileCompletionField.bio:
        return bundle.bio.trim().isEmpty;
    }
  }
}
