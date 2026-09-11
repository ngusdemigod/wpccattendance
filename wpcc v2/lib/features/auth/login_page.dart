import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/wpcc_logo.dart';
import 'auth_repository.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.tokenHash, this.linkType});
  final String? tokenHash;
  final String? linkType;
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final code = TextEditingController();
  bool loading = false;
  String? message;
  String? codeError;
  bool verifyingLink = false;

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
    code.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (loading || verifyingLink) return;
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
      final masked = await AuthRepository().requestMemberMagicLink(code.text);
      if (mounted) {
        setState(() => message = masked == null
            ? 'Check your email for your WPCC sign in link.'
            : 'Sign in link sent to $masked');
      }
    } catch (e) {
      if (mounted) {
        setState(() =>
            message = 'Unable to send the sign in link. Please try again.');
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (verifyingLink) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Signing you in…'),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const WpccLogo(size: 54),
                    const SizedBox(height: 28),
                    Text('WPCC Community',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                                fontWeight: FontWeight.w600,
                                letterSpacing: -1.1)),
                    const SizedBox(height: 8),
                    Text('Sign in with your membership code.',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: WpccColors.muted)),
                    const SizedBox(height: 28),
                    TextField(
                      controller: code,
                      onChanged: (_) {
                        if (codeError != null) setState(() => codeError = null);
                      },
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => submit(),
                      decoration: InputDecoration(
                          labelText: 'Membership code',
                          hintText: 'Enter your WPCC member code',
                          errorText: codeError),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton(
                        onPressed: loading ? null : submit,
                        style: FilledButton.styleFrom(
                            backgroundColor: WpccColors.ink,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18))),
                        child: loading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Text('Send sign in link'),
                      ),
                    ),
                    if (message != null) ...[
                      const SizedBox(height: 16),
                      Text(message!,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: WpccColors.inkSoft)),
                    ],
                    const SizedBox(height: 18),
                    TextButton(
                        onPressed: () => context.go('/login'),
                        child: const Text('Use another membership code')),
                  ]),
            ),
          ),
        ),
      ),
    );
  }
}
