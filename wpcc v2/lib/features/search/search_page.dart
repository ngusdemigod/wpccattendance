import 'dart:async';

import 'package:flutter/material.dart';
import '../../core/theme/app_motion.dart';
import '../../core/widgets/member_skeleton.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/widgets/adaptive_layout.dart';
import '../../core/widgets/member_components.dart';
import '../../core/widgets/initials_avatar.dart';
import '../departments/department_repository.dart';
import '../home/home_page.dart';
import 'search_repository.dart';
import 'search_filter_sheet.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key, this.loadSearch, this.initialFilter});
  final Future<List<Map<String, dynamic>>> Function(String query)? loadSearch;
  final String? initialFilter;

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late final repo = SearchRepository();
  late final departmentRepo = DepartmentRepository();
  final controller = TextEditingController();
  Timer? timer;
  List<String> recent = [];
  List<Map<String, dynamic>> results = [];
  bool loading = false;
  String? searchError;
  final searchRequests = SearchRequestCoordinator();
  String filter = 'All';
  bool _filterInitialized = false;

  @override
  void initState() {
    super.initState();
    _loadRecent();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_filterInitialized) return;
    final selection = MemberSearchScope.maybeOf(context);
    final requested = widget.initialFilter ?? selection?.value ?? 'All';
    filter =
        sections.any((section) => section.$1 == requested) ? requested : 'All';
    selection?.value = filter;
    _filterInitialized = true;
  }

  void _selectFilter(String selected) {
    MemberSearchScope.maybeOf(context)?.value = selected;
    setState(() => filter = selected);
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
    timer?.cancel();
    searchRequests.begin();
    setState(() {
      loading = value.trim().isNotEmpty;
      searchError = null;
      if (!loading) results = [];
    });
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
      final found = await (widget.loadSearch ?? repo.search)(query);
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
            (row) => _sectionLabel(row['section']?.toString() ?? '') == filter,
          )
          .toList();

  static const sections = searchSections;

  Future<void> _filters() async {
    final selected = await showSearchFilterSheet(context, selected: filter);
    if (!mounted || selected == null) return;
    _selectFilter(selected);
  }

  Widget _heading(String title) => Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Text(title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontSize: 17, height: 24 / 17, fontWeight: FontWeight.w600)));

  @override
  Widget build(BuildContext context) {
    final hasQuery = controller.text.trim().isNotEmpty;
    final groups = <String, List<Map<String, dynamic>>>{};
    for (final row in visible) {
      groups
          .putIfAbsent(
              _sectionLabel(row['section']?.toString() ?? ''), () => [])
          .add(row);
    }
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: memberPagePadding(context, top: 20, bottom: 124),
          children: [
            MemberPageHeader(
                title: 'Search',
                onBack: () =>
                    context.canPop() ? context.pop() : context.go('/home')),
            Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                    maxWidth: MediaQuery.sizeOf(context).width >= 900
                        ? 720
                        : double.infinity),
                child: MemberSearchBar(
                    controller: controller,
                    autofocus: true,
                    onChanged: _changed,
                    onSubmitted: (value) => _search(value, remember: true),
                    onClear: controller.text.isEmpty
                        ? null
                        : () {
                            controller.clear();
                            _changed('');
                          },
                    onFilter: _filters),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
                height: 48,
                child: ListView(scrollDirection: Axis.horizontal, children: [
                  for (final section in sections)
                    Padding(
                        padding: const EdgeInsets.only(right: 7),
                        child: MemberFilterChip(
                            label: section.$1,
                            icon: section.$2,
                            selected: filter == section.$1,
                            onPressed: () => _selectFilter(section.$1))),
                ])),
            const SizedBox(height: 25),
            if (hasQuery) ...[
              if (loading)
                const MemberSkeleton(label: 'Searching')
              else if (searchError != null)
                MemberStatus(
                    message: searchError!,
                    icon: PhosphorIconsRegular.warningCircle,
                    onRetry: () => _search(controller.text))
              else if (visible.isEmpty)
                const MemberStatus(
                    message: 'No results',
                    icon: PhosphorIconsRegular.magnifyingGlass)
              else
                for (final group in groups.entries) ...[
                  _heading(group.key),
                  AdaptiveCards(
                      minimumWidth: 420,
                      maximumColumns: 2,
                      gap: 7,
                      children: group.value.map(_result).toList()),
                  const SizedBox(height: 22),
                ],
            ] else ...[
              if (recent.isNotEmpty) ...[
                _heading('Recent searches'),
                for (final term in recent)
                  Padding(
                      padding: const EdgeInsets.only(bottom: 7),
                      child: MemberListRow(
                          title: term,
                          leading:
                              const Icon(PhosphorIconsRegular.clock, size: 20),
                          onTap: () {
                            controller.text = term;
                            _search(term, remember: true);
                            setState(() {});
                          },
                          trailing: MemberIconButton(
                              icon: PhosphorIconsRegular.x,
                              label: 'Remove $term from recent searches',
                              plain: true,
                              onPressed: () async {
                                recent.remove(term);
                                final prefs =
                                    await SharedPreferences.getInstance();
                                await prefs.setStringList(
                                    'wpcc_recent_searches', recent);
                                if (mounted) setState(() {});
                              }))),
                const SizedBox(height: 22),
              ],
              _heading('Explore'),
              const HomeQuickLinks(),
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
    final subtitle = row['subtitle']?.toString() ??
        row['body']?.toString() ??
        _sectionLabel(section);
    return MemberListRow(
      title: title,
      subtitleWidget: Text(subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall),
      leading: section == 'people'
          ? InitialsAvatar(
              memberStyle: true,
              initials: _initials(title),
              imageUrl: image,
              size: 64)
          : MemberArtwork(
              imageUrl: image, size: 64, height: 66, icon: _icon(section)),
      onTap: () => _open(row),
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
        sheetAnimationStyle: AppMotion.sheetStyle(context),
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
    final name = member['full_name']?.toString() ??
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
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
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
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 16),
            Tooltip(
              message: 'View $name photo',
              child: Semantics(
                button: true,
                excludeSemantics: false,
                label: 'View $name photo',
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => showMotionDialog<void>(
                    animationStyle: AppMotion.dialogStyle(context),
                    context: context,
                    barrierColor: Colors.black87,
                    builder: (_) => Dialog.fullscreen(
                      backgroundColor: Colors.black,
                      child: Stack(
                        children: [
                          Center(
                            child: InitialsAvatar(
                              memberStyle: true,
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
                              tooltip: 'Close photo',
                              icon: const Icon(
                                PhosphorIconsRegular.x,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  child: InitialsAvatar(
                    memberStyle: true,
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
                letterSpacing: 0,
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
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant),
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
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
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
                          color:
                              Theme.of(context).colorScheme.surfaceContainerLow,
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
  ) =>
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(22),
          border:
              Border.all(color: Theme.of(context).colorScheme.outlineVariant),
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
                    ).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
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
