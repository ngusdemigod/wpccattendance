import 'dart:async';

import '/app/app_shell_widget.dart';
import '/auth/supabase_auth/supabase_user_provider.dart';
import '/backend/supabase/supabase.dart';
import '/features/profile/profile_identity_resolver.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import 'login_model.dart';
export 'login_model.dart';

class LoginWidget extends StatefulWidget {
  const LoginWidget({
    super.key,
    this.tokenHash = '',
    this.authType = '',
    this.authErrorDescription = '',
  });

  static String routeName = 'Login';
  static String routePath = '/login';

  final String tokenHash;
  final String authType;
  final String authErrorDescription;

  @override
  State<LoginWidget> createState() => _LoginWidgetState();
}

class _LoginWidgetState extends State<LoginWidget> {
  static const int _memberCodeLength = 4;
  static const int _resendDurationSeconds = 15;
  final ProfileIdentityResolver _identityResolver = ProfileIdentityResolver();

  late LoginModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  late final List<TextEditingController> _digitControllers;
  late final List<FocusNode> _digitFocusNodes;
  Timer? _resendTimer;

  int _secondsRemaining = 0;
  bool _showInboxState = false;
  String _submittedMemberCode = '';
  String _maskedEmail = '';

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => LoginModel());
    _digitControllers = List.generate(
      _memberCodeLength,
      (_) => TextEditingController(),
    );
    _digitFocusNodes = List.generate(
      _memberCodeLength,
      (_) => FocusNode(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _digitFocusNodes.first.requestFocus();
      final authError = widget.authErrorDescription.trim();
      if (authError.isNotEmpty) {
        unawaited(_showFeedback(authError));
        return;
      }

      // Hash-routing builds only expose parameters after `#/login` to
      // GoRouter. Recover parameters placed before the hash by older emails.
      final tokenHash = widget.tokenHash.trim().isNotEmpty
          ? widget.tokenHash.trim()
          : (Uri.base.queryParameters['token_hash']?.trim() ?? '');
      if (tokenHash.isNotEmpty) {
        final authType = widget.authType.trim().isNotEmpty
            ? widget.authType.trim()
            : (Uri.base.queryParameters['type']?.trim() ?? 'email');
        unawaited(_completeMagicLinkSignIn(tokenHash, authType));
      }
    });
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    for (final controller in _digitControllers) {
      controller.dispose();
    }
    for (final focusNode in _digitFocusNodes) {
      focusNode.dispose();
    }
    _model.dispose();
    super.dispose();
  }

  Future<void> _showFeedback(String message) async {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: GoogleFonts.instrumentSans(
              color: Colors.white,
              fontSize: 14.0,
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: const Color(0xFF1A1A1A),
        ),
      );
  }

  String _sanitizeMemberCode(String input) {
    final normalized = input.replaceAll(RegExp(r'[^0-9]'), '');
    return normalized.length > _memberCodeLength
        ? normalized.substring(0, _memberCodeLength)
        : normalized;
  }

  Map<String, dynamic>? _decodeResponseBody(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {}
    return null;
  }

  String _extractErrorMessage(http.Response response) {
    final decoded = _decodeResponseBody(response.body);
    final error = decoded?['error']?.toString().trim();
    if (error != null && error.isNotEmpty) {
      return error;
    }
    return 'Unable to send the sign in link. Status ${response.statusCode}.';
  }

  String _mapAuthRequestMessage(String message) {
    if (message.trim().toLowerCase() == 'email service not configured') {
      return 'Sign-in email is temporarily unavailable. Please try again later or contact support.';
    }
    return message;
  }

  OtpType _resolveOtpType(String rawType) {
    switch (rawType.trim().toLowerCase()) {
      case 'signup':
        return OtpType.signup;
      case 'invite':
        return OtpType.invite;
      case 'recovery':
        return OtpType.recovery;
      case 'email':
        return OtpType.email;
      case 'email_change':
      case 'emailchange':
        return OtpType.emailChange;
      case 'magiclink':
      default:
        return OtpType.magiclink;
    }
  }

  String _timeLabel(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final remainingSeconds = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remainingSeconds';
  }

  void _syncMemberCodeValue(String value) {
    final clipped = _sanitizeMemberCode(value);
    if (_model.memberCodeTextController!.text == clipped) {
      return;
    }
    _model.memberCodeTextController!.value = TextEditingValue(
      text: clipped,
      selection: TextSelection.collapsed(offset: clipped.length),
    );
  }

  void _syncJoinedMemberCode() {
    _syncMemberCodeValue(
      _digitControllers.map((controller) => controller.text).join(),
    );
  }

  void _setDigitValues(String value) {
    final sanitized = _sanitizeMemberCode(value);
    for (var index = 0; index < _digitControllers.length; index++) {
      _digitControllers[index].text =
          index < sanitized.length ? sanitized[index] : '';
    }
    _syncJoinedMemberCode();
    final targetIndex = sanitized.length >= _memberCodeLength
        ? _memberCodeLength - 1
        : sanitized.length;
    _digitFocusNodes[targetIndex.clamp(0, _memberCodeLength - 1)]
        .requestFocus();
  }

  void _handleDigitChanged(int index, String value) {
    final sanitized = _sanitizeMemberCode(value);
    if (sanitized.length > 1) {
      _setDigitValues(
        _digitControllers
            .asMap()
            .entries
            .map((entry) => entry.key == index ? sanitized : entry.value.text)
            .join(),
      );
      return;
    }

    _digitControllers[index].value = TextEditingValue(
      text: sanitized,
      selection: TextSelection.collapsed(offset: sanitized.length),
    );
    _syncJoinedMemberCode();
    if (sanitized.isNotEmpty) {
      if (index < _memberCodeLength - 1) {
        _digitFocusNodes[index + 1].requestFocus();
      } else {
        _digitFocusNodes[index].unfocus();
      }
    } else if (index > 0) {
      _digitFocusNodes[index - 1].requestFocus();
    }
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

  void _resetToMemberCodeEntry() {
    _resendTimer?.cancel();
    for (final controller in _digitControllers) {
      controller.clear();
    }
    _model.memberCodeTextController?.clear();
    safeSetState(() {
      _showInboxState = false;
      _submittedMemberCode = '';
      _maskedEmail = '';
      _secondsRemaining = 0;
      _model.isLoading = false;
      _model.errorText = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _digitFocusNodes.first.requestFocus();
      }
    });
  }

  Future<void> _completeMagicLinkSignIn(
    String tokenHash,
    String authType,
  ) async {
    if (_model.isLoading) {
      return;
    }

    safeSetState(() {
      _model.isLoading = true;
      _model.errorText = null;
    });

    try {
      final authResponse = await SupaFlow.client.auth.verifyOTP(
        tokenHash: tokenHash,
        type: _resolveOtpType(authType),
      );

      final sessionUser = authResponse.user ??
          authResponse.session?.user ??
          SupaFlow.client.auth.currentUser;
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
      await _showFeedback(error.message);
    } catch (_) {
      await _showFeedback(
        'This sign-in link is invalid or has expired. Request a new link and try again.',
      );
    } finally {
      if (mounted) {
        safeSetState(() {
          _model.isLoading = false;
        });
      }
    }
  }

  Future<void> _submitMagicLinkRequest({required bool resend}) async {
    final sanitizedCode = resend
        ? _submittedMemberCode
        : _sanitizeMemberCode(_model.memberCodeTextController.text.trim());

    if (!resend && sanitizedCode.length != _memberCodeLength) {
      await _showFeedback(
        'Enter the 4-digit code from your Departmental Leader.',
      );
      return;
    }

    if (resend && (_secondsRemaining > 0 || sanitizedCode.isEmpty)) {
      return;
    }

    safeSetState(() {
      _model.isLoading = true;
      _model.errorText = null;
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
          'membership_code': sanitizedCode,
          'redirect_to': appBaseRedirectUrl(),
        }),
      );

      if (response.statusCode != 200) {
        throw FormatException(_extractErrorMessage(response));
      }

      final decoded = _decodeResponseBody(response.body);
      final serverMessage = decoded?['message']?.toString().trim() ??
          'If the member code is valid, a sign in link has been sent.';
      final maskedEmail = decoded?['email_masked']?.toString().trim() ?? '';

      safeSetState(() {
        _showInboxState = true;
        _submittedMemberCode = sanitizedCode;
        _maskedEmail = maskedEmail;
      });
      _startResendCountdown();

      if (resend) {
        await _showFeedback(serverMessage);
      }
    } catch (error) {
      final message = error is FormatException
          ? _mapAuthRequestMessage(error.message)
          : 'Unable to send the sign in link. Check the membership code and try again.';
      await _showFeedback(message);
    } finally {
      if (mounted) {
        safeSetState(() {
          _model.isLoading = false;
        });
      }
    }
  }

  Future<void> _continueWithCode() async {
    await _submitMagicLinkRequest(resend: false);
  }

  Future<void> _resendMagicLink() async {
    await _submitMagicLinkRequest(resend: true);
  }

  Widget _buildMemberCodeInput() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_memberCodeLength, (index) {
        return Padding(
          padding:
              EdgeInsets.only(right: index == _memberCodeLength - 1 ? 0 : 12),
          child: SizedBox(
            width: 64,
            height: 72,
            child: TextField(
              controller: _digitControllers[index],
              focusNode: _digitFocusNodes[index],
              autofocus: index == 0,
              keyboardType: TextInputType.number,
              textInputAction: index == _memberCodeLength - 1
                  ? TextInputAction.done
                  : TextInputAction.next,
              textAlign: TextAlign.center,
              autocorrect: false,
              enableSuggestions: false,
              style: GoogleFonts.instrumentSans(
                color: const Color(0xFF111827),
                fontSize: 30.0,
                fontWeight: FontWeight.w600,
                height: 1.0,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              onChanged: (value) => _handleDigitChanged(index, value),
              onSubmitted: (_) {
                if (index == _memberCodeLength - 1) {
                  _continueWithCode();
                } else {
                  _digitFocusNodes[index + 1].requestFocus();
                }
              },
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFF7F7F6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18.0),
                  borderSide: const BorderSide(
                    color: Color(0x14111827),
                    width: 1.0,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18.0),
                  borderSide: const BorderSide(
                    color: Color(0x14111827),
                    width: 1.0,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18.0),
                  borderSide: const BorderSide(
                    color: Color(0x26111827),
                    width: 1.1,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18.0),
                  borderSide: const BorderSide(
                    color: Color(0x22D92D20),
                    width: 1.0,
                  ),
                ),
                contentPadding: EdgeInsets.zero,
                counterText: '',
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required VoidCallback? onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56.0,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(999.0),
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999.0),
              color: onTap == null
                  ? const Color(0xFFB8BCC3)
                  : const Color(0xFF000000),
            ),
            child: Center(
              child: _model.isLoading
                  ? const SizedBox(
                      width: 22.0,
                      height: 22.0,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      label,
                      style: GoogleFonts.instrumentSans(
                        color: Colors.white,
                        fontSize: 15.0,
                        fontWeight: FontWeight.w700,
                        height: 1.0,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton({
    required String label,
    required VoidCallback? onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56.0,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(999.0),
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999.0),
              color: const Color(0xFFF3F4F6),
              border: Border.all(
                color: const Color(0xFFE5E7EB),
              ),
            ),
            child: Center(
              child: Text(
                label,
                style: GoogleFonts.instrumentSans(
                  color: const Color(0xFF111827),
                  fontSize: 15.0,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMemberCodeState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FlowMotion(
          delay: const Duration(milliseconds: 40),
          child: Text(
            'Enter Member Code',
            textAlign: TextAlign.center,
            style: GoogleFonts.instrumentSerif(
              color: const Color(0xFF111827),
              fontSize: 32.0,
              fontWeight: FontWeight.w400,
              height: 0.95,
              letterSpacing: -0.64,
            ),
          ),
        ),
        const SizedBox(height: 22.0),
        _FlowMotion(
          delay: const Duration(milliseconds: 110),
          child: _buildMemberCodeInput(),
        ),
        const SizedBox(height: 28.0),
        _FlowMotion(
          delay: const Duration(milliseconds: 180),
          child: _buildPrimaryButton(
            label: 'Continue',
            onTap: _model.isLoading ? null : _continueWithCode,
          ),
        ),
        const SizedBox(height: 16.0),
        _FlowMotion(
          delay: const Duration(milliseconds: 240),
          offsetY: 0.05,
          child: Text(
            'Your code is provided by your Departmental Leader',
            textAlign: TextAlign.center,
            style: GoogleFonts.instrumentSans(
              color: const Color(0xFF8A8F98),
              fontSize: 12.0,
              fontWeight: FontWeight.w400,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInboxState() {
    final resendLabel = _secondsRemaining > 0
        ? 'Resend in ${_timeLabel(_secondsRemaining)}'
        : 'Resend sign in link';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _FlowMotion(
          delay: Duration(milliseconds: 40),
          child: Icon(
            Icons.mark_email_unread_outlined,
            size: 56.0,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 18.0),
        _FlowMotion(
          delay: const Duration(milliseconds: 110),
          child: Text(
            'Check Your Inbox',
            textAlign: TextAlign.center,
            style: GoogleFonts.instrumentSerif(
              color: const Color(0xFF111827),
              fontSize: 32.0,
              fontWeight: FontWeight.w400,
              height: 0.95,
              letterSpacing: -0.64,
            ),
          ),
        ),
        const SizedBox(height: 18.0),
        _FlowMotion(
          delay: const Duration(milliseconds: 160),
          child: Text(
            _maskedEmail.isNotEmpty
                ? 'We sent a sign in link to $_maskedEmail'
                : 'If the member code is valid, we sent a sign in link to the email on file.',
            textAlign: TextAlign.center,
            style: GoogleFonts.instrumentSans(
              color: const Color(0xFF8A8F98),
              fontSize: 13.0,
              fontWeight: FontWeight.w400,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 32.0),
        _FlowMotion(
          delay: const Duration(milliseconds: 220),
          child: _buildPrimaryButton(
            label: resendLabel,
            onTap: (_model.isLoading || _secondsRemaining > 0)
                ? null
                : _resendMagicLink,
          ),
        ),
        const SizedBox(height: 12.0),
        _FlowMotion(
          delay: const Duration(milliseconds: 280),
          child: _buildSecondaryButton(
            label: 'Use another member code',
            onTap: _model.isLoading ? null : _resetToMemberCodeEntry,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Title(
      title: 'Login',
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18.0,
                  vertical: 24.0,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430.0),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0.0, 64.0, 0.0, 24.0),
                    child: _showInboxState
                        ? _buildInboxState()
                        : _buildMemberCodeState(),
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

class _FlowMotion extends StatefulWidget {
  const _FlowMotion({
    required this.child,
    this.delay = Duration.zero,
    this.offsetY = 0.035,
  });

  final Widget child;
  final Duration delay;
  final double offsetY;

  @override
  State<_FlowMotion> createState() => _FlowMotionState();
}

class _FlowMotionState extends State<_FlowMotion> {
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
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      tween: Tween<double>(begin: 0, end: _visible ? 1 : 0),
      child: widget.child,
      builder: (context, value, child) {
        final offsetY = (1 - value) * widget.offsetY * 48;
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, offsetY),
            child: child,
          ),
        );
      },
    );
  }
}
