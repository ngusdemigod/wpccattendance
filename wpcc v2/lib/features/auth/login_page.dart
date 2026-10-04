import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'auth_repository.dart';
import '../onboarding/prototype_auth_view.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.tokenHash, this.linkType});
  final String? tokenHash;
  final String? linkType;
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final code = TextEditingController();
  final email = TextEditingController();
  final otp = TextEditingController();
  final password = TextEditingController();
  bool usePassword = false;
  bool loading = false;
  String? message;
  String? codeError;
  bool verifyingLink = false;
  bool useEmail = false;
  bool otpSent = false;
  String? maskedEmail;
  int resendSeconds = 0;
  Timer? resendTimer;

  @override
  void initState() {
    super.initState();
    if (widget.tokenHash != null) {
      verifyingLink = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => verifyLink());
    }
  }

  Future<void> verifyLink() async {
    if (!mounted) return;
    try {
      await AuthRepository()
          .verifyMagicLink(widget.tokenHash!, widget.linkType);
      if (mounted) context.go('/home');
    } catch (_) {
      if (mounted) {
        setState(() {
          verifyingLink = false;
          message =
              'This sign in link is invalid or has expired. Please request a new link.';
        });
      }
    }
  }

  @override
  void dispose() {
    resendTimer?.cancel();
    code.dispose();
    email.dispose();
    otp.dispose();
    password.dispose();
    super.dispose();
  }

  void startResendCountdown() {
    resendTimer?.cancel();
    setState(() => resendSeconds = 60);
    resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      if (resendSeconds <= 1) {
        timer.cancel();
        setState(() => resendSeconds = 0);
      } else {
        setState(() => resendSeconds--);
      }
    });
  }

  Future<void> submit() async {
    if (loading || verifyingLink) return;
    if (usePassword) {
      if (email.text.trim().isEmpty || password.text.isEmpty) {
        setState(() => message = 'Enter your email and password.');
        return;
      }
      setState(() {
        loading = true;
        message = null;
      });
      try {
        await AuthRepository().signInWithPassword(email.text, password.text);
        if (mounted) context.go('/home');
      } catch (_) {
        if (mounted) {
          setState(() => message =
              'Unable to sign in. Check your email and password, or use an email code.');
        }
      } finally {
        if (mounted) setState(() => loading = false);
      }
      return;
    }
    if (useEmail) return requestEmailCode();
    if (code.text.trim().isEmpty) {
      setState(() => codeError = 'Enter your membership code.');
      return;
    }
    setState(() {
      loading = true;
      message = null;
      codeError = null;
    });
    try {
      code.text = normalizeMembershipCode(code.text);
      await AuthRepository().requestMemberOtp(code.text);
      if (mounted) {
        setState(() {
          otpSent = true;
          maskedEmail = null;
          message = null;
        });
        startResendCountdown();
      }
    } catch (e) {
      if (mounted) {
        setState(() => message =
            'Unable to send the verification code. Please try again.');
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> requestEmailCode() async {
    final value = email.text.trim();
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value)) {
      setState(() => message = 'Enter a valid email address.');
      return;
    }
    setState(() {
      loading = true;
      message = null;
    });
    try {
      await AuthRepository().requestEmailOtp(value);
      if (!mounted) return;
      setState(() => otpSent = true);
      startResendCountdown();
    } catch (_) {
      if (mounted) {
        setState(() => message =
            'Unable to send a code. Confirm this email belongs to your account.');
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> verifyEmailCode() async {
    if (loading) return;
    final value = otp.text.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(value)) {
      setState(() => message = 'Enter the six-digit code from your email.');
      return;
    }
    setState(() {
      loading = true;
      message = null;
    });
    try {
      if (useEmail) {
        await AuthRepository().verifyEmailOtp(email.text, value);
      } else {
        await AuthRepository().verifyMemberOtp(code.text, value);
      }
      if (mounted) context.go('/home');
    } catch (_) {
      if (mounted) setState(() => message = 'That code is invalid or expired.');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final prototype = PrototypeAuthScope.of(context) ??
        PrototypeAuthScope(
            photo: 0, onBack: () {}, child: const SizedBox.shrink());
    return PrototypeAuthView(
        scope: prototype,
        code: code,
        email: email,
        password: password,
        otp: otp,
        useEmail: useEmail,
        usePassword: usePassword,
        otpSent: otpSent,
        linkSent: false,
        loading: loading || verifyingLink,
        verifying: verifyingLink,
        resendSeconds: resendSeconds,
        error: message ?? codeError,
        maskedEmail: maskedEmail,
        onSubmit: submit,
        onVerify: verifyEmailCode,
        onResend: () {
          if (resendSeconds == 0 && !loading) submit();
        },
        onBack: () => setState(() {
          otpSent = false;

          message = null;
          otp.clear();
        }),
        onMode: (emailMode, passwordMode) => setState(() {
          useEmail = emailMode;
          usePassword = passwordMode;
          message = null;
          codeError = null;
          otpSent = false;
        }),
      );
  }
}
