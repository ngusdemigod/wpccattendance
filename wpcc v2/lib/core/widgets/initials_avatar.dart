import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar({super.key, required this.initials, this.size = 40, this.imageUrl});

  final String initials;
  final double size;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final child = imageUrl != null && imageUrl!.isNotEmpty
        ? ClipOval(child: Image.network(imageUrl!, width: size, height: size, fit: BoxFit.cover))
        : Center(
            child: Text(
              initials,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: size * .25,
                    letterSpacing: -.4,
                  ),
            ),
          );

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFE8EAF0), width: 1),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [WpccColors.lavender, WpccColors.coolBlue, WpccColors.warm],
          stops: [0, .55, 1],
          transform: GradientRotation(2.530727),
        ),
        boxShadow: const [BoxShadow(color: Color(0x0A31374E), blurRadius: 22, offset: Offset(0, 10))],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          child,
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: const Alignment(-.4, -.52),
                  radius: .72,
                  colors: [Colors.white.withValues(alpha: .44), Colors.transparent],
                  stops: const [0, .55],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
