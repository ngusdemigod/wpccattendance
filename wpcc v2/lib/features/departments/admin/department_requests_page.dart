import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/widgets/member_components.dart';
import '../../../core/widgets/member_skeleton.dart';
import '../department_repository.dart';

class DepartmentRequestsPage extends StatefulWidget {
  const DepartmentRequestsPage(
      {super.key, required this.departmentId, this.repository});
  final String departmentId;
  final DepartmentRepository? repository;
  @override
  State<DepartmentRequestsPage> createState() => _DepartmentRequestsPageState();
}

class _DepartmentRequestsPageState extends State<DepartmentRequestsPage> {
  late final repo = widget.repository ?? DepartmentRepository();
  late Future<List<Map<String, dynamic>>> requests =
      repo.pendingRequests(widget.departmentId);
  bool busy = false, changed = false;
  void _reload() => setState(() {
        requests = repo.pendingRequests(widget.departmentId);
      });

  Future<void> _review(Map<String, dynamic> row, bool approve) async {
    if (busy) return;
    final name = row['full_name']?.toString() ?? 'Member';
    final confirmed = await showMotionDialog<bool>(
        context: context,
        animationStyle: AppMotion.dialogStyle(context),
        builder: (context) => AlertDialog(
              title: Text(
                  approve ? 'Approve join request?' : 'Decline join request?'),
              content: Text(approve
                  ? '$name will gain access to this department in this branch.'
                  : '$name will not be added to this department.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel')),
                FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(approve ? 'Approve' : 'Decline')),
              ],
            ));
    if (!mounted || confirmed != true) return;
    setState(() => busy = true);
    try {
      await repo.reviewRequest(
          widget.departmentId, row['id'].toString(), approve);
      if (!mounted) return;
      changed = true;
      _reload();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(approve ? 'Member approved' : 'Request declined')));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Unable to review request. Refresh and try again.')));
        _reload();
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
            title: const Text('Join requests'),
            leading: MemberIconButton(
                label: 'Back',
                icon: PhosphorIconsRegular.caretLeft,
                onPressed: () => context.canPop()
                    ? context.pop(changed)
                    : context.go('/departments/${widget.departmentId}')),
            actions: [
              IconButton(
                  tooltip: 'Refresh requests',
                  onPressed: busy ? null : _reload,
                  icon: const Icon(PhosphorIconsRegular.arrowClockwise))
            ]),
        body: SafeArea(
            child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                      future: requests,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState != ConnectionState.done) {
                          return const SingleChildScrollView(
                              child: Padding(
                                  padding: EdgeInsets.all(20),
                                  child: MemberSkeleton()));
                        }
                        if (snapshot.hasError) {
                          return MemberStatus(
                              message:
                                  'Requests unavailable. Check your department permissions or try again.',
                              onRetry: _reload);
                        }
                        final rows = snapshot.data ?? [];
                        if (rows.isEmpty) {
                          return const MemberStatus(
                              message: 'No pending join requests',
                              icon: PhosphorIconsRegular.userCheck);
                        }
                        return ListView.separated(
                            padding: const EdgeInsets.all(20),
                            itemCount: rows.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 32),
                            itemBuilder: (context, index) {
                              final row = rows[index];
                              return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        row['full_name']?.toString() ??
                                            'Member',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium),
                                    const SizedBox(height: 12),
                                    Wrap(spacing: 12, runSpacing: 8, children: [
                                      FilledButton.icon(
                                          onPressed: busy
                                              ? null
                                              : () => _review(row, true),
                                          icon: const Icon(
                                              PhosphorIconsRegular.check,
                                              size: 20),
                                          label: const Text('Approve')),
                                      TextButton(
                                          onPressed: busy
                                              ? null
                                              : () => _review(row, false),
                                          child: const Text('Decline')),
                                    ]),
                                  ]);
                            });
                      }),
                ))),
      );
}
