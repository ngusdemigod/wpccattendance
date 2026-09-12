import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/initials_avatar.dart';
import 'profile_repository.dart';
import 'classes_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final repo = ProfileRepository();
  late Future<Map<String, dynamic>?> future;
  bool uploadingAvatar = false;
  String? avatarOverride;
  @override
  void initState() {
    super.initState();
    future = repo.profile();
  }

  void reload() => setState(() => future = repo.profile());
  @override
  Widget build(BuildContext context) => SafeArea(
        bottom: false,
        child: FutureBuilder<Map<String, dynamic>?>(
          future: future,
          builder: (context, s) {
            if (s.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (s.hasError || s.data == null) {
              return const Center(child: Text('Unable to load profile'));
            }
            final p = s.data!;
            final initials =
                _initials(p['full_name']?.toString() ?? 'WPCC Member');
            return ListView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 110),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Profile',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -.7,
                                ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => context.push('/search'),
                      tooltip: 'Search',
                      icon: Icon(PhosphorIcons.magnifyingGlass(), size: 21),
                    ),
                    IconButton(
                      onPressed: () => _edit(p),
                      tooltip: 'Edit profile',
                      icon: Icon(PhosphorIcons.pencilSimple(), size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                const ProfileTabs(index: 0),
                const SizedBox(height: 30),
                Center(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      InitialsAvatar(
                        key: ValueKey(avatarOverride ?? p['avatar']),
                        initials: initials,
                        imageUrl: avatarOverride ?? p['avatar']?.toString(),
                        size: 104,
                      ),
                      Positioned(
                        right: -4,
                        bottom: -4,
                        child: Material(
                          color: WpccColors.navActive,
                          shape: const CircleBorder(),
                          child: IconButton(
                            tooltip: 'Change profile photo',
                            onPressed: uploadingAvatar ? null : _changeAvatar,
                            color: Colors.white,
                            iconSize: 18,
                            icon: uploadingAvatar
                                ? const SizedBox(
                                    width: 17,
                                    height: 17,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Icon(PhosphorIcons.camera()),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: WpccColors.successBackground,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Active',
                      style: TextStyle(
                        fontSize: 10,
                        color: WpccColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    p['full_name']?.toString() ?? 'WPCC Member',
                    style: Theme.of(
                      context,
                    )
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 5),
                Center(
                  child: Text(
                    [p['leadership_title'], p['department_name']]
                        .where((x) => x != null && x.toString().isNotEmpty)
                        .join(' · '),
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: WpccColors.muted),
                  ),
                ),
                if ((p['membership_code']?.toString() ?? '').isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Member ID: ${p['membership_code']}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 26),
                Text(
                  'PERSONAL DETAILS',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontSize: 11,
                        color: WpccColors.muted,
                        letterSpacing: 1.1,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 9),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: WpccColors.line),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      _row(
                        PhosphorIcons.identificationCard(),
                        'Membership code',
                        p['membership_code'],
                      ),
                      _row(PhosphorIcons.envelopeSimple(), 'Email', p['email']),
                      _row(PhosphorIcons.phone(), 'Phone', p['phone']),
                      _row(PhosphorIcons.mapPin(), 'Branch', p['branch_name']),
                      _row(
                        PhosphorIcons.usersThree(),
                        'Department',
                        p['department_name'],
                      ),
                      _row(
                        PhosphorIcons.briefcase(),
                        'Occupation',
                        p['occupation'],
                      ),
                      _row(
                        PhosphorIcons.houseLine(),
                        'Address',
                        p['residential_address'],
                      ),
                      _row(PhosphorIcons.user(), 'Gender', p['gender']),
                      _row(
                        PhosphorIcons.heart(),
                        'Marital status',
                        p['marital_status'],
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );
  Widget _row(IconData icon, String label, dynamic value) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: WpccColors.inkSoft),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(color: WpccColors.muted),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    (value?.toString().trim().isNotEmpty ?? false)
                        ? value.toString()
                        : '—',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
  Future<void> _edit(Map<String, dynamic> p) async {
    final bio = TextEditingController(text: p['bio']?.toString() ?? '');
    final occupation = TextEditingController(
      text: p['occupation']?.toString() ?? '',
    );
    final address = TextEditingController(
      text: p['residential_address']?.toString() ?? '',
    );
    var saving = false;
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          return SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                18,
                18,
                18,
                18 + MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Edit profile',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: bio,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Bio'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: occupation,
                      decoration: const InputDecoration(
                        labelText: 'Occupation',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: address,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Residential address',
                      ),
                    ),
                    const SizedBox(height: 14),
                    FilledButton(
                      onPressed: saving
                          ? null
                          : () async {
                              setSheetState(() => saving = true);
                              try {
                                await repo.updateAllowedDetails(
                                  bio: bio.text,
                                  occupation: occupation.text,
                                  address: address.text,
                                );
                                if (sheetContext.mounted) {
                                  Navigator.pop(sheetContext, true);
                                }
                              } catch (_) {
                                if (sheetContext.mounted) {
                                  setSheetState(() => saving = false);
                                  ScaffoldMessenger.of(
                                    sheetContext,
                                  ).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Unable to update profile. Your changes are still here.',
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                      style: FilledButton.styleFrom(
                        backgroundColor: WpccColors.ink,
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Save changes'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
    bio.dispose();
    occupation.dispose();
    address.dispose();
    if (saved == true && mounted) reload();
  }

  Future<void> _changeAvatar() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
      allowMultiple: false,
    );
    final file = result?.files.singleOrNull;
    if (file == null || !mounted) return;
    setState(() => uploadingAvatar = true);
    try {
      final avatarUrl = await repo.uploadAvatar(file);
      if (mounted) {
        setState(() => avatarOverride = avatarUrl);
        reload();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile photo updated')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error.toString().replaceFirst('Bad state: ', ''),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => uploadingAvatar = false);
    }
  }

  String _initials(String name) => name
      .trim()
      .split(RegExp(r'\s+'))
      .where((e) => e.isNotEmpty)
      .take(2)
      .map((e) => e[0].toUpperCase())
      .join();
}
