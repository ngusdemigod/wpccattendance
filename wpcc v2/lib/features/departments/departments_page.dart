import 'package:flutter/material.dart';
import '../../core/widgets/member_sheet.dart';
import '../../core/widgets/member_skeleton.dart';
import '../../core/widgets/adaptive_layout.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/widgets/member_components.dart';
import '../data/supabase_repository.dart';

class DepartmentsPage extends StatefulWidget {
  const DepartmentsPage(
      {super.key, this.loadDepartments, this.filesOnly = false});
  final bool filesOnly;
  final Future<List<Map<String, dynamic>>> Function()? loadDepartments;
  @override
  State<DepartmentsPage> createState() => _DepartmentsPageState();
}

class _DepartmentsPageState extends State<DepartmentsPage> {
  late final repo = SupabaseRepository();
  late Future<List<Map<String, dynamic>>> future;
  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    future = (widget.loadDepartments ?? repo.myDepartments)();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async {
            setState(_load);
            try {
              await future;
            } catch (_) {}
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: memberPagePadding(context, phone: 20, top: 20),
            children: [
              MemberPageHeader(
                  title: widget.filesOnly ? 'Department files' : 'Departments',
                  onBack: () =>
                      context.canPop() ? context.pop() : context.go('/home'),
                  actions: [
                    if (!widget.filesOnly)
                      MemberIconButton(
                          icon: PhosphorIconsRegular.plus,
                          label: 'Join another department',
                          onPressed: _joinDepartment),
                  ]),
              Text(
                  widget.filesOnly
                      ? 'Choose a department.'
                      : 'Find your place to serve.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
              const SizedBox(height: 25),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: future,
                builder: (context, s) {
                  if (s.connectionState != ConnectionState.done) {
                    return const MemberSkeleton();
                  }
                  if (s.hasError) {
                    return MemberStatus(
                      icon: PhosphorIconsRegular.warningCircle,
                      message: 'Unable to load departments',
                      onRetry: () => setState(_load),
                    );
                  }
                  final rows = s.data ?? const [];
                  if (rows.isEmpty) {
                    return const MemberStatus(
                      icon: PhosphorIconsRegular.usersThree,
                      message: 'No departments yet',
                    );
                  }
                  final joined =
                      rows.where((row) => row['status'] != 'pending').toList();
                  final pending =
                      rows.where((row) => row['status'] == 'pending').toList();
                  return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (joined.isNotEmpty) ...[
                          const MemberSectionHeader(title: 'Your departments'),
                          AdaptiveCards(
                              minimumWidth: 420,
                              maximumColumns: 2,
                              gap: 12,
                              children: joined.map(_card).toList()),
                        ],
                        if (!widget.filesOnly && pending.isNotEmpty) ...[
                          if (joined.isNotEmpty) const SizedBox(height: 28),
                          const MemberSectionHeader(title: 'Pending requests'),
                          for (final row in pending) ...[
                            _card(row),
                            Divider(
                                height: 1,
                                color: Theme.of(context)
                                    .colorScheme
                                    .outlineVariant),
                          ],
                        ],
                      ]);
                },
              ),
            ],
          ),
        ),
      );
  Future<void> _joinDepartment() async {
    try {
      final departments = await repo.departmentDirectory();
      if (!mounted) return;
      final selected = await showMemberSheet<String>(
          context: context,
          title: 'Join a department',
          builder: (context) => SafeArea(
                  child: ListView(shrinkWrap: true, children: [
                const ListTile(
                    subtitle: Text(
                        'Your request goes to an administrator for approval.')),
                for (final department
                    in departments.where((row) => row['is_member'] != true))
                  ListTile(
                      title:
                          Text(department['name']?.toString() ?? 'Department'),
                      trailing: const Icon(PhosphorIconsRegular.plus),
                      onTap: () => Navigator.pop(
                          context, department['department_id'].toString())),
              ])));
      if (selected == null) return;
      await repo.requestDepartment(selected);
      if (!mounted) return;
      setState(_load);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request sent. Awaiting approval.')));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Unable to submit the request. Please try again.')));
      }
    }
  }

  Widget _card(Map<String, dynamic> d) {
    final pending = d['status'] == 'pending';
    final status = pending
        ? 'Pending'
        : d['is_primary'] == true
            ? 'Primary'
            : d['is_member'] == true
                ? 'Member'
                : d['status']?.toString();
    final description = d['description']?.toString().trim() ?? '';
    final metadata = [
      if (description.isNotEmpty) description,
      if (d['member_count'] != null) '${d['member_count']} members',
    ].join(' · ');
    final avatar = d['avatar_url']?.toString() ?? '';
    return MemberListRow(
      key: ValueKey(d['department_id']),
      plain: pending,
      title: (d['name']?.toString().trim().isNotEmpty ?? false)
          ? d['name'].toString()
          : 'Department name unavailable',
      subtitle: pending
          ? 'Awaiting approval'
          : metadata.isEmpty
              ? null
              : metadata,
      subtitleWidget: pending || metadata.isEmpty
          ? null
          : Text(metadata,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall),
      leading: MemberArtwork(
          imageUrl: avatar.isNotEmpty ? avatar : d['cover_url']?.toString(),
          size: 48,
          height: 48,
          icon: pending
              ? PhosphorIconsRegular.hourglass
              : PhosphorIconsRegular.usersThree),
      trailing: pending
          ? null
          : status == null || status.isEmpty
              ? null
              : Container(
                  constraints: const BoxConstraints(maxWidth: 90),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12)),
                  child: Text(status,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant))),
      onTap: pending
          ? null
          : () => context.push(
                '/departments/${d['department_id']}${widget.filesOnly ? '?tab=files' : ''}',
                extra: {
                  'id': d['department_id'],
                  'name': d['name'],
                  'description': d['description'],
                  'cover_url': d['cover_url'],
                  'avatar_url': d['avatar_url'],
                },
              ),
    );
  }
}
