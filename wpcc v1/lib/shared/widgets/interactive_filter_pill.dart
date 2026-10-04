import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class InteractiveFilterPill extends StatelessWidget {
  const InteractiveFilterPill({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.height = 34,
    this.horizontalPadding = 14,
    this.iconSize = 15,
    this.spacing = 6,
    this.selectedBackgroundColor = const Color(0xFF111113),
    this.unselectedBackgroundColor = Colors.white,
    this.selectedForegroundColor = Colors.white,
    this.unselectedForegroundColor = const Color(0xFF374151),
    this.selectedBorderColor = const Color(0xFF111113),
    this.unselectedBorderColor = const Color(0x24111827),
    this.fontSize = 12,
    this.fontWeight = FontWeight.w500,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final double height;
  final double horizontalPadding;
  final double iconSize;
  final double spacing;
  final Color selectedBackgroundColor;
  final Color unselectedBackgroundColor;
  final Color selectedForegroundColor;
  final Color unselectedForegroundColor;
  final Color selectedBorderColor;
  final Color unselectedBorderColor;
  final double fontSize;
  final FontWeight fontWeight;

  @override
  Widget build(BuildContext context) {
    final foregroundColor =
        selected ? selectedForegroundColor : unselectedForegroundColor;

    return Material(
      color: selected ? selectedBackgroundColor : unselectedBackgroundColor,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          height: height,
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? selectedBorderColor : unselectedBorderColor,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox.square(
                dimension: iconSize,
                child: Center(
                  child: Icon(
                    icon,
                    size: iconSize,
                    color: foregroundColor,
                  ),
                ),
              ),
              SizedBox(width: spacing),
              Text(
                label,
                textScaler: TextScaler.noScaling,
                style: GoogleFonts.instrumentSans(
                  fontSize: fontSize,
                  fontWeight: fontWeight,
                  height: 1,
                  color: foregroundColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
