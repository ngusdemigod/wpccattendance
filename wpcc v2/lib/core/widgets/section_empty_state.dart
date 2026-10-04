import 'package:flutter/material.dart';

class SectionEmptyState extends StatelessWidget {
  const SectionEmptyState(
      {super.key,
      required this.icon,
      required this.message,
      this.height = 140});
  final IconData icon;
  final String message;
  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: height,
        child: Center(
            child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon,
                size: 24,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(height: 10),
            Text(message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall),
          ]),
        )),
      );
}
