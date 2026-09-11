import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/section_empty_state.dart';
import '../data/supabase_repository.dart';

class DepartmentsPage extends StatefulWidget {
  const DepartmentsPage({super.key});
  @override
  State<DepartmentsPage> createState() => _DepartmentsPageState();
}

class _DepartmentsPageState extends State<DepartmentsPage> {
  final repo = SupabaseRepository();
  String filter = 'all';
  late Future<List<Map<String, dynamic>>> future;
  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    future = repo.departments(filter: filter);
  }

  void choose(String v) {
    setState(() {
      filter = v;
      _load();
    });
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async {
            setState(_load);
            await future;
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 110),
            children: [
              Text(
                'Departments',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: -.7,
                    ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _chip('all', 'All'),
                  _chip('mine', 'My Teams'),
                  _chip('leading', 'Leading'),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      filter == 'all'
                          ? 'My departments'
                          : filter == 'leading'
                              ? 'Departments I lead'
                              : 'My teams',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  Text(
                    'Manage',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontSize: 12,
                          color: WpccColors.muted,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: future,
                builder: (context, s) {
                  if (s.connectionState != ConnectionState.done) {
                    return const SizedBox(
                      height: 180,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (s.hasError) {
                    return const SectionEmptyState(
                      icon: Icons.error_outline,
                      message: 'Unable to load departments',
                    );
                  }
                  final rows = s.data ?? const [];
                  if (rows.isEmpty) {
                    return SectionEmptyState(
                      icon: Icons.groups_outlined,
                      message: filter == 'leading'
                          ? 'You are not leading a department'
                          : 'No departments found',
                    );
                  }
                  return AnimatedSize(
                    duration: const Duration(milliseconds: 190),
                    curve: Curves.easeOutCubic,
                    child: Column(
                      children: rows
                          .map(
                            (d) => TweenAnimationBuilder<double>(
                              key: ValueKey(d['department_id']),
                              duration: const Duration(milliseconds: 190),
                              tween: Tween(begin: 0, end: 1),
                              builder: (context, v, child) => Opacity(
                                opacity: v,
                                child: Transform.translate(
                                  offset: Offset(0, 6 * (1 - v)),
                                  child: child,
                                ),
                              ),
                              child: _card(d),
                            ),
                          )
                          .toList(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      );
  Widget _chip(String key, String label) => Padding(
        padding: const EdgeInsets.only(right: 7),
        child: ChoiceChip(
          selected: filter == key,
          showCheckmark: false,
          label: Text(label),
          onSelected: (_) => choose(key),
          selectedColor: WpccColors.ink,
          backgroundColor: Colors.white,
          side: BorderSide.none,
          labelStyle: TextStyle(
            fontSize: 12,
            color: filter == key ? Colors.white : WpccColors.inkSoft,
          ),
        ),
      );
  Widget _card(Map<String, dynamic> d) => InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: () => context.push(
          '/departments/${d['department_id']}',
          extra: {
            'id': d['department_id'],
            'name': d['name'],
            'description': d['description'],
            'cover_url': d['cover_url'],
            'avatar_url': d['avatar_url'],
          },
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 9),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: WpccColors.line),
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F3F7),
                  borderRadius: BorderRadius.circular(17),
                  image: (d['avatar_url']?.toString() ?? '').isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(d['avatar_url'].toString()),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: (d['avatar_url']?.toString() ?? '').isEmpty
                    ? const Icon(Icons.groups_outlined, size: 22)
                    : null,
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d['name']?.toString() ?? 'Department',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${d['member_count'] ?? 0} members · ${d['is_primary'] == true ? 'Primary department' : d['is_member'] == true ? 'My team' : 'Community'}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 12,
                            color: WpccColors.muted,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (d['is_primary'] == true)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8E4F3),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: const Text(
                    'Primary',
                    style: TextStyle(fontSize: 10, color: Color(0xFFD43194)),
                  ),
                ),
            ],
          ),
        ),
      );
}
