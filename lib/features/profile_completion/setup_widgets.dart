import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../shared/widgets/fade_slide_switcher.dart';

class SetupScaffold extends StatelessWidget {
  const SetupScaffold({
    super.key,
    required this.header,
    required this.body,
    required this.footer,
  });

  final Widget header;
  final Widget body;
  final Widget footer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(32, 24, 32, 28),
              child: Column(
                children: [
                  header,
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: constraints.maxHeight - 162),
                        child: Center(child: body),
                      ),
                    ),
                  ),
                  footer,
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class SetupHeader extends StatelessWidget {
  const SetupHeader({
    super.key,
    required this.label,
    this.onBack,
  });

  final String label;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 32,
          height: 32,
          child: onBack == null
              ? null
              : IconButton(
                  onPressed: onBack,
                  padding: EdgeInsets.zero,
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 16,
                    color: Color(0xFF111113),
                  ),
                ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: StepIndicator(label: label),
          ),
        ),
      ],
    );
  }
}

class StepIndicator extends StatelessWidget {
  const StepIndicator({
    super.key,
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.instrumentSans(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.4,
        color: const Color(0xFFA0A6AF),
      ),
    );
  }
}

class SetupTitle extends StatelessWidget {
  const SetupTitle({
    super.key,
    required this.text,
    this.isSuccess = false,
  });

  final String text;
  final bool isSuccess;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: GoogleFonts.instrumentSerif(
        textStyle: TextStyle(
          fontFamily: 'Instrument Serif',
          fontSize: isSuccess ? 38 : 34,
          fontWeight: FontWeight.w400,
          height: 0.98,
          letterSpacing: isSuccess ? -1.4 : -1.2,
          color: const Color(0xFF111827),
        ),
      ),
    );
  }
}

class SetupCopy extends StatelessWidget {
  const SetupCopy({
    super.key,
    required this.text,
    this.width = 270,
  });

  final String text;
  final double width;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: width),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.instrumentSans(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          height: 1.55,
          color: const Color(0xFF7C828D),
        ),
      ),
    );
  }
}

