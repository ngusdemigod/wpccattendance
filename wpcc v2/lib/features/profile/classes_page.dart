import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/section_empty_state.dart';
import 'profile_repository.dart';

class ClassesPage extends StatefulWidget {
  const ClassesPage({super.key});
  @override
  State<ClassesPage> createState() => _ClassesPageState();
}

class _ClassesPageState extends State<ClassesPage> {
  final repo = ProfileRepository();
  late Future<List<Map<String, dynamic>>> future;
  @override
  void initState() {
    super.initState();
    future = repo.classes();
  }

  void retry() => setState(() => future = repo.classes());
  @override
  Widget build(BuildContext context) => SafeArea(
    bottom: false,
    child: FutureBuilder<List<Map<String, dynamic>>>(
      future: future,
      builder: (context, s) {
        final rows = s.data ?? const <Map<String, dynamic>>[];
        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 110),
          children: [
            const Text(
              'Profile',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 15),
            const ProfileTabs(index: 1),
            const SizedBox(height: 34),
            const Text(
              'My classes',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                letterSpacing: -.7,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Track your assigned classes and learning progress.',
              style: TextStyle(fontSize: 12, color: WpccColors.muted),
            ),
            const SizedBox(height: 24),
            if (s.connectionState != ConnectionState.done)
              const SectionEmptyState(
                icon: Icons.school_outlined,
                message: 'Loading your classes…',
                height: 300,
              )
            else if (s.hasError) ...[
              SectionEmptyState(
                icon: PhosphorIcons.warningCircle(),
                message: 'Unable to load classes',
                height: 260,
              ),
              TextButton(onPressed: retry, child: const Text('Try again')),
            ] else ...[
              _metrics(rows),
              const SizedBox(height: 22),
              const Text(
                'CURRENT CLASSES',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: WpccColors.muted,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 10),
              if (rows.isEmpty)
                const SectionEmptyState(
                  icon: Icons.school_outlined,
                  message: 'No classes assigned',
                  height: 300,
                )
              else
                ...rows.map(_course),
            ],
          ],
        );
      },
    ),
  );
  Widget _metrics(List<Map<String, dynamic>> rows) {
    final a = rows.where((r) => r['status'] == 'completed').length,
        b = rows.where((r) => r['status'] == 'in_progress').length,
        c = rows
            .where((r) => r['due_at'] != null && r['status'] != 'completed')
            .length;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: WpccColors.line),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          _metric('$a', 'Completed'),
          _metric('$b', 'In progress'),
          _metric('$c', 'Due'),
        ],
      ),
    );
  }

  Widget _metric(String v, String l) => Expanded(
    child: Column(
      children: [
        Text(
          v,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 3),
        Text(l, style: const TextStyle(fontSize: 10, color: WpccColors.muted)),
      ],
    ),
  );
  Widget _course(Map<String, dynamic> r) {
    final p = ((r['progress_percent'] as num?)?.toDouble() ?? 0).clamp(0, 100);
    return InkWell(
      onTap: () {
        final d = r['deep_link']?.toString();
        if (d != null && d.startsWith('/')) context.push(d);
      },
      borderRadius: BorderRadius.circular(22),
      child: Container(
        margin: const EdgeInsets.only(bottom: 9),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: WpccColors.line),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F1FA),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(PhosphorIcons.bookOpen(), size: 19),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r['title']?.toString() ?? 'Class',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${p.round()}% complete',
                    style: const TextStyle(
                      fontSize: 11,
                      color: WpccColors.muted,
                    ),
                  ),
                  const SizedBox(height: 7),
                  LinearProgressIndicator(
                    value: p / 100,
                    minHeight: 4,
                    borderRadius: BorderRadius.circular(10),
                    backgroundColor: const Color(0xFFF0F1F4),
                    valueColor: const AlwaysStoppedAnimation(WpccColors.ink),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileTabs extends StatelessWidget {
  const ProfileTabs({super.key, required this.index});
  final int index;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 42,
    child: Row(
      children: [
        tab(context, 0, 'Overview', '/profile'),
        tab(context, 1, 'Classes', '/profile/classes'),
        tab(context, 2, 'Query', '/profile/query'),
      ],
    ),
  );
  Widget tab(BuildContext context, int value, String label, String route) =>
      Padding(
        padding: const EdgeInsets.only(right: 10),
        child: InkWell(
          onTap: value == index ? null : () => context.go(route),
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: value == index ? WpccColors.navActive : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: value == index
                  ? WpccColors.navActive
                  : WpccColors.lineSubtle),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: value == index ? FontWeight.w600 : FontWeight.w500,
                color: value == index ? Colors.white : WpccColors.inkSoft,
              ),
            ),
          ),
        ),
      );
}
