import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/app_images.dart';
import 'departments_models.dart';
import 'departments_service.dart';
import 'widgets/attendance_members_popup.dart';
import 'widgets/department_avatar.dart';
import 'widgets/member_profile_popup.dart';

/// Department Detail: dark hero header with Overview / Members /
/// Attendance / Files tabs. All values come from Supabase.
class DepartmentDetailScreen extends StatefulWidget {
  const DepartmentDetailScreen({
    super.key,
    required this.departmentId,
    required this.departmentName,
  });

  final String departmentId;
  final String departmentName;

  @override
  State<DepartmentDetailScreen> createState() => _DepartmentDetailScreenState();
}

class _DepartmentDetailScreenState extends State<DepartmentDetailScreen> {
  final DepartmentsService _service = DepartmentsService();

  late Future<DepartmentDetailData?> _detailFuture;
  Future<List<DepartmentMember>>? _membersFuture;
  Future<List<DepartmentPastEvent>>? _eventsFuture;
  Future<List<AttendanceRankEntry>>? _rankingsFuture;

  int _tab = 0;

  static const _tabLabels = ['Overview', 'Members', 'Attendance', 'Files'];

  @override
  void initState() {
    super.initState();
    _detailFuture = _service.fetchDepartmentDetail(widget.departmentId);
  }

  Future<List<DepartmentMember>> _membersOnce() =>
      _membersFuture ??= _service.fetchMembers(widget.departmentId);

  Future<List<DepartmentPastEvent>> _eventsOnce() =>
      _eventsFuture ??= _service.fetchPastEvents(widget.departmentId);

