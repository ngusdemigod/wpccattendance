import 'package:flutter/material.dart';

import '../departments_models.dart';
import '../departments_service.dart';
import 'department_avatar.dart';

/// Bottom sheet listing members present at a past event, ranked by
/// clock-in time (earliest first).
Future<void> showAttendanceMembersPopup(
  BuildContext context, {
  required DepartmentPastEvent event,
  required String departmentId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x85111827),
    builder: (_) => _AttendanceMembersSheet(
      event: event,
      departmentId: departmentId,
    ),
  );
}

class _AttendanceMembersSheet extends StatefulWidget {
  const _AttendanceMembersSheet({
    required this.event,
    required this.departmentId,
  });

  final DepartmentPastEvent event;
  final String departmentId;

  @override
  State<_AttendanceMembersSheet> createState() =>
      _AttendanceMembersSheetState();
}

class _AttendanceMembersSheetState extends State<_AttendanceMembersSheet> {
  late final Future<List<EventAttendanceEntry>> _future;

  @override
  void initState() {
    super.initState();
    _future = DepartmentsService()
        .fetchEventAttendance(widget.event.id, widget.departmentId);
  }

  String get _dateLabel {
    final date = widget.event.startAt;
    if (date == null) {
      return '';
    }
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _timeLabel(DateTime? time) {
    if (time == null) {
      return '—';
    }
    final local = time.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.62,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (context, scroll) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFFCFBF9),
            borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0x22111827),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.event.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          [
                            _dateLabel,
                            '${widget.event.presentCount} present',
                          ].where((part) => part.isNotEmpty).join(' · '),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0x14111827)),
                      ),
                      child: const Icon(Icons.close_rounded,
                          size: 18, color: Color(0xFF111827)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Members present',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: FutureBuilder<List<EventAttendanceEntry>>(
                  future: _future,
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
                      return const Center(
                        child: Text(
                          'Could not load attendance for this event.',
                          style: TextStyle(
                              fontSize: 12, color: Color(0xFF6B7280)),
                        ),
                      );
                    }
                    final entries = snapshot.data ?? const [];
                    if (entries.isEmpty) {
                      return const Center(
                        child: Text(
                          'No attendance records for this event.',
                          style: TextStyle(
                              fontSize: 12, color: Color(0xFF6B7280)),
                        ),
                      );
                    }
                    return ListView.separated(
                      controller: scroll,
                      itemCount: entries.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, color: Color(0x0F111827)),
                      itemBuilder: (context, index) {
                        final entry = entries[index];
                        final topRank = index < 3;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: topRank
                                      ? const Color(0xFFF1EADD)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                      color: const Color(0x14111827)),
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
                                size: 38,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      entry.fullName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w400,
                                        color: Color(0xFF111827),
                                      ),
                                    ),
                                    if (entry.roleTitle != null) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        entry.roleTitle!,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF8A8F98),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _timeLabel(entry.clockedInAt),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFF4B5563),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
