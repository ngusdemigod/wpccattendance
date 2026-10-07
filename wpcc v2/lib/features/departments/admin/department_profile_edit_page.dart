import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/widgets/member_components.dart';
import '../../../core/widgets/member_skeleton.dart';
import '../department_repository.dart';
import '../../../core/widgets/member_back.dart';

class DepartmentProfileEditPage extends StatefulWidget {
  const DepartmentProfileEditPage(
      {super.key, required this.departmentId, this.repository});
  final String departmentId;
  final DepartmentRepository? repository;
  @override
  State<DepartmentProfileEditPage> createState() =>
      _DepartmentProfileEditPageState();
}

class _DepartmentProfileEditPageState extends State<DepartmentProfileEditPage> {
  late final repo = widget.repository ?? DepartmentRepository();
  late Future<Map<String, dynamic>?> department =
      repo.context(widget.departmentId);
  PlatformFile? cover, avatar;
  bool busy = false;

  Future<void> _pick(bool isCover) async {
    try {
      final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
          withData: true);
      if (!mounted || result == null) return;
      final file = result.files.single;
      if (file.bytes == null || file.size == 0 || file.size > 5 * 1024 * 1024) {
        throw StateError('Choose an image smaller than 5 MB.');
      }
      setState(() {
        if (isCover) {
          cover = file;
        } else {
          avatar = file;
        }
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Choose a JPG, PNG or WebP image under 5 MB.')));
      }
    }
  }

  Future<void> _save(Map<String, dynamic> data) async {
    if (busy || data['can_manage'] != true) return;
    final branch = data['branch_id']?.toString();
    if (branch == null) return;
    setState(() => busy = true);
    try {
      Future<String?> upload(PlatformFile? file) async => file == null
          ? null
          : repo.uploadPublicAsset(
              branchId: branch,
              departmentId: widget.departmentId,
              file: file,
              folder: 'departments');
      final coverUrl = await upload(cover);
      final avatarUrl = await upload(avatar);
      await repo.updateImages(widget.departmentId,
          coverUrl: coverUrl, avatarUrl: avatarUrl);
      if (mounted) context.pop(true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Unable to save images. Please try again.')));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: MemberAppBar(
            title: const Text('Department images'),
            onBack: () => context.canPop()
                ? context.pop()
                : context.go('/departments/${widget.departmentId}')),
        body: FutureBuilder<Map<String, dynamic>?>(
            future: department,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const SingleChildScrollView(
                    child: MemberSkeleton(hero: true));
              }
              if (snapshot.hasError) {
                return MemberStatus(
                    message: 'Unable to load department',
                    onRetry: () => setState(() {
                          department = repo.context(widget.departmentId);
                        }));
              }
              final data = snapshot.data;
              if (data == null || data['can_manage'] != true) {
                return const MemberStatus(
                    message:
                        'Department image editing is not available for your account');
              }
              return Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 680),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                      children: [
                        Text(data['name']?.toString() ?? 'Department',
                            style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 24),
                        _image('Cover image', cover,
                            data['cover_url']?.toString(), false),
                        const SizedBox(height: 24),
                        _image('Department image', avatar,
                            data['avatar_url']?.toString(), true),
                        const SizedBox(height: 32),
                        FilledButton(
                            onPressed: busy || (cover == null && avatar == null)
                                ? null
                                : () => _save(data),
                            child: Text(busy ? 'Saving...' : 'Save images')),
                      ],
                    ),
                  ));
            }),
      );

  Widget _image(String label, PlatformFile? file, String? url, bool circular) {
    final fallback = ColoredBox(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        child: const Center(child: Icon(PhosphorIconsRegular.image, size: 32)));
    final image = file?.bytes != null
        ? Image.memory(file!.bytes!,
            fit: BoxFit.cover, errorBuilder: (_, __, ___) => fallback)
        : url?.isNotEmpty == true
            ? Image.network(url!,
                fit: BoxFit.cover, errorBuilder: (_, __, ___) => fallback)
            : fallback;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: Theme.of(context).textTheme.titleSmall),
      const SizedBox(height: 12),
      if (circular)
        SizedBox(width: 96, height: 96, child: ClipOval(child: image))
      else
        AspectRatio(
            aspectRatio: 16 / 9,
            child: ClipRRect(
                borderRadius: BorderRadius.circular(12), child: image)),
      const SizedBox(height: 8),
      TextButton.icon(
          onPressed: busy ? null : () => _pick(!circular),
          icon: const Icon(PhosphorIconsRegular.uploadSimple, size: 20),
          label: Text('Change ${label.toLowerCase()}')),
    ]);
  }
}