  Future<List<AttendanceRankEntry>> _rankingsOnce(int pastEvents) =>
      _rankingsFuture ??=
          _service.fetchAttendanceRankings(widget.departmentId, pastEvents);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder<DepartmentDetailData?>(
        future: _detailFuture,
        builder: (context, snapshot) {
          final detail = snapshot.data;
          final loading = snapshot.connectionState == ConnectionState.waiting;
          return Column(
            children: [
              _DepartmentHeader(
                name: detail?.name ?? widget.departmentName,
                description: detail?.description,
                memberCount: detail?.memberCount,
                activeEvents: detail?.activeEvents,
                pastEvents: detail?.pastEvents,
              ),
              _TabStrip(
                labels: _tabLabels,
                active: _tab,
                onChanged: (index) => setState(() => _tab = index),
              ),
              Expanded(
                child: loading && detail == null
                    ? const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF111827),
                        ),
                      )
                    : snapshot.hasError || detail == null
                        ? const _MessageCard(
                            icon: Icons.wifi_off_rounded,
                            title: 'Could not load department',
                            message:
                                'Check your connection and try again shortly.',
                          )
                        : _buildTabBody(detail),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTabBody(DepartmentDetailData detail) {
    switch (_tab) {
      case 0:
        return _OverviewTab(
          detail: detail,
          rankingsFuture: _rankingsOnce(detail.pastEvents),
        );
      case 1:
        return _MembersTab(
          detail: detail,
          membersFuture: _membersOnce(),
        );
      case 2:
        return _AttendanceTab(
          departmentId: detail.id,
          eventsFuture: _eventsOnce(),
        );
      default:
        return const _FilesTab();
    }
  }
}

// ─────────────────────────────────────────────────────────── header ──

class _DepartmentHeader extends StatelessWidget {
  const _DepartmentHeader({
    required this.name,
    this.description,
    this.memberCount,
    this.activeEvents,
    this.pastEvents,
  });

  final String name;
  final String? description;
  final int? memberCount;
  final int? activeEvents;
  final int? pastEvents;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, topPad + 14, 20, 22),
      decoration: const BoxDecoration(
        color: Color(0xFF111827),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(34)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _headerAction(
                context,
                Icons.chevron_left_rounded,
                onTap: () => Navigator.of(context).maybePop(),
              ),
              const Expanded(
                child: Text(
                  'Department',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.2,
                    color: Colors.white,
                  ),
                ),
              ),
              _headerAction(context, Icons.mode_comment_outlined, onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Department chat is coming soon.')),
                );
              }),
              const SizedBox(width: 8),
              _headerAction(context, Icons.more_vert_rounded, onTap: () {}),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: ClipOval(
                  child: Image.asset(
                    AppImages.wpccLogo,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.instrumentSerif(
                        fontSize: 21,
                        fontWeight: FontWeight.w400,
                        height: 1.12,
                        color: Colors.white,
                        letterSpacing: -0.4,
                      ),
                    ),
                    if ((description ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        description!.trim(),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.35,
                          color: Colors.white.withValues(alpha: 0.72),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _stat('Members', memberCount),
              const SizedBox(width: 8),
              _stat('Active events', activeEvents),
              const SizedBox(width: 8),
              _stat('Past events', pastEvents),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerAction(
    BuildContext context,
    IconData icon, {
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF374151)),
        ),
        child: Icon(icon, size: 19, color: Colors.white),
      ),
    );
  }

  Widget _stat(String label, int? value) {
    return Expanded(
      child: Container(
        constraints: const BoxConstraints(minHeight: 62),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1F2937),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: const Color(0xFF374151)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value?.toString() ?? '—',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w400,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w400,
                color: Colors.white.withValues(alpha: 0.72),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────── tabs ──

class _TabStrip extends StatelessWidget {
  const _TabStrip({
    required this.labels,
    required this.active,
    required this.onChanged,
  });

  final List<String> labels;
  final int active;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: List.generate(labels.length, (index) {
            final selected = index == active;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => onChanged(index),
                child: Container(
                  height: 30,
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? const Color(0xFF111113) : Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: selected
                          ? const Color(0xFF111113)
                          : const Color(0x24111827),
                    ),
                  ),
                  child: Text(
                    labels[index],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : const Color(0xFF374151),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────── overview ──

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.detail, required this.rankingsFuture});

  final DepartmentDetailData detail;
  final Future<List<AttendanceRankEntry>> rankingsFuture;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        const _SectionTitle('Leadership'),
        SizedBox(
          height: 70,
          child: detail.leaders.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'No active leaders recorded for this department.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                    ),
                  ),
                )
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: detail.leaders.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final leader = detail.leaders[index];
                    return Container(
                      constraints: const BoxConstraints(minWidth: 150),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFCFBF9),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0x14111827)),
                      ),
                      child: Row(
                        children: [
                          DepartmentAvatar(
                            name: leader.fullName,
                            avatarUrl: leader.avatarUrl,
                            size: 42,
                          ),
                          const SizedBox(width: 10),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                leader.fullName,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFF111827),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                leader.roleTitle,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFF8A8F98),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        const _SectionTitle('Department account'),
        const _ComingSoonAccountCard(),
        const _SectionTitle('Attendance rankings'),
        _RankingsCard(rankingsFuture: rankingsFuture),
      ],
    );
  }
}

class _ComingSoonAccountCard extends StatelessWidget {
  const _ComingSoonAccountCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Departmental account',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Department wallets and account details are on the way.',
                  style: TextStyle(fontSize: 11, color: Color(0xB3FFFFFF)),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF111113),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'Coming soon',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w400,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RankingsCard extends StatelessWidget {
  const _RankingsCard({required this.rankingsFuture});

  final Future<List<AttendanceRankEntry>> rankingsFuture;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFBF9),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0x14111827)),
      ),
      child: FutureBuilder<List<AttendanceRankEntry>>(
        future: rankingsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF111827),
                ),
              ),
            );
          }
          final entries = snapshot.data ?? const [];
          if (snapshot.hasError || entries.isEmpty) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 22),
              child: Center(
                child: Text(
                  'No attendance records yet for this department.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                ),
              ),
            );
          }
          return Column(
            children: List.generate(entries.length, (index) {
              final entry = entries[index];
              return Column(
                children: [
                  if (index > 0)
                    const Divider(height: 1, color: Color(0x0F111827)),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: index < 3
                                ? const Color(0xFFF1EADD)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: const Color(0x14111827)),
                          ),
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF111827),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        DepartmentAvatar(
                          name: entry.fullName,
                          avatarUrl: entry.avatarUrl,
                          size: 34,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                index == 0
                                    ? '${entry.fullName} 🔥'
                                    : entry.fullName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFF111827),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${entry.attendedCount} event${entry.attendedCount == 1 ? '' : 's'} attended',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF8A8F98),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${entry.scorePercent}%',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF111827),
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Rank score',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF8A8F98),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }),
          );
        },
      ),
    );
  }
}

