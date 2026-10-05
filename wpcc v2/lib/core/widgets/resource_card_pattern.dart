import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/member_material.dart';

class ResourceCardSurface extends StatelessWidget {
  const ResourceCardSurface({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final solid = MemberMaterials.solid(context);
    final content = DecoratedBox(decoration: BoxDecoration(
      color: solid ? theme.colorScheme.surfaceContainerLow : theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: MediaQuery.highContrastOf(context)
          ? theme.colorScheme.onSurface : theme.colorScheme.outlineVariant)), child: child);
    return ClipRRect(borderRadius: BorderRadius.circular(20),
      child: solid ? content : BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16), child: content));
  }
}

/// Abstract washes and curved bands from the approved resource-card CSS.
class ResourceCardPattern extends CustomPainter {
  const ResourceCardPattern({required this.index, required this.dark,
    this.enabled = true});
  final int index;
  final bool dark;
  final bool enabled;

  @override
  void paint(Canvas canvas, Size size) {
    if (!enabled) return;
    const palettes = [
      [Color(0xFF30B3F4), Color(0xFF1595ED), Color(0xFF8ADBFF)],
      [Color(0xFF8D61D8), Color(0xFF7547CB), Color(0xFF9971EF)],
      [Color(0xFF078B46), Color(0xFF007B3B), Color(0xFF39CB95)],
      [Color(0xFFEC4D0C), Color(0xFFD94308), Color(0xFFF39A1C)],
      [Color(0xFFED76A5), Color(0xFFCB4480), Color(0xFFEC8AAB)],
    ];
    const offsets = [Offset(.24, .35), Offset(.36, .18), Offset(-.2, .6),
      Offset(-.12, .55), Offset(.24, .35)];
    final variant = index % palettes.length;
    final colors = palettes[variant];
    final bounds = Offset.zero & size;
    canvas.save();
    canvas.clipRect(bounds);
    canvas.drawRect(bounds, Paint()..shader = LinearGradient(
      begin: const Alignment(-.423, -.906),
      end: const Alignment(.423, .906),
      colors: colors.take(2).map((c) => c.withValues(alpha: dark ? .18 : .1)).toList(),
    ).createShader(bounds));
    // CSS uses content-box sizing, a 24px border, and center rotation.
    final outer = Rect.fromLTWH(size.width * offsets[variant].dx,
      size.height * offsets[variant].dy, size.width * 1.3 + 48,
      size.height * .8 + 48);
    canvas.translate(outer.center.dx, outer.center.dy);
    canvas.rotate(-.4886921906);
    final centered = Rect.fromCenter(center: Offset.zero,
      width: outer.width, height: outer.height);
    final outerShape = RRect.fromRectAndRadius(centered,
      Radius.elliptical(outer.width * .48, outer.height * .48));
    canvas.drawDRRect(outerShape, outerShape.deflate(24),
      Paint()..color = colors[2].withValues(alpha: dark ? .1 : .09));
    canvas.restore();
  }

  @override
  bool shouldRepaint(ResourceCardPattern oldDelegate) =>
      index != oldDelegate.index || dark != oldDelegate.dark || enabled != oldDelegate.enabled;
}
