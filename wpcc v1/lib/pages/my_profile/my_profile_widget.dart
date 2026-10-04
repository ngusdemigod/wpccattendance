import '/auth/supabase_auth/auth_util.dart';
import '/backend/supabase/database/tables/membershipcode.dart';
import '/backend/supabase/database/tables/profiles_priv_info.dart';
import '/features/profile/profile_identity_resolver.dart';
import '/flutter_flow/custom_functions.dart' as functions;
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/upload_data.dart';
import '/services/profile_security/profile_security_models.dart';
import '/services/profile_security/secure_profile_repository.dart';
import '/shared/widgets/wpcc_shimmer.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MyProfileWidget extends StatefulWidget {
  const MyProfileWidget({super.key});

  static String routeName = 'my_profile';
  static String routePath = '/my_profile';

  @override
  State<MyProfileWidget> createState() => _MyProfileWidgetState();
}

class _MyProfileWidgetState extends State<MyProfileWidget> {
  final ProfileIdentityResolver _identityResolver = ProfileIdentityResolver();
  final SecureProfileRepository _secureProfileRepository =
      SecureProfileRepository();
  late Future<List<ProfilesPrivInfoRow>> _profileFuture;
  late Future<String> _membershipCodeFuture;
  late Future<SecureProfileBundle> _secureBundleFuture;
  bool _isUploadingAvatar = false;

  @override
  void initState() {
    super.initState();
    _profileFuture = _loadProfile();
    _membershipCodeFuture = _loadMembershipCode();
    _secureBundleFuture = _secureProfileRepository.loadSecureProfileBundle();
  }

  Map<String, dynamic>? _jwtClaims() {
    final jwt = functions.decodeSupabaseJWT(currentJwtToken);
    if (jwt is Map<String, dynamic>) {
      return jwt;
    }
    return null;
  }

  String _claimString(String key, {Map<String, dynamic>? claims}) {
    final value = (claims ?? _jwtClaims())?[key];
    return value?.toString().trim() ?? '';
  }