class PrimarySetupButton extends StatelessWidget {
  const PrimarySetupButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.isPink = false,
    this.leadingIcon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isPink;
  final IconData? leadingIcon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shadowColor: Colors.transparent,
          backgroundColor:
              isPink ? const Color(0xFFD600B8) : const Color(0xFF111113),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        child: FadeSlideSwitcher(
          duration: const Duration(milliseconds: 180),
          reverseDuration: const Duration(milliseconds: 140),
          offset: const Offset(0, 0.06),
          child: isLoading
              ? const SizedBox(
                  key: ValueKey('loading'),
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Row(
                  key: const ValueKey('content'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (leadingIcon != null) ...[
                      Icon(leadingIcon, size: 18, color: Colors.white),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      label,
                      style: GoogleFonts.instrumentSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class SecurityFooter extends StatelessWidget {
  const SecurityFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.lock_outline_rounded,
          size: 14,
          color: Color(0xFF7C828D),
        ),
        const SizedBox(width: 7),
        Text(
          'Your personal data is end to end encrypted',
          style: GoogleFonts.instrumentSans(
            fontSize: 11,
            fontWeight: FontWeight.w400,
            height: 1.35,
            color: const Color(0xFFA0A6AF),
          ),
        ),
      ],
    );
  }
}

class ProgressDots extends StatelessWidget {
  const ProgressDots({
    super.key,
    required this.activeIndex,
    this.total = 3,
  });

  final int activeIndex;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (index) {
        final isActive = index == activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: isActive ? 20 : 6,
          height: 6,
          margin: EdgeInsets.only(right: index == total - 1 ? 0 : 6),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF111113) : const Color(0xFFD7D2CB),
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}

class UploadIconRing extends StatefulWidget {
  const UploadIconRing({super.key});

  @override
  State<UploadIconRing> createState() => _UploadIconRingState();
}

class _UploadIconRingState extends State<UploadIconRing>
    with TickerProviderStateMixin {
  late final AnimationController _innerController;
  late final AnimationController _outerController;

  @override
  void initState() {
    super.initState();
    _innerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
    _outerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 32),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _innerController.dispose();
    _outerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 186,
      height: 186,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _outerController,
            builder: (context, child) {
              return Transform.rotate(
                angle: -_outerController.value * math.pi * 2,
                child: child,
              );
            },
            child: const CustomPaint(
              size: Size.square(186),
              painter: _RingPainter(
                color: Color(0x2ED600B8),
                radius: 92,
                strokeWidth: 1,
                dashLength: 5,
                gapLength: 4,
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _innerController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _innerController.value * math.pi * 2,
                child: child,
              );
            },
            child: const CustomPaint(
              size: Size.square(150),
              painter: _RingPainter(
                color: Color(0x47111827),
                radius: 74,
                strokeWidth: 2,
                dashLength: 3,
                gapLength: 4,
              ),
            ),
          ),
          Container(
            width: 102,
            height: 102,
            decoration: const BoxDecoration(
              color: Color(0xFFF1EADD),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.add_photo_alternate_outlined,
              size: 42,
              color: Color(0xFF111113),
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileImagePreview extends StatelessWidget {
  const ProfileImagePreview({
    super.key,
    required this.initials,
    required this.onChangeImage,
    required this.scale,
    required this.offset,
    required this.onTransformChanged,
    this.avatarBytes,
    this.legacyAvatarUrl = '',
  });

  final Uint8List? avatarBytes;
  final String legacyAvatarUrl;
  final String initials;
  final VoidCallback onChangeImage;
  final double scale;
  final Offset offset;
  final ValueChanged<ProfileImageTransform> onTransformChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 146,
      height: 146,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Center(
            child: Container(
              width: 132,
              height: 132,
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0x14111827)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A111827),
                    blurRadius: 46,
                    offset: Offset(0, 18),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipOval(
                      child: AdjustableAvatarImage(
                        avatarBytes: avatarBytes,
                        legacyAvatarUrl: legacyAvatarUrl,
                        initials: initials,
                        scale: scale,
                        offset: offset,
                        onTransformChanged: onTransformChanged,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 4,
                    bottom: 4,
                    child: Semantics(
                      button: true,
                      label: 'Change profile image',
                      child: InkWell(
                        onTap: onChangeImage,
                        customBorder: const CircleBorder(),
                        child: Ink(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: const Color(0xFF111113),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                          child: const Icon(
                            Icons.camera_alt_outlined,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileImageTransform {
  const ProfileImageTransform({
    required this.scale,
    required this.offset,
  });

  final double scale;
  final Offset offset;
}

class AdjustableAvatarImage extends StatefulWidget {
  const AdjustableAvatarImage({
    super.key,
    required this.avatarBytes,
    required this.legacyAvatarUrl,
    required this.initials,
    required this.scale,
    required this.offset,
    required this.onTransformChanged,
  });

  final Uint8List? avatarBytes;
  final String legacyAvatarUrl;
  final String initials;
  final double scale;
  final Offset offset;
  final ValueChanged<ProfileImageTransform> onTransformChanged;

  @override
  State<AdjustableAvatarImage> createState() => _AdjustableAvatarImageState();
}

class _AdjustableAvatarImageState extends State<AdjustableAvatarImage> {
  double _baseScale = 1;
  Offset _baseOffset = Offset.zero;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onScaleStart: (_) {
            _baseScale = widget.scale;
            _baseOffset = widget.offset;
          },
          onScaleUpdate: (details) {
            final nextScale = (_baseScale * details.scale).clamp(1.0, 3.0);
            final maxTravel = (constraints.biggest.shortestSide * (nextScale - 1)) / 2;
            final unclampedOffset = _baseOffset + details.focalPointDelta;
            final nextOffset = Offset(
              unclampedOffset.dx.clamp(-maxTravel, maxTravel),
              unclampedOffset.dy.clamp(-maxTravel, maxTravel),
            );
            widget.onTransformChanged(
              ProfileImageTransform(
                scale: nextScale,
                offset: nextOffset,
              ),
            );
          },
          child: Transform.translate(
            offset: widget.offset,
            child: Transform.scale(
              scale: widget.scale,
              child: _AvatarImage(
                avatarBytes: widget.avatarBytes,
                legacyAvatarUrl: widget.legacyAvatarUrl,
                initials: widget.initials,
              ),
            ),
          ),
        );
      },
    );
  }
}

class SetupTextField extends StatelessWidget {
  const SetupTextField({
    super.key,
    required this.label,
    required this.controller,
    required this.helper,
    this.errorText,
    this.keyboardType = TextInputType.text,
    this.onChanged,
    this.hintText,
  });

  final String label;
  final TextEditingController controller;
  final String helper;
  final String? errorText;
  final TextInputType keyboardType;
  final ValueChanged<String>? onChanged;
  final String? hintText;

  @override
  Widget build(BuildContext context) {
    return _SetupInputShell(
      label: label,
      helper: helper,
      errorText: errorText,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        onChanged: onChanged,
        style: GoogleFonts.instrumentSans(
          fontSize: 17,
          fontWeight: FontWeight.w400,
          height: 1.4,
          color: const Color(0xFF111827),
        ),
        decoration: _inputDecoration(hintText),
      ),
    );
  }
}

class SetupTextArea extends StatelessWidget {
  const SetupTextArea({
    super.key,
    required this.label,
    required this.controller,
    required this.helper,
    this.errorText,
    this.onChanged,
    this.hintText,
  });

  final String label;
  final TextEditingController controller;
  final String helper;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final String? hintText;

  @override
  Widget build(BuildContext context) {
    return _SetupInputShell(
      label: label,
      helper: helper,
      errorText: errorText,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        maxLines: 3,
        minLines: 3,
        style: GoogleFonts.instrumentSans(
          fontSize: 17,
          fontWeight: FontWeight.w400,
          height: 1.4,
          color: const Color(0xFF111827),
        ),
        decoration: _inputDecoration(hintText),
      ),
    );
  }
}

class SetupPickerField extends StatelessWidget {
  const SetupPickerField({
    super.key,
    required this.label,
    required this.value,
    required this.helper,
    required this.onTap,
    this.errorText,
    this.hintText,
    this.trailingIcon = Icons.keyboard_arrow_down_rounded,
  });

  final String label;
  final String value;
  final String helper;
  final VoidCallback onTap;
  final String? errorText;
  final String? hintText;
  final IconData trailingIcon;

  @override
  Widget build(BuildContext context) {
    final hasValue = value.trim().isNotEmpty;
    return _SetupInputShell(
      label: label,
      helper: helper,
      errorText: errorText,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  hasValue ? value : (hintText ?? ''),
                  style: GoogleFonts.instrumentSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w400,
                    height: 1.4,
                    color: hasValue
                        ? const Color(0xFF111827)
                        : const Color(0xFFB4B8BF),
                  ),
                ),
              ),
              Icon(
                trailingIcon,
                size: 20,
                color: const Color(0xFF7C828D),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

InputDecoration _inputDecoration(String? hintText) {
  return InputDecoration(
    isDense: true,
    hintText: hintText,
    hintStyle: GoogleFonts.instrumentSans(
      fontSize: 17,
      fontWeight: FontWeight.w400,
      color: const Color(0xFFB4B8BF),
    ),
    border: const UnderlineInputBorder(
      borderSide: BorderSide(color: Color(0x29111827)),
    ),
    enabledBorder: const UnderlineInputBorder(
      borderSide: BorderSide(color: Color(0x29111827)),
    ),
    focusedBorder: const UnderlineInputBorder(
      borderSide: BorderSide(color: Color(0xFF111113)),
    ),
    contentPadding: const EdgeInsets.only(bottom: 14),
  );
}

class _SetupInputShell extends StatelessWidget {
  const _SetupInputShell({
    required this.label,
    required this.helper,
    required this.child,
    this.errorText,
  });

  final String label;
  final String helper;
  final String? errorText;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.instrumentSans(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.32,
            color: const Color(0xFFA0A6AF),
          ),
        ),
        const SizedBox(height: 11),
        child,
        const SizedBox(height: 12),
        Text(
          errorText ?? helper,
          style: GoogleFonts.instrumentSans(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            height: 1.45,
            color: errorText == null
                ? const Color(0xFF7C828D)
                : const Color(0xFFD92D20),
          ),
        ),
      ],
    );
  }
}

class SuccessCheck extends StatelessWidget {
  const SuccessCheck({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 112,
      height: 112,
      decoration: const BoxDecoration(
        color: Color(0xFFE3F5E9),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Color(0x8FE3F5E9),
            blurRadius: 0,
            spreadRadius: 12,
          ),
        ],
      ),
      child: const Icon(
        Icons.check_rounded,
        size: 56,
        color: Color(0xFF1A6B35),
      ),
    );
  }
}

