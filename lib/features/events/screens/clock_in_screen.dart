import 'package:flutter/material.dart';

import '../../../flutter_flow/nav/nav.dart';
import '../controllers/clock_in_controller.dart';
import '../data/location_verification_service.dart';
import '../models/event_flow_models.dart';
import '../widgets/event_flow_widgets.dart';
import 'checked_in_screen.dart';
import 'location_not_found_screen.dart';

class ClockInScreen extends StatefulWidget {
  const ClockInScreen({
    super.key,
    required this.eventId,
  });

  static const String routeName = 'LiveClockIn';
  static const String routePath = '/events/:eventId/clock-in';

  final String eventId;

  @override
  State<ClockInScreen> createState() => _ClockInScreenState();
}

class _ClockInScreenState extends State<ClockInScreen> {
  late final ClockInController _controller;
  bool _didNavigate = false;

  @override
  void initState() {
    super.initState();
    _controller = ClockInController(eventId: widget.eventId)
      ..addListener(_handleStateChange)
      ..start();
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_handleStateChange)
      ..dispose();
    super.dispose();
  }

  void _handleStateChange() {
    if (!mounted || _didNavigate || !_controller.state.isFinal) {
      return;
    }
    _didNavigate = true;
    final state = _controller.state;
    if (state.stage == ClockInStage.success) {
      context.goNamedAuth(
        CheckedInScreen.routeName,
        mounted,
        pathParameters: {'eventId': widget.eventId},
        queryParameters: {'action': state.action.queryValue},
      );
      return;
    }

    context.goNamedAuth(
      LocationNotFoundScreen.routeName,
      mounted,
      pathParameters: {'eventId': widget.eventId},
      queryParameters: {
        'reason': (state.failureReason ?? EventCheckInFailureReason.unknown)
            .queryValue,
        if ((state.failureMessage ?? '').trim().isNotEmpty)
          'message': state.failureMessage!.trim(),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final details = _controller.data;
        final event = details?.event;
        final isClockOut = _controller.state.action == EventAttendanceAction.clockOut;
        return Scaffold(
          backgroundColor: Colors.white,
          body: Stack(
            fit: StackFit.expand,
            children: [
              if (event != null)
                EventMapCard(
                  event: event,
                  userLatitude: _controller.state.userLatitude,
                  userLongitude: _controller.state.userLongitude,
                  height: double.infinity,
                )
              else
                Container(color: const Color(0xFFEEF1F4)),
              Container(color: Colors.white.withValues(alpha: 0.16)),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _BackButton(
                            onTap: () => Navigator.of(context).maybePop(),
                          ),
                          const SizedBox(width: 10),
                          if (event != null)
                            Expanded(
                              child: EventMiniCard(
                                event: event,
                                statusLabel: _statusLabel(details),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF111113),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFD600B8),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _stageLabel(_controller.state),
                                style: const TextStyle(
                                  fontFamily: 'Instrument Sans',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Spacer(),
                      _RadarTarget(label: event?.locationName ?? 'Attendance point'),
                      const Spacer(),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFCFBF9),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: const Color.fromRGBO(17, 24, 39, 0.10),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isClockOut ? 'Check-out rules' : 'Clock-in rules',
                              style: const TextStyle(
                                fontFamily: 'Instrument Sans',
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF111827),
                              ),
                            ),
                            const SizedBox(height: 14),
                            _RuleRow(
                              title: 'Allow location permission',
                              body:
                                  'Enable GPS on your device so the app can validate your attendance point accurately.',
                              state: _controller.state.stage.index >=
                                      ClockInStage.gettingLocation.index
                                  ? _RuleState.done
                                  : _RuleState.pending,
                            ),
                            const Divider(
                              height: 26,
                              color: Color.fromRGBO(17, 24, 39, 0.10),
                            ),
                            _RuleRow(
                              title: isClockOut
                                  ? 'Return to the event location'
                                  : 'Stay within the event location',
                              body:
                                  'You must be within ${LocationVerificationService.boundaryMeters.toStringAsFixed(0)}m of the approved event location before attendance is ${isClockOut ? 'closed' : 'recorded'}.',
                              state: _controller.state.stage.index >=
                                          ClockInStage.verifyingBoundary.index &&
                                      _controller.state.failureReason !=
                                          EventCheckInFailureReason.outsideBoundary
                                  ? _RuleState.done
                                  : _controller.state.stage ==
                                          ClockInStage.verifyingBoundary
                                      ? _RuleState.loading
                                      : _RuleState.pending,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _statusLabel(EventDetailsData? details) {
    if (details?.currentAttendance?.isCheckedIn == true) {
      return details?.event.hasEnded == true ? 'Check out' : 'Checked in';
    }
    if (details?.event.isOpenForCheckIn == true) {
      return 'Open';
    }
    return 'Closed';
  }

  String _stageLabel(EventCheckInState state) {
    final isClockOut = state.action == EventAttendanceAction.clockOut;
    switch (state.stage) {
      case ClockInStage.initial:
      case ClockInStage.loadingEvent:
        return 'Checking event boundary';
      case ClockInStage.requestingPermission:
        return 'Requesting location permission';
      case ClockInStage.gettingLocation:
        return 'Getting your location';
      case ClockInStage.verifyingBoundary:
        return isClockOut
            ? 'Verifying check-out point'
            : 'Verifying attendance point';
      case ClockInStage.submittingCheckIn:
        return isClockOut ? 'Submitting check-out' : 'Submitting check-in';
      case ClockInStage.success:
        return isClockOut ? 'Check-out verified' : 'Check-in verified';
      case ClockInStage.failure:
        return 'Verification failed';
    }
  }
}

class _RadarTarget extends StatefulWidget {
  const _RadarTarget({required this.label});

  final String label;

  @override
  State<_RadarTarget> createState() => _RadarTargetState();
}

class _RadarTargetState extends State<_RadarTarget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 190,
          height: 190,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final scale = 0.8 + (_controller.value * 0.35);
              final opacity = 1 - _controller.value;
              return Stack(
                alignment: Alignment.center,
                children: [
                  Transform.scale(
                    scale: scale,
                    child: Opacity(
                      opacity: opacity * 0.24,
                      child: Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFD600B8).withValues(alpha: 0.18),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 92,
                    height: 92,
                    decoration: BoxDecoration(
                      color: const Color(0xFF111113),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    child: const Icon(
                      Icons.church_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        Container(
          margin: const EdgeInsets.only(top: 12),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 18,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Text(
            widget.label,
            style: const TextStyle(
              fontFamily: 'Instrument Sans',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF374151),
            ),
          ),
        ),
      ],
    );
  }
}

enum _RuleState { done, pending, loading }

class _RuleRow extends StatelessWidget {
  const _RuleRow({
    required this.title,
    required this.body,
    required this.state,
  });

  final String title;
  final String body;
  final _RuleState state;

  @override
  Widget build(BuildContext context) {
    Widget leading;
    switch (state) {
      case _RuleState.done:
        leading = Container(
          width: 26,
          height: 26,
          decoration: const BoxDecoration(
            color: Color(0xFFE3F5E9),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_rounded, size: 16, color: Color(0xFF1A6B35)),
        );
      case _RuleState.loading:
        leading = Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: const Color.fromRGBO(17, 24, 39, 0.14)),
          ),
          padding: const EdgeInsets.all(5),
          child: const CircularProgressIndicator(
            strokeWidth: 2,
            color: Color(0xFFD600B8),
          ),
        );
      case _RuleState.pending:
        leading = Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: const Color.fromRGBO(17, 24, 39, 0.14)),
          ),
        );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        leading,
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Instrument Sans',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                body,
                style: const TextStyle(
                  fontFamily: 'Instrument Sans',
                  fontSize: 12,
                  height: 1.45,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
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
    );
  }
}