  String _nestedClaimString(
    String parentKey,
    String childKey, {
    Map<String, dynamic>? claims,
  }) {
    final parent = (claims ?? _jwtClaims())?[parentKey];
    if (parent is Map<String, dynamic>) {
      return parent[childKey]?.toString().trim() ?? '';
    }
    return '';
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

  Future<String> _loadMembershipCode() async {
    final identity = await _identityResolver.resolveCurrentUser();
    final cachedMembershipCode = identity.membershipCode.trim();
    if (cachedMembershipCode.isNotEmpty) {
      return cachedMembershipCode;
    }

    return MembershipcodeTable()
        .queryRows(
      queryFn: (q) => q.eq('memberid', identity.profileUserId),
      limit: 1,
    )
        .then((rows) {
      if (rows.isEmpty) {
        return '';
      }
      return rows.first.membershipcode.trim();
    });
  }

  ProfilesPrivInfoRow? _profileFromSnapshot(List<ProfilesPrivInfoRow>? rows) {
    if (rows == null || rows.isEmpty) {
      return null;
    }
    return rows.first;
  }

  String _firstNonEmpty(List<String> values, {String fallback = ''}) {
    for (final value in values) {
      if (value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return fallback;
  }

  String _titleCase(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return '';
    }
    return trimmed
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .map((part) {
      if (part.length == 1) {
        return part.toUpperCase();
      }
      return '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}';
    }).join(' ');
  }

  String _formatDate(DateTime? value) {
    if (value == null) {
      return '';
    }
    return dateTimeFormat('MMM y', value);
  }

  String _monthDay(DateTime? value) {
    if (value == null) {
      return '';
    }
    return dateTimeFormat('MMM d', value);
  }

  String _displayName({
    required ProfilesPrivInfoRow? profile,
    required Map<String, dynamic>? claims,
  }) {
    final jwtName = _firstNonEmpty([
      _claimString('full_name', claims: claims),
      _nestedClaimString('user_metadata', 'full_name', claims: claims),
      _nestedClaimString('user_metadata', 'name', claims: claims),
    ]);

    return _firstNonEmpty([
      profile?.fullName ?? '',
      jwtName,
      currentUserDisplayName,
      currentUserEmail,
    ], fallback: 'User');
  }

  String _email({
    required ProfilesPrivInfoRow? profile,
    required Map<String, dynamic>? claims,
  }) {
    return _firstNonEmpty([
      profile?.email ?? '',
      _claimString('email', claims: claims),
      _nestedClaimString('user_metadata', 'email', claims: claims),
      currentUserEmail,
    ], fallback: 'Not available');
  }

  String _branch({
    required ProfilesPrivInfoRow? profile,
    required Map<String, dynamic>? claims,
  }) {
    return _firstNonEmpty([
      _claimString('wpbranch', claims: claims),
      _nestedClaimString('app_metadata', 'wpbranch', claims: claims),
      profile?.branchId ?? '',
    ], fallback: 'Branch unavailable');
  }

  String _department({
    required ProfilesPrivInfoRow? profile,
    required Map<String, dynamic>? claims,
  }) {
    return _firstNonEmpty([
      _claimString('wpdept', claims: claims),
      _nestedClaimString('app_metadata', 'wpdept', claims: claims),
      profile?.departmentId ?? '',
    ], fallback: 'Department unavailable');
  }

  String _role({
    required ProfilesPrivInfoRow? profile,
    required Map<String, dynamic>? claims,
  }) {
    final role = _firstNonEmpty([
      profile?.role ?? '',
      _claimString('wprole', claims: claims),
      _nestedClaimString('app_metadata', 'wprole', claims: claims),
    ], fallback: 'member');
    return _titleCase(role);
  }

  String _bio(ProfilesPrivInfoRow? profile) {
    return _firstNonEmpty([
      profile?.bio ?? '',
    ], fallback: 'No bio added yet.');
  }

  bool _verified(ProfilesPrivInfoRow? profile) {
    return profile?.verified ?? false;
  }

  bool _profileComplete(ProfilesPrivInfoRow? profile, SecureProfileBundle bundle) {
    return profile?.profilecomplete == true || bundle.setupCompleted;
  }

  DateTime? _joinedDate(ProfilesPrivInfoRow? profile) {
    return profile?.dateJoinedWpcc ?? profile?.dateJoined ?? profile?.createdAt;
  }

  DateTime? _dob(ProfilesPrivInfoRow? profile) {
    return profile?.dateOfBirth ?? profile?.dob;
  }

  String _statusLabel(ProfilesPrivInfoRow? profile, SecureProfileBundle bundle) {
    if (_verified(profile)) {
      return 'Verified';
    }
    if (_profileComplete(profile, bundle)) {
      return 'Complete';
    }
    return 'Pending';
  }

  String _joinedLabel(ProfilesPrivInfoRow? profile) {
    final joinedDate = _joinedDate(profile);
    if (joinedDate == null) {
      return 'Unknown';
    }
    return _formatDate(joinedDate);
  }

  String _membershipValue(String? value, {bool titleCase = false}) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'Not available';
    }
    return titleCase ? _titleCase(text) : text;
  }

  String _avatarInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    final words = parts.take(2).toList();
    if (words.isEmpty) {
      return 'U';
    }
    if (words.length == 1) {
      return words.first.substring(0, 1).toUpperCase();
    }
    return '${words[0].substring(0, 1)}${words[1].substring(0, 1)}'
        .toUpperCase();
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

      await _secureProfileRepository.saveProfileImage(Uint8List.fromList(bytes));

      if (!mounted) {
        return;
      }

