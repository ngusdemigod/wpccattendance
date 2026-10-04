import 'package:flutter/material.dart';

/// Page padding uses the available viewport; card layouts use local constraints.
EdgeInsets adaptivePagePadding(BuildContext context,
    {double phone = 18, double top = 18, double bottom = 112}) {
  final width = MediaQuery.sizeOf(context).width;
  final horizontal = width < 600
      ? phone
      : width < 900
          ? 24.0
          : 32.0;
  return EdgeInsets.fromLTRB(horizontal, top, horizontal, bottom);
}

/// A stable Wrap tree preserves child state when rotation changes the column count.
class AdaptiveSections extends StatelessWidget {
  const AdaptiveSections({super.key, required this.children, this.gap = 24});
  final List<Widget> children;
  final double gap;
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final columns = box.maxWidth >= 900 ? 2 : 1;
        final width = (box.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(spacing: gap, runSpacing: gap, children: [
          for (final child in children) SizedBox(width: width, child: child),
        ]);
      });
}

class AdaptiveCards extends StatelessWidget {
  const AdaptiveCards(
      {super.key,
      required this.children,
      this.minimumWidth = 260,
      this.maximumColumns = 3,
      this.phoneColumns = 1,
      this.gap = 12});
  final List<Widget> children;
  final double minimumWidth, gap;
  final int maximumColumns, phoneColumns;
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final columns = MediaQuery.sizeOf(context).width < 600
            ? phoneColumns
            : ((box.maxWidth + gap) / (minimumWidth + gap))
                .floor()
                .clamp(phoneColumns, maximumColumns);
        final width = (box.maxWidth - (columns - 1) * gap) / columns;
        return Wrap(spacing: gap, runSpacing: gap, children: [
          for (final child in children) SizedBox(width: width, child: child),
        ]);
      });
}