// ───────────────────────────────────────────────────────── members ──

class _MembersTab extends StatelessWidget {
  const _MembersTab({required this.detail, required this.membersFuture});

  final DepartmentDetailData detail;
  final Future<List<DepartmentMember>> membersFuture;

  void _openMember(BuildContext context, DepartmentMember member) {
    showMemberProfilePopup(
      context,
      member: member,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<DepartmentMember>>(
      future: membersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF111827),
            ),
          );
        }
        if (snapshot.hasError) {
          return const _MessageCard(
            icon: Icons.wifi_off_rounded,
            title: 'Could not load members',
            message: 'Check your connection and try again shortly.',
          );
        }
        final members = snapshot.data ?? const [];
        if (members.isEmpty) {
          return const _MessageCard(
            icon: Icons.groups_outlined,
            title: 'No members yet',
            message: 'Members of this department will appear here.',
          );
        }

        final leaderIds = detail.leaders.map((leader) => leader.userId).toSet();
        final memberById = {
          for (final member in members) member.userId: member,
        };
        final plainMembers = members
            .where((member) => !leaderIds.contains(member.userId))
            .toList();

        return ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
          children: [
            const Text(
              'Departmental leaders',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                height: 18 / 15,
                letterSpacing: -0.5,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 10),
            if (detail.leaders.isNotEmpty)
              _LeadersCard(
                leaders: detail.leaders,
                onTapLeader: (leader) {
                  final member = memberById[leader.userId] ??
                      DepartmentMember(
                        userId: leader.userId,
                        fullName: leader.fullName,
                        avatarUrl: leader.avatarUrl,
                        departmentName: detail.name,
                        roleTitle: leader.roleTitle,
                      );
                  _openMember(context, member);
                },
              )
            else
              const Text(
                'No active leaders recorded for this department.',
                style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
            const SizedBox(height: 22),
            const Text(
              'Members',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                height: 18 / 15,
                letterSpacing: -0.5,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 14),
            _MembersGrid(
              members: plainMembers,
              onTap: (member) => _openMember(context, member),
            ),
          ],
        );
      },
    );
  }
}

class _LeadersCard extends StatelessWidget {
  const _LeadersCard({required this.leaders, required this.onTapLeader});

  final List<DepartmentLeader> leaders;
  final ValueChanged<DepartmentLeader> onTapLeader;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFFBEAF4),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: const Color(0xFFF4C7DE)),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -26,
              right: -26,
              child: Container(
                width: 88,
                height: 88,
                decoration: const BoxDecoration(
                  color: Color(0xFFF1C5E4),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.78),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'DEPARTMENTAL LEADERS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.6,
                        color: Color(0xFFB10F8F),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: leaders.take(4).map((leader) {
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => onTapLeader(leader),
                          behavior: HitTestBehavior.opaque,
                          child: Column(
                            children: [
                              DepartmentAvatar(
                                name: leader.fullName,
                                avatarUrl: leader.avatarUrl,
                                size: 56,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                leader.fullName.split(' ').first,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFF111827),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                leader.roleTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF8A8F98),
                                ),
                              ),
                            ],
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
}

class _MembersGrid extends StatelessWidget {
  const _MembersGrid({required this.members, required this.onTap});

