import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../auth/supabase_auth/auth_util.dart';
import '../../backend/supabase/supabase.dart';
import '../../backend/supabase/database/database.dart';
import '../../flutter_flow/flutter_flow_util.dart';
import '../../flutter_flow/upload_data.dart';
import '../../index.dart';
import '../../services/profile_security/secure_profile_repository.dart';
import '../../shared/widgets/hamburger_menu_button.dart';
import '../../shared/widgets/wpcc_shimmer.dart';
import '../profile_completion/profile_completion_service.dart';
import 'profile_feature_service.dart';
import 'profile_identity_resolver.dart';
import 'profile_classes_screen.dart';
import 'profile_query_screen.dart';
import 'profile_ui_kit.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<_ProfileScreenData> _profileFuture;
  ProfileRouteTab _activeTab = ProfileRouteTab.overview;
  final _profileDetailsService = _ProfilePersonalDetailsService();
  bool _isUpdatingAvatar = false;
  final ValueNotifier<double> _avatarUploadProgress = ValueNotifier(0);
  Uint8List? _pendingAvatarBytes;
  ProfileCompletionStatus _lastSeenCompletionStatus =
      AppStateNotifier.instance.profileCompletionStatus;

  @override
  void initState() {
    super.initState();
    _profileFuture = _ProfileService().load();
    // The profile tab is built once and kept alive alongside the other tabs
    // in the app shell's IndexedStack, so it can be sitting on a fetch made
    // before the onboarding flow's completion write lands. Re-fetch when
    // that status flips to complete so newly-saved fields aren't left stale.
    AppStateNotifier.instance.addListener(_handleAppStateChanged);
  }

  @override
  void dispose() {
    AppStateNotifier.instance.removeListener(_handleAppStateChanged);
    _avatarUploadProgress.dispose();
    super.dispose();
  }

  void _handleAppStateChanged() {
    final status = AppStateNotifier.instance.profileCompletionStatus;
    if (status == _lastSeenCompletionStatus) {
      return;
    }
    _lastSeenCompletionStatus = status;
    if (status == ProfileCompletionStatus.complete && mounted) {
      _refreshProfile();
    }
  }

  void _retry() {
    setState(() {
      _profileFuture = _ProfileService().load();
    });
  }

  Future<void> _refreshProfile() async {
    final refreshedFuture = _ProfileService().load();
    setState(() {
      _profileFuture = refreshedFuture;
    });
    await refreshedFuture;
  }

  Future<void> _copyMemberId(String memberId) async {
    if (memberId.trim().isEmpty) {
      return;
    }
    await Clipboard.setData(ClipboardData(text: memberId));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Member ID copied')),
    );
  }

  Future<void> _openAvatarOptions(_ProfileScreenData data) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x85111827),
      builder: (sheetContext) => _AvatarOptionsSheet(
        data: data,
        onViewPhoto: data.avatarUrl.isEmpty
            ? null
            : () {
                Navigator.of(sheetContext).pop();
                _openAvatarPreview(data);
              },
        onReplace: () {
          Navigator.of(sheetContext).pop();
          _replaceAvatar();
        },
      ),
    );
  }

  Future<void> _replaceAvatar() async {
    final media = await selectMediaWithSourceBottomSheet(
      context: context,
      imageQuality: 90,
      allowPhoto: true,
      pickerFontFamily: 'Instrument Sans',
    );
    if (!mounted || media == null || media.isEmpty) {
      return;
    }
    if (!media.every((file) => validateFileFormat(file.storagePath, context))) {
      return;
    }
    final bytes = media.first.bytes;
    final sourcePath = media.first.storagePath;
    if (bytes.isEmpty) {
      return;
    }

    final avatarBytes = Uint8List.fromList(bytes);
    _avatarUploadProgress.value = 0.02;
    setState(() {
      _isUpdatingAvatar = true;
      _pendingAvatarBytes = avatarBytes;
    });
    try {
      await SecureProfileRepository().saveProfileImage(
        avatarBytes,
        sourcePath: sourcePath,
        onProgress: (progress) {
          if (!mounted) {
            return;
          }
          _avatarUploadProgress.value = progress.clamp(0.02, 1.0);
        },
      );
      if (!mounted) {
        return;
      }
      final refreshedFuture = _ProfileService().load();
      _avatarUploadProgress.value = 1;
      setState(() {
        _profileFuture = refreshedFuture;
      });
      await refreshedFuture;
      if (!mounted) {
        return;
      }
      _avatarUploadProgress.value = 0;
      setState(() {
        _isUpdatingAvatar = false;
        _pendingAvatarBytes = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile photo updated')),
      );
    } catch (error) {
      debugPrint('Avatar update failed: $error');
      if (!mounted) {
        return;
      }
      _avatarUploadProgress.value = 0;
      setState(() {
        _isUpdatingAvatar = false;
        _pendingAvatarBytes = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not update photo. Please try again.'),
        ),
      );
    }
  }

  void _openAvatarPreview(_ProfileScreenData data) {
    Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.black87,
        transitionDuration: const Duration(milliseconds: 240),
        pageBuilder: (_, animation, __) => FadeTransition(
          opacity: animation,
          child: _AvatarPreviewPage(
            imageUrl: data.avatarUrl,
            initials: data.initials,
          ),
        ),
      ),
    );
  }

  void _openClasses() {
    setState(() => _activeTab = ProfileRouteTab.classes);
  }

  void _openQuery() {
    setState(() => _activeTab = ProfileRouteTab.query);
  }

  void _selectTab(ProfileRouteTab tab) {
    if (_activeTab == tab) return;
    setState(() => _activeTab = tab);
  }

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
          context: context,
          barrierColor: const Color(0x66111827),
          builder: (dialogContext) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
              decoration: BoxDecoration(
                color: const Color(0xFFFCFBF9),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0x14111827)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Log out?',
                    style: _serif(
                      size: 28,
                      letterSpacing: -0.56,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'You will need to verify your account again to continue.',
                    style: _sans(
                      size: 13,
                      color: const Color(0xFF6B7280),
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        child: Text(
                          'Cancel',
                          style: _sans(
                            size: 13,
                            weight: FontWeight.w600,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                        child: Text(
                          'Log out',
                          style: _sans(
                            size: 13,
                            weight: FontWeight.w700,
                            color: const Color(0xFFCF2A2A),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ) ??
        false;

    if (!shouldLogout) {
      return;
    }
    if (!context.mounted) {
      return;
    }

    // ignore: use_build_context_synchronously
    final router = GoRouter.of(context);
    router.prepareAuthEvent();
    await authManager.signOut();
    router.clearRedirectLocation();

    if (!context.mounted) {
      return;
    }

    // ignore: use_build_context_synchronously
    context.goNamedAuth(
      LoginWidget.routeName,
      context.mounted,
    );
  }

  TextStyle _serif({
    double size = 28,
    FontWeight weight = FontWeight.w400,
    Color color = const Color(0xFF111827),
    double height = 1.02,
    double letterSpacing = -0.84,
  }) {
    return GoogleFonts.instrumentSerif(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  TextStyle _sans({
    double size = 13,
    FontWeight weight = FontWeight.w400,
    Color color = const Color(0xFF111827),
    double height = 1.25,
    double letterSpacing = 0,
  }) {
    return GoogleFonts.instrumentSans(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Row(
        children: [
          const HamburgerMenuButton(),
          const SizedBox(width: 12),
          Expanded(child: Text('Profile', style: _serif())),
          Row(
            children: [
              _ProfileIconButton(
                icon: Icons.search_rounded,
                semanticLabel: 'Search profile',
                onTap: () => context.pushNamed(GlobalSearchScreen.routeName),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return ProfileRouteTabs(
      activeTab: _activeTab,
      onSelected: (tab) {
        switch (tab) {
          case ProfileRouteTab.overview:
            _selectTab(tab);
            break;
          case ProfileRouteTab.classes:
            _openClasses();
            break;
          case ProfileRouteTab.query:
            _openQuery();
            break;
        }
      },
    );
  }

  Widget _buildOverview(_ProfileScreenData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 22),
        _ProfileIdentity(
          data: data,
          sans: _sans,
          onCopyMemberId: _copyMemberId,
          isUpdatingAvatar: _isUpdatingAvatar,
          avatarUploadProgress: _avatarUploadProgress,
          pendingAvatarBytes: _pendingAvatarBytes,
          onAvatarTap:
              _isUpdatingAvatar ? null : () => _openAvatarOptions(data),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: _ProfileStatsBar(data: data, sans: _sans),
        ),
        _SectionHeading(title: 'Personal Details', textStyle: _sans),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
          child: _PersonalDetailsCard(
            data: data,
            sans: _sans,
            onSaveField: _profileDetailsService.updateField,
            onProfileUpdated: _refreshProfile,
          ),
        ),
        _SectionHeading(title: 'Classes', textStyle: _sans),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
          child: _PendingClassesCard(data: data, sans: _sans),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
          child: Align(
            alignment: Alignment.centerLeft,
            child: InkWell(
              onTap: _logout,
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  'Log out',
                  style: _sans(
                    size: 14,
                    weight: FontWeight.w700,
                    color: const Color(0xFFCF2A2A),
                    height: 1,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_activeTab == ProfileRouteTab.classes) {
      return ProfileClassesScreen(
        embedded: true,
        onTabSelected: _selectTab,
      );
    }
    if (_activeTab == ProfileRouteTab.query) {
      return ProfileQueryScreen(
        embedded: true,
        onTabSelected: _selectTab,
      );
    }

    return DecoratedBox(
      decoration: const BoxDecoration(color: Colors.white),
      child: SafeArea(
        bottom: false,
        child: FutureBuilder<_ProfileScreenData>(
          future: _profileFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _ProfileLoadingView();
            }

            if (snapshot.hasError) {
              return _ProfileErrorView(onRetry: _retry);
            }

            final data = snapshot.data;
            if (data == null) {
              return _ProfileErrorView(onRetry: _retry);
            }

            return Column(
              children: [
                ColoredBox(
                  color: Colors.white,
                  child: _buildHeader(),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTabs(),
                        _buildOverview(data),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ProfileService {
  Future<_ProfileScreenData> load() async {
    final results = await Future.wait<dynamic>([
      MyProfileTable().queryRows(
        queryFn: (q) => q,
        limit: 1,
      ),
      MyClassesTable().queryRows(
        queryFn: (q) => q
            .order('due_at', ascending: true)
            .order('assigned_at', ascending: false),
        limit: 8,
      ),
    ]);

    final profileRows = results[0] as List<MyProfileRow>;
    final classRows = results[1] as List<MyClassesRow>;

    if (profileRows.isEmpty) {
      throw StateError(
          'No my_profile row returned for the authenticated user.');
    }

    final profile = profileRows.first;
    final fullName = _firstNonEmpty([
      profile.fullName,
      currentUserDisplayName,
      currentUserEmail,
    ], fallback: 'User');
    final completedCount = profile.coursesCompletedCount ?? 0;
    final inProgressCount = profile.classesInProgressCount ?? 0;
    final pendingCount = profile.pendingClassesCount ?? 0;
    final roleChip = _firstNonEmpty([
      profile.leadershipTitle,
      profile.roleName,
    ]);

    final pendingClasses = classRows
        .map((row) => _PendingClassItem(
              title: row.title?.trim() ?? '',
              meta: _pendingClassMeta(row),
              startedAt: row.assignedAt ?? row.availableFrom,
              status: _normalizedClassStatus(row.status),
            ))
        .where((item) => item.title.isNotEmpty)
        .toList();

    return _ProfileScreenData(
      initials: _initialsFor(fullName),
      avatarUrl: profile.avatar?.trim() ?? '',
      fullName: fullName,
      roleChip: roleChip.isEmpty ? null : _prettifyRole(roleChip),
      departmentChip: _firstNonEmpty([profile.departmentName]).isEmpty
          ? null
          : _firstNonEmpty([profile.departmentName]),
      isVerified: profile.isVerified == true,
      verificationLabel: profile.isVerified == true ? 'Verified Worker' : null,
      coursesCompleted: completedCount,
      coursesTotal: completedCount + inProgressCount + pendingCount,
      queryCount: profile.queriesCount,
      attendanceRate: profile.attendanceRatePercent,
      memberSince: profile.memberSince,
      memberId: _baseMemberCode(_firstNonEmpty([
        profile.membershipCode,
        profile.memberIdDisplay,
      ])),
      branchName: _firstNonEmpty([profile.branchName]),
      statusLabel: profile.statusLabel?.trim(),
      departmentName: _firstNonEmpty([profile.departmentName]),
      departmentBadge:
          (profile.leadershipTitle?.trim().isNotEmpty ?? false) ? 'Lead' : null,
      email: _firstNonEmpty([
        profile.email,
        currentUserEmail,
      ]),
      phone: _firstNonEmpty([
        profile.phone,
        currentPhoneNumber,
      ]),
      gender: _firstNonEmpty([profile.gender]),
      maritalStatus: _firstNonEmpty([profile.maritalStatus]),
      occupation: _firstNonEmpty([profile.occupation]),
      residentialAddress: _firstNonEmpty([profile.residentialAddress]),
      dateOfBirth: profile.dateOfBirth,
      emergencyContact: _firstNonEmpty([profile.emergencyContact]),
      waterBaptismDate: profile.waterBaptismDate,
      maturityClassCompleted: _firstNonEmpty([profile.maturityClassCompleted]),
      ministryClassCompleted: _firstNonEmpty([profile.ministryClassCompleted]),
      missionClassCompleted: _firstNonEmpty([profile.missionClassCompleted]),
      bio: _firstNonEmpty([profile.bio]),
      joinedDate: profile.memberSince,
      pendingClasses: pendingClasses,
    );
  }

  static String _initialsFor(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .toList();
    if (parts.isEmpty) {
      return 'U';
    }
    return parts.map((part) => part[0].toUpperCase()).join();
  }

  static String _firstNonEmpty(
    List<String?> values, {
    String fallback = '',
  }) {
    for (final value in values) {
      final trimmed = value?.trim() ?? '';
      if (trimmed.isNotEmpty) {
        return trimmed;
      }
    }
    return fallback;
  }

  static String _prettifyRole(String value) {
    final upper = value.trim().toUpperCase();
    if (upper == 'PRO' || upper == 'HOD') {
      return upper;
    }
    return value
        .trim()
        .split(RegExp(r'[_\s]+'))
        .where((part) => part.isNotEmpty)
        .map((part) {
      if (part.length <= 3 && part.toUpperCase() == part) {
        return part;
      }
      return '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}';
    }).join(' ');
  }

  static String _pendingClassMeta(MyClassesRow row) {
    final parts = <String>[];
    if (row.moduleIndex != null && row.moduleTotal != null) {
      parts.add('Module ${row.moduleIndex} of ${row.moduleTotal}');
    }
    final description = row.description?.trim() ?? '';
    if (description.isNotEmpty) {
      parts.add(description);
    }
    if (parts.isEmpty && row.assignedAt != null) {
      parts.add('Assigned ${_formatMonthDay(row.assignedAt!)}');
    }
    return parts.join(' - ');
  }

  static String _formatMonthDay(DateTime value) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[value.month - 1]} ${value.day}';
  }

  static String _normalizedClassStatus(String? value) {
    switch (value?.trim().toLowerCase()) {
      case 'completed':
        return 'completed';
      case 'in_progress':
      case 'pending':
      default:
        return 'in_progress';
    }
  }

  static String _baseMemberCode(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return '';
    }
    final digitMatches = RegExp(r'\d{4}').allMatches(trimmed).toList();
    if (digitMatches.isNotEmpty) {
      return digitMatches.last.group(0)!;
    }
    final segments = trimmed
        .split('/')
        .map((segment) => segment.trim())
        .where((segment) => segment.isNotEmpty)
        .toList();
    return segments.isEmpty ? trimmed : segments.last;
  }
}

class _ProfileScreenData {
  const _ProfileScreenData({
    required this.initials,
    required this.avatarUrl,
    required this.fullName,
    required this.roleChip,
    required this.departmentChip,
    required this.isVerified,
    required this.verificationLabel,
    required this.coursesCompleted,
    required this.coursesTotal,
    required this.queryCount,
    required this.attendanceRate,
    required this.memberSince,
    required this.memberId,
    required this.branchName,
    required this.statusLabel,
    required this.departmentName,
    required this.departmentBadge,
    required this.email,
    required this.phone,
    required this.gender,
    required this.maritalStatus,
    required this.occupation,
    required this.residentialAddress,
    required this.dateOfBirth,
    required this.emergencyContact,
    required this.waterBaptismDate,
    required this.maturityClassCompleted,
    required this.ministryClassCompleted,
    required this.missionClassCompleted,
    required this.bio,
    required this.joinedDate,
    required this.pendingClasses,
  });

  final String initials;
  final String avatarUrl;
  final String fullName;
  final String? roleChip;
  final String? departmentChip;
  final bool isVerified;
  final String? verificationLabel;
  final int coursesCompleted;
  final int coursesTotal;
  final int? queryCount;
  final int? attendanceRate;
  final DateTime? memberSince;
  final String memberId;
  final String branchName;
  final String? statusLabel;
  final String departmentName;
  final String? departmentBadge;
  final String email;
  final String phone;
  final String gender;
  final String maritalStatus;
  final String occupation;
  final String residentialAddress;
  final DateTime? dateOfBirth;
  final String emergencyContact;
  final DateTime? waterBaptismDate;
  final String maturityClassCompleted;
  final String ministryClassCompleted;
  final String missionClassCompleted;
  final String bio;
  final DateTime? joinedDate;
  final List<_PendingClassItem> pendingClasses;
}

class _PendingClassItem {
  const _PendingClassItem({
    required this.title,
    required this.meta,
    required this.startedAt,
    required this.status,
  });

  final String title;
  final String meta;
  final DateTime? startedAt;
  final String status;
}

class _ProfileIdentity extends StatelessWidget {
  const _ProfileIdentity({
    required this.data,
    required this.sans,
    required this.avatarUploadProgress,
    required this.onCopyMemberId,
    this.onAvatarTap,
    this.isUpdatingAvatar = false,
    this.pendingAvatarBytes,
  });

  final _ProfileScreenData data;
  final VoidCallback? onAvatarTap;
  final bool isUpdatingAvatar;
  final ValueListenable<double> avatarUploadProgress;
  final Future<void> Function(String memberId) onCopyMemberId;
  final Uint8List? pendingAvatarBytes;
  final TextStyle Function({
    double size,
    FontWeight weight,
    Color color,
    double height,
    double letterSpacing,
  }) sans;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Semantics(
            button: true,
            label: 'View or replace profile photo',
            child: GestureDetector(
              onTap: onAvatarTap,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 84,
                    height: 84,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isUpdatingAvatar
                            ? const Color(0xFF1A9B4A)
                            : const Color(0xFFE9D6A6),
                        width: 2,
                      ),
                      color: Colors.white,
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (isUpdatingAvatar)
                          ValueListenableBuilder<double>(
                            valueListenable: avatarUploadProgress,
                            builder: (context, progress, _) {
                              final ringProgress =
                                  progress.clamp(0, 1).toDouble();
                              return CircularProgressIndicator(
                                value: ringProgress <= 0 ? null : ringProgress,
                                strokeWidth: 3,
                                backgroundColor: const Color(0x1A1A9B4A),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Color(0xFF1A9B4A),
                                ),
                              );
                            },
                          ),
                        Padding(
                          padding: const EdgeInsets.all(4),
                          child: ClipOval(
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                if (pendingAvatarBytes != null)
                                  Image.memory(
                                    pendingAvatarBytes!,
                                    fit: BoxFit.cover,
                                  )
                                else if (data.avatarUrl.isNotEmpty)
                                  CachedNetworkImage(
                                    imageUrl: data.avatarUrl,
                                    fit: BoxFit.cover,
                                    errorWidget: (_, __, ___) =>
                                        _AvatarFallback(
                                      initials: data.initials,
                                      textStyle: sans,
                                    ),
                                  )
                                else
                                  _AvatarFallback(
                                    initials: data.initials,
                                    textStyle: sans,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFF111113),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      alignment: Alignment.center,
                      child: isUpdatingAvatar
                          ? ValueListenableBuilder<double>(
                              valueListenable: avatarUploadProgress,
                              builder: (context, progress, _) {
                                final ringProgress =
                                    progress.clamp(0, 1).toDouble();
                                return Text(
                                  '${(ringProgress * 100).round()}%',
                                  style: sans(
                                    size: 7.5,
                                    weight: FontWeight.w700,
                                    color: Colors.white,
                                    height: 1,
                                  ),
                                );
                              },
                            )
                          : const Icon(
                              Icons.camera_alt_outlined,
                              size: 13,
                              color: Colors.white,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (data.statusLabel?.isNotEmpty ?? false) ...[
            const SizedBox(height: 10),
            _SmallStatusBadge(
              label: data.statusLabel!,
              background: const Color(0xFFE3F5E9),
              foreground: const Color(0xFF1A6B35),
            ),
          ],
          if ((data.roleChip?.isNotEmpty ?? false) ||
              (data.departmentChip?.isNotEmpty ?? false)) ...[
            const SizedBox(height: 10),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                if (data.roleChip?.isNotEmpty ?? false)
                  _InfoChip(label: data.roleChip!),
                if (data.departmentChip?.isNotEmpty ?? false)
                  _InfoChip(label: data.departmentChip!),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Text(
            data.fullName,
            textAlign: TextAlign.center,
            style: sans(
              size: 20,
              weight: FontWeight.w600,
              color: const Color(0xFF111827),
              height: 1.2,
            ),
          ),
          if (data.memberId.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    data.memberId,
                    style: sans(
                      size: 12,
                      weight: FontWeight.w600,
                      color: const Color(0xFF6B7280),
                      height: 1.2,
                      letterSpacing: .6,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Semantics(
                    button: true,
                    label: 'Copy member ID',
                    child: InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: () => onCopyMemberId(data.memberId),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          FFIcons.kcopySimple,
                          size: 15,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (data.isVerified && (data.verificationLabel?.isNotEmpty ?? false))
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE3F5E9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 12,
                      color: Color(0xFF1A6B35),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    data.verificationLabel!,
                    style: sans(
                      size: 12,
                      weight: FontWeight.w400,
                      color: const Color(0xFF6B7280),
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback({
    required this.initials,
    required this.textStyle,
  });

  final String initials;
  final TextStyle Function({
    double size,
    FontWeight weight,
    Color color,
    double height,
    double letterSpacing,
  }) textStyle;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      alignment: Alignment.center,
      child: Text(
        initials,
        style: textStyle(
          size: 26,
          weight: FontWeight.w600,
          color: const Color(0xFF111827),
          height: 1,
        ),
      ),
    );
  }
}

class _ProfileStatsBar extends StatelessWidget {
  const _ProfileStatsBar({
    required this.data,
    required this.sans,
  });

  final _ProfileScreenData data;
  final TextStyle Function({
    double size,
    FontWeight weight,
    Color color,
    double height,
    double letterSpacing,
  }) sans;

  String _memberSinceLabel(DateTime? value) {
    if (value == null) {
      return '--';
    }
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[value.month - 1]} ${value.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFBF9),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0x14111827)),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            _StatColumn(
              value: data.coursesTotal > 0 ? '${data.coursesCompleted}' : '--',
              trailing:
                  data.coursesTotal > 0 ? ' of ${data.coursesTotal}' : null,
              label: 'Courses taken',
              sans: sans,
            ),
            const _StatDivider(),
            _StatColumn(
              value: data.queryCount?.toString() ?? '--',
              label: 'Queries',
              sans: sans,
            ),
            const _StatDivider(),
            _StatColumn(
              value: data.attendanceRate != null
                  ? '${data.attendanceRate}%'
                  : '--',
              label: 'Attendance rate',
              sans: sans,
            ),
            const _StatDivider(),
            _StatColumn(
              value: _memberSinceLabel(data.memberSince),
              valueSize: 14,
              label: 'Member since',
              sans: sans,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({
    required this.value,
    required this.label,
    required this.sans,
    this.trailing,
    this.valueSize = 16,
  });

  final String value;
  final String label;
  final String? trailing;
  final double valueSize;
  final TextStyle Function({
    double size,
    FontWeight weight,
    Color color,
    double height,
    double letterSpacing,
  }) sans;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                children: [
                  TextSpan(
                    text: value,
                    style: sans(
                      size: valueSize,
                      weight: FontWeight.w600,
                      color: const Color(0xFF111113),
                      height: 1.1,
                    ),
                  ),
                  if (trailing != null)
                    TextSpan(
                      text: trailing,
                      style: sans(
                        size: 8,
                        weight: FontWeight.w400,
                        color: const Color(0xFF8A8F98),
                        height: 1.1,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: sans(
                size: 8,
                weight: FontWeight.w400,
                color: const Color(0xFF8A8F98),
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      margin: const EdgeInsets.symmetric(vertical: 6),
      color: const Color(0x0F111827),
    );
  }
}

class _PersonalDetailsCard extends StatelessWidget {
  const _PersonalDetailsCard({
    required this.data,
    required this.sans,
    required this.onSaveField,
    required this.onProfileUpdated,
  });

  final _ProfileScreenData data;
  final Future<void> Function(_EditableProfileField field, String value)
      onSaveField;
  final Future<void> Function() onProfileUpdated;
  final TextStyle Function({
    double size,
    FontWeight weight,
    Color color,
    double height,
    double letterSpacing,
  }) sans;

  String _formatLongDate(DateTime? value) {
    if (value == null) {
      return '';
    }
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[value.month - 1]} ${value.day}, ${value.year}';
  }

  @override
  Widget build(BuildContext context) {
    final rows = <_DetailRowData>[
      _DetailRowData(
        icon: Icons.badge_outlined,
        label: 'Full name',
        value: data.fullName,
        editableField: _EditableProfileField.fullName,
      ),
      _DetailRowData(
        icon: Icons.alternate_email_rounded,
        label: 'Email',
        value: data.email,
      ),
      _DetailRowData(
        icon: Icons.phone_outlined,
        label: 'Phone number',
        value: data.phone,
        editableField: _EditableProfileField.phoneNumber,
        keyboardType: TextInputType.phone,
      ),
      _DetailRowData(
        icon: Icons.person_outline_rounded,
        label: 'Gender',
        value: data.gender,
        editableField: _EditableProfileField.gender,
      ),
      _DetailRowData(
        icon: Icons.favorite_border_rounded,
        label: 'Marital status',
        value: data.maritalStatus,
        editableField: _EditableProfileField.maritalStatus,
      ),
      _DetailRowData(
        icon: Icons.work_outline_rounded,
        label: 'Occupation',
        value: data.occupation,
        editableField: _EditableProfileField.occupation,
      ),
      _DetailRowData(
        icon: Icons.home_outlined,
        label: 'Residential address',
        value: data.residentialAddress,
        editableField: _EditableProfileField.residentialAddress,
        maxLines: 2,
      ),
      _DetailRowData(
        icon: Icons.cake_outlined,
        label: 'Date of birth',
        value: _formatLongDate(data.dateOfBirth),
      ),
      if (data.departmentName.isNotEmpty)
        _DetailRowData(
          icon: Icons.account_balance_outlined,
          label: 'Department',
          value: data.departmentName,
          badge: data.departmentBadge,
        ),
      if (data.branchName.isNotEmpty)
        _DetailRowData(
          icon: Icons.location_on_outlined,
          label: 'Branch',
          value: data.branchName,
        ),
      if (data.joinedDate != null)
        _DetailRowData(
          icon: Icons.event_outlined,
          label: 'Date joined',
          value: _formatLongDate(data.joinedDate),
        ),
      _DetailRowData(
        icon: Icons.shield_outlined,
        label: 'Emergency contact',
        value: data.emergencyContact,
        editableField: _EditableProfileField.emergencyContact,
      ),
      if (data.waterBaptismDate != null)
        _DetailRowData(
          icon: Icons.water_drop_outlined,
          label: 'Water baptism',
          value: _formatLongDate(data.waterBaptismDate),
        ),
      _DetailRowData(
        icon: Icons.school_outlined,
        label: 'Maturity class',
        value: data.maturityClassCompleted,
      ),
      _DetailRowData(
        icon: Icons.school_outlined,
        label: 'Ministry class',
        value: data.ministryClassCompleted,
      ),
      _DetailRowData(
        icon: Icons.school_outlined,
        label: 'Mission class',
        value: data.missionClassCompleted,
      ),
      _DetailRowData(
        icon: Icons.notes_outlined,
        label: 'Bio',
        value: data.bio,
        editableField: _EditableProfileField.bio,
        maxLines: 3,
      ),
    ];

    if (rows.isEmpty) {
      return _EmptyCard(
        message: 'No personal details available',
        sans: sans,
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFCFBF9),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0x14111827)),
      ),
      child: Column(
        children: List.generate(rows.length, (index) {
          final row = rows[index];
          return _ProfileDetailRow(
            data: row,
            isLast: index == rows.length - 1,
            sans: sans,
            onSaveField: onSaveField,
            onProfileUpdated: onProfileUpdated,
          );
        }),
      ),
    );
  }
}

class _PendingClassesCard extends StatelessWidget {
  const _PendingClassesCard({
    required this.data,
    required this.sans,
  });

  final _ProfileScreenData data;
  final TextStyle Function({
    double size,
    FontWeight weight,
    Color color,
    double height,
    double letterSpacing,
  }) sans;

  @override
  Widget build(BuildContext context) {
    if (data.pendingClasses.isEmpty) {
      return _EmptyCard(
        message: 'No classes available',
        sans: sans,
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFCFBF9),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0x14111827)),
      ),
      child: Column(
        children: List.generate(data.pendingClasses.length, (index) {
          final item = data.pendingClasses[index];
          return _PendingClassRow(
            item: item,
            isLast: index == data.pendingClasses.length - 1,
            sans: sans,
          );
        }),
      ),
    );
  }
}

class _PendingClassRow extends StatelessWidget {
  const _PendingClassRow({
    required this.item,
    required this.isLast,
    required this.sans,
  });

  final _PendingClassItem item;
  final bool isLast;
  final TextStyle Function({
    double size,
    FontWeight weight,
    Color color,
    double height,
    double letterSpacing,
  }) sans;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: Color(0x0D111827)),
              ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.menu_book_outlined,
              size: 18,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: sans(
                    size: 13,
                    weight: FontWeight.w600,
                    color: const Color(0xFF111827),
                    height: 1.25,
                  ),
                ),
                if (item.meta.isNotEmpty)
                  Text(
                    item.meta,
                    style: sans(
                      size: 10.5,
                      color: const Color(0xFF8A8F98),
                      height: 1.35,
                    ),
                  ),
              ],
            ),
          ),
          _SmallStatusBadge(
            label: item.status == 'completed' ? 'Completed' : 'In progress',
            background: item.status == 'completed'
                ? const Color(0xFFE3F5E9)
                : const Color(0xFFF3F4F6),
            foreground: item.status == 'completed'
                ? const Color(0xFF1A6B35)
                : const Color(0xFF374151),
          ),
        ],
      ),
    );
  }
}

class _ProfileDetailRow extends StatefulWidget {
  const _ProfileDetailRow({
    required this.data,
    required this.isLast,
    required this.sans,
    required this.onSaveField,
    required this.onProfileUpdated,
  });

  final _DetailRowData data;
  final bool isLast;
  final Future<void> Function(_EditableProfileField field, String value)
      onSaveField;
  final Future<void> Function() onProfileUpdated;
  final TextStyle Function({
    double size,
    FontWeight weight,
    Color color,
    double height,
    double letterSpacing,
  }) sans;

  @override
  State<_ProfileDetailRow> createState() => _ProfileDetailRowState();
}

class _ProfileDetailRowState extends State<_ProfileDetailRow> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(covariant _ProfileDetailRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isEditing && oldWidget.data.value != widget.data.value) {
      _controller.text = widget.data.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final field = widget.data.editableField;
    if (field == null || _isSaving) {
      return;
    }
    setState(() {
      _isSaving = true;
    });
    try {
      await widget.onSaveField(field, _controller.text);
      await widget.onProfileUpdated();
      if (!mounted) {
        return;
      }
      setState(() {
        _isEditing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${widget.data.label} updated')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not update ${widget.data.label.toLowerCase()}.',
          ),
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

  void _beginEdit() {
    if (widget.data.editableField == null) {
      return;
    }
    setState(() {
      _isEditing = true;
      _controller.text =
          widget.data.value == _kUnavailableValue ? '' : widget.data.value;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
        _controller.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _controller.text.length,
        );
      }
    });
  }

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
      _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final showEditor = _isEditing && data.editableField != null;
    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        border: widget.isLast
            ? null
            : const Border(
                bottom: BorderSide(color: Color(0x0D111827)),
              ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: SizedBox(
              width: 20,
              child: Icon(
                data.icon,
                size: 18,
                color: const Color(0xFF111827),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: showEditor
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.label,
                        style: widget.sans(
                          size: 11,
                          color: const Color(0xFF8A8F98),
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        keyboardType: data.maxLines > 1
                            ? TextInputType.multiline
                            : data.keyboardType,
                        textInputAction: data.maxLines > 1
                            ? TextInputAction.newline
                            : TextInputAction.done,
                        maxLines: data.maxLines,
                        minLines: 1,
                        onSubmitted: data.maxLines == 1 ? (_) => _save() : null,
                        style: widget.sans(
                          size: 13,
                          weight: FontWeight.w600,
                          color: const Color(0xFF111827),
                          height: 1.35,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: 'Enter ${data.label.toLowerCase()}',
                          hintStyle: widget.sans(
                            size: 12,
                            color: const Color(0xFFB0B6BE),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide:
                                const BorderSide(color: Color(0x1A111827)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide:
                                const BorderSide(color: Color(0xFF1A8F3E)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          TextButton(
                            onPressed: _isSaving ? null : _cancelEdit,
                            child: Text(
                              'Cancel',
                              style: widget.sans(
                                size: 12,
                                weight: FontWeight.w600,
                                color: const Color(0xFF6B7280),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          TextButton(
                            onPressed: _isSaving ? null : _save,
                            child: Text(
                              _isSaving ? 'Saving...' : 'Save',
                              style: widget.sans(
                                size: 12,
                                weight: FontWeight.w700,
                                color: const Color(0xFF1A8F3E),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.label,
                        style: widget.sans(
                          size: 11,
                          color: const Color(0xFF8A8F98),
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        data.value.isEmpty ? _kUnavailableValue : data.value,
                        maxLines: data.maxLines,
                        overflow: TextOverflow.ellipsis,
                        style: widget.sans(
                          size: 13,
                          weight: FontWeight.w600,
                          color: const Color(0xFF111827),
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
          ),
          if (!_isEditing && (data.badge?.isNotEmpty ?? false))
            _SmallStatusBadge(
              label: data.badge!,
              background: const Color(0xFFF3F4F6),
              foreground: const Color(0xFF374151),
            ),
          if (!_isEditing && data.editableField != null) ...[
            const SizedBox(width: 8),
            InkWell(
              onTap: _beginEdit,
              borderRadius: BorderRadius.circular(999),
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0x1A111827)),
                ),
                child: const Icon(
                  Icons.edit_outlined,
                  size: 13,
                  color: Color(0xFF111827),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailRowData {
  const _DetailRowData({
    required this.icon,
    required this.label,
    required this.value,
    this.badge,
    this.editableField,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? badge;
  final _EditableProfileField? editableField;
  final TextInputType keyboardType;
  final int maxLines;
}

const _kUnavailableValue = 'Unavailable';

enum _EditableProfileField {
  fullName,
  phoneNumber,
  gender,
  maritalStatus,
  occupation,
  residentialAddress,
  emergencyContact,
  bio,
}

class _ProfilePersonalDetailsService {
  _ProfilePersonalDetailsService({
    ProfileIdentityResolver? identityResolver,
    SecureProfileRepository? repository,
  })  : _identityResolver = identityResolver ?? ProfileIdentityResolver(),
        _repository = repository ?? SecureProfileRepository();

  final ProfileIdentityResolver _identityResolver;
  final SecureProfileRepository _repository;

  Future<void> updateField(
    _EditableProfileField field,
    String value,
  ) async {
    final identity = await _identityResolver.resolveCurrentUser();
    final profileRows = await ProfilesTable().queryRows(
      queryFn: (q) => q.eq('id', identity.profileUserId),
      limit: 1,
    );
    if (profileRows.isEmpty) {
      throw StateError('Own profile row was not found.');
    }

    final profile = profileRows.first;
    final normalizedValue = _normalizeValue(value);
    final nameParts = field == _EditableProfileField.fullName
        ? _splitName(normalizedValue)
        : null;

    final privPayload = <String, dynamic>{
      'id': identity.profileUserId,
      'branch_id': profile.branchId,
      'department_id': profile.departmentId,
      'email': profile.email,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
      if (field == _EditableProfileField.fullName) ...{
        'full_name': normalizedValue,
        'firstname': nameParts?.firstName,
        'lastname': nameParts?.lastName,
      },
      if (field == _EditableProfileField.phoneNumber) ...{
        'phone': normalizedValue,
        'phone_number': normalizedValue,
      },
      if (field == _EditableProfileField.gender) 'gender': normalizedValue,
      if (field == _EditableProfileField.maritalStatus)
        'marital_status': normalizedValue,
      if (field == _EditableProfileField.occupation)
        'occupation': normalizedValue,
      if (field == _EditableProfileField.residentialAddress) ...{
        'address': normalizedValue,
        'residential_address': normalizedValue,
      },
      if (field == _EditableProfileField.emergencyContact)
        'emergency_contact': normalizedValue,
      if (field == _EditableProfileField.bio) 'bio': normalizedValue,
    };

    await _repository.saveCanonicalPrivateProfile(
      privateProfileData: privPayload,
    );
  }

  String? _normalizeValue(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  _NameParts _splitName(String? fullName) {
    final trimmed = fullName?.trim() ?? '';
    if (trimmed.isEmpty) {
      return const _NameParts(firstName: null, lastName: null);
    }

    final parts =
        trimmed.split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) {
      return const _NameParts(firstName: null, lastName: null);
    }

    final firstName = parts.first;
    final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : null;
    return _NameParts(firstName: firstName, lastName: lastName);
  }
}

class _NameParts {
  const _NameParts({
    required this.firstName,
    required this.lastName,
  });

  final String? firstName;
  final String? lastName;
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.title,
    required this.textStyle,
  });

  final String title;
  final TextStyle Function({
    double size,
    FontWeight weight,
    Color color,
    double height,
    double letterSpacing,
  }) textStyle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Text(
        title.toUpperCase(),
        style: textStyle(
          size: 11,
          weight: FontWeight.w600,
          color: const Color(0xFF8A8F98),
          letterSpacing: 1.0,
          height: 1.2,
        ),
      ),
    );
  }
}

class _ProfileIconButton extends StatelessWidget {
  const _ProfileIconButton({
    required this.icon,
    required this.semanticLabel,
    required this.onTap,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFFFCFBF9),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0x14111827)),
          ),
          child: Icon(
            icon,
            size: 20,
            color: const Color(0xFF111827),
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFBF9),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0x14111827)),
      ),
      child: Text(
        label,
        style: GoogleFonts.instrumentSans(
          fontSize: 11,
          fontWeight: FontWeight.w400,
          color: const Color(0xFF374151),
          height: 1,
        ),
      ),
    );
  }
}

class _SmallStatusBadge extends StatelessWidget {
  const _SmallStatusBadge({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.instrumentSans(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: foreground,
          height: 1,
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({
    required this.message,
    required this.sans,
  });

  final String message;
  final TextStyle Function({
    double size,
    FontWeight weight,
    Color color,
    double height,
    double letterSpacing,
  }) sans;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFBF9),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0x14111827)),
      ),
      child: Text(
        message,
        style: sans(
          size: 12,
          color: const Color(0xFF8A8F98),
          height: 1.4,
        ),
      ),
    );
  }
}

class _ProfileLoadingView extends StatelessWidget {
  const _ProfileLoadingView();

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.only(bottom: 104),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 14),
          _ProfileSkeletonLine(
              width: 108,
              height: 30,
              margin: EdgeInsets.fromLTRB(20, 0, 20, 0)),
          _ProfileSkeletonLine(
              width: 180,
              height: 30,
              margin: EdgeInsets.fromLTRB(20, 12, 20, 0)),
          SizedBox(height: 22),
          Center(
            child: WpccShimmerCircle(size: 78),
          ),
          _ProfileSkeletonLine(
              width: 140,
              height: 26,
              margin: EdgeInsets.fromLTRB(0, 20, 0, 0),
              centered: true),
          _ProfileSkeletonLine(
              width: 112,
              height: 14,
              margin: EdgeInsets.fromLTRB(0, 8, 0, 0),
              centered: true),
          SizedBox(height: 16),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 14),
            child: WpccShimmerCard(
              height: 58,
              radius: 30,
              child: SizedBox.expand(),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(14, 16, 14, 0),
            child: WpccShimmerCard(
              height: 112,
              radius: 30,
              child: SizedBox.expand(),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(14, 20, 14, 0),
            child: WpccShimmerCard(
              height: 220,
              radius: 30,
              child: SizedBox.expand(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileSkeletonLine extends StatelessWidget {
  const _ProfileSkeletonLine({
    required this.width,
    required this.height,
    required this.margin,
    this.centered = false,
  });

  final double width;
  final double height;
  final EdgeInsets margin;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final child = Padding(
      padding: margin,
      child: WpccShimmerBlock(
        width: width,
        height: height,
        radius: 14,
      ),
    );
    return centered ? Center(child: child) : child;
  }
}

class _ProfileErrorView extends StatelessWidget {
  const _ProfileErrorView({
    required this.onRetry,
  });

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Unable to load profile right now.',
              textAlign: TextAlign.center,
              style: GoogleFonts.instrumentSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: onRetry,
              child: Text(
                'Retry',
                style: GoogleFonts.instrumentSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFC5099C),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarOptionsSheet extends StatelessWidget {
  const _AvatarOptionsSheet({
    required this.data,
    required this.onReplace,
    this.onViewPhoto,
  });

  final _ProfileScreenData data;
  final VoidCallback onReplace;
  final VoidCallback? onViewPhoto;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
        decoration: BoxDecoration(
          color: const Color(0xFFFCFBF9),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: const Color(0x1A111827)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0x24111827),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Center(
              child: Container(
                width: 96,
                height: 96,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE9D6A6), width: 2),
                  color: Colors.white,
                ),
                child: ClipOval(
                  child: data.avatarUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: data.avatarUrl,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) =>
                              _SheetAvatarFallback(initials: data.initials),
                        )
                      : _SheetAvatarFallback(initials: data.initials),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              data.fullName,
              textAlign: TextAlign.center,
              style: profileSans(size: 15, weight: FontWeight.w600),
            ),
            const SizedBox(height: 2),
            Text(
              'Profile photo',
              textAlign: TextAlign.center,
              style: profileSans(size: 12, color: const Color(0xFF8A8F98)),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: onReplace,
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: const Color(0xFF111113),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.camera_alt_outlined, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Replace photo',
                      style: profileSans(
                        size: 14,
                        weight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (onViewPhoto != null) ...[
              const SizedBox(height: 10),
              SizedBox(
                height: 50,
                child: OutlinedButton(
                  onPressed: onViewPhoto,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF111827),
                    side: const BorderSide(color: Color(0x1A111827)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: Text(
                    'View photo',
                    style: profileSans(size: 14, weight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SheetAvatarFallback extends StatelessWidget {
  const _SheetAvatarFallback({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFB88A5A), Color(0xFFE9CFA8), Color(0xFF7A4F32)],
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: profileSans(
            size: 30,
            weight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _AvatarPreviewPage extends StatelessWidget {
  const _AvatarPreviewPage({
    required this.imageUrl,
    required this.initials,
  });

  final String imageUrl;
  final String initials;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        onTap: () => Navigator.of(context).maybePop(),
        child: Stack(
          children: [
            const Positioned.fill(
              child: ColoredBox(color: Color(0xEB000000)),
            ),
            Center(
              child: imageUrl.isNotEmpty
                  ? InteractiveViewer(
                      minScale: 0.8,
                      maxScale: 4,
                      child: CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.contain,
                      ),
                    )
                  : Text(
                      initials,
                      style: profileSans(
                        size: 72,
                        weight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              right: 12,
              child: IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.close_rounded, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
