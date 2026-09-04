import '/app/app_shell_widget.dart';
import '/app/theme/design_tokens.dart';
import '/flutter_flow/custom_icons.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/shared/widgets/v76_foundation_widgets.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Confirmation shown after the existing attendance-geofence function records
/// a clock-in. The event identifier is retained for the declared GoRouter
/// route contract, even though the confirmation does not need to display it.
class ClockInSuccessWidget extends StatelessWidget {
  const ClockInSuccessWidget({super.key, this.eventId = ''});

  static const String routeName = 'ClockInSuccess';
  static const String routePath = '/clockInSuccess';

  final String eventId;

  void _returnToHome(BuildContext context) {
    context.goNamedAuth(
      AppShellWidget.routeName,
      context.mounted,
      ignoreRedirect: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Title(
      title: 'Clock in complete',
      color: tokens.background,
      child: Scaffold(
        backgroundColor: tokens.background,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
                child: Column(
                  children: [
                    V76FrostedHeader(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          tooltip: 'Close',
                          onPressed: () => _returnToHome(context),
                          icon: const Icon(FFIcons.kxBold),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFE7F7EF),
                        border: Border.all(color: const Color(0xFFBCE8CF)),
                      ),
                      child: const Icon(
                        FFIcons.kcheckBold,
                        size: 42,
                        color: Color(0xFF16794D),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'You’re clocked in',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.instrumentSerif(
                        fontSize: 34,
                        height: .98,
                        letterSpacing: -.68,
                        color: tokens.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Your attendance has been recorded successfully.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.instrumentSans(
                        fontSize: 14,
                        height: 1.45,
                        color: tokens.textMuted,
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: FilledButton(
                        onPressed: () => _returnToHome(context),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF000000),
                          shape: const StadiumBorder(),
                        ),
                        child: Text(
                          'Back to home',
                          style: GoogleFonts.instrumentSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
