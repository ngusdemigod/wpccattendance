import 'package:flutter/material.dart';

import 'profile_classes_screen.dart';
import 'profile_feature_service.dart';
import 'profile_query_detail_screen.dart';
import 'profile_ui_kit.dart';

class ProfileQueryScreen extends StatefulWidget {
  const ProfileQueryScreen({super.key});

  @override
  State<ProfileQueryScreen> createState() => _ProfileQueryScreenState();
}

class _ProfileQueryScreenState extends State<ProfileQueryScreen> {
  final ProfileFeatureService _service = ProfileFeatureService();
  ProfileQueryFilter _activeFilter = ProfileQueryFilter.overview;
  late Future<List<ProfileQueryItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.getUserQueries(_activeFilter);
  }

  void _reload() {
    setState(() {
      _future = _service.getUserQueries(_activeFilter);
    });
  }

  void _setFilter(ProfileQueryFilter filter) {
    if (_activeFilter == filter) {
      return;
    }
    setState(() {
      _activeFilter = filter;
      _future = _service.getUserQueries(filter);
    });
  }

  void _handleRouteTab(ProfileRouteTab tab) {
    switch (tab) {
      case ProfileRouteTab.overview:
        Navigator.of(context).maybePop();
        break;
      case ProfileRouteTab.classes:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ProfileClassesScreen()),
        );
        break;
      case ProfileRouteTab.query:
        break;
    }
  }

  Future<void> _acknowledge(ProfileQueryItem item) async {
    await _service.acknowledgeQuery(item.id);
    if (!mounted) {
      return;
    }
    _reload();
  }

  Future<void> _respond(ProfileQueryItem item) async {
    final responseText = await showQueryResponseSheet(context);
    if (responseText == null || responseText.trim().isEmpty) {
      return;
    }

    await _service.submitQueryResponse(item.id, responseText);
    if (!mounted) {
      return;
    }
    _reload();
  }

  void _openDetails(ProfileQueryItem item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProfileQueryDetailScreen(queryId: item.id),
      ),
    );
  }

  String _emptyMessage() {
    switch (_activeFilter) {
      case ProfileQueryFilter.overview:
        return 'No query records exist for this worker yet.';
      case ProfileQueryFilter.resolved:
        return 'No resolved query records were found.';
      case ProfileQueryFilter.needsAttention:
        return 'There are no query records that currently need action.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            ProfileSubpageHeader(
              title: 'Query',
              onBack: () => Navigator.of(context).maybePop(),
            ),
            ProfileRouteTabs(
              activeTab: ProfileRouteTab.query,
              onSelected: _handleRouteTab,
            ),
            QueryFilterTabs(
              activeFilter: _activeFilter,
              onSelected: _setFilter,
            ),
            Expanded(
              child: FutureBuilder<List<ProfileQueryItem>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const ProfileLoadingList(itemCount: 3);
                  }

                  if (snapshot.hasError) {
                    return ListView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                      children: [
                        ProfileRetryCard(
                          title: 'Unable to load queries',
                          message:
                              'The query data could not be fetched. Confirm the scoped profile read models migration has been applied and retry.',
                          onRetry: _reload,
                        ),
                      ],
                    );
                  }

                  final items = snapshot.data ?? const <ProfileQueryItem>[];
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                    children: [
                      if (items.isEmpty)
                        ProfileEmptyCard(
                          title: 'No query records',
                          message: _emptyMessage(),
                        )
                      else
                        ...items.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _QueryCard(
                              item: item,
                              onAcknowledge: item.requiresAcknowledgement &&
                                      item.acknowledgedAt == null
                                  ? () => _acknowledge(item)
                                  : null,
                              onRespond: item.requiresResponse
                                  ? () => _respond(item)
                                  : null,
                              onViewDetails: () => _openDetails(item),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QueryCard extends StatelessWidget {
  const _QueryCard({
    required this.item,
    required this.onAcknowledge,
    required this.onRespond,
    required this.onViewDetails,
  });

  final ProfileQueryItem item;
  final VoidCallback? onAcknowledge;
  final VoidCallback? onRespond;
  final VoidCallback onViewDetails;

  @override
  Widget build(BuildContext context) {
    final badge = queryBadge(item.status);
    final escalation = queryEscalationLabel(item);
    return ProfileSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: queryIconBackground(item.status),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Icon(
                  queryIcon(item.status),
                  size: 18,
                  color: const Color(0xFF111827),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: profileSans(size: 14, weight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    if ((item.raisedByName ?? '').isNotEmpty)
                      Text(
                        'Raised by ${item.raisedByName}${(item.raisedByDepartment ?? '').isNotEmpty ? ', ${item.raisedByDepartment}' : ''}',
                        style: profileSans(
                            size: 12,
                            color: const Color(0xFF4B5563),
                            height: 1.45),
                      ),
                    if (escalation != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        escalation,
                        style: profileSans(
                            size: 11, color: const Color(0xFFC77700)),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ProfileStatusBadge(
                label: badge.label,
                backgroundColor: badge.backgroundColor,
                textColor: badge.textColor,
              ),
            ],
          ),
          const SizedBox(height: 14),
          ProfileSurfaceCard(
            radius: 24,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Report details',
                  style: profileSans(size: 14, weight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                Text(
                  item.details,
                  style: profileSans(
                    size: 12,
                    color: const Color(0xFF4B5563),
                    height: 1.5,
                  ),
                ),
                if (onAcknowledge != null || onRespond != null) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      if (onAcknowledge != null)
                        ProfilePillButton(
                          label: 'Acknowledge',
                          onPressed: onAcknowledge,
                          backgroundColor: const Color(0xFF111113),
                          foregroundColor: Colors.white,
                        ),
                      if (onAcknowledge != null && onRespond != null)
                        const SizedBox(width: 10),
                      if (onRespond != null)
                        ProfilePillButton(
                          label: 'Submit response',
                          onPressed: onRespond,
                          outlined: true,
                          foregroundColor: const Color(0xFF111827),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  queryTimelineLabel(item),
                  style: profileSans(size: 11, color: const Color(0xFF8A8F98)),
                ),
              ),
              const SizedBox(width: 12),
              ProfilePillButton(
                label: 'View details',
                onPressed: onViewDetails,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
