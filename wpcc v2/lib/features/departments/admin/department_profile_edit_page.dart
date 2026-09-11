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
  State<DepartmentProfileEditPage> createState() => _DepartmentProfileEditPageState();
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
    final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
    return result?.files.single;
  }

  Future<void> _save() async {
    if (department?['can_manage'] != true) return;
    if (name.text.trim().length < 2 || description.text.length > 500) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Check department name and description.')));
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
      if (mounted) context.pop(true);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to update the department profile. Please try again.')));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(onPressed: () => context.pop(), icon: Icon(PhosphorIcons.caretLeft(), size: 20)),
        title: const Text('Change profile', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : loadError != null
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Text(loadError!), const SizedBox(height: 8), TextButton(onPressed: () { setState(() { loading = true; loadError = null; }); _load(); }, child: const Text('Retry'))]))
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
                children: [
                  Center(
                    child: InkWell(
                      onTap: () async {
                        try {
                          final file = await _pickImage();
                          if (!mounted) return;
                          if (file != null) setState(() => avatarFile = file);
                        } catch (_) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to select that image. Please try again.')));
                        }
                      },
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          InitialsAvatar(initials: _initials(name.text), imageUrl: avatarUrl, size: 84),
                          Positioned(
                            right: -3,
                            bottom: -3,
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: const BoxDecoration(color: WpccColors.ink, shape: BoxShape.circle),
                              child: Icon(PhosphorIcons.pencilSimple(), size: 14, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(controller: name, onChanged: (_) => setState(() {}), decoration: const InputDecoration(labelText: 'Department name')),
                  const SizedBox(height: 10),
                  InputDecorator(
                    decoration: const InputDecoration(labelText: 'Team size'),
                    child: Text('${department?['member_count'] ?? 0} members', style: const TextStyle(fontSize: 13)),
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
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to select that image. Please try again.')));
                      }
                    },
                    child: Container(
                      height: 150,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F1F5),
                        borderRadius: BorderRadius.circular(22),
                        image: coverUrl != null && coverUrl!.isNotEmpty ? DecorationImage(image: NetworkImage(coverUrl!), fit: BoxFit.cover) : null,
                      ),
                      child: coverUrl == null || coverUrl!.isEmpty
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(PhosphorIcons.image(), size: 24),
                                const SizedBox(height: 7),
                                const Text('Choose cover image', style: TextStyle(fontSize: 11)),
                              ],
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(controller: description, maxLines: 5, maxLength: 500, decoration: const InputDecoration(labelText: 'About department')),
                  const SizedBox(height: 14),
                  FilledButton(
                    onPressed: busy ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: WpccColors.ink,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                    child: busy ? const CircularProgressIndicator(strokeWidth: 2, color: Colors.white) : const Text('Update profile'),
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
