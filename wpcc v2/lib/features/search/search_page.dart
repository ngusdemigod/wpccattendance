import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/initials_avatar.dart';
import '../departments/department_repository.dart';
import 'search_repository.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final repo = SearchRepository();
  final departmentRepo = DepartmentRepository();
  final controller = TextEditingController();
  Timer? timer;
  List<String> recent = [];
  List<Map<String, dynamic>> results = [];
  bool loading = false;
  String? searchError;
  final searchRequests = SearchRequestCoordinator();
  String filter = 'All';

  @override
  void initState() {
    super.initState();
    _loadRecent();
  }

  @override
  void dispose() {
    timer?.cancel();
    controller.dispose();
    super.dispose();
  }

  Future<void> _loadRecent() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(
        () => recent = prefs.getStringList('wpcc_recent_searches') ?? [],
      );
    }
  }

  Future<void> _saveRecent(String query) async {
    final prefs = await SharedPreferences.getInstance();
    recent = [
      query,
      ...recent.where((value) => value.toLowerCase() != query.toLowerCase()),
    ].take(8).toList();
    await prefs.setStringList('wpcc_recent_searches', recent);
    if (mounted) setState(() {});
  }

  void _changed(String value) {
    setState(() {});
    timer?.cancel();
    timer = Timer(const Duration(milliseconds: 320), () => _search(value));
  }

  Future<void> _search(String value, {bool remember = false}) async {
    final query = value.trim();
    final generation = searchRequests.begin();
    if (query.isEmpty) {
      if (mounted) {
        setState(() {
          results = [];
          loading = false;
          searchError = null;
        });
      }
      return;
    }
    setState(() {
      loading = true;
      searchError = null;
    });
    try {
      final found = await repo.search(query);
      if (!mounted || !searchRequests.isCurrent(generation)) return;
      setState(() => results = found);
      if (remember) await _saveRecent(query);
    } catch (_) {
      if (mounted && searchRequests.isCurrent(generation)) {
        setState(() => searchError = 'Unable to search right now.');
      }
    } finally {
      if (mounted && searchRequests.isCurrent(generation)) {
        setState(() => loading = false);
      }
    }
  }

  List<Map<String, dynamic>> get visible => filter == 'All'
      ? results
      : results
            .where(
              (row) =>
                  _sectionLabel(row['section']?.toString() ?? '') == filter,
            )
            .toList();

  @override
  Widget build(BuildContext context) {
    final hasQuery = controller.text.trim().isNotEmpty;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(19, 12, 19, 32),
          children: [
            Row(
              children: [
                IconButton.outlined(
                  tooltip: 'Back',
                  onPressed: () => context.pop(),
                  style: IconButton.styleFrom(
                    minimumSize: const Size(44, 44),
                    side: const BorderSide(color: WpccColors.line),
                    backgroundColor: Colors.white,
                  ),
                  icon: Icon(PhosphorIcons.arrowLeft(), size: 19),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: controller,
                    autofocus: true,
                    onChanged: _changed,
                    onSubmitted: (value) => _search(value, remember: true),
                    decoration: InputDecoration(
                      hintText: 'Search giving, events, departments',
                      suffixIcon: controller.text.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(9),
                              child: DecoratedBox(
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF4EFF8),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  PhosphorIcons.magnifyingGlass(),
                                  size: 17,
                                ),
                              ),
                            )
                          : IconButton(
                              tooltip: 'Clear search',
                              onPressed: () {
                                controller.clear();
                                _changed('');
                              },
                              icon: Icon(PhosphorIcons.x(), size: 15),
                            ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Search across the app and jump straight to what you need.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: WpccColors.inkSoft),
            ),
            if (!hasQuery && recent.isNotEmpty) ...[
              const SizedBox(height: 22),
              Text(
                'Recent searches',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 9),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: recent
                    .map(
                      (term) => InputChip(
                        label: Text(term),
                        onPressed: () {
                          controller.text = term;
                          _search(term, remember: true);
                          setState(() {});
                        },
                        onDeleted: () async {
                          recent.remove(term);
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setStringList(
                            'wpcc_recent_searches',
                            recent,
                          );
                          if (mounted) setState(() {});
                        },
                        labelStyle: const TextStyle(fontSize: 11),
                        backgroundColor: Colors.white,
                        side: BorderSide.none,
                      ),
                    )
                    .toList(),
              ),
            ],
            const SizedBox(height: 28),
            Text(
              'Search Results',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            if (hasQuery) ...[
              if (loading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(36),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (searchError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 100),
                  child: Column(
                    children: [
                      Icon(
                        PhosphorIcons.warningCircle(),
                        size: 28,
                        color: WpccColors.muted,
                      ),
                      const SizedBox(height: 9),
                      Text(
                        searchError!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: WpccColors.muted,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => _search(controller.text),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              else if (visible.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 120),
                  child: Column(
                    children: [
                      Text(
                        'No result found',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: WpccColors.inkSoft,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .94),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: WpccColors.line),
                  ),
                  child: Column(children: visible.map(_result).toList()),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _result(Map<String, dynamic> row) {
    final section = row['section']?.toString() ?? '';
    final title = row['title']?.toString() ?? '';
    final image = row['image_url']?.toString();
    return InkWell(
      onTap: () => _open(row),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: WpccColors.line)),
        ),
        child: Row(
          children: [
            if (section == 'people')
              InitialsAvatar(
                initials: _initials(title),
                imageUrl: image,
                size: 58,
              )
            else
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F2F5),
                  borderRadius: BorderRadius.circular(13),
                  image: image != null && image.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(image),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: image == null || image.isEmpty
                    ? Icon(_icon(section), size: 19)
                    : null,
              ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    row['subtitle']?.toString() ??
                        row['body']?.toString() ??
                        _sectionLabel(section),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: WpccColors.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _open(Map<String, dynamic> row) async {
    final section = row['section']?.toString();
    final id = row['id']?.toString();
    if (id == null) return;
    if (section == 'events') {
      await context.push('/events/$id');
      return;
    }
    if (section == 'departments') {
      await context.push('/departments/$id');
      return;
    }
    if (section == 'people') {
      await _openMember(id);
      return;
    }
    if (section == 'announcements' && mounted) {
      // v76 approves announcement cards on Home but no standalone detail page.
      // Deep-link to the approved announcement surface instead of inventing one.
      context.go('/home');
    }
  }

  Future<void> _openMember(String id) async {
    try {
      final member = await departmentRepo.publicMember(id);
      if (!mounted || member == null) return;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => _PublicMemberSheet(member: member),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'You can view public details only for members who share one of your departments.',
          ),
        ),
      );
    }
  }

  String _sectionLabel(String section) => switch (section) {
    'events' => 'Events',
    'departments' => 'Departments',
    'announcements' => 'Announcements',
    'people' => 'People',
    _ => 'All',
  };

  IconData _icon(String section) => switch (section) {
    'events' => PhosphorIcons.calendarDots(),
    'departments' => PhosphorIcons.usersThree(),
    'announcements' => PhosphorIcons.megaphone(),
    _ => PhosphorIcons.fileText(),
  };

  String _initials(String name) => name
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .take(2)
      .map((part) => part[0].toUpperCase())
      .join();
}

class SearchRequestCoordinator {
  int _generation = 0;

  int begin() => ++_generation;

  bool isCurrent(int generation) => generation == _generation;
}

class _PublicMemberSheet extends StatelessWidget {
  const _PublicMemberSheet({required this.member});
  final Map<String, dynamic> member;

  @override
  Widget build(BuildContext context) {
    final departments =
        (member['departments'] as List?)?.cast<dynamic>() ?? const [];
    final name =
        member['full_name']?.toString() ??
        member['display_name']?.toString() ??
        'Member';
    final initials = member['initials']?.toString() ?? '--';
    final avatar = member['avatar']?.toString();
    return Container(
      padding: EdgeInsets.fromLTRB(
        18,
        10,
        18,
        24 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: const BoxDecoration(
        color: WpccColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: WpccColors.line,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 16),
            Tooltip(
              message: 'View $name photo',
              child: Semantics(
                button: true,
                excludeSemantics: true,
                label: 'View $name photo',
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => showDialog<void>(
                    context: context,
                    barrierColor: Colors.black87,
                    builder: (_) => Dialog.fullscreen(
                      backgroundColor: Colors.black,
                      child: Stack(
                        children: [
                          Center(
                            child: InitialsAvatar(
                              initials: initials,
                              imageUrl: avatar,
                              size: 280,
                            ),
                          ),
                          Positioned(
                            top: 16,
                            right: 16,
                            child: IconButton(
                              onPressed: () => Navigator.of(
                                context,
                                rootNavigator: true,
                              ).pop(),
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  child: InitialsAvatar(
                    initials: initials,
                    imageUrl: avatar,
                    size: 92,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: -.4,
              ),
            ),
            const SizedBox(height: 20),
            _detail(
              context,
              PhosphorIcons.phone(),
              'Phone number',
              member['phone']?.toString() ?? 'Not available',
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: WpccColors.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(PhosphorIcons.usersThree(), size: 18),
                      const SizedBox(width: 9),
                      Text(
                        'Departments',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: WpccColors.muted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: departments.map((value) {
                      final map = value is Map
                          ? Map<String, dynamic>.from(value)
                          : <String, dynamic>{};
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F5F8),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          map['name']?.toString() ?? '',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detail(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: WpccColors.line),
    ),
    child: Row(
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: WpccColors.muted),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
