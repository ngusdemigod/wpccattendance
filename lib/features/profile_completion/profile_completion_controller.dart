import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../services/profile_security/secure_profile_repository.dart';
import 'profile_completion_models.dart';
import 'profile_completion_service.dart';

enum SetupFlowStep {
  greeting,
  uploadPrompt,
  uploadPreview,
  form,
  success,
}

class ProfileCompletionController extends ChangeNotifier {
  ProfileCompletionController({
    ProfileCompletionService? service,
    SecureProfileRepository? repository,
  })  : _service = service ?? ProfileCompletionService(),
        _repository = repository ?? SecureProfileRepository();

  final ProfileCompletionService _service;
  final SecureProfileRepository _repository;

  final TextEditingController fieldController = TextEditingController();

  SetupFlowStep step = SetupFlowStep.greeting;
  Uint8List? avatarBytes;
  double avatarScale = 1;
  Offset avatarOffset = Offset.zero;
  String legacyAvatarUrl = '';
  String initials = 'AG';
  bool isLoading = true;
  bool isSaving = false;
  String? submitError;
  String? fieldError;

  final Map<ProfileCompletionField, String> _textValues =
      <ProfileCompletionField, String>{};
  final Map<ProfileCompletionField, DateTime> _dateValues =
      <ProfileCompletionField, DateTime>{};
  List<ProfileCompletionRequirement> _requirements =
      const <ProfileCompletionRequirement>[];
  int _currentRequirementIndex = 0;
  bool _avatarPickedThisSession = false;

  List<ProfileCompletionRequirement> get requirements => _requirements;
  String get firstName =>
      _textValues[ProfileCompletionField.firstName]?.trim() ?? '';
  ProfileCompletionRequirement? get currentRequirement =>
      _requirements.isEmpty ? null : _requirements[_currentRequirementIndex];
  int get currentRequirementIndex => _currentRequirementIndex;
  bool get hasAvatar =>
      avatarBytes != null || legacyAvatarUrl.trim().isNotEmpty;
  bool get hasPendingRequirements => _requirements.isNotEmpty;
  bool get isLastRequirement =>
      _requirements.isNotEmpty &&
      _currentRequirementIndex == _requirements.length - 1;
  int get totalProgressSteps =>
      hasPendingRequirements ? _requirements.length + 1 : 1;
  int get activeProgressIndex {
    if (step == SetupFlowStep.greeting ||
        step == SetupFlowStep.uploadPrompt ||
        step == SetupFlowStep.uploadPreview) {
      return 0;
    }
    if (step == SetupFlowStep.form) {
      return _currentRequirementIndex + 1;
    }
    return totalProgressSteps - 1;
  }

