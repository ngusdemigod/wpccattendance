import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../department_repository.dart';

class DepartmentAnnouncementPage extends StatefulWidget {
  const DepartmentAnnouncementPage({super.key, required this.departmentId});
  final String departmentId;

  @override
  State<DepartmentAnnouncementPage> createState() => _DepartmentAnnouncementPageState();
}

class _DepartmentAnnouncementPageState extends State<DepartmentAnnouncementPage> {
  final repo = DepartmentRepository();
  final title = TextEditingController();
  final body = TextEditingController();
  PlatformFile? image;
  Map<String, dynamic>? department;
  bool busy = false;

  @override
  void initState() {
    super.initState();
    repo.context(widget.departmentId).then((value) {
      if (mounted) setState(() => department = value);
    });
  }

  @override
  void dispose() {
    title.dispose();
    body.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (title.text.trim().length < 3 || body.text.trim().length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add a title and message.')));
      return;
    }
    setState(() => busy = true);
    try {
      String? mediaUrl;
      if (image != null) {
        final branch = department?['branch_id']?.toString();
        if (branch == null) throw StateError('Department branch unavailable');
        mediaUrl = await repo.uploadPublicAsset(
          branchId: branch,
          departmentId: widget.departmentId,
          file: image!,
          folder: 'announcements',
        );
      }
      await repo.postAnnouncement(
        departmentId: widget.departmentId,
        title: title.text.trim(),
        content: body.text.trim(),
        mediaUrl: mediaUrl,
      );
      if (mounted) context.pop(true);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to post the announcement. Check your connection and try again.')));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(onPressed: () => context.pop(), icon: Icon(PhosphorIcons.caretLeft(), size: 20)),
        title: const Text('Post announcement', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
          children: [
            const Text('Audience', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            const Align(
              alignment: Alignment.centerLeft,
              child: Chip(
                label: Text('This department'),
                labelStyle: TextStyle(fontSize: 11, color: Colors.white),
                backgroundColor: WpccColors.ink,
                side: BorderSide.none,
              ),
            ),
            const SizedBox(height: 14),
            TextField(controller: title, decoration: const InputDecoration(labelText: 'Title')),
            const SizedBox(height: 10),
            TextField(controller: body, maxLines: 7, decoration: const InputDecoration(labelText: 'Message')),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () async {
                try {
                  final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
                  if (!mounted) return;
                  if (result != null) setState(() => image = result.files.single);
                } catch (_) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to select that image. Please try again.')));
                }
              },
              icon: Icon(PhosphorIcons.image(), size: 18),
              label: Text(image?.name ?? 'Add image'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                foregroundColor: WpccColors.ink,
                side: const BorderSide(color: WpccColors.line),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: busy ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: WpccColors.ink,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              child: busy ? const CircularProgressIndicator(strokeWidth: 2, color: Colors.white) : const Text('Post announcement'),
            ),
          ],
        ),
      ),
    );
  }
}
