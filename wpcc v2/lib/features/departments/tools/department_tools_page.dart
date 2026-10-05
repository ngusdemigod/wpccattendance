import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/widgets/member_components.dart';
import '../../../core/theme/member_theme.dart';
import '../../../core/widgets/member_skeleton.dart';
import '../../data/supabase_repository.dart';
import 'department_tool_card.dart';
import 'department_tool_catalog.dart';

class DepartmentToolsPage extends StatefulWidget {
  const DepartmentToolsPage(
      {super.key, this.departmentId, this.loadDepartments});
  final String? departmentId;
  final Future<List<Map<String, dynamic>>> Function()? loadDepartments;
  @override
  State<DepartmentToolsPage> createState() => _DepartmentToolsPageState();
}

class _DepartmentToolsPageState extends State<DepartmentToolsPage> {
  late Future<List<Map<String, dynamic>>> departments;
  Map<String, dynamic>? selected;
  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    departments =
        widget.loadDepartments?.call() ?? SupabaseRepository().myDepartments();
  }

  @override
  Widget build(BuildContext context) {
    final tablet = MediaQuery.sizeOf(context).width >= 600;
    final fallbackTint = MemberPagePalette.colors('/resources/department-tools',
        Theme.of(context).brightness == Brightness.dark).first;
    return Scaffold(
      backgroundColor: DepartmentToolStyle.page(context),
      body: SafeArea(
          child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 840),
          child: DecoratedBox(
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [fallbackTint, fallbackTint.withValues(alpha: 0)],
                    transform: const _DepartmentGradientExtent())),
            child: RefreshIndicator(
                onRefresh: () async {
                  setState(() {
                    selected = null;
                    _load();
                  });
                  try {
                    await departments;
                  } catch (_) {/* Error view provides retry. */}
                },
                child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(tablet ? 32 : 20,
                        tablet ? 28 : 18, tablet ? 32 : 20, 70),
                    children: [
                      SizedBox(
                          height: 48,
                          child: Row(children: [
                            IconButton(
                                tooltip: 'Back',
                                icon:
                                    const Icon(PhosphorIconsRegular.arrowLeft),
                                color: DepartmentToolStyle.ink(context),
                                onPressed: () {
                                  if (selected != null &&
                                      widget.departmentId == null) {
                                    setState(() => selected = null);
                                  } else if (context.canPop()) {
                                    context.pop();
                                  } else {
                                    context.go('/home');
                                  }
                                }),
                            const SizedBox(width: 12),
                            Expanded(
                                child: Text('Service tools',
                                    style: DepartmentToolStyle.text(context, 20,
                                        height: 26 / 20, weight: FontWeight.w600))),
                          ])),
                      const SizedBox(height: 24),
                      FutureBuilder<List<Map<String, dynamic>>>(
                          future: departments,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState !=
                                ConnectionState.done) {
                              return const MemberSkeleton();
                            }
                            if (snapshot.hasError) {
                              return MemberStatus(
                                  icon: PhosphorIconsRegular.warningCircle,
                                  message: 'Unable to load department tools',
                                  onRetry: () => setState(_load));
                            }
                            // This result comes from the authenticated "mine" RPC; requests
                            // appended by myDepartments must never become tool access.
                            final active = (snapshot.data ?? [])
                                .where((d) =>
                                    d['status'] != 'pending' &&
                                    d['department_id'] != null)
                                .toList();
                            var current = selected;
                            if (widget.departmentId != null) {
                              current = null;
                              for (final d in active) {
                                if (d['department_id'].toString() ==
                                    widget.departmentId) { current = d; }
                              }
                              if (current == null) {
                                return const MemberStatus(
                                    icon: PhosphorIconsRegular.lock,
                                    message:
                                        'No active membership for these department tools');
                              }
                            }
                            return AnimatedSwitcher(
                              duration: MediaQuery.disableAnimationsOf(context)
                                  ? Duration.zero : const Duration(milliseconds: 180),
                              switchInCurve: const Cubic(.2, .8, .2, 1),
                              transitionBuilder: (child, animation) => FadeTransition(
                                opacity: animation, child: AnimatedBuilder(
                                  animation: animation, child: child,
                                  builder: (context, child) => Transform.translate(
                                    offset: Offset(0, 8 * (1 - animation.value)), child: child))),
                              child: KeyedSubtree(key: ValueKey(current?['department_id']),
                                child: current == null ? _catalog(active) : _tools(current)));
                          }),
                    ])),
          ),
        ),
      )),
    );
  }

  Widget _heading(String title, String description) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: DepartmentToolStyle.text(context, 23.2,
                weight: FontWeight.w600, height: 1.25)),
        const SizedBox(height: 8),
        Text(description,
            style: DepartmentToolStyle.text(context, 14,
                muted: true, height: 1.55)),
        const SizedBox(height: 28),
      ]);

  Widget _catalog(List<Map<String, dynamic>> rows) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _heading('Your departments', 'Tools for your departments.'),
        if (rows.isEmpty)
          const MemberStatus(
              icon: PhosphorIconsRegular.users,
              message: 'No active department memberships yet'),
        DepartmentToolGrid(
            children: rows.map((d) {
          final name = d['name']?.toString() ?? 'Department';
          final definition = DepartmentToolDefinition.forName(name);
          return DepartmentToolCard(
              key: ValueKey(d['department_id']),
              title: name,
              description: definition?.description ??
                  'View department files and schedules.',
              icon: definition?.icon ?? PhosphorIconsRegular.users,
              onTap: () => setState(() => selected = d));
        }).toList()),
      ]);

  Widget _tools(Map<String, dynamic> department) {
    final name = department['name']?.toString() ?? 'Department';
    final definition = DepartmentToolDefinition.forName(name);
    final id = Uri.encodeComponent(department['department_id'].toString());
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _heading(name, 'Department resources'),
      DepartmentToolGrid(children: [
        if (definition != null)
          DepartmentToolCard(
              title: definition.title,
              description: definition.description,
              icon: definition.icon,
              unavailable: true,
              onTap: null),
        DepartmentToolCard(
            title: 'Department files',
            description: 'Find shared resources and manage your downloads.',
            icon: PhosphorIconsRegular.folder,
            onTap: () =>
                context.push('/departments/$id?tab=files', extra: department)),
        DepartmentToolCard(
            title: 'Schedules',
            description: 'View service dates and department plans.',
            icon: PhosphorIconsRegular.calendar,
            onTap: () => context.push('/departments/$id?tab=attendance',
                extra: department)),
        const DepartmentToolCard(
            title: 'Assigned tasks',
            description: 'See your responsibilities and update progress.',
            icon: PhosphorIconsRegular.listChecks,
            unavailable: true,
            onTap: null),
      ]),
    ]);
  }
}

/// CSS reference fades to transparent at exactly 310 logical pixels.
class _DepartmentGradientExtent extends GradientTransform {
  const _DepartmentGradientExtent();
  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.diagonal3Values(1, bounds.height == 0 ? 1 : 310 / bounds.height, 1);
}
