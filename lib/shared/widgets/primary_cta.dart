import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import 'fade_slide_switcher.dart';

enum CtaState { idle, loading, success, disabled }

class PrimaryCta extends StatefulWidget {
  const PrimaryCta({
    super.key,
    required this.label,
    required this.onPressed,
    this.state = CtaState.idle,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final CtaState state;
  final IconData? icon;

  @override
  State<PrimaryCta> createState() => _PrimaryCtaState();
}

class _PrimaryCtaState extends State<PrimaryCta>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.0,
      upperBound: 1.0,
      value: 1.0,
    );
    _scaleAnim = Tween<double>(begin: 0.98, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _onTapDown(_) => _scaleController.reverse();
  void _onTapUp(_) => _scaleController.forward();
  void _onTapCancel() => _scaleController.forward();

  @override
  Widget build(BuildContext context) {
    final isDisabled =
        widget.state == CtaState.disabled || widget.state == CtaState.loading;

    final bgColor = isDisabled ? const Color(0xFFE7E2DC) : AppColors.primary;
    final fgColor = isDisabled ? const Color(0xFF8D7D70) : Colors.white;

    return GestureDetector(
      onTapDown: isDisabled ? null : _onTapDown,
      onTapUp: isDisabled ? null : _onTapUp,
      onTapCancel: isDisabled ? null : _onTapCancel,
      onTap: isDisabled ? null : widget.onPressed,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: 54,
          decoration: BoxDecoration(
            color: isDisabled ? bgColor : bgColor,
            borderRadius: BorderRadius.circular(999),
          ),
          alignment: Alignment.center,
          child: FadeSlideSwitcher(
            duration: const Duration(milliseconds: 180),
            reverseDuration: const Duration(milliseconds: 140),
            offset: const Offset(0, 0.06),
            child: widget.state == CtaState.loading
                ? const SizedBox(
                    key: ValueKey('loading'),
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    key: const ValueKey('content'),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(widget.icon, size: 20, color: fgColor),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        widget.label,
                        style: TextStyle(
                          color: fgColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
