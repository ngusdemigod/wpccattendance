import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/initials_avatar.dart';
import '../department_repository.dart';

class DepartmentProfileEditPage extends StatefulWidget {
  const DepartmentProfileEditPage({super.key, required this.departmentId});
  final String departmentId;

  @override
  State<DepartmentProfileEditPage> createState() =>
      _DepartmentProfileEditPageState();
}

class _DepartmentProfileEditPageState extends State<DepartmentProfileEditPage> {
  final repo = DepartmentRepository();
  final name = TextEditingController();
  final description = TextEditingController();
  Map<String, dynamic>? department;
  String? coverUrl;
  String? avatarUrl;
  PlatformFile? coverFile;
  PlatformFile? avatarFile;
  bool busy = false;
  bool loading = true;
  String? loadError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      department = await repo.context(widget.departmentId);
      name.text = department?['name']?.toString() ?? '';
      description.text = department?['description']?.toString() ?? '';
      coverUrl = department?['cover_url']?.toString();
      avatarUrl = department?['avatar_url']?.toString();
      if (department == null) loadError = 'Department profile is unavailable.';
    } catch (_) {
      loadError = 'Unable to load the department profile.';
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    name.dispose();
    description.dispose();
    super.dispose();
  }

  Future<PlatformFile?> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    return result?.files.single;
  }

  Future<void> _save() async {
    if (department?['can_manage'] != true) return;
    if (name.text.trim().length < 2 || description.text.length > 500) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Check department name and description.')),
      );
      return;
    }
    setState(() => busy = true);
    try {
      final branch = department?['branch_id']?.toString();
      if (branch == null) throw StateError('Department branch is unavailable');
      if (coverFile != null) {
        coverUrl = await repo.uploadPublicAsset(
          branchId: branch,
          departmentId: widget.departmentId,
          file: coverFile!,
          folder: 'departments',
        );
      }
      if (avatarFile != null) {
        avatarUrl = await repo.uploadPublicAsset(
          branchId: branch,
          departmentId: widget.departmentId,
          file: avatarFile!,
          folder: 'departments',
        );
      }
      await repo.updateProfile(
        departmentId: widget.departmentId,
        name: name.text.trim(),
        description: description.text.trim(),
        coverUrl: coverUrl,
        avatarUrl: avatarUrl,
      );
      if (mounted) {
        context.pop(true);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to update the department profile. Please try again.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Icon(PhosphorIcons.caretLeft(), size: 20),
        ),
        title: const Text(
          'Change profile',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: busy ? null : _save,
            child: const Text(
              'Save',
              style: TextStyle(fontSize: 12, color: Color(0xFF7D46B4)),
            ),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : loadError != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(loadError!),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            loading = true;
                            loadError = null;
                          });
                          _load();
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SafeArea(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
                    children: [
                      Container(
                        height: 177,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(26),
                          color: const Color(0xFF4E4267),
                          image: coverUrl != null && coverUrl!.isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(coverUrl!),
                                  fit: BoxFit.cover,
                                  colorFilter: const ColorFilter.mode(
                                    Color(0x55000000),
                                    BlendMode.darken,
                                  ),
                                )
                              : null,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Text(
                                '${department?['member_count'] ?? 0} members',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              name.text.isEmpty ? 'Department' : name.text,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              description.text.isEmpty
                                  ? 'Department community and resources.'
                                  : description.text,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      InkWell(
                        onTap: () async {
                          try {
                            final file = await _pickImage();
                            if (!mounted) return;
                            if (file != null) setState(() => coverFile = file);
                          } catch (_) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Unable to select that image. Please try again.',
                                ),
                              ),
                            );
                          }
                        },
                        child: Container(
                          height: 48,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: WpccColors.line),
                          ),
                          child: const Text(
                            'Change cover image',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(26),
                          border: Border.all(color: WpccColors.line),
                        ),
                        child: Column(
                          children: [
                            _ProfileField(
                              controller: name,
                              label: 'Department name',
                              onChanged: (_) => setState(() {}),
                            ),
                            _ProfileField(
                              controller: description,
                              label: 'About department',
                              maxLines: 4,
                              onChanged: (_) => setState(() {}),
                            ),
                            InkWell(
                              onTap: () async {
                                final file = await _pickImage();
                                if (mounted && file != null) {
                                  setState(() => avatarFile = file);
                                }
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Avatar initials',
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelSmall
                                                ?.copyWith(
                                                  fontSize: 11,
                                                  color: WpccColors.muted,
                                                ),
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            _initials(name.text),
                                            style:
                                                const TextStyle(fontSize: 14),
                                          ),
                                        ],
                                      ),
                                    ),
                                    InitialsAvatar(
                                      initials: _initials(name.text),
                                      imageUrl: avatarUrl,
                                      size: 34,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      FilledButton(
                        onPressed: busy ? null : _save,
                        style: FilledButton.styleFrom(
                          backgroundColor: WpccColors.ink,
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: busy
                            ? const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              )
                            : const Text('Update profile'),
                      ),
                    ],
                  ),
                ),
    );
  }

  String _initials(String value) => value
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .take(2)
      .map((part) => part[0].toUpperCase())
      .join();
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({
    required this.controller,
    required this.label,
    this.maxLines = 1,
    this.onChanged,
  });
  final TextEditingController controller;
  final String label;
  final int maxLines;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: WpccColors.line)),
        ),
        child: TextField(
          controller: controller,
          maxLines: maxLines,
          maxLength: maxLines > 1 ? 500 : null,
          onChanged: onChanged,
          decoration: InputDecoration(
            labelText: label,
            counterText: '',
            filled: false,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          style: const TextStyle(fontSize: 14),
        ),
      );
}
