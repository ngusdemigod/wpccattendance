import 'package:flutter/widgets.dart';

import '../../flutter_flow/custom_icons.dart';
import '../../services/profile_security/profile_security_models.dart';

enum ProfileCompletionField {
  avatar,
  prefix,
  firstName,
  lastName,
  phoneNumber,
  residentialAddress,
  dateOfBirth,
  gender,
  maritalStatus,
  occupation,
  emergencyContact,
  dateJoinedWpcc,
  waterBaptismDate,
  bio,
}

enum ProfileCompletionInputType {
  text,
  multiline,
  phone,
  date,
  select,
}

class ProfileCompletionRequirement {
  const ProfileCompletionRequirement({
    required this.field,
    required this.label,
    required this.title,
    required this.copy,
    required this.helper,
    required this.hintText,
    required this.icon,
    required this.inputType,
    this.options = const <String>[],
  });

  final ProfileCompletionField field;
  final String label;
  final String title;
  final String copy;
  final String helper;
  final String hintText;
  final IconData icon;
  final ProfileCompletionInputType inputType;
  final List<String> options;
}

class ProfileCompletionDraft {
  const ProfileCompletionDraft({
    required this.bundle,
    required this.missingRequirements,
  });

  final SecureProfileBundle bundle;
  final List<ProfileCompletionRequirement> missingRequirements;
}

const List<ProfileCompletionRequirement> kProfileCompletionRequirements = [
  ProfileCompletionRequirement(
    field: ProfileCompletionField.prefix,
    label: 'Prefix',
    title: 'How should we prefix your name?',
    copy: 'This keeps your worker record consistent across departments.',
    helper: 'Use the church prefix or title attached to your worker record.',
    hintText: 'WPCC/HQ/',
    icon: FFIcons.kidentificationBadge,
    inputType: ProfileCompletionInputType.text,
  ),
  ProfileCompletionRequirement(
    field: ProfileCompletionField.firstName,
    label: 'First name',
    title: 'What is your first name?',
    copy: 'Use the same first name you want members and leaders to see.',
    helper: 'Use your proper first name, not a nickname.',
    hintText: 'Angus',
    icon: FFIcons.kuserCircle,
    inputType: ProfileCompletionInputType.text,
  ),
  ProfileCompletionRequirement(
    field: ProfileCompletionField.lastName,
    label: 'Last name',
    title: 'What is your last name?',
    copy: 'This helps keep attendance and worker records accurate.',
    helper: 'Use your proper surname.',
    hintText: 'Igbani',
    icon: FFIcons.kuserCircle,
    inputType: ProfileCompletionInputType.text,
  ),
  ProfileCompletionRequirement(
    field: ProfileCompletionField.phoneNumber,
    label: 'Phone number',
    title: 'Update your phone number',
    copy: 'Enter a number we can easily reach you on. WhatsApp is preferred.',
    helper: 'This number is only visible to approved church administrators.',
    hintText: '+234 803 000 0001',
    icon: FFIcons.kphone,
    inputType: ProfileCompletionInputType.phone,
  ),
  ProfileCompletionRequirement(
    field: ProfileCompletionField.residentialAddress,
    label: 'Residential address',
    title: 'Where do you stay?',
    copy: 'Add your current home address for welfare and emergency support.',
    helper: 'Only authorized leaders can access this information when needed.',
    hintText: '23 Admiralty Way, Lekki Phase 1, Lagos',
    icon: FFIcons.khouseLine,
    inputType: ProfileCompletionInputType.multiline,
  ),
  ProfileCompletionRequirement(
    field: ProfileCompletionField.dateOfBirth,
    label: 'Date of birth',
    title: 'When is your birthday?',
    copy: 'We use this for member records and important church follow-up.',
    helper: 'Select your date of birth.',
    hintText: 'Select date of birth',
    icon: FFIcons.kcalendar,
    inputType: ProfileCompletionInputType.date,
  ),
  ProfileCompletionRequirement(
    field: ProfileCompletionField.gender,
    label: 'Gender',
    title: "What's your gender?",
    copy: 'This keeps profile details consistent across ministry records.',
    helper: 'Select the option that matches your record.',
    hintText: 'Select gender',
    icon: FFIcons.kuser,
    inputType: ProfileCompletionInputType.select,
    options: ['Male', 'Female'],
  ),
  ProfileCompletionRequirement(
    field: ProfileCompletionField.maritalStatus,
    label: 'Marital status',
    title: 'What is your marital status?',
    copy: 'This supports welfare follow-up and family-focused ministries.',
    helper: 'Select the option that best fits your current status.',
    hintText: 'Select marital status',
    icon: FFIcons.kheart,
    inputType: ProfileCompletionInputType.select,
    options: ['Single', 'Married', 'Engaged', 'Widowed', 'Separated'],
  ),
  ProfileCompletionRequirement(
    field: ProfileCompletionField.occupation,
    label: 'Occupation',
    title: 'What do you do?',
    copy: 'This helps church leaders understand the skills in the workforce.',
    helper: 'Use a short role or profession title.',
    hintText: 'Media technician',
    icon: FFIcons.kbriefcase,
    inputType: ProfileCompletionInputType.text,
  ),
  ProfileCompletionRequirement(
    field: ProfileCompletionField.emergencyContact,
    label: 'Emergency contact',
    title: 'Who should we contact in an emergency?',
    copy: 'Add one reliable contact we can reach if something urgent happens.',
    helper: 'Include a name and reachable phone number.',
    hintText: 'Jane Doe - +234 803 000 0002',
    icon: FFIcons.kaddressBook,
    inputType: ProfileCompletionInputType.text,
  ),
  ProfileCompletionRequirement(
    field: ProfileCompletionField.dateJoinedWpcc,
    label: 'Date joined WPCC',
    title: 'When did you join WPCC?',
    copy: 'This keeps your member timeline and worker history accurate.',
    helper: 'Select the date you joined WPCC.',
    hintText: 'Select date joined',
    icon: FFIcons.kcalendarDots,
    inputType: ProfileCompletionInputType.date,
  ),
  ProfileCompletionRequirement(
    field: ProfileCompletionField.waterBaptismDate,
    label: 'Water baptism date',
    title: 'When were you water baptized?',
    copy: 'This helps the church maintain accurate spiritual growth records.',
    helper: 'Select your water baptism date.',
    hintText: 'Select baptism date',
    icon: FFIcons.kdrop,
    inputType: ProfileCompletionInputType.date,
  ),
  ProfileCompletionRequirement(
    field: ProfileCompletionField.bio,
    label: 'Bio',
    title: 'Tell us a little about yourself',
    copy: 'A short bio helps members and leaders know you better.',
    helper: 'Keep it short and clear.',
    hintText: 'I serve in the media team and love supporting church broadcasts.',
    icon: FFIcons.knotepad,
    inputType: ProfileCompletionInputType.multiline,
  ),
];
