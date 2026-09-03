import '/backend/supabase/database/tables/profiles_priv_info.dart';
import '/features/profile/profile_identity_resolver.dart';
import '/services/profile_security/secure_profile_repository.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/upload_data.dart';
import '/shared/widgets/wpcc_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EditProfileWidget extends StatefulWidget {
  const EditProfileWidget({super.key});

  static String routeName = 'edit_profile';
  static String routePath = '/editProfile';

  @override
  State<EditProfileWidget> createState() => _EditProfileWidgetState();
}

class _EditProfileWidgetState extends State<EditProfileWidget> {
  final _formKey = GlobalKey<FormState>();
  final ProfileIdentityResolver _identityResolver = ProfileIdentityResolver();
  final SecureProfileRepository _secureProfileRepository =
      SecureProfileRepository();

  Future<ProfilesPrivInfoRow?>? _profileBootstrapFuture;
  ProfilesPrivInfoRow? _profile;

  String _fullName = '';
  String _phone = '';
  String _bio = '';
  String _residentialAddress = '';
  String _occupation = '';
  String _maritalStatus = '';
  String _emergencyContact = '';
  String _avatarUrl = '';
  Uint8List? _avatarBytes;
  bool _isSaving = false;
  bool _isUploadingAvatar = false;

  @override
  void initState() {
    super.initState();
    _profileBootstrapFuture = _bootstrapProfile();
  }

  Future<List<ProfilesPrivInfoRow>> _loadProfile() async {
    final identity = await _identityResolver.resolveCurrentUser();
    if (identity.profileUserId.isEmpty) {
      return const [];
    }

    return ProfilesPrivInfoTable().queryRows(
      queryFn: (q) => q.eq('id', identity.profileUserId),
      limit: 1,
    );
  }

  Future<ProfilesPrivInfoRow?> _bootstrapProfile() async {
    final rows = await _loadProfile();
    final profile = rows.isNotEmpty ? rows.first : null;
    final secureBundle = await _secureProfileRepository.loadSecureProfileBundle();
    if (!mounted) {
      return profile;
    }

    setState(() {
      _profile = profile;
      _fullName = profile?.fullName ?? '';
      _phone = secureBundle.phoneNumber;
      _bio = profile?.bio ?? '';
      _residentialAddress = secureBundle.residentialAddress;
      _occupation = profile?.occupation ?? '';
      _maritalStatus = profile?.maritalStatus ?? '';
      _emergencyContact = profile?.emergencyContact ?? '';
      _avatarUrl = secureBundle.legacyAvatarUrl;
      _avatarBytes = secureBundle.avatarBytes;
    });

    return profile;
  }