      setState(() {
        _profileFuture = _loadProfile();
        _secureBundleFuture = _secureProfileRepository.loadSecureProfileBundle();
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

  Future<void> _logout() async {
    final router = GoRouter.of(context);
    router.prepareAuthEvent();
    await authManager.signOut();
    router.clearRedirectLocation();

    if (!mounted) {
      return;
    }

    context.goNamedAuth(
      LoginWidget.routeName,
      context.mounted,
    );
  }

  Future<void> _openEditProfile() async {
    await context.pushNamed(
      EditProfileWidget.routeName,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _profileFuture = _loadProfile();
      _secureBundleFuture = _secureProfileRepository.loadSecureProfileBundle();
    });
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

  Widget _buildAvatar({
    required String imageUrl,
    required Uint8List? imageBytes,
    required String initials,
    required bool verified,
  }) {
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
            child: _ProfileAvatar(
              imageUrl: imageUrl,
              imageBytes: imageBytes,
              initials: initials,
              radius: 48,
            ),
          ),
          if (verified)
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

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0C0C0C),
      body: SafeArea(
        child: FutureBuilder<List<ProfilesPrivInfoRow>>(
          future: _profileFuture,
          builder: (context, profileSnapshot) {
            final profile = _profileFromSnapshot(profileSnapshot.data);
            if (profileSnapshot.connectionState == ConnectionState.waiting &&
                profile == null) {
              return const WpccScreenShimmer(includeBottomNavSpace: false);
            }

            return FutureBuilder<SecureProfileBundle>(
              future: _secureBundleFuture,
              builder: (context, secureSnapshot) {
                final secureBundle = secureSnapshot.data ??
                    const SecureProfileBundle(
                      phoneNumber: '',
                      residentialAddress: '',
                      avatarBytes: null,
                      legacyAvatarUrl: '',
                      setupCompleted: false,
                      initials: 'U',
                    );
                final claims = _jwtClaims();
                final name = _displayName(profile: profile, claims: claims);
                final initials = _avatarInitials(name);
                final role = _role(profile: profile, claims: claims);
                final branch = _branch(profile: profile, claims: claims);
                final department = _department(profile: profile, claims: claims);
                final bio = _bio(profile);
                final email = _email(profile: profile, claims: claims);
                final phone = _firstNonEmpty(
                  [secureBundle.phoneNumber, currentPhoneNumber],
                  fallback: 'Not available',
                );
                final joinedLabel = _joinedLabel(profile);
                final statusLabel = _statusLabel(profile, secureBundle);
                final isVerified = _verified(profile);
                final dobLabel = _monthDay(_dob(profile));
                final maritalStatus = _membershipValue(
                  profile?.maritalStatus,
                  titleCase: true,
                );
                final occupation = _membershipValue(
                  profile?.occupation,
                  titleCase: true,
                );
                final maturityClassCompleted = _membershipValue(
                  profile?.maturityClassCompleted,
                  titleCase: true,
                );
                final emergencyContact =
                    _membershipValue(profile?.emergencyContact);
                final ministryClassCompleted = _membershipValue(
                  profile?.ministryClassCompleted,
                  titleCase: true,
                );
                final missionClassCompleted = _membershipValue(
                  profile?.missionClassCompleted,
                  titleCase: true,
                );

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _TopBar(
                            onBack: () => context.pop(),
                            onEdit: () => _openEditProfile(),
                          ),
                          const SizedBox(height: 20),
                          Center(
                            child: _buildAvatar(
                              imageUrl: _firstNonEmpty(
                                [
                                  profile?.avatar ?? '',
                                  secureBundle.legacyAvatarUrl,
                                ],
                                fallback: '',
                              ),
                              imageBytes:
                                  (profile?.avatar?.trim().isNotEmpty ?? false)
                                      ? null
                                      : secureBundle.avatarBytes,
                              initials: initials,
                              verified: isVerified,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            name,
                            textAlign: TextAlign.center,
                            style: theme.headlineMedium.override(
                              font: GoogleFonts.instrumentSans(
                                fontWeight: FontWeight.w800,
                              ),
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              const Icon(
                                Icons.home_rounded,
                                color: Color(0xFFC5099C),
                                size: 14,
                              ),
                              Text(
                                '$role - $branch',
                                style: theme.bodySmall.override(
                                  font: GoogleFonts.instrumentSans(
                                    fontWeight: FontWeight.w400,
                                  ),
                                  color: const Color(0xFFB6B6B6),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1A1A),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 16,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _StatTile(
                                    value: joinedLabel,
                                    label: 'Joined',
                                  ),
                                ),
                                const _StatsDivider(),
                                Expanded(
                                  child: _StatTile(
                                    value: department,
                                    label: 'Department',
                                  ),
                                ),
                                const _StatsDivider(),
                                Expanded(
                                  child: _StatTile(
                                    value: statusLabel,
                                    label: 'Status',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 22),
                          _sectionTitle('About Me'),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              bio,
                              textAlign: TextAlign.center,
                              style: theme.bodyMedium.override(
                                font: GoogleFonts.instrumentSans(
                                  fontWeight: FontWeight.w400,
                                ),
                                color: const Color(0xFFB7B7B7),
                                lineHeight: 1.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),
                          _sectionTitle('Personal Details'),
                          const SizedBox(height: 12),
                          _DetailCard(
                            icon: Icons.mail_rounded,
                            label: 'Email Address',
                            value: email,
                          ),
                          const SizedBox(height: 12),
                          _DetailCard(
                            icon: Icons.phone_rounded,
                            label: 'Phone Number',
                            value: phone,
                          ),
                          const SizedBox(height: 12),
                          FutureBuilder<String>(
                            future: _membershipCodeFuture,
                            builder: (context, membershipSnapshot) {
                              final membershipCode = _firstNonEmpty([
                                profile?.membershipCode ?? '',
                                membershipSnapshot.data ?? '',
                              ], fallback: 'Not assigned');

                              return _DetailCard(
                                icon: Icons.badge_rounded,
                                label: 'Membership Code',
                                value: membershipCode,
                              );
                            },
                          ),
                          const SizedBox(height: 22),
                          _sectionTitle('Membership Details'),
                          const SizedBox(height: 12),
                          _DetailCard(
                            icon: Icons.cake_rounded,
                            label: 'Date of Birth',
                            value: dobLabel.isNotEmpty
                                ? dobLabel
                                : 'Not available',
                          ),
                          const SizedBox(height: 12),
                          _DetailCard(
                            icon: Icons.favorite_rounded,
                            label: 'Marital Status',
                            value: maritalStatus,
                          ),
                          const SizedBox(height: 12),
                          _DetailCard(
                            icon: Icons.work_rounded,
                            label: 'Occupation',
                            value: occupation,
                          ),
                          const SizedBox(height: 12),
                          _DetailCard(
                            icon: Icons.school_rounded,
                            label: 'Maturity Class',
                            value: maturityClassCompleted,
                          ),
                          const SizedBox(height: 12),
                          _DetailCard(
                            icon: Icons.contact_phone_rounded,
                            label: 'Emergency Contact',
                            value: emergencyContact,
                          ),
                          const SizedBox(height: 12),
                          _DetailCard(
                            icon: Icons.church_rounded,
                            label: 'Ministry Class',
                            value: ministryClassCompleted,
                          ),
                          const SizedBox(height: 12),
                          _DetailCard(
                            icon: Icons.public_rounded,
                            label: 'Mission Class',
                            value: missionClassCompleted,
                          ),
                          const SizedBox(height: 22),
                          Center(
                            child: TextButton(
                              onPressed: _logout,
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFFC5099C),
                                padding: EdgeInsets.zero,
                                tapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                minimumSize: Size.zero,
                              ),
                              child: Text(
                                'Log out',
                                style: theme.bodySmall.override(
                                  font: GoogleFonts.instrumentSans(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  color: const Color(0xFFC5099C),
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.onBack,
    required this.onEdit,
  });

  final VoidCallback onBack;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Row(
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
          onPressed: onBack,
        ),
        Expanded(
          child: Center(
            child: Text(
              'My Profile',
              style: FlutterFlowTheme.of(context).titleMedium.override(
                    font: GoogleFonts.instrumentSans(
                      fontWeight: FontWeight.w700,
                    ),
                    color: Colors.white,
                  ),
            ),
          ),
        ),
        FlutterFlowIconButton(
          borderColor: Colors.transparent,
          borderRadius: 16,
          buttonSize: 42,
          fillColor: Colors.transparent,
          icon: const Icon(
            Icons.edit_rounded,
            color: Color(0xFFC5099C),
            size: 18,
          ),
          onPressed: onEdit,
        ),
      ],
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.imageUrl,
    required this.imageBytes,
    required this.initials,
    required this.radius,
  });

  final String imageUrl;
  final Uint8List? imageBytes;
  final String initials;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    if (imageBytes != null) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: const Color(0xFF201814),
        backgroundImage: MemoryImage(imageBytes!),
      );
    }

    if (imageUrl.trim().isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: const Color(0xFF201814),
        backgroundImage: NetworkImage(imageUrl),
        onBackgroundImageError: (_, __) {},
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFF201814),
      child: Text(
        initials,
        style: theme.titleLarge.override(
          font: GoogleFonts.instrumentSans(
            fontWeight: FontWeight.w800,
          ),
          color: const Color(0xFFC5099C),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.titleMedium.override(
            font: GoogleFonts.instrumentSans(
              fontWeight: FontWeight.w800,
            ),
            fontSize: 14,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: theme.labelSmall.override(
            font: GoogleFonts.instrumentSans(
              fontWeight: FontWeight.w400,
            ),
            color: const Color(0xFFA4A4A4),
          ),
        ),
      ],
    );
  }
}

class _StatsDivider extends StatelessWidget {
  const _StatsDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 28,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      color: const Color(0xFF2A2A2A),
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF302418),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: const Color(0xFFC5099C),
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.labelSmall.override(
                      font: GoogleFonts.instrumentSans(
                        fontWeight: FontWeight.w400,
                      ),
                      color: const Color(0xFFA7A7A7),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.bodyMedium.override(
                      font: GoogleFonts.instrumentSans(
                        fontWeight: FontWeight.w600,
                      ),
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
