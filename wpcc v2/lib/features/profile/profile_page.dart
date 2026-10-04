import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_motion.dart';
import '../../core/widgets/member_skeleton.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/widgets/initials_avatar.dart';
import '../../core/widgets/member_components.dart';
import '../../core/widgets/member_sheet.dart';
import '../../core/widgets/member_glass.dart';
import 'profile_repository.dart';
import '../auth/auth_repository.dart';
import '../rewards/rewards_card.dart';

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

  void reload() => setState(() {
        future = repo.profile();
      });
  @override
  Widget build(BuildContext context) => SafeArea(
        bottom: false,
        child: FutureBuilder<Map<String, dynamic>?>(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const SingleChildScrollView(
                  padding: EdgeInsets.all(24), child: MemberSkeleton(rows: 6));
            }
            if (snapshot.hasError || snapshot.data == null) {
              return Center(
                  child: MemberStatus(
                      message: 'Unable to load profile',
                      icon: PhosphorIcons.warningCircle(),
                      onRetry: reload));
            }
            final profile = snapshot.data!;
            return LayoutBuilder(
                builder: (context, box) => Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: 680),
                        child: ListView(
                          padding: memberPagePadding(context, bottom: 124),
                          children: [
                            MemberPageHeader(
                                title: 'My account',
                                onBack: () {
                                  if (context.canPop()) {
                                    context.pop();
                                  } else {
                                    context.go('/home');
                                  }
                                },
                                actions: [
                                  MemberIconButton(
                                      icon: PhosphorIcons.slidersHorizontal(),
                                      label: 'Appearance',
                                      plain: true,
                                      onPressed: _showAppearance),
                                ]),
                            Padding(
                                padding:
                                    const EdgeInsets.only(top: 4, bottom: 24),
                                child: _identity(
                                    profile,
                                    _initials(
                                        profile['full_name']?.toString() ??
                                            'WPCC Member'))),
                            const RewardsCard(compact: true),
                            const SizedBox(height: 24),
                            _AccountGroup(title: 'Account', children: [
                              _ProfileAction(
                                  title: 'Personal details',
                                  icon: PhosphorIcons.user(),
                                  onTap: () => _showPersonalDetails(profile)),
                              _ProfileAction(
                                  title: 'Appearance',
                                  icon: PhosphorIcons.sun(),
                                  onTap: _showAppearance,
                                  divider: true),
                              _ProfileAction(
                                  title: 'Set or change password',
                                  icon: PhosphorIcons.lockKey(),
                                  onTap: _setPassword,
                                  divider: true),
                            ]),
                            const SizedBox(height: 24),
                            _AccountGroup(title: 'Church life', children: [
                              _ProfileAction(
                                  title: 'My departments',
                                  icon: PhosphorIcons.users(),
                                  onTap: () => context.push('/departments')),
                              _ProfileAction(
                                  title: 'Prayer alerts',
                                  icon: PhosphorIcons.bell(),
                                  onTap: () => context.push('/prayer-alerts'),
                                  divider: true),
                              _ProfileAction(
                                  title: 'Giving history',
                                  icon: PhosphorIcons.clockCounterClockwise(),
                                  onTap: () => context.push('/give/history'),
                                  divider: true),
                              _ProfileAction(
                                  title: 'Classes',
                                  subtitle: 'Unavailable',
                                  icon: PhosphorIcons.graduationCap(),
                                  divider: true),
                            ]),
                            const SizedBox(height: 20),
                            _ProfileAction(
                                title: 'Search',
                                icon: PhosphorIcons.magnifyingGlass(),
                                onTap: () => context.push('/search'),
                                divider: false),
                            _ProfileAction(
                                title: 'Log out',
                                icon: PhosphorIcons.signOut(),
                                divider: true,
                                destructive: true,
                                onTap: () async {
                                  await AuthRepository().signOut();
                                  if (context.mounted) context.go('/login');
                                }),
                          ],
                        ),
                      ),
                    ));
          },
        ),
      );

  Widget _identity(Map<String, dynamic> profile, String initials) {
    final role = [profile['leadership_title'], profile['department_name']]
        .where((value) => value != null && value.toString().trim().isNotEmpty)
        .join(' · ');
    return Column(children: [
      Tooltip(
          message: 'Change profile photo',
          child: Semantics(
            button: true,
            label: 'Change profile photo',
            child: Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: uploadingAvatar ? null : _changeAvatar,
                child: SizedBox.square(
                    dimension: 88,
                    child: uploadingAvatar
                        ? const Center(child: CircularProgressIndicator())
                        : InitialsAvatar(
                            memberStyle: true,
                            key: ValueKey(avatarOverride ?? profile['avatar']),
                            initials: initials,
                            imageUrl:
                                avatarOverride ?? profile['avatar']?.toString(),
                            size: 88)),
              ),
            ),
          )),
      const SizedBox(height: 16),
      Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Text(profile['full_name']?.toString() ?? 'WPCC Member',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontSize: 24, height: 1.3, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        if (role.isNotEmpty)
          Text(role,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(fontSize: 13, height: 21 / 13)),
        if ((profile['membership_code']?.toString() ?? '').isNotEmpty)
          Text('Member ID: ${profile['membership_code']}',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(fontSize: 13, height: 21 / 13)),
      ]),
    ]);
  }

  Future<void> _showPersonalDetails(Map<String, dynamic> profile) =>
      showMemberSheet<void>(
        context: context,
        title: 'Personal details',
        builder: (sheetContext) =>
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _detailsHeading('Church'),
          _row(PhosphorIcons.identificationCard(), 'Membership code',
              profile['membership_code']),
          _row(PhosphorIcons.mapPin(), 'Branch', profile['branch_name']),
          _row(PhosphorIcons.usersThree(), 'Department',
              profile['department_name']),
          _detailsHeading('Contact'),
          _row(PhosphorIcons.envelopeSimple(), 'Email', profile['email']),
          _row(PhosphorIcons.phone(), 'Phone', profile['phone']),
          _row(PhosphorIcons.houseLine(), 'Address',
              profile['residential_address']),
          _detailsHeading('About you'),
          _row(PhosphorIcons.briefcase(), 'Occupation', profile['occupation']),
          _row(PhosphorIcons.calendarDots(), 'Date of birth',
              profile['date_of_birth']),
          _row(PhosphorIcons.user(), 'Gender', profile['gender']),
          _row(PhosphorIcons.heart(), 'Marital status',
              profile['marital_status']),
          const SizedBox(height: 16),
          FilledButton.icon(
              onPressed: () {
                Navigator.pop(sheetContext);
                _edit(profile);
              },
              icon: Icon(PhosphorIcons.pencilSimple(), size: 20),
              label: const Text('Edit profile'),
              style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48))),
        ]),
      );

  Widget _detailsHeading(String title) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 8),
        child: Text(title,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600)),
      );

  Future<void> _showAppearance() => showMemberAppearanceSheet(context);
  Widget _row(IconData icon, String label, dynamic value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon,
                size: 20,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    (value?.toString().trim().isNotEmpty ?? false)
                        ? value.toString()
                        : 'Not set',
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.4,
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
    final address = TextEditingController(
      text: p['residential_address']?.toString() ?? '',
    );
    final phone = TextEditingController(text: p['phone']?.toString() ?? '');
    final birthday =
        TextEditingController(text: p['date_of_birth']?.toString() ?? '');
    final occupations = (p['occupation']?.toString() ?? '')
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet();
    final occupationOptions = <String>{
      'Entrepreneur',
      'Engineer',
      'Doctor',
      'Fashion designer',
      'Teacher',
      'Student',
      'Civil servant',
      'Accountant',
      'Artist',
      'Retired',
      ...occupations
    };
    String? gender = p['gender']?.toString();
    String? maritalStatus = p['marital_status']?.toString();
    var saving = false;
    final saved = await showModalBottomSheet<bool>(
      sheetAnimationStyle: AppMotion.sheetStyle(context),
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
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
                    const Text('Occupations · select all that apply'),
                    Wrap(spacing: 8, children: [
                      for (final option in occupationOptions)
                        FilterChip(
                            label: Text(option),
                            selected: occupations.contains(option),
                            onSelected: saving
                                ? null
                                : (selected) => setSheetState(() {
                                      if (selected) {
                                        occupations.add(option);
                                      } else {
                                        occupations.remove(option);
                                      }
                                    })),
                    ]),
                    TextField(
                        controller: phone,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(labelText: 'Phone')),
                    const SizedBox(height: 10),
                    TextField(
                        controller: birthday,
                        readOnly: true,
                        decoration: const InputDecoration(
                            labelText: 'Date of birth',
                            suffixIcon:
                                Icon(PhosphorIconsRegular.calendarBlank)),
                        onTap: saving
                            ? null
                            : () async {
                                final now = DateTime.now();
                                final initial =
                                    DateTime.tryParse(birthday.text);
                                final selected = await showDatePicker(
                                    context: context,
                                    initialDate:
                                        initial != null && !initial.isAfter(now)
                                            ? initial
                                            : DateTime(now.year - 18),
                                    firstDate: DateTime(1900),
                                    lastDate: now);
                                if (selected != null) {
                                  birthday.text = selected
                                      .toIso8601String()
                                      .split('T')
                                      .first;
                                }
                              }),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                        isExpanded: true,
                        itemHeight: null,
                        initialValue:
                            gender?.isNotEmpty == true ? gender : null,
                        decoration: const InputDecoration(labelText: 'Gender'),
                        items: <String>{
                          'Male',
                          'Female',
                          'Prefer not to say',
                          if (gender?.isNotEmpty == true) gender!
                        }
                            .map((value) => DropdownMenuItem(
                                value: value, child: Text(value)))
                            .toList(),
                        onChanged: saving ? null : (value) => gender = value),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                        isExpanded: true,
                        itemHeight: null,
                        initialValue: maritalStatus?.isNotEmpty == true
                            ? maritalStatus
                            : null,
                        decoration:
                            const InputDecoration(labelText: 'Marital status'),
                        items: <String>{
                          'Single',
                          'Married',
                          'Widowed',
                          'Divorced',
                          'Prefer not to say',
                          if (maritalStatus?.isNotEmpty == true) maritalStatus!
                        }
                            .map((value) => DropdownMenuItem(
                                value: value, child: Text(value)))
                            .toList(),
                        onChanged:
                            saving ? null : (value) => maritalStatus = value),
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
                                  occupation: occupations.join(', '),
                                  address: address.text,
                                  phone: phone.text,
                                  gender: gender,
                                  maritalStatus: maritalStatus,
                                  dateOfBirth: birthday.text,
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
                        backgroundColor:
                            Theme.of(context).colorScheme.onSurface,
                        foregroundColor: Theme.of(context).colorScheme.surface,
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: saving
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Theme.of(context).colorScheme.surface,
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
    address.dispose();
    phone.dispose();
    birthday.dispose();
    if (saved == true && mounted) reload();
  }

  Future<void> _setPassword() async {
    final password = TextEditingController();
    final confirmation = TextEditingController();
    bool saving = false;
    String? error;
    await showMotionDialog<void>(
        animationStyle: AppMotion.dialogStyle(context),
        context: context,
        builder: (dialogContext) => StatefulBuilder(
            builder: (context, setDialogState) => AlertDialog(
                    title: const Text('Set password'),
                    content: SingleChildScrollView(
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                      TextField(
                          controller: password,
                          obscureText: true,
                          decoration:
                              const InputDecoration(labelText: 'New password')),
                      const SizedBox(height: 12),
                      TextField(
                          controller: confirmation,
                          obscureText: true,
                          decoration: const InputDecoration(
                              labelText: 'Confirm password')),
                      if (error != null) Text(error!),
                    ])),
                    actions: [
                      TextButton(
                          onPressed: saving
                              ? null
                              : () => Navigator.pop(dialogContext),
                          child: const Text('Cancel')),
                      FilledButton(
                          onPressed: saving
                              ? null
                              : () async {
                                  if (password.text.length < 12 ||
                                      password.text != confirmation.text) {
                                    setDialogState(() => error =
                                        'Use at least 12 characters and matching passwords.');
                                    return;
                                  }
                                  setDialogState(() {
                                    saving = true;
                                    error = null;
                                  });
                                  try {
                                    await AuthRepository()
                                        .setPassword(password.text);
                                    if (dialogContext.mounted) {
                                      Navigator.pop(dialogContext);
                                    }
                                    if (mounted) {
                                      ScaffoldMessenger.of(this.context)
                                          .showSnackBar(const SnackBar(
                                              content:
                                                  Text('Password updated')));
                                    }
                                  } catch (_) {
                                    if (dialogContext.mounted) {
                                      setDialogState(() {
                                        saving = false;
                                        error =
                                            'Unable to update password. Sign in again using an email code and retry.';
                                      });
                                    }
                                  }
                                },
                          child: Text(saving ? 'Saving…' : 'Save')),
                    ])));
    password.dispose();
    confirmation.dispose();
  }

  Future<void> _changeAvatar() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp'],
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

class _ProfileAction extends StatelessWidget {
  const _ProfileAction(
      {required this.title,
      required this.icon,
      this.subtitle,
      this.onTap,
      this.divider = false,
      this.destructive = false});
  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback? onTap;
  final bool divider;
  final bool destructive;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
            border: divider
                ? Border(
                    top: BorderSide(
                        color: Theme.of(context).colorScheme.outlineVariant))
                : null),
        child: Semantics(
            button: true,
            enabled: onTap != null,
            child: Opacity(
                opacity: onTap == null ? .45 : 1,
                child: MemberListRow(
                    plain: true,
                    title: title,
                    subtitle: subtitle,
                    leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerLow,
                            borderRadius: BorderRadius.circular(10)),
                        child: Icon(icon,
                            size: 20,
                            color: destructive
                                ? Theme.of(context).colorScheme.error
                                : null)),
                    onTap: onTap))),
      );
}

class _AccountGroup extends StatelessWidget {
  const _AccountGroup({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 10),
              child:
                  Text(title, style: Theme.of(context).textTheme.titleMedium)),
          MemberGlass(
              radius: 20,
              child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Column(children: children))),
        ],
      );
}