  final List<DepartmentMember> members;
  final ValueChanged<DepartmentMember> onTap;

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) {
      return const Text(
        'No other members yet.',
        style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 16,
        crossAxisSpacing: 10,
        childAspectRatio: 0.72,
      ),
      itemCount: members.length,
      itemBuilder: (context, index) {
        final member = members[index];
        final secondLine = member.lastName?.trim().isNotEmpty == true
            ? member.lastName!.trim()
            : (member.roleTitle ?? 'Member');
        return GestureDetector(
          onTap: () => onTap(member),
          behavior: HitTestBehavior.opaque,
          child: Column(
            children: [
              DepartmentAvatar(
                name: member.fullName,
                avatarUrl: member.avatarUrl,
                size: 56,
              ),
              const SizedBox(height: 6),
              Text(
                member.firstName?.trim().isNotEmpty == true
                    ? member.firstName!.trim()
                    : member.fullName.split(' ').first,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                secondLine,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF8A8F98),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ────────────────────────────────────────────────────── attendance ──

class _AttendanceTab extends StatelessWidget {
  const _AttendanceTab({
    required this.departmentId,
    required this.eventsFuture,
  });

  final String departmentId;
  final Future<List<DepartmentPastEvent>> eventsFuture;

  String _dateLabel(DateTime? date) {
    if (date == null) {
      return '';
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
    final local = date.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';
    return '${local.day} ${months[local.month - 1]} ${local.year} · $hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<DepartmentPastEvent>>(
      future: eventsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF111827),
            ),
          );
        }
        if (snapshot.hasError) {
          return const _MessageCard(
            icon: Icons.wifi_off_rounded,
            title: 'Could not load events',
            message: 'Check your connection and try again shortly.',
          );
        }
        final events = snapshot.data ?? const [];
        if (events.isEmpty) {
          return const _MessageCard(
            icon: Icons.event_busy_outlined,
            title: 'No past events',
            message: 'Past departmental and global events will appear here.',
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 18, 20, 2),
              child: Text(
                'Past events',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  height: 18 / 15,
                  letterSpacing: -0.5,
                  color: Color(0xFF111827),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index];
                  final isGlobal = event.scope == DepartmentEventScope.global;
                  return GestureDetector(
                    onTap: () => showAttendanceMembersPopup(
                      context,
                      event: event,
                      departmentId: departmentId,
                    ),
                    child: Container(
                      margin: const EdgeInsets.only(top: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFCFBF9),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: const Color(0x14111827)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  event.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: isGlobal
                                      ? const Color(0xFFF1EADD)
                                      : const Color(0xFFE4F0FB),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  isGlobal ? 'Global' : 'Departmental',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w400,
                                    color: isGlobal
                                        ? const Color(0xFF111827)
                                        : const Color(0xFF1A4F82),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            [
                              _dateLabel(event.startAt),
                              if ((event.location ?? '').trim().isNotEmpty)
                                event.location!.trim(),
                            ].where((part) => part.isNotEmpty).join(' · '),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(Icons.how_to_reg_outlined,
                                  size: 15, color: Color(0xFF4B5563)),
                              const SizedBox(width: 6),
                              Text(
                                '${event.presentCount} present',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFF4B5563),
                                ),
                              ),
                              const Spacer(),
                              const Icon(Icons.chevron_right_rounded,
                                  size: 18, color: Color(0xFF8A8F98)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────── files ──

class _FilesTab extends StatelessWidget {
  const _FilesTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFFFCFBF9),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: const Color(0x14111827)),
          ),
          child: Column(
            children: [
              Container(
                width: 66,
                height: 66,
                decoration: const BoxDecoration(
                  color: Color(0xFFF1EADD),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.folder_outlined,
                  size: 32,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Department files',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Shared media files for this department are coming soon.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF111113),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Coming soon',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────── shared ──

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w400,
          letterSpacing: 1.1,
          color: Color(0xFF8A8F98),
        ),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      children: [
        Container(
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
        ),
      ],
    );
  }
}
