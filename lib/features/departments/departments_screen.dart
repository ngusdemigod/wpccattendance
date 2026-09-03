import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/app_images.dart';
import '../../flutter_flow/custom_icons.dart';
import '../../flutter_flow/nav/nav.dart';
import '../../shared/widgets/hamburger_menu_button.dart';
import '../../shared/widgets/interactive_filter_pill.dart';
import '../search/screens/global_search_screen.dart';
import 'department_detail_screen.dart';
import 'departments_models.dart';
import 'departments_service.dart';

/// Departments tab: the signed-in user's departments with role badges.
class DepartmentsScreen extends StatefulWidget {
  const DepartmentsScreen({super.key});

  @override
  State<DepartmentsScreen> createState() => _DepartmentsScreenState();
}

enum _DepartmentsFilter { all, myTeams, leading, member }

class _DepartmentsScreenState extends State<DepartmentsScreen> {
  final DepartmentsService _service = DepartmentsService();

  late Future<DepartmentsListData> _future;
  _DepartmentsFilter _filter = _DepartmentsFilter.all;

  @override
  void initState() {
    super.initState();
    _future = _service.fetchDepartmentsList();
  }

  Future<void> _refresh() async {
    final future = _service.fetchDepartmentsList();
    setState(() => _future = future);
    await future;
  }

  List<DepartmentListItem> _applyFilter(List<DepartmentListItem> items) {
    Iterable<DepartmentListItem> filtered = items;
    switch (_filter) {
      case _DepartmentsFilter.all:
        break;
      case _DepartmentsFilter.myTeams:
        filtered = filtered.where((d) => d.isMine || d.isLeading);
        break;
      case _DepartmentsFilter.leading:
        filtered = filtered.where((d) => d.isLeading);
        break;
      case _DepartmentsFilter.member:
        filtered = filtered.where((d) => !d.isLeading);
        break;
    }
    return filtered.toList();
  }

  void _openDepartment(DepartmentListItem item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DepartmentDetailScreen(
          departmentId: item.id,
          departmentName: item.name,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: FutureBuilder<DepartmentsListData>(
          future: _future,
          builder: (context, snapshot) {
            final items = _applyFilter(snapshot.data?.departments ?? const []);
            final hasItems =
                snapshot.hasData && !snapshot.hasError && items.isNotEmpty;

            return RefreshIndicator(
              onRefresh: _refresh,
              color: const Color(0xFF111827),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _DepartmentsHeaderDelegate(
                      child: _buildHeader(),
                    ),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(20, 14, 20, hasItems ? 0 : 24),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate.fixed([
                        _buildFilterRow(),
                        const SizedBox(height: 18),
                        ..._buildStatusWidgets(snapshot, items),
                      ]),
                    ),
                  ),
                  if (hasItems)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _DepartmentCard(
                            item: items[index],
                            onTap: () => _openDepartment(items[index]),
                          ),
                          childCount: items.length,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const HamburgerMenuButton(),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Departments',
                style: GoogleFonts.instrumentSerif(
                  fontSize: 28,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF111827),
                  height: 1.02,
                  letterSpacing: -0.84,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => context.pushNamed(
                GlobalSearchScreen.routeName,
                queryParameters: {'filter': 'departments'},
              ),
              child: const Icon(
                Icons.search_rounded,
                size: 24,
                color: Color(0xFF4B5563),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterRow() {
    const labels = {
      _DepartmentsFilter.all: 'All',
      _DepartmentsFilter.myTeams: 'My Teams',
      _DepartmentsFilter.leading: 'Leading',
      _DepartmentsFilter.member: 'Member',
    };
    const icons = {
      _DepartmentsFilter.all: FFIcons.kgridFour,
      _DepartmentsFilter.myTeams: FFIcons.kusersThree,
      _DepartmentsFilter.leading: FFIcons.kuserCheck,
      _DepartmentsFilter.member: FFIcons.kuser,
    };
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: _DepartmentsFilter.values.map((filter) {
          final active = filter == _filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InteractiveFilterPill(
              label: labels[filter]!,
              icon: icons[filter]!,
              selected: active,
              onTap: () => setState(() => _filter = filter),
              height: 34,
              horizontalPadding: 15,
              iconSize: 15,
              fontWeight: FontWeight.w500,
            ),
          );
        }).toList(),
      ),
    );
  }

  List<Widget> _buildStatusWidgets(
    AsyncSnapshot<DepartmentsListData> snapshot,
    List<DepartmentListItem> items,
  ) {
    if (snapshot.connectionState == ConnectionState.waiting &&
        !snapshot.hasData) {
      return [
        _sectionHeader(),
        const SizedBox(height: 4),
        ...List.generate(4, (_) => const _DepartmentCardSkeleton()),
      ];
    }
    if (snapshot.hasError) {
      return [
        const SizedBox(height: 32),
        const _EmptyState(
          icon: Icons.wifi_off_rounded,
          title: 'Could not load departments',
          message: 'Check your connection and pull to refresh.',
        ),
      ];
    }
    if (items.isEmpty) {
      return [
        _sectionHeader(),
        const SizedBox(height: 24),
        const _EmptyState(
          icon: Icons.apartment_outlined,
          title: 'No departments found',
          message: 'Departments will show up here once available.',
        ),
      ];
    }
    return [
      _sectionHeader(),
      const SizedBox(height: 4),
    ];
  }

  Widget _sectionHeader() {
    return const Row(
      children: [
        Expanded(
          child: Text(
            'My Departments',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              height: 18 / 15,
              letterSpacing: -0.5,
              color: Color(0xFF111827),
            ),
          ),
        ),
        Text(
          'Manage ›',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            letterSpacing: -0.5,
            color: Color(0xFF4B5563),
          ),
        ),
      ],
    );
  }
}

class _DepartmentsHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _DepartmentsHeaderDelegate({required this.child});

  final Widget child;

  @override
  double get minExtent => 70;

  @override
  double get maxExtent => 70;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return ColoredBox(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: child,
      ),
    );
  }

  @override
  bool shouldRebuild(_DepartmentsHeaderDelegate oldDelegate) =>
      child != oldDelegate.child;
}

class _DepartmentCard extends StatelessWidget {
  const _DepartmentCard({required this.item, required this.onTap});

  final DepartmentListItem item;
  final VoidCallback onTap;

  static const _badgeStyles = {
    DepartmentRole.primary: (Color(0xFFFBEAF4), Color(0xFFB10F8F), 'Primary'),
    DepartmentRole.leader: (Color(0xFFF7EFD8), Color(0xFF9A6B00), 'Leader'),
    DepartmentRole.member: (Color(0xFFE3F5E9), Color(0xFF1A6B35), 'Member'),
  };

  @override
  Widget build(BuildContext context) {
    final (badgeBg, badgeFg, badgeLabel) = _badgeStyles[item.role]!;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFCFBF9),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0x14111827)),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0x14111827)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  AppImages.wpccLogo,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF111827),
                      letterSpacing: -0.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${item.memberCount} member${item.memberCount == 1 ? '' : 's'}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF8A8F98),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: badgeBg,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                badgeLabel,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                  color: badgeFg,
                ),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: Color(0xFF8A8F98),
            ),
          ],
        ),
      ),
    );
  }
}

class _DepartmentCardSkeleton extends StatelessWidget {
  const _DepartmentCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFBF9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x14111827)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFF1EADD),
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 12,
                  width: 140,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1EADD),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 9,
                  width: 70,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F0E8),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFBF9),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0x14111827)),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: Color(0xFFF1EADD),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 26, color: const Color(0xFF111827)),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
