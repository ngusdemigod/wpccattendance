import 'dart:async';
import 'dart:ui';

import '/auth/supabase_auth/auth_util.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/custom_icons.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/clock_in_success/clock_in_success_widget.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

class AttendanceActionWidget extends StatefulWidget {
  const AttendanceActionWidget({
    super.key,
    required this.eventId,
    required this.clockOut,
  });

  static const String routeName = 'AttendanceAction';
  static const String routePath = '/attendanceAction';

  final String eventId;
  final bool clockOut;

  @override
  State<AttendanceActionWidget> createState() => _AttendanceActionWidgetState();
}

class _AttendanceActionWidgetState extends State<AttendanceActionWidget>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  Timer? _clockTimer;

  DateTime _now = DateTime.now();
  bool _busy = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _now = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  String get _actionLabel => widget.clockOut ? 'Clock Out' : 'Clock In';

  String get _instructionText => widget.clockOut
      ? 'Please be at the event location before clocking out.'
      : 'You must be at event venue to clock in.';

  String _friendlyErrorMessage(String rawMessage) {
    final message = rawMessage.trim();

    try {
      final decoded = jsonDecode(message);
      if (decoded is Map<String, dynamic>) {
        final serverMessage = decoded['message']?.toString().trim() ?? '';
        if (serverMessage.isNotEmpty) {
          switch (serverMessage) {
            case 'User not at location':
              return 'You must be at event venue to clock in';
            case 'Location permission is required to continue.':
              return 'Location access is required so we can verify you are at the event.';
            default:
              return serverMessage;
          }
        }
      }
    } catch (_) {
      // Fall back to the plain-text message below.
    }

    switch (message) {
      case 'User not at location':
        return 'You must be at event venue to clock in';
      case 'Location permission is required to continue.':
        return 'Location access is required so we can verify you are at the event.';
      case 'Missing event id.':
        return 'We could not identify this event. Please go back and open it again.';
      case 'You must be signed in to submit attendance.':
        return 'Please sign in again before submitting attendance.';
      default:
        return message;
    }
  }

  Future<Position> _getCurrentPosition() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception('Location permission is required to continue.');
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
  }

  Future<void> _submitAttendance() async {
    if (_busy) {
      return;
    }

    setState(() {
      _busy = true;
      _errorMessage = null;
    });

    try {
      if (widget.eventId.trim().isEmpty) {
        throw Exception('Missing event id.');
      }
      if (currentJwtToken.trim().isEmpty) {
        throw Exception('You must be signed in to submit attendance.');
      }

      final position = await _getCurrentPosition();
      final response = await http.post(
        Uri.parse(supabaseFunctionUrl('attendance-geofence')),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $currentJwtToken',
        },
        body: jsonEncode({
          'event_id': widget.eventId,
          'user_location': {
            'latitude': position.latitude,
            'longitude': position.longitude,
          },
        }),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        const fallbackMessage =
            'We could not complete the request. Please try again.';
        final rawMessage = response.body.isEmpty
            ? 'Request failed with status ${response.statusCode}.'
            : response.body;
        throw Exception(_friendlyErrorMessage(rawMessage.isEmpty
            ? fallbackMessage
            : rawMessage));
      }

      if (!mounted) {
        return;
      }

      if (mounted) {
        if (widget.clockOut) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Clock out recorded successfully.'),
            ),
          );
          await Future<void>.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            Navigator.of(context).pop(true);
          }
        } else {
          await Future<void>.delayed(const Duration(milliseconds: 180));
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => ClockInSuccessWidget(
                  eventId: widget.eventId,
                ),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      final message =
          _friendlyErrorMessage(e.toString().replaceFirst('Exception: ', ''));
      setState(() {
        _errorMessage = message;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Widget _pulseRing({
    required double size,
    required double phase,
    required Color color,
  }) {
    return AnimatedBuilder(
      animation: _pulseController,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ),
      builder: (context, child) {
        final t = (_pulseController.value + phase) % 1.0;
        final scale = 1.0 + (t * 0.45);
        final opacity = (1.0 - t).clamp(0.0, 1.0);
        return Opacity(
          opacity: opacity * 0.35,
          child: Transform.scale(
            scale: scale,
            child: child,
          ),
        );
      },
    );
  }

  Widget _buildActionButton(BuildContext context) {
    return GestureDetector(
      onTap: _busy ? null : _submitAttendance,
      child: Container(
        width: 210,
        height: 210,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(0x4D017859),
              blurRadius: 32,
              spreadRadius: 2,
              offset: Offset(0, 10),
            ),
          ],
          gradient: RadialGradient(
            colors: [Color(0xFF26A983), Color(0xFF017859)],
            stops: [0.05, 1],
            center: Alignment(0, 0),
            radius: 0.85,
          ),
        ),
        alignment: Alignment.center,
        child: _busy
            ? const SizedBox(
                width: 42,
                height: 42,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    FFIcons.khandTapBold,
                    color: FlutterFlowTheme.of(context).onPrimary,
                    size: 50,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _actionLabel,
                    textAlign: TextAlign.center,
                    style: FlutterFlowTheme.of(context).titleMedium.override(
                          font: GoogleFonts.instrumentSans(
                            fontWeight: FontWeight.w700,
                            fontStyle: FlutterFlowTheme.of(context)
                                .titleMedium
                                .fontStyle,
                          ),
                          color: FlutterFlowTheme.of(context).onPrimary,
                          letterSpacing: 0.0,
                          fontWeight: FontWeight.w700,
                          fontStyle: FlutterFlowTheme.of(context)
                              .titleMedium
                              .fontStyle,
                          lineHeight: 1.2,
                        ),
                  ),
                ],
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111516),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final cardHeight =
                constraints.maxHeight > 32 ? constraints.maxHeight - 32 : constraints.maxHeight;
            final cardWidth = constraints.maxWidth > 420
                ? 420.0
                : constraints.maxWidth;

            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: cardWidth,
                  height: cardHeight,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF101315),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF1D2325),
                            width: 1,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x66000000),
                              blurRadius: 24,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                          child: Column(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  FlutterFlowIconButton(
                                    borderRadius: 9999,
                                    buttonSize: 42,
                                    fillColor: const Color(0xFF1A1D1E),
                                    icon: Icon(
                                      FFIcons.kxBold,
                                      color: FlutterFlowTheme.of(context)
                                          .primaryText,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      Navigator.of(context).pop(false);
                                    },
                                  ),
                                ],
                              ),
                              const Spacer(),
                              RepaintBoundary(
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    _pulseRing(
                                      size: 240,
                                      phase: 0.0,
                                      color: const Color(0xFF017859),
                                    ),
                                    _pulseRing(
                                      size: 210,
                                      phase: 0.45,
                                      color: const Color(0xFF017859),
                                    ),
                                    _buildActionButton(context),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 28),
                              Text(
                                dateTimeFormat('HH.mm', _now),
                                textAlign: TextAlign.center,
                                style: FlutterFlowTheme.of(context)
                                    .headlineLarge
                                    .override(
                                  font: GoogleFonts.instrumentSans(
                                    fontWeight: FontWeight.w700,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .headlineLarge
                                        .fontStyle,
                                  ),
                                  color:
                                      FlutterFlowTheme.of(context).primaryText,
                                  letterSpacing: 0.0,
                                  fontWeight: FontWeight.w700,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .headlineLarge
                                      .fontStyle,
                                  lineHeight: 1.1,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    FFIcons.klightningBold,
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryText,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _instructionText,
                                    textAlign: TextAlign.center,
                                    style: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .override(
                                      font: GoogleFonts.instrumentSans(
                                        fontWeight: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontWeight,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontStyle,
                                      ),
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryText,
                                      letterSpacing: 0.0,
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                      lineHeight: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                              if (_errorMessage != null) ...[
                                const SizedBox(height: 16),
                                Text(
                                  _errorMessage!,
                                  textAlign: TextAlign.center,
                                  style: FlutterFlowTheme.of(context)
                                      .bodySmall
                                      .override(
                                    font: GoogleFonts.instrumentSans(
                                      fontWeight: FontWeight.w400,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodySmall
                                          .fontStyle,
                                    ),
                                    color: const Color(0xFFFF8A80),
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.w400,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodySmall
                                        .fontStyle,
                                    lineHeight: 1.4,
                                  ),
                                ),
                              ],
                              const Spacer(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