  Future<void> load() async {
    isLoading = true;
    notifyListeners();

    try {
      final draft = await _service.loadDraft();
      final bundle = draft.bundle;
      avatarBytes = bundle.avatarBytes;
      legacyAvatarUrl = bundle.legacyAvatarUrl;
      initials = bundle.initials;
      _textValues
        ..clear()
        ..addAll({
          ProfileCompletionField.prefix: bundle.prefix,
          ProfileCompletionField.firstName: bundle.firstName,
          ProfileCompletionField.lastName: bundle.lastName,
          ProfileCompletionField.phoneNumber: bundle.phoneNumber,
          ProfileCompletionField.residentialAddress: bundle.residentialAddress,
          ProfileCompletionField.gender: bundle.gender,
          ProfileCompletionField.maritalStatus: bundle.maritalStatus,
          ProfileCompletionField.occupation: bundle.occupation,
          ProfileCompletionField.emergencyContact: bundle.emergencyContact,
          ProfileCompletionField.bio: bundle.bio,
        });
      _dateValues
        ..clear()
        ..addEntries([
          if (bundle.dateOfBirth != null)
            MapEntry(ProfileCompletionField.dateOfBirth, bundle.dateOfBirth!),
          if (bundle.dateJoinedWpcc != null)
            MapEntry(
              ProfileCompletionField.dateJoinedWpcc,
              bundle.dateJoinedWpcc!,
            ),
          if (bundle.waterBaptismDate != null)
            MapEntry(
              ProfileCompletionField.waterBaptismDate,
              bundle.waterBaptismDate!,
            ),
        ]);
      _requirements = draft.missingRequirements;
      _currentRequirementIndex = 0;
      _avatarPickedThisSession = false;
      fieldError = null;
      submitError = null;

      if (draft.bundle.setupCompleted && _requirements.isEmpty) {
        step = SetupFlowStep.success;
      } else {
        step = SetupFlowStep.greeting;
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void continueFromGreeting() {
    submitError = null;
    fieldError = null;

    if (!hasAvatar) {
      step = SetupFlowStep.uploadPrompt;
    } else if (_requirements.isEmpty) {
      step = SetupFlowStep.success;
    } else {
      step = SetupFlowStep.form;
      _syncFieldController();
    }
    notifyListeners();
  }

  void setAvatar(Uint8List bytes) {
    avatarBytes = bytes;
    avatarScale = 1;
    avatarOffset = Offset.zero;
    legacyAvatarUrl = '';
    _avatarPickedThisSession = true;
    submitError = null;
    fieldError = null;
    step = SetupFlowStep.uploadPreview;
    notifyListeners();
  }

  void updateAvatarTransform({
    required double scale,
    required Offset offset,
  }) {
    avatarScale = scale;
    avatarOffset = offset;
    notifyListeners();
  }

  bool canGoBack() {
    switch (step) {
      case SetupFlowStep.greeting:
      case SetupFlowStep.uploadPrompt:
      case SetupFlowStep.success:
        return false;
      case SetupFlowStep.uploadPreview:
        return true;
      case SetupFlowStep.form:
        return _currentRequirementIndex > 0 || _avatarPickedThisSession;
    }
  }

  void goBack() {
    submitError = null;
    fieldError = null;
    switch (step) {
      case SetupFlowStep.greeting:
      case SetupFlowStep.uploadPrompt:
      case SetupFlowStep.success:
        return;
      case SetupFlowStep.uploadPreview:
        step = SetupFlowStep.uploadPrompt;
        break;
      case SetupFlowStep.form:
        if (_currentRequirementIndex > 0) {
          _currentRequirementIndex -= 1;
          _syncFieldController();
        } else if (_avatarPickedThisSession) {
          step = SetupFlowStep.uploadPreview;
        }
        break;
    }
    notifyListeners();
  }

  void continueFromPreview() {
    submitError = null;
    fieldError = null;
    if (_requirements.isEmpty) {
      return;
    }
    step = SetupFlowStep.form;
    _currentRequirementIndex = 0;
    _syncFieldController();
    notifyListeners();
  }

  void onFieldChanged(String value) {
    final requirement = currentRequirement;
    if (requirement == null) {
      return;
    }
    _textValues[requirement.field] = value;
    if (fieldError != null) {
      fieldError = null;
      notifyListeners();
    }
  }

  void selectOption(String value) {
    final requirement = currentRequirement;
    if (requirement == null) {
      return;
    }
    _textValues[requirement.field] = value;
    fieldController.text = value;
    fieldError = null;
    notifyListeners();
  }

  void selectDate(DateTime value) {
    final requirement = currentRequirement;
    if (requirement == null) {
      return;
    }
    final normalized = DateTime(value.year, value.month, value.day);
    _dateValues[requirement.field] = normalized;
    fieldError = null;
    notifyListeners();
  }

  String textValue(ProfileCompletionField field) => _textValues[field] ?? '';

  DateTime? dateValue(ProfileCompletionField field) => _dateValues[field];

  Future<bool> submit({
    Uint8List? processedAvatarBytes,
  }) async {
    final requirement = currentRequirement;
    if (step == SetupFlowStep.form && requirement != null) {
      fieldError = _validateRequirement(requirement);
      submitError = null;
      if (fieldError != null) {
        notifyListeners();
        return false;
      }
    }

    isSaving = true;
    submitError = null;
    notifyListeners();

    try {
      if (step == SetupFlowStep.form && requirement != null) {
        _persistCurrentRequirementValue(requirement);
      }

      final shouldComplete = _requirements.isEmpty ||
          step == SetupFlowStep.uploadPreview ||
          isLastRequirement;
      if (shouldComplete) {
        await _repository.saveCanonicalPrivateProfile(
          privateProfileData: _privateProfilePayload(markComplete: true),
          avatarBytes: processedAvatarBytes ?? avatarBytes,
          markSetupComplete: true,
        );
        step = SetupFlowStep.success;
      } else {
        _currentRequirementIndex += 1;
        _syncFieldController();
      }
      return true;
    } catch (_) {
      submitError =
          'We could not save your profile right now. Please try again.';
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  String? _validateRequirement(ProfileCompletionRequirement requirement) {
    final currentText = textValue(requirement.field).trim();
    switch (requirement.field) {
      case ProfileCompletionField.prefix:
        return currentText.isEmpty ? 'Add your prefix to continue.' : null;
      case ProfileCompletionField.firstName:
        return currentText.isEmpty ? 'Add your first name to continue.' : null;
      case ProfileCompletionField.lastName:
        return currentText.isEmpty ? 'Add your last name to continue.' : null;
      case ProfileCompletionField.phoneNumber:
        return validatePhone(currentText);
      case ProfileCompletionField.residentialAddress:
        return validateAddress(currentText);
      case ProfileCompletionField.dateOfBirth:
        return _dateValues[requirement.field] == null
            ? 'Select your date of birth to continue.'
            : null;
      case ProfileCompletionField.gender:
        return currentText.isEmpty ? 'Select your gender to continue.' : null;
      case ProfileCompletionField.maritalStatus:
        return currentText.isEmpty
            ? 'Select your marital status to continue.'
            : null;
      case ProfileCompletionField.occupation:
        return currentText.isEmpty ? 'Add your occupation to continue.' : null;
      case ProfileCompletionField.emergencyContact:
        if (currentText.isEmpty) {
          return 'Add an emergency contact to continue.';
        }
        if (currentText.length < 8) {
          return 'Enter a more complete emergency contact.';
        }
        return null;
      case ProfileCompletionField.dateJoinedWpcc:
        return _dateValues[requirement.field] == null
            ? 'Select the date you joined WPCC.'
            : null;
      case ProfileCompletionField.waterBaptismDate:
        return _dateValues[requirement.field] == null
            ? 'Select your water baptism date.'
            : null;
      case ProfileCompletionField.bio:
        if (currentText.isEmpty) {
          return 'Add a short bio to continue.';
        }
        if (currentText.length < 12) {
          return 'Write a slightly fuller bio.';
        }
        return null;
      case ProfileCompletionField.avatar:
        return null;
    }
  }

  void _persistCurrentRequirementValue(
      ProfileCompletionRequirement requirement) {
    if (requirement.inputType == ProfileCompletionInputType.date) {
      return;
    }
    _textValues[requirement.field] = fieldController.text.trim();
  }

  void _syncFieldController() {
    final requirement = currentRequirement;
    if (requirement == null) {
      fieldController.clear();
      return;
    }
    switch (requirement.inputType) {
      case ProfileCompletionInputType.text:
      case ProfileCompletionInputType.multiline:
      case ProfileCompletionInputType.phone:
      case ProfileCompletionInputType.select:
        fieldController.text = textValue(requirement.field);
        break;
      case ProfileCompletionInputType.date:
        fieldController.clear();
        break;
    }
  }

  Map<String, Object?> _privateProfilePayload({
    required bool markComplete,
  }) {
    final prefix = textValue(ProfileCompletionField.prefix).trim();
    final firstName = textValue(ProfileCompletionField.firstName).trim();
    final lastName = textValue(ProfileCompletionField.lastName).trim();
    return <String, Object?>{
      'prefix': prefix,
      'firstname': firstName,
      'lastname': lastName,
      'full_name': [firstName, lastName]
          .where((part) => part.isNotEmpty)
          .join(' ')
          .trim(),
      'phone': textValue(ProfileCompletionField.phoneNumber).trim(),
      'phone_number': textValue(ProfileCompletionField.phoneNumber).trim(),
      'address': textValue(ProfileCompletionField.residentialAddress).trim(),
      'residential_address':
          textValue(ProfileCompletionField.residentialAddress).trim(),
      'date_of_birth': _dateValues[ProfileCompletionField.dateOfBirth],
      'dob': _dateValues[ProfileCompletionField.dateOfBirth],
      'gender': textValue(ProfileCompletionField.gender).trim(),
      'marital_status': textValue(ProfileCompletionField.maritalStatus).trim(),
      'occupation': textValue(ProfileCompletionField.occupation).trim(),
      'emergency_contact':
          textValue(ProfileCompletionField.emergencyContact).trim(),
      'date_joined_wpcc': _dateValues[ProfileCompletionField.dateJoinedWpcc],
      'water_baptism_date':
          _dateValues[ProfileCompletionField.waterBaptismDate],
      'bio': textValue(ProfileCompletionField.bio).trim(),
      'profilecomplete': markComplete,
    };
  }

  static String? validatePhone(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return 'Add your phone number to continue.';
    }

    final normalized = trimmed.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (!RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(normalized)) {
      return 'Enter a valid phone number in international format.';
    }

    return null;
  }

  static String? validateAddress(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return 'Add your address to continue.';
    }
    if (trimmed.length < 8) {
      return 'Enter a more complete home address.';
    }
    return null;
  }

  @override
  void dispose() {
    fieldController.dispose();
    super.dispose();
  }
}
