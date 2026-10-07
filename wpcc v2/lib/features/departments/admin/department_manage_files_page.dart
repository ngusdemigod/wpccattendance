import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_motion.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/section_empty_state.dart';
import '../department_repository.dart';
import '../../../core/widgets/member_back.dart';

class DepartmentManageFilesPage extends StatefulWidget {
  const DepartmentManageFilesPage({super.key, required this.departmentId});
  final String departmentId;

  @override
  State<DepartmentManageFilesPage> createState() =>
      _DepartmentManageFilesPageState();
}

class _DepartmentManageFilesPageState extends State<DepartmentManageFilesPage> {
  final repo = DepartmentRepository();
  late Future<List<Map<String, dynamic>>> files;
  late Future<Map<String, dynamic>?> department;
  bool uploading = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    files = repo.files(widget.departmentId);
    department = repo.context(widget.departmentId);
  }

  Future<void> _upload() async {
    final contextRow = await department;
    if (!mounted) return;
    final branch = contextRow?['branch_id']?.toString();
    if (branch == null) return;
    final result = await FilePicker.platform
        .pickFiles(withData: true, allowMultiple: false);
    if (result == null || !mounted) return;
    setState(() => uploading = true);
    try {
      await repo.uploadPrivateFile(
        departmentId: widget.departmentId,
        branchId: branch,
        file: result.files.single,
      );
      if (mounted) setState(_reload);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Unable to upload file. Please try again.')));
      }
    } finally {
      if (mounted) setState(() => uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MemberAppBar(
title: const Text('Manage files',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      ),
      body: SafeArea(
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: files,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return SectionEmptyState(
                  icon: PhosphorIcons.warningCircle(),
                  message: 'Unable to load files');
            }
            final rows = snapshot.data ?? const [];
            return ListView(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 30),
              children: [
                OutlinedButton.icon(
                  onPressed: uploading ? null : _upload,
                  icon: Icon(PhosphorIcons.uploadSimple(), size: 18),
                  label: Text(uploading ? 'Uploading…' : 'Upload files'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    foregroundColor: Theme.of(context).colorScheme.onSurface,
                    side: BorderSide(
                        color: Theme.of(context).colorScheme.outlineVariant),
                  ),
                ),
                const SizedBox(height: 14),
                if (rows.isEmpty)
                  SectionEmptyState(
                      icon: PhosphorIcons.fileDashed(),
                      message: 'No department files')
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: rows.length,
                    gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: MediaQuery.sizeOf(context).width < 600
                          ? (MediaQuery.sizeOf(context).width - 36) / 2
                          : 260,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: .76,
                    ),
                    itemBuilder: (context, index) => _FileManageCard(
                      departmentId: widget.departmentId,
                      row: rows[index],
                      onChanged: () {
                        if (mounted) setState(_reload);
                      },
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

class _FileManageCard extends StatefulWidget {
  const _FileManageCard(
      {required this.row, required this.onChanged, required this.departmentId});
  final String departmentId;
  final Map<String, dynamic> row;
  final VoidCallback onChanged;

  @override
  State<_FileManageCard> createState() => _FileManageCardState();
}

class _FileManageCardState extends State<_FileManageCard> {
  final repo = DepartmentRepository();
  bool busy = false;

  @override
  Widget build(BuildContext context) {
    final leadersOnly = widget.row['visibility'] == 'leaders';
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(16)),
                  child: Icon(_icon(), size: 29),
                ),
                Positioned(
                  right: 6,
                  top: 6,
                  child: Tooltip(
                    message: leadersOnly
                        ? 'Make visible to members'
                        : 'Restrict to leaders',
                    child: Semantics(
                      button: true,
                      label: leadersOnly
                          ? 'Make file visible to members'
                          : 'Restrict file to leaders',
                      child: InkWell(
                        onTap: busy ? null : () => _toggle(leadersOnly),
                        customBorder: const CircleBorder(),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                              color: leadersOnly
                                  ? Colors.redAccent
                                  : WpccColors.ink,
                              shape: BoxShape.circle),
                          child: Icon(
                              leadersOnly
                                  ? PhosphorIcons.lock()
                                  : PhosphorIcons.lockOpen(),
                              size: 15,
                              color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.row['file_name']?.toString() ?? '',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          TextButton.icon(
            onPressed: busy ? null : _remove,
            icon:
                Icon(PhosphorIcons.trash(), size: 14, color: Colors.redAccent),
            label: const Text('Remove file',
                style: TextStyle(fontSize: 10, color: Colors.redAccent)),
            style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
          ),
        ],
      ),
    );
  }

  Future<void> _toggle(bool currentlyLeaders) async {
    final previous = currentlyLeaders ? 'leaders' : 'members';
    final next = currentlyLeaders ? 'members' : 'leaders';
    setState(() {
      busy = true;
      widget.row['visibility'] = next;
    });
    try {
      await repo.toggleVisibility(widget.row['id'].toString(), next,
          departmentId: widget.departmentId);
      widget.onChanged();
    } catch (_) {
      if (mounted) {
        setState(() => widget.row['visibility'] = previous);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to change file visibility')),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _remove() async {
    final name = widget.row['file_name']?.toString() ?? 'this file';
    final confirmed = await showMotionDialog<bool>(
      animationStyle: AppMotion.dialogStyle(context),
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove file?'),
        content: Text('$name will no longer be available in this department.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep file')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Remove file')),
        ],
      ),
    );
    if (confirmed != true || !mounted || busy) return;
    setState(() => busy = true);
    try {
      await repo.deleteFile(widget.row['id'].toString(),
          departmentId: widget.departmentId);
      widget.onChanged();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unable to remove file')));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  IconData _icon() {
    final mime = widget.row['mime_type']?.toString() ?? '';
    if (mime.startsWith('image/')) return PhosphorIcons.image();
    if (mime.contains('sheet') || mime == 'text/csv') {
      return PhosphorIcons.table();
    }
    return PhosphorIcons.fileText();
  }
}