class _AvatarImage extends StatelessWidget {
  const _AvatarImage({
    required this.avatarBytes,
    required this.legacyAvatarUrl,
    required this.initials,
  });

  final Uint8List? avatarBytes;
  final String legacyAvatarUrl;
  final String initials;

  @override
  Widget build(BuildContext context) {
    if (avatarBytes != null) {
      return Image.memory(
        avatarBytes!,
        fit: BoxFit.cover,
      );
    }

    if (legacyAvatarUrl.trim().isNotEmpty) {
      return Image.network(
        legacyAvatarUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _AvatarFallback(initials: initials);
        },
      );
    }

    return _AvatarFallback(initials: initials);
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback({
    required this.initials,
  });

  final String initials;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFB88A5A),
            Color(0xFFE9CFA8),
            Color(0xFF7A4F32),
          ],
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: GoogleFonts.instrumentSans(
            fontSize: 36,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.color,
    required this.radius,
    required this.strokeWidth,
    required this.dashLength,
    required this.gapLength,
  });

  final Color color;
  final double radius;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = color
      ..strokeCap = StrokeCap.round;
    final center = size.center(Offset.zero);
    final circumference = 2 * math.pi * radius;
    final arcLength = (dashLength / circumference) * 2 * math.pi;
    final gapArc = (gapLength / circumference) * 2 * math.pi;

    double start = 0;
    while (start < 2 * math.pi) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        arcLength,
        false,
        paint,
      );
      start += arcLength + gapArc;
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return color != oldDelegate.color ||
        radius != oldDelegate.radius ||
        strokeWidth != oldDelegate.strokeWidth ||
        dashLength != oldDelegate.dashLength ||
        gapLength != oldDelegate.gapLength;
  }
}
