import 'package:flutter/material.dart';

class GivingBackdrop extends StatelessWidget {
  const GivingBackdrop({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
      decoration: BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: const [0, .5, 1],
              colors: Theme.of(context).brightness == Brightness.dark
                  ? const [
                      Color(0xFF153B36),
                      Color(0xFF171C20),
                      Color(0xFF151517)
                    ]
                  : const [
                      Color(0xFFE3F1EA),
                      Color(0xFFF3F4F6),
                      Color(0xFFF8EEF1)
                    ])),
      child: SizedBox.expand(child: child));
}
