import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/app_shell_widget.dart';
import '../../../flutter_flow/custom_icons.dart';
import '../../../flutter_flow/nav/nav.dart';
import '../../announcements/announcement_detail_screen.dart';
import '../../departments/department_detail_screen.dart';
import '../../departments/departments_models.dart';
import '../../departments/widgets/member_profile_popup.dart';
import '../../events/screens/event_details_screen.dart';
import '../controllers/global_search_controller.dart';
import '../models/global_search_models.dart';
import '../widgets/search_input_panel.dart';
import '../widgets/search_result_cards.dart';
import '../widgets/search_states.dart';

/// Global search screen — one search experience across people, events,
/// announcements, and departments, backed by the `global_search` RPC.
class GlobalSearchScreen extends StatefulWidget {
  const GlobalSearchScreen({
    super.key,
    this.initialQuery = '',
    this.initialFilter = '',
  });

  static const String routeName = 'GlobalSearch';
  static const String routePath = '/search';

  final String initialQuery;
  final String initialFilter;

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  late final GlobalSearchController _controller;
  late final TextEditingController _textController;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = GlobalSearchController()
      ..filter = SearchFilterX.fromQueryParam(widget.initialFilter);
    _textController = TextEditingController(text: widget.initialQuery);
    if (widget.initialQuery.trim().isNotEmpty) {
      _controller.search(widget.initialQuery);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  void _handleBack() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }
    context.goNamedAuth(
      AppShellWidget.routeName,
      mounted,
      ignoreRedirect: true,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _clearQuery() {
    _textController.clear();
    _controller.clear();
    _focusNode.requestFocus();
  }

  void _openResult(GlobalSearchResult result) {
    switch (result.section) {
      case SearchFilter.events:
        context.pushNamed(
          EventDetailsScreen.routeName,
          pathParameters: {'eventId': result.id},
        );
        break;
      case SearchFilter.announcements:
        context.pushNamed(
          AnnouncementDetailScreen.routeName,
          pathParameters: {'announcementId': result.id},
        );
        break;
      case SearchFilter.departments:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DepartmentDetailScreen(
              departmentId: result.id,
              departmentName: result.title,
            ),
          ),
        );
        break;
      case SearchFilter.people:
        _openPerson(result);
        break;
      case SearchFilter.all:
        break;
    }
  }

  void _openPerson(GlobalSearchResult result) {
    final m = result.metadata;
    showMemberProfilePopup(
      context,
      member: DepartmentMember(
        userId: m['user_id'] as String? ?? result.id,
        fullName: result.title,
        firstName: m['firstname'] as String?,
        lastName: m['lastname'] as String?,
        avatarUrl: m['avatar'] as String?,
        verified: m['verified'] == true,
        memberSince: DateTime.tryParse(
          (m['date_joined'] ?? m['profile_created_at'] ?? '') as String,
        ),
        branchName: m['branch_name'] as String?,
        departmentName: m['department_name'] as String?,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _Header(onBack: _handleBack),
            Expanded(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) => ListView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.only(bottom: 24),
                  children: [
                    SearchInputPanel(
                      controller: _textController,
                      focusNode: _focusNode,
                      onChanged: _controller.onQueryChanged,
                      onClear: _clearQuery,
                      showSummary: _controller.hasQuery &&
                          _controller.status == GlobalSearchStatus.success,
                      query: _controller.query,
                      totalMatches: _controller.totalMatches,
                      activeFilter: _controller.filter,
                    ),
                    SearchFilterChips(
                      active: _controller.filter,
                      onSelected: _controller.setFilter,
                    ),
                    ..._buildBody(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildBody() {
    switch (_controller.status) {
      case GlobalSearchStatus.idle:
        return const [SearchIdleState()];
      case GlobalSearchStatus.loading:
        return const [SearchLoadingSkeleton()];
      case GlobalSearchStatus.empty:
        return [SearchEmptyState(query: _controller.query)];
      case GlobalSearchStatus.error:
        return [SearchErrorCard(onRetry: _controller.retry)];
      case GlobalSearchStatus.success:
        return _buildResults();
    }
  }

  List<Widget> _buildResults() {
    final query = _controller.query;
    final children = <Widget>[];

    final top = _controller.topResult;
    if (top != null) {
      children.add(SearchSectionHeader(
        icon: FFIcons.ksparkle,
        title: 'Top result',
        trailingLabel: 'Open',
        onTrailingTap: () => _openResult(top),
      ));
      children.add(TopResultCard(
        result: top,
        query: query,
        onTap: () => _openResult(top),
      ));
    }

    final quickActions = _controller.quickActions;
    if (quickActions.isNotEmpty) {
      children.add(SearchSectionHeader(
        icon: FFIcons.kbolt,
        title: 'Quick actions',
        trailingLabel:
            '${quickActions.length} action${quickActions.length == 1 ? '' : 's'}',
      ));
      children.add(QuickActionsGrid(
        actions: quickActions,
        onActionTap: (action) => _controller.setFilter(action.targetFilter),
      ));
    }

    _controller.groupedSections.forEach((section, rows) {
      final total = _controller.sectionTotal(section);
      children.add(SearchSectionHeader(
        icon: section.icon,
        title: section.sectionTitle,
        trailingLabel: total > rows.length ? 'View all $total' : null,
        onTrailingTap:
            total > rows.length ? () => _controller.setFilter(section) : null,
      ));
      children.add(Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            for (final row in rows)
              SearchResultCard(
                result: row,
                query: query,
                onTap: () => _openResult(row),
              ),
          ],
        ),
      ));
    });

    return children;
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFFCFBF9),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0x1A111827)),
              ),
              child: const Icon(
                FFIcons.karrowLeft,
                size: 19,
                color: Color(0xFF111827),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Search',
              style: GoogleFonts.instrumentSerif(
                fontSize: 28,
                fontWeight: FontWeight.w400,
                height: 1.02,
                letterSpacing: -0.84,
                color: const Color(0xFF111827),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
