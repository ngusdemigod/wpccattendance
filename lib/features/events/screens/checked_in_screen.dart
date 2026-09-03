import 'package:flutter/material.dart';

import '../../../shared/widgets/wpcc_shimmer.dart';
import '../data/events_repository.dart';
import '../models/event_flow_models.dart';
import '../widgets/event_flow_widgets.dart';

class CheckedInScreen extends StatefulWidget {
  const CheckedInScreen({
    super.key,
    required this.eventId,
    this.action,
  });

  static const String routeName = 'LiveCheckedIn';
  static const String routePath = '/events/:eventId/checked-in';

  final String eventId;
  final String? action;

  @override
  State<CheckedInScreen> createState() => _CheckedInScreenState();
}

class _CheckedInScreenState extends State<CheckedInScreen> {
  late final Future<EventDetailsData> _future =
      EventRepository().fetchEventDetails(widget.eventId);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<EventDetailsData>(
      future: _future,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: SafeArea(
              child: WpccScreenShimmer(includeBottomNavSpace: false),
            ),
          );
        }

        final details = snapshot.data!;
        final attendance = details.currentAttendance;
        final requestedAction = EventAttendanceActionX.fromQuery(widget.action);
        final resolvedAction = attendance?.isCheckedIn == true
            ? EventAttendanceAction.clockIn
            : (attendance?.checkedOutAt != null
                ? EventAttendanceAction.clockOut
                : requestedAction);
        final actionTime = resolvedAction == EventAttendanceAction.clockOut
            ? attendance?.checkedOutAt
            : attendance?.checkedInAt;
        final statusText = resolvedAction == EventAttendanceAction.clockOut
            ? 'Attendance closed successfully'
            : 'Verified inside approved boundary';

        return EventFlowScaffold(
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              children: [
                _HeaderBack(onTap: () => Navigator.of(context).maybePop()),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.fromLTRB(18, 26, 18, 22),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCFBF9),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: const Color.fromRGBO(17, 24, 39, 0.10),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 82,
                        height: 82,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3F5E9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color:
                                  const Color(0xFFE3F5E9).withValues(alpha: 0.7),
                              blurRadius: 0,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          size: 40,
                          color: Color(0xFF1A6B35),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        resolvedAction.title,
                        style: const TextStyle(
                          fontFamily: 'Instrument Serif',
                          fontSize: 28,
                          height: 1.05,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF111113),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Clocked ${resolvedAction == EventAttendanceAction.clockOut ? 'out' : 'in'} at ${actionTime == null ? 'Unavailable' : _formatTime(actionTime)}',
                          style: const TextStyle(
                            fontFamily: 'Instrument Sans',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                EventMiniCard(
                  event: details.event,
                  statusLabel: resolvedAction.pastTenseLabel,
                ),
                const SizedBox(height: 14),
                EventDetailListCard(
                  rows: [
                    MapEntry('Location', details.event.locationName),
                    const MapEntry(
                      'Attendance point',
                      'Wisdom Power Christian Centre',
                    ),
                    MapEntry('Status', statusText),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatTime(DateTime value) {
    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    final suffix = value.hour >= 12 ? 'pm' : 'am';
    return '$hour:$minute$suffix';
  }
}

class _HeaderBack extends StatelessWidget {
  const _HeaderBack({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFFCFBF9),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color.fromRGBO(17, 24, 39, 0.10)),
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
        ),
      ),
    );
  }
}