  Future<void> _handleAvatarTap() async {
    if (_isUploadingAvatar) {
      return;
    }

    setState(() {
      _isUploadingAvatar = true;
    });

    try {
      final selectedMedia = await selectMediaWithSourceBottomSheet(
        context: context,
        imageQuality: 85,
        allowPhoto: true,
        pickerFontFamily: 'Plus Jakarta Sans',
      );

      if (selectedMedia == null || selectedMedia.isEmpty) {
        return;
      }

      if (!selectedMedia
          .every((media) => validateFileFormat(media.storagePath, context))) {
        return;
      }

      final bytes = selectedMedia.first.bytes;
      if (bytes.isEmpty) {
        return;
      }

      final avatarBytes = Uint8List.fromList(bytes);
      await _secureProfileRepository.saveProfileImage(avatarBytes);

      if (!mounted) {
        return;
      }

      setState(() {
        _avatarBytes = avatarBytes;
        _avatarUrl = '';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Avatar updated successfully')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingAvatar = false;
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    final identity = await _identityResolver.resolveCurrentUser();
    if (!mounted) {
      return;
    }

    if (identity.profileUserId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active profile found.')),
      );
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final trimmedFullName = _fullName.trim();
      final trimmedPhone = _phone.trim();
      final trimmedBio = _bio.trim();
      final trimmedAddress = _residentialAddress.trim();
      final trimmedOccupation = _occupation.trim();
      final trimmedMaritalStatus = _maritalStatus.trim();
      final trimmedEmergencyContact = _emergencyContact.trim();

      final nameParts = trimmedFullName
          .split(RegExp(r'\s+'))
          .where((part) => part.isNotEmpty)
          .toList();
      await _secureProfileRepository.saveCanonicalPrivateProfile(
        privateProfileData: {
          'full_name': trimmedFullName.isEmpty ? null : trimmedFullName,
          'firstname': nameParts.isEmpty ? null : nameParts.first,
          'lastname': nameParts.length < 2 ? null : nameParts.sublist(1).join(' '),
          'bio': trimmedBio.isEmpty ? null : trimmedBio,
          'occupation': trimmedOccupation.isEmpty ? null : trimmedOccupation,
          'marital_status':
              trimmedMaritalStatus.isEmpty ? null : trimmedMaritalStatus,
          'emergency_contact': trimmedEmergencyContact.isEmpty
              ? null
              : trimmedEmergencyContact,
          'phone': trimmedPhone.isEmpty ? null : trimmedPhone,
          'phone_number': trimmedPhone.isEmpty ? null : trimmedPhone,
          'address': trimmedAddress.isEmpty ? null : trimmedAddress,
          'residential_address': trimmedAddress.isEmpty ? null : trimmedAddress,
        },
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
      context.pop(true);
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to update profile. Please try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: FlutterFlowTheme.of(context).titleSmall.override(
            font: GoogleFonts.instrumentSans(
              fontWeight: FontWeight.w700,
            ),
            color: Colors.white,
          ),
    );
  }

  Widget _fieldCard({
    required String label,
    required String initialValue,
    required ValueChanged<String> onChanged,
    String? hintText,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    FormFieldValidator<String>? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF2A2A2A),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: FlutterFlowTheme.of(context).bodySmall.override(
                  font: GoogleFonts.instrumentSans(
                    fontWeight: FontWeight.w600,
                  ),
                  color: const Color(0xFFB9B9B9),
                ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: initialValue,
            onChanged: onChanged,
            maxLines: maxLines,
            keyboardType: keyboardType,
            validator: validator,
            style: FlutterFlowTheme.of(context).bodyMedium.override(
                  font: GoogleFonts.instrumentSans(
                    fontWeight: FontWeight.w400,
                  ),
                  color: Colors.white,
                ),
            decoration: InputDecoration(
              isDense: true,
              hintText: hintText,
              hintStyle: FlutterFlowTheme.of(context).bodyMedium.override(
                    font: GoogleFonts.instrumentSans(
                      fontWeight: FontWeight.w400,
                    ),
                    color: const Color(0xFF6E6E6E),
                  ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              contentPadding: const EdgeInsets.only(bottom: 8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _readOnlyChip({
    required String label,
    required String value,
    Color? accentColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF171717),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: const Color(0xFF2A2A2A),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: FlutterFlowTheme.of(context).bodySmall.override(
                  font: GoogleFonts.instrumentSans(
                    fontWeight: FontWeight.w600,
                  ),
                  color: const Color(0xFFB9B9B9),
                ),
          ),
          Text(
            value,
            style: FlutterFlowTheme.of(context).bodySmall.override(
                  font: GoogleFonts.instrumentSans(
                    fontWeight: FontWeight.w600,
                  ),
                  color: accentColor ?? Colors.white,
                ),
          ),
        ],
      ),
    );
  }

  Widget _avatarPreview() {
    final imageUrl = _avatarUrl.trim();
    ImageProvider<Object>? avatarProvider;
    if (_avatarBytes != null) {
      avatarProvider = MemoryImage(_avatarBytes!);
    } else if (imageUrl.isNotEmpty) {
      avatarProvider = NetworkImage(imageUrl);
    }
    final initials = _fullName.trim().isNotEmpty
        ? _fullName
            .trim()
            .split(RegExp(r'\s+'))
            .where((part) => part.isNotEmpty)
            .take(2)
            .map((part) => part.substring(0, 1))
            .join()
            .toUpperCase()
        : 'U';

    return GestureDetector(
      onTap: _handleAvatarTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFC5099C),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 48,
              backgroundColor: const Color(0xFF201814),
              backgroundImage: avatarProvider,
              onBackgroundImageError: (_, __) {},
              child: _avatarBytes == null && imageUrl.isEmpty
                  ? Text(
                      initials,
                      style: FlutterFlowTheme.of(context).titleLarge.override(
                            font: GoogleFonts.instrumentSans(
                              fontWeight: FontWeight.w800,
                            ),
                            color: const Color(0xFFC5099C),
                          ),
                    )
                  : null,
            ),
          ),
          Positioned(
            left: 2,
            top: 2,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1ECC70),
                border: Border.all(
                  color: const Color(0xFF0C0C0C),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 14,
              ),
            ),
          ),
          if (_isUploadingAvatar)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: 0.35),
                ),
                child: const Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            right: 2,
            bottom: 2,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFC5099C),
                border: Border.all(
                  color: const Color(0xFF0C0C0C),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                color: Colors.white,
                size: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    final profile = _profile;
    final isVerified = profile?.verified ?? false;

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    FlutterFlowIconButton(
                      borderColor: Colors.transparent,
                      borderRadius: 16,
                      buttonSize: 42,
                      fillColor: Colors.transparent,
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      onPressed: () => context.pop(),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          'Edit Profile',
                          style:
                              FlutterFlowTheme.of(context).titleMedium.override(
                                    font: GoogleFonts.instrumentSans(
                                      fontWeight: FontWeight.w700,
                                    ),
                                    color: Colors.white,
                                  ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 42),
                  ],
                ),
                const SizedBox(height: 20),
                Center(child: _avatarPreview()),
                const SizedBox(height: 18),
                Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (isVerified)
                        const Icon(
                          Icons.verified_rounded,
                          color: Color(0xFF1ECC70),
                          size: 18,
                        ),
                      Text(
                        isVerified
                            ? 'Verified profile'
                            : 'Profile pending verification',
                        style: FlutterFlowTheme.of(context).bodySmall.override(
                              font: GoogleFonts.instrumentSans(
                                fontWeight: FontWeight.w600,
                              ),
                              color: const Color(0xFFB9B9B9),
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF151515),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFF242424)),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _readOnlyChip(
                        label: 'Branch',
                        value: _profile?.branchId ?? 'Unavailable',
                        accentColor: const Color(0xFFC5099C),
                      ),
                      _readOnlyChip(
                        label: 'Department',
                        value: _profile?.departmentId ?? 'Unavailable',
                        accentColor: const Color(0xFFC5099C),
                      ),
                      _readOnlyChip(
                        label: 'Role',
                        value: _profile?.role ?? 'Member',
                        accentColor: const Color(0xFFC5099C),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                _sectionTitle('Personal Details'),
                const SizedBox(height: 12),
                _fieldCard(
                  label: 'Full Name',
                  initialValue: _fullName,
                  onChanged: (value) => _fullName = value,
                  hintText: 'Enter your full name',
                  validator: (value) {
                    if ((value ?? '').trim().isEmpty) {
                      return 'Full name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _fieldCard(
                  label: 'Phone Number',
                  initialValue: _phone,
                  onChanged: (value) => _phone = value,
                  hintText: 'Enter your phone number',
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                _fieldCard(
                  label: 'Bio',
                  initialValue: _bio,
                  onChanged: (value) => _bio = value,
                  hintText: 'Tell people a little about yourself',
                  maxLines: 4,
                ),
                const SizedBox(height: 22),
                _sectionTitle('Membership Details'),
                const SizedBox(height: 12),
                _fieldCard(
                  label: 'Residential Address',
                  initialValue: _residentialAddress,
                  onChanged: (value) => _residentialAddress = value,
                  hintText: 'Enter your address',
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                _fieldCard(
                  label: 'Occupation',
                  initialValue: _occupation,
                  onChanged: (value) => _occupation = value,
                  hintText: 'Enter your occupation',
                ),
                const SizedBox(height: 12),
                _fieldCard(
                  label: 'Marital Status',
                  initialValue: _maritalStatus,
                  onChanged: (value) => _maritalStatus = value,
                  hintText: 'Single, Married, etc.',
                ),
                const SizedBox(height: 12),
                _fieldCard(
                  label: 'Emergency Contact',
                  initialValue: _emergencyContact,
                  onChanged: (value) => _emergencyContact = value,
                  hintText: 'Enter emergency contact number',
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 22),
                FFButtonWidget(
                  onPressed: _isSaving ? null : _saveProfile,
                  text: _isSaving ? 'Updating...' : 'Save Changes',
                  options: FFButtonOptions(
                    width: double.infinity,
                    height: 52,
                    color: const Color(0xFFC5099C),
                    textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                          font: GoogleFonts.instrumentSans(
                            fontWeight: FontWeight.w700,
                          ),
                          color: Colors.white,
                        ),
                    elevation: 0,
                    borderSide: const BorderSide(
                      color: Colors.transparent,
                      width: 0,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C0C0C),
      body: SafeArea(
        child: FutureBuilder<ProfilesPrivInfoRow?>(
          future: _profileBootstrapFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                _profile == null) {
              return const WpccScreenShimmer(includeBottomNavSpace: false);
            }

            if (_profile == null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'No profile record was found for this account.',
                    textAlign: TextAlign.center,
                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                          font: GoogleFonts.instrumentSans(
                            fontWeight: FontWeight.w400,
                          ),
                          color: Colors.white,
                        ),
                  ),
                ),
              );
            }

            return _buildForm();
          },
        ),
      ),
    );
  }
}
