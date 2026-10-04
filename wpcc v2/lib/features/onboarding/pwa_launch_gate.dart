import 'package:flutter/material.dart';
import 'pwa_onboarding.dart';
import 'prototype_auth_view.dart';

class PwaLaunchGate extends StatefulWidget {
  const PwaLaunchGate({super.key, required this.child, required this.signedIn});
  final Widget child;
  final bool signedIn;
  @override
  State<PwaLaunchGate> createState() => _PwaLaunchGateState();
}

class _PwaLaunchGateState extends State<PwaLaunchGate> {
  bool finished = false;
  int photo = 0;
  bool replayOnboarding = false;
  @override
  Widget build(BuildContext context) {
    if (finished) {
      return PrototypeAuthScope(
          photo: photo,
          onBack: () => setState(() {
                finished = false;
                replayOnboarding = true;
              }),
          child: widget.child);
    }
    return PwaOnboarding(
        splashOnly: widget.signedIn,
        skipSplash: replayOnboarding,
        revealChild: widget.child,
        onContinue: (index) => setState(() {
              photo = index;
              finished = true;
            }));
  }
}
