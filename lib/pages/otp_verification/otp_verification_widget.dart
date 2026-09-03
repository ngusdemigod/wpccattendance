import 'dart:async';

import '/auth/supabase_auth/supabase_user_provider.dart';
import '/backend/supabase/supabase.dart';
import '/app/app_shell_widget.dart';
import '/features/profile/profile_identity_resolver.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/login/login_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import 'otp_verification_model.dart';
export 'otp_verification_model.dart';

class OtpVerificationWidget extends StatefulWidget {
  const OtpVerificationWidget({
    super.key,
    this.emailMasked = '',
    this.otpContextToken = '',
    this.membershipCode = '',
  });

  static const String routeName = 'OtpVerification';
  static const String routePath = '/otpVerification';

  final String emailMasked;
  final String otpContextToken;
  final String membershipCode;

  @override
  State<OtpVerificationWidget> createState() => _OtpVerificationWidgetState();
}

class _OtpVerificationWidgetState extends State<OtpVerificationWidget> {
  static const int _otpLength = 8;
  static const int _resendDurationSeconds = 45;
  final ProfileIdentityResolver _identityResolver = ProfileIdentityResolver();

  late OtpVerificationModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  Timer? _resendTimer;
  int _secondsRemaining = _resendDurationSeconds;
  bool _isVerifying = false;
  bool _isPreparingSession = false;
  bool _isUpdatingController = false;
  String _otpValue = '';
  String _emailMaskedValue = '';
  String _otpContextToken = '';
  String? _sessionErrorMessage;

  String get _membershipCode => widget.membershipCode.trim();
  bool get _hasActiveVerificationSession =>
      _otpContextToken.isNotEmpty && !_isPreparingSession;

  Map<String, dynamic>? _decodeResponseBody(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {}
    return null;
  }

  String _extractErrorMessage(http.Response response, String fallback) {
    final decoded = _decodeResponseBody(response.body);
    final error = decoded?['error']?.toString().trim();
    if (error != null && error.isNotEmpty) {
      return error;
    }
    return fallback;
  }

