import 'package:flutter/material.dart';

import 'profile_feature_service.dart';
import 'profile_ui_kit.dart';

class ProfileQueryDetailScreen extends StatefulWidget {
  const ProfileQueryDetailScreen({
    super.key,
    required this.queryId,
  });

  final String queryId;

  @override
  State<ProfileQueryDetailScreen> createState() =>
      _ProfileQueryDetailScreenState();
}

class _ProfileQueryDetailScreenState extends State<ProfileQueryDetailScreen> {
  final ProfileFeatureService _service = ProfileFeatureService();
  late Future<ProfileQueryItem?> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.getQueryDetails(widget.queryId);
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _service.getQueryDetails(widget.queryId);
    });
    await _future;
  }

  Future<void> _acknowledge() async {
    await _service.acknowledgeQuery(widget.queryId);
    if (!mounted) {
      return;
    }
    await _refresh();
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
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: FutureBuilder<ProfileQueryItem?>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Column(
                children: [
                  ProfileSubpageHeader(
                    title: 'Query',
                    onBack: () => Navigator.of(context).maybePop(),
                  ),
                  const Expanded(child: ProfileLoadingList(itemCount: 1)),
                ],
              );
            }

            return Column(
              children: [
                ProfileSubpageHeader(
                  title: 'Query',
                  onBack: () => Navigator.of(context).maybePop(),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                    children: [
                      if (snapshot.hasError)
                        ProfileRetryCard(
                          title: 'Unable to load query',
                          message: 'The query detail could not be loaded.',
                          onRetry: _refresh,
                        )
                      else if (snapshot.data == null)
                        const ProfileEmptyCard(
                          title: 'Query not found',
                          message:
                              'This query no longer exists or is not available to this account.',
                        )
                      else
                        _QueryDetailCard(
                          item: snapshot.data!,
                          onAcknowledge:
                              snapshot.data!.requiresAcknowledgement &&
                                      snapshot.data!.acknowledgedAt == null
                                  ? _acknowledge
                                  : null,
                          onRespond: snapshot.data!.requiresResponse
                              ? () => _respond(snapshot.data!)
                              : null,
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _QueryDetailCard extends StatelessWidget {
  const _QueryDetailCard({
    required this.item,
    required this.onAcknowledge,
    required this.onRespond,
  });

  final ProfileQueryItem item;
  final VoidCallback? onAcknowledge;
  final VoidCallback? onRespond;

  @override
  Widget build(BuildContext context) {
    final badge = queryBadge(item.status);
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
                      style: profileSans(size: 18, weight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    if ((item.raisedByName ?? '').isNotEmpty)
                      Text(
                        'Raised by ${item.raisedByName}${(item.raisedByDepartment ?? '').isNotEmpty ? ', ${item.raisedByDepartment}' : ''}',
                        style: profileSans(
                            size: 12, color: const Color(0xFF4B5563)),
                      ),
                    if (queryEscalationLabel(item) != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        queryEscalationLabel(item)!,
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
          const SizedBox(height: 18),
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
                      size: 12, color: const Color(0xFF4B5563), height: 1.55),
                ),
                if ((item.responseText ?? '').isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Your response',
                    style: profileSans(size: 12, weight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.responseText!,
                    style: profileSans(
                        size: 12, color: const Color(0xFF4B5563), height: 1.55),
                  ),
                ],
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
          const SizedBox(height: 18),
          Text(
            queryTimelineLabel(item),
            style: profileSans(size: 11, color: const Color(0xFF8A8F98)),
          ),
        ],
      ),
    );
  }
}

Future<String?> showQueryResponseSheet(BuildContext context) async {
  final controller = TextEditingController();
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFFFCFBF9),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
    ),
    builder: (context) {
      final bottomInset = MediaQuery.of(context).viewInsets.bottom;
      return Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, bottomInset + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Submit response',
                style: profileSans(size: 16, weight: FontWeight.w600)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Enter your response',
                hintStyle:
                    profileSans(size: 12, color: const Color(0xFF8A8F98)),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.all(16),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: const BorderSide(color: Color(0x14111827)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: const BorderSide(color: Color(0xFF111113)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ProfilePillButton(
                    label: 'Cancel',
                    onPressed: () => Navigator.of(context).pop(),
                    outlined: true,
                    foregroundColor: const Color(0xFF111827),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ProfilePillButton(
                    label: 'Submit',
                    onPressed: () => Navigator.of(context).pop(controller.text),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}

class QueryBadgeSpec {
  const QueryBadgeSpec({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;
}

QueryBadgeSpec queryBadge(String status) {
  switch (status) {
    case 'resolved':
      return const QueryBadgeSpec(
        label: 'Resolved',
        backgroundColor: Color(0xFFE3F5E9),
        textColor: Color(0xFF1A6B35),
      );
    case 'escalated':
      return const QueryBadgeSpec(
        label: 'Escalated',
        backgroundColor: Color(0xFFF4E2AF),
        textColor: Color(0xFF7C5609),
      );
    default:
      return const QueryBadgeSpec(
        label: 'Awaiting response',
        backgroundColor: Color(0xFFF3F4F6),
        textColor: Color(0xFF374151),
      );
  }
}

IconData queryIcon(String status) {
  switch (status) {
    case 'resolved':
      return Icons.check_circle_outline_rounded;
    case 'escalated':
      return Icons.chat_bubble_outline_rounded;
    default:
      return Icons.info_outline_rounded;
  }
}

Color queryIconBackground(String status) {
  switch (status) {
    case 'resolved':
      return const Color(0xFFE3F5E9);
    case 'escalated':
      return const Color(0xFFF4E2AF);
    default:
      return const Color(0xFFF2F4F7);
  }
}

String? queryEscalationLabel(ProfileQueryItem item) {
  if (item.status == 'resolved' || item.escalatesAt == null) {
    return null;
  }

  final now = DateTime.now();
  final duration = item.escalatesAt!.difference(now);
  if (duration.isNegative) {
    return 'Escalated';
  }
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  final seconds = duration.inSeconds.remainder(60);
  return 'Escalation in ${hours}hrs ${minutes}min ${seconds}sec';
}

String queryTimelineLabel(ProfileQueryItem item) {
  final opened = _formatMonthDay(item.openedAt);
  final updated = _relativeUpdate(item.updatedAt ?? item.openedAt);
  if (item.status == 'resolved' && item.closedAt != null) {
    return 'Closed $opened - ${_relativeUpdate(item.closedAt)}';
  }
  if (opened != null && updated != null) {
    return 'Opened $opened - Last update $updated';
  }
  return 'Query activity available';
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

String? _relativeUpdate(DateTime? value) {
  if (value == null) {
    return null;
  }
  final difference = DateTime.now().difference(value);
  if (difference.inMinutes < 1) {
    return 'just now';
  }
  if (difference.inHours < 1) {
    return '${difference.inMinutes}m ago';
  }
  if (difference.inDays < 1) {
    return '${difference.inHours}h ago';
  }
  if (difference.inDays == 1) {
    return 'yesterday';
  }
  return '${difference.inDays}d ago';
}
