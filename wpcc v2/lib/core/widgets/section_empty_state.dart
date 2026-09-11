import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class SectionEmptyState extends StatefulWidget {
  const SectionEmptyState({super.key, required this.icon, required this.message, this.height = 140});
  final IconData icon;
  final String message;
  final double height;

  @override
  State<SectionEmptyState> createState() => _SectionEmptyStateState();
}

class _SectionEmptyStateState extends State<SectionEmptyState> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat();

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final x = -1.5 + (_controller.value * 3);
          return DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment(x - .7, 0),
                end: Alignment(x + .7, 0),
                colors: const [Color(0x00F0F1F6), Color(0x99F0F1F6), Color(0x00F0F1F6)],
              ),
            ),
            child: child,
          );
        },
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(widget.icon, size: 25, color: WpccColors.muted),
            const SizedBox(height: 8),
            Text(widget.message, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: WpccColors.muted)),
          ]),
        ),
      ),
    );
  }
}