  String _mapAuthRequestMessage(String message) {
    if (message.trim().toLowerCase() == 'email service not configured') {
      return 'Verification email is temporarily unavailable. Please try again later or contact support.';
    }
    return message;
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => OtpVerificationModel());
    _emailMaskedValue = widget.emailMasked.trim();
    _otpContextToken = widget.otpContextToken.trim();
    _sessionErrorMessage = _otpContextToken.isEmpty
        ? 'Starting your verification session...'
        : null;
    _syncOtpValue('');
    _model.otpController?.addListener(_handleControllerChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _model.otpFocusNode?.requestFocus();
      if (_otpContextToken.isEmpty && _membershipCode.isNotEmpty) {
        unawaited(_prepareVerificationSession(showSuccessToast: false));
      }
    });
    _startResendCountdown();
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _model.otpController?.removeListener(_handleControllerChange);
    _model.dispose();
    super.dispose();
  }

  void _startResendCountdown() {
    _resendTimer?.cancel();
    setState(() {
      _secondsRemaining = _resendDurationSeconds;
    });
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_secondsRemaining <= 1) {
        timer.cancel();
        setState(() {
          _secondsRemaining = 0;
        });
        return;
      }

      setState(() {
        _secondsRemaining -= 1;
      });
    });
  }

  void _handleControllerChange() {
    if (_isUpdatingController) {
      return;
    }

    final controller = _model.otpController;
    if (controller == null) {
      return;
    }

    final digitsOnly = controller.text.replaceAll(RegExp(r'[^0-9]'), '');
    final clipped = digitsOnly.length > _otpLength
        ? digitsOnly.substring(0, _otpLength)
        : digitsOnly;

    if (clipped != controller.text) {
      _syncOtpValue(clipped);
      return;
    }

    if (clipped != _otpValue) {
      setState(() {
        _otpValue = clipped;
      });
    }
  }

  void _focusOtpField() {
    _model.otpFocusNode?.requestFocus();
  }

  void _syncOtpValue(String value) {
    final clipped =
        value.length > _otpLength ? value.substring(0, _otpLength) : value;

    _isUpdatingController = true;
    try {
      _model.otpController?.value = TextEditingValue(
        text: clipped,
        selection: TextSelection.collapsed(offset: clipped.length),
      );
    } finally {
      _isUpdatingController = false;
    }

    if (mounted) {
      setState(() {
        _otpValue = clipped;
      });
    }
  }

  Future<void> _prepareVerificationSession({
    required bool showSuccessToast,
  }) async {
    if (_membershipCode.isEmpty || _isPreparingSession) {
      return;
    }

    setState(() {
      _isPreparingSession = true;
      _sessionErrorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse(supabaseFunctionUrl('send-otp')),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $kSupabaseAnonKey',
          'apikey': kSupabaseAnonKey,
        },
        body: jsonEncode(<String, String>{
          'membership_code': _membershipCode,
          'redirect_to': appBaseRedirectUrl(),
        }),
      );

      if (response.statusCode != 200) {
        throw FormatException(
          _extractErrorMessage(
            response,
            'Unable to start verification. Please try again.',
          ),
        );
      }

      final decoded = _decodeResponseBody(response.body);
      final maskedEmail = decoded?['email_masked']?.toString().trim() ?? '';
      final otpContextToken =
          decoded?['otp_context_token']?.toString().trim() ?? '';

      setState(() {
        if (maskedEmail.isNotEmpty) {
          _emailMaskedValue = maskedEmail;
        }
        if (otpContextToken.isNotEmpty) {
          _otpContextToken = otpContextToken;
          _sessionErrorMessage = null;
        } else {
          _sessionErrorMessage =
              'We could not start email verification for this member code.';
        }
      });

      _syncOtpValue('');
      _startResendCountdown();

      if (!mounted || !showSuccessToast) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A new verification code has been sent.'),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      final message = error is FormatException
          ? _mapAuthRequestMessage(error.message)
          : 'Unable to resend the verification code. Please try again.';
      setState(() {
        _sessionErrorMessage = message;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPreparingSession = false;
        });
      }
    }
  }

  Future<void> _verifyCode() async {
    if (!_hasActiveVerificationSession) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preparing your verification session. Please wait.'),
        ),
      );
      return;
    }

    if (_otpValue.length != _otpLength) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter the full verification code first.'),
        ),
      );
      return;
    }

    setState(() {
      _isVerifying = true;
    });

    try {
      if (_otpContextToken.isEmpty) {
        throw const FormatException(
          'Your verification session has expired. Request a new code.',
        );
      }

      final response = await http.post(
        Uri.parse(supabaseFunctionUrl('verify-otp')),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $kSupabaseAnonKey',
          'apikey': kSupabaseAnonKey,
        },
        body: jsonEncode(<String, String>{
          'otp': _otpValue,
          'otp_context_token': _otpContextToken,
        }),
      );

      if (response.statusCode != 200) {
        throw FormatException(
          _extractErrorMessage(
            response,
            'Unable to verify the code. Please try again.',
          ),
        );
      }

      final decoded = _decodeResponseBody(response.body);
      final session = decoded?['session'];
      if (session is! Map<String, dynamic>) {
        throw const FormatException(
          'Missing verified session. Request a new code.',
        );
      }

      final authResponse = await SupaFlow.client.auth.recoverSession(
        jsonEncode(session),
      );

      final sessionUser = authResponse.user;
      if (sessionUser != null) {
        final authUser = AttendamceSupabaseUser(sessionUser);
        currentUser = authUser;
        AppStateNotifier.instance.update(authUser);
        await _identityResolver.relinkCurrentAuthProfile();
      }

      if (!mounted) {
        return;
      }

      context.goNamedAuth(
        AppShellWidget.routeName,
        mounted,
        ignoreRedirect: true,
      );
    } on AuthException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      final message = error is FormatException
          ? _mapAuthRequestMessage(error.message)
          : 'Unable to verify the code. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
      }
    }
  }

  Future<void> _resendCode() async {
    if (_secondsRemaining > 0) {
      return;
    }

    if (_membershipCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Missing membership code for resend.'),
        ),
      );
      return;
    }

    _syncOtpValue('');
    await _prepareVerificationSession(showSuccessToast: true);
    if (!mounted) {
      return;
    }
    _model.otpFocusNode?.requestFocus();
  }

  String _timeLabel(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final remainingSeconds = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remainingSeconds';
  }

  void _goBack() {
    _syncOtpValue('');
    context.goNamedAuth(
      LoginWidget.routeName,
      mounted,
      ignoreRedirect: true,
    );
  }

  Widget _buildDigitBox(
    int index, {
    required double width,
    required double height,
  }) {
    final isFilled = index < _otpValue.length;
    final isActive = index == _otpValue.length;
    final digit = isFilled ? _otpValue[index] : '';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? const Color(0x26111827) : const Color(0x14111827),
          width: isActive ? 1.1 : 1,
        ),
      ),
      child: Center(
        child: Text(
          digit,
          style: GoogleFonts.instrumentSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF111827),
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton() {
    final isEnabled = _otpValue.length == _otpLength &&
        !_isVerifying &&
        _hasActiveVerificationSession;

    return SizedBox(
      height: 56,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: isEnabled ? _verifyCode : null,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color:
                  isEnabled ? const Color(0xFF000000) : const Color(0xFFB8BCC3),
            ),
            child: Center(
              child: _isVerifying
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.3,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : _isPreparingSession
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.3,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          _hasActiveVerificationSession
                              ? 'Continue'
                              : 'Verification unavailable',
                          style: GoogleFonts.instrumentSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1,
                          ),
                        ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Title(
      title: 'Verification Code',
      color: FlutterFlowTheme.of(context).primary.withAlpha(0XFF),
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
          FocusManager.instance.primaryFocus?.unfocus();
        },
        child: Scaffold(
          key: scaffoldKey,
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _OtpFlowMotion(
                          delay: const Duration(milliseconds: 10),
                          offsetY: 0.02,
                          child: Material(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(999),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(999),
                              onTap: _goBack,
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0x14111827),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  size: 16,
                                  color: Color(0xFF111827),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _OtpFlowMotion(
                        delay: const Duration(milliseconds: 40),
                        child: Text(
                          'Enter OTP Code',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.instrumentSerif(
                            fontSize: 32,
                            fontWeight: FontWeight.w400,
                            height: 0.95,
                            letterSpacing: -0.64,
                            color: const Color(0xFF111827),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _OtpFlowMotion(
                        delay: const Duration(milliseconds: 100),
                        offsetY: 0.03,
                        child: Text(
                          _isPreparingSession
                              ? 'Preparing your verification session...'
                              : _emailMaskedValue.isNotEmpty
                                  ? 'We sent an 8 digit code to $_emailMaskedValue'
                                  : 'We sent an 8 digit code to your email on file',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.instrumentSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            height: 1.5,
                            color: const Color(0xFF8A8F98),
                          ),
                        ),
                      ),
                      const SizedBox(height: 26),
                      _OtpFlowMotion(
                        delay: const Duration(milliseconds: 160),
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTap: _focusOtpField,
                          child: Center(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final spacing =
                                    constraints.maxWidth >= 360 ? 8.0 : 5.0;
                                final boxWidth = (constraints.maxWidth -
                                        (spacing * (_otpLength - 1))) /
                                    _otpLength;
                                final clampedWidth = boxWidth.clamp(32.0, 42.0);
                                final boxHeight = clampedWidth * 1.22;

                                return Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Opacity(
                                      opacity: 0.0,
                                      child: SizedBox(
                                        height: boxHeight,
                                        child: TextFormField(
                                          controller: _model.otpController,
                                          focusNode: _model.otpFocusNode,
                                          keyboardType: TextInputType.number,
                                          textAlign: TextAlign.center,
                                          autocorrect: false,
                                          enableSuggestions: false,
                                          autofillHints: const <String>[],
                                          inputFormatters: [
                                            FilteringTextInputFormatter
                                                .digitsOnly,
                                            LengthLimitingTextInputFormatter(
                                              _otpLength,
                                            ),
                                          ],
                                          onChanged: _syncOtpValue,
                                          decoration: const InputDecoration(
                                            border: InputBorder.none,
                                            isCollapsed: true,
                                            contentPadding: EdgeInsets.zero,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: List.generate(
                                        _otpLength,
                                        (index) => Padding(
                                          padding: EdgeInsets.only(
                                            right: index == _otpLength - 1
                                                ? 0
                                                : spacing,
                                          ),
                                          child: _buildDigitBox(
                                            index,
                                            width: clampedWidth,
                                            height: boxHeight,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      _OtpFlowMotion(
                        delay: const Duration(milliseconds: 220),
                        child: SizedBox(
                          width: double.infinity,
                          child: _buildPrimaryButton(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_sessionErrorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _OtpFlowMotion(
                            delay: const Duration(milliseconds: 250),
                            offsetY: 0.02,
                            child: Text(
                              _sessionErrorMessage!,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.instrumentSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                height: 1.45,
                                color: const Color(0xFFD92D20),
                              ),
                            ),
                          ),
                        ),
                      _OtpFlowMotion(
                        delay: const Duration(milliseconds: 280),
                        offsetY: 0.025,
                        child: GestureDetector(
                          onTap: _secondsRemaining > 0 ? null : _resendCode,
                          child: RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: GoogleFonts.instrumentSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF8A8F98),
                              ),
                              children: [
                                const TextSpan(
                                  text: "Didn't receive the code? ",
                                ),
                                TextSpan(
                                  text: _secondsRemaining > 0
                                      ? 'Resend in ${_timeLabel(_secondsRemaining)}'
                                      : 'Resend code',
                                  style: GoogleFonts.instrumentSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF111827),
                                  ),
                                ),
                              ],
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
      ),
    );
  }
}

class _OtpFlowMotion extends StatefulWidget {
  const _OtpFlowMotion({
    required this.child,
    this.delay = Duration.zero,
    this.offsetY = 0.035,
  });

  final Widget child;
  final Duration delay;
  final double offsetY;

  @override
  State<_OtpFlowMotion> createState() => _OtpFlowMotionState();
}

class _OtpFlowMotionState extends State<_OtpFlowMotion> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (widget.delay > Duration.zero) {
        await Future<void>.delayed(widget.delay);
      }
      if (mounted) {
        setState(() {
          _visible = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      opacity: _visible ? 1 : 0,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        offset: _visible ? Offset.zero : Offset(0, widget.offsetY),
        child: widget.child,
      ),
    );
  }
}
