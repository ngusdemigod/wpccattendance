import 'package:flutter/material.dart';

import 'profile_feature_service.dart';
import 'profile_query_screen.dart';
import 'profile_ui_kit.dart';

class ProfileClassesScreen extends StatefulWidget {
  const ProfileClassesScreen({super.key});

  @override
  State<ProfileClassesScreen> createState() => _ProfileClassesScreenState();
}

class _ProfileClassesScreenState extends State<ProfileClassesScreen> {
  final ProfileFeatureService _service = ProfileFeatureService();
  late Future<ProfileClassesPayload> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.getUserClasses();
  }

  void _retry() {
    setState(() {
      _future = _service.getUserClasses();
    });
  }

  void _handleBack() {
    Navigator.of(context).maybePop();
  }

  void _handleTab(ProfileRouteTab tab) {
    switch (tab) {
      case ProfileRouteTab.overview:
        Navigator.of(context).maybePop();
        break;
      case ProfileRouteTab.classes:
        break;
      case ProfileRouteTab.query:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ProfileQueryScreen()),
        );
        break;
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
            ProfileSubpageHeader(title: 'Classes', onBack: _handleBack),
            ProfileRouteTabs(
              activeTab: ProfileRouteTab.classes,
              onSelected: _handleTab,
            ),
            Expanded(
              child: FutureBuilder<ProfileClassesPayload>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const ProfileLoadingList(includeStats: true);
                  }

                  if (snapshot.hasError) {
                    return ListView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                      children: [
                        ProfileRetryCard(
                          title: 'Unable to load classes',
                          message:
                              'The classes data could not be fetched right now. Retry after confirming the scoped profile read models migration has been applied.',
                          onRetry: _retry,
                        ),
                      ],
                    );
                  }

                  final payload = snapshot.data;
                  if (payload == null) {
                    return ListView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                      children: [
                        ProfileRetryCard(
                          title: 'Classes unavailable',
                          message:
                              'No class data was returned for this profile.',
                          onRetry: _retry,
                        ),
                      ],
                    );
                  }

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              value: payload.summary.completedCount.toString(),
                              label: 'Completed',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _StatCard(
                              value: payload.summary.inProgressCount.toString(),
                              label: 'In progress',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _StatCard(
                              value: payload.summary.dueSoonCount.toString(),
                              label: 'Due soon',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (payload.items.isEmpty)
                        const ProfileEmptyCard(
                          title: 'No classes assigned',
                          message:
                              'This account does not have any class assignments yet. Assign classes from the database to populate this screen.',
                        )
                      else
                        ...payload.items.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _ClassCard(item: item),
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

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ProfileSurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: profileSans(size: 18, weight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: profileSans(size: 10, color: const Color(0xFF8A8F98)),
          ),
        ],
      ),
    );
  }
}

class _ClassCard extends StatelessWidget {
  const _ClassCard({
    required this.item,
  });

  final ProfileClassItem item;

  @override
  Widget build(BuildContext context) {
    final badge = _classBadge(item.status);
    final iconSpec = _iconSpec(item);
    final metaParts = <String>[
      if (item.moduleIndex != null && item.moduleTotal != null)
        'Module ${item.moduleIndex} of ${item.moduleTotal}',
      if (item.description.isNotEmpty) item.description,
    ];
    final footerLeft =
        item.certificateAvailable ? 'Certificate available' : _footerText(item);
    var buttonLabel = 'Open';
    if (item.status == 'completed') {
      buttonLabel = 'View';
    } else if (item.status == 'in_progress') {
      buttonLabel = 'Continue';
    }

    return ProfileSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconSpec.backgroundColor,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Icon(iconSpec.icon, size: 19, color: iconSpec.iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: profileSans(
                          size: 14, weight: FontWeight.w600, height: 1.25),
                    ),
                    if (metaParts.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        metaParts.join(' - '),
                        style: profileSans(
                          size: 11,
                          color: const Color(0xFF4B5563),
                          height: 1.45,
                        ),
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
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                'Progress',
                style: profileSans(size: 10, color: const Color(0xFF8A8F98)),
              ),
              const Spacer(),
              Text(
                '${item.progressPercent}%',
                style: profileSans(size: 10, color: const Color(0xFF8A8F98)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 6,
              value: item.progressPercent / 100,
              backgroundColor: const Color(0xFFF7F5EF),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFF111113)),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  footerLeft,
                  style: profileSans(
                    size: 11,
                    color: footerLeft == 'Certificate available'
                        ? const Color(0xFF8A8F98)
                        : const Color(0xFF8A8F98),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Disabled until a real class detail or action route exists.
              ProfilePillButton(
                label: buttonLabel,
                onPressed: null,
                backgroundColor: const Color(0xFFD600B8),
                foregroundColor: Colors.white,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _footerText(ProfileClassItem item) {
    final dueLabel = _formatMonthDay(item.dueAt);
    final lessons = item.remainingLessons;
    if (dueLabel != null && lessons != null) {
      return 'Due $dueLabel - $lessons lessons left';
    }
    if (dueLabel != null) {
      return 'Due $dueLabel';
    }
    if (lessons != null) {
      return '$lessons lessons left';
    }
    return 'No due date';
  }
}

class _BadgeSpec {
  const _BadgeSpec({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;
}

class _IconSpec {
  const _IconSpec({
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
  });

  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
}

_BadgeSpec _classBadge(String status) {
  switch (status) {
    case 'completed':
      return const _BadgeSpec(
        label: 'Completed',
        backgroundColor: Color(0xFFE3F5E9),
        textColor: Color(0xFF1A6B35),
      );
    case 'in_progress':
    case 'pending':
      return const _BadgeSpec(
        label: 'In progress',
        backgroundColor: Color(0xFFE3F5E9),
        textColor: Color(0xFF1A6B35),
      );
    default:
      return const _BadgeSpec(
        label: 'In progress',
        backgroundColor: Color(0xFFE3F5E9),
        textColor: Color(0xFF1A6B35),
      );
  }
}

_IconSpec _iconSpec(ProfileClassItem item) {
  final key = '${item.iconKey ?? ''} ${item.category ?? ''} ${item.title}'
      .toLowerCase();
  if (key.contains('media') || key.contains('video') || key.contains('audio')) {
    return const _IconSpec(
      icon: Icons.mic_none_rounded,
      backgroundColor: Color(0xFFE4F0FB),
      iconColor: Color(0xFF111827),
    );
  }
  if (key.contains('orientation') || key.contains('discipleship')) {
    return const _IconSpec(
      icon: Icons.menu_book_outlined,
      backgroundColor: Color(0xFFF2F4F7),
      iconColor: Color(0xFF111827),
    );
  }
  if (key.contains('certificate') || key.contains('refresh')) {
    return const _IconSpec(
      icon: Icons.perm_device_information_outlined,
      backgroundColor: Color(0xFFE4F0FB),
      iconColor: Color(0xFF111827),
    );
  }
  return const _IconSpec(
    icon: Icons.menu_book_outlined,
    backgroundColor: Color(0xFFF2F4F7),
    iconColor: Color(0xFF111827),
  );
}

String? _formatMonthDay(DateTime? value) {
  if (value == null) {
    return null;
  }

  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[value.month - 1]} ${value.day}';
}
