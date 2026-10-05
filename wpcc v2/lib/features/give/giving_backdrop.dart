import 'package:flutter/material.dart';

class GivingBackdrop extends StatelessWidget {
  const GivingBackdrop({super.key, required this.child, this.status});
  final Widget child;
  final String? status;

  List<Color> _colors(bool dark) {
    if (status == 'failed' || status == 'abandoned' || status == 'reversed') {
      return dark
          ? const [Color(0xFF50262C), Color(0xFF241B20), Color(0xFF151517)]
          : const [Color(0xFFF9DADD), Color(0xFFF7ECEE), Color(0xFFF3F4F6)];
    }
    if (status == 'pending' ||
        status == 'initialized' ||
        status == 'processing') {
      return dark
          ? const [Color(0xFF494019), Color(0xFF242219), Color(0xFF151517)]
          : const [Color(0xFFFFEBAA), Color(0xFFFAF5DE), Color(0xFFF3F4F6)];
    }
    return dark
        ? const [Color(0xFF153B36), Color(0xFF171C20), Color(0xFF151517)]
        : const [Color(0xFFE3F1EA), Color(0xFFF3F4F6), Color(0xFFF8EEF1)];
  }

  @override
  Widget build(BuildContext context) => DecoratedBox(
      decoration: BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: const [0, .5, 1],
              colors:
                  _colors(Theme.of(context).brightness == Brightness.dark))),
      child: SizedBox.expand(child: child));
}
