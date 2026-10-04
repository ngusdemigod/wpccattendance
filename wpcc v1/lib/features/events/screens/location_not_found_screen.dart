import 'package:flutter/material.dart';

import '../../../flutter_flow/nav/nav.dart';
import '../../../shared/widgets/wpcc_shimmer.dart';
import '../data/events_repository.dart';
import '../models/event_flow_models.dart';
import '../widgets/event_flow_widgets.dart';
import 'clock_in_screen.dart';
import 'event_details_screen.dart';

class LocationNotFoundScreen extends StatefulWidget {
  const LocationNotFoundScreen({
    super.key,
    required this.eventId,
    this.reason,
    this.message,
  });

  static const String routeName = 'LiveLocationNotFound';
  static const String routePath = '/events/:eventId/location-not-found';

  final String eventId;
  final String? reason;
  final String? message;

  @override
  State<LocationNotFoundScreen> createState() => _LocationNotFoundScreenState();
}

class _LocationNotFoundScreenState extends State<LocationNotFoundScreen> {
  late final Future<EventDetailsData> _future =
      EventRepository().fetchEventDetails(widget.eventId);

  @override
  Widget build(BuildContext context) {
    final failureReason = EventCheckInFailureReasonX.fromQuery(widget.reason);
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
        return EventFlowScaffold(
          bottom: EventCtaButton(
            label: 'Start over',
            dark: true,
            onTap: () => context.goNamedAuth(
              EventDetailsScreen.routeName,
              mounted,
              pathParameters: {'eventId': widget.eventId},
            ),
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
              children: [
                _HeaderBack(onTap: () => Navigator.of(context).maybePop()),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.fromLTRB(18, 28, 18, 24),
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
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1EADD),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFF1EADD).withValues(alpha: 0.7),
                              blurRadius: 0,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.location_off_rounded,
                          size: 38,
                          color: Color(0xFF111113),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        failureReason.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Instrument Serif',
                          fontSize: 29,
                          height: 1.04,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        (widget.message?.trim().isNotEmpty == true
                                ? widget.message!.trim()
                                : failureReason.message)
                            .replaceAll('You are ', 'We could not verify that your device is ')
                            .replaceAll('m away from the attendance point.', 'away from the attendance point.'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Instrument Sans',
                          fontSize: 12,
                          height: 1.5,
                          color: Color(0xFF4B5563),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                EventMiniCard(
                  event: details.event,
                  statusLabel: 'Closed',
                  actionLabel: 'Retry',
                  onActionTap: () => context.goNamedAuth(
                    ClockInScreen.routeName,
                    mounted,
                    pathParameters: {'eventId': widget.eventId},
                  ),
                ),
                const SizedBox(height: 14),
                EventDetailListCard(
                  rows: [
                    MapEntry('Expected location', details.event.locationName),
                    const MapEntry(
                      'Attendance point',
                      'Wisdom Power Christian Centre',
                    ),
                    MapEntry('Status', failureReason.statusLabel),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCFBF9),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: const Color.fromRGBO(17, 24, 39, 0.10),
                    ),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 13,
                            backgroundColor: Color(0xFFF1EADD),
                            child: Icon(
                              Icons.info_outline_rounded,
                              size: 15,
                              color: Color(0xFF111113),
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Before you try again',
                            style: TextStyle(
                              fontFamily: 'Instrument Sans',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF111827),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Make sure location permission is enabled, GPS is turned on, and you are physically within the church attendance area.',
                        style: TextStyle(
                          fontFamily: 'Instrument Sans',
                          fontSize: 11,
                          height: 1.5,
                          color: Color(0xFF4B5563),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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
