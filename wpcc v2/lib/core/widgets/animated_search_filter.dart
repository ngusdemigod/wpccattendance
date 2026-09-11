import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../theme/app_theme.dart';

class AnimatedSearchFilter extends StatefulWidget {
  const AnimatedSearchFilter({
    super.key,
    required this.hint,
    required this.onSearch,
    required this.filterOptions,
    required this.selectedFilter,
    required this.onFilter,
  });

  final String hint;
  final ValueChanged<String> onSearch;
  final List<String> filterOptions;
  final String selectedFilter;
  final ValueChanged<String> onFilter;

  @override
  State<AnimatedSearchFilter> createState() => _AnimatedSearchFilterState();
}

class _AnimatedSearchFilterState extends State<AnimatedSearchFilter> {
  bool expanded = false;
  final controller = TextEditingController();
  final focusNode = FocusNode();

  @override
  void dispose() {
    controller.dispose();
    focusNode.dispose();
    super.dispose();
  }

  void open() {
    setState(() => expanded = true);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => focusNode.requestFocus());
  }

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        width: expanded ? 218 : 48,
        height: 48,
        decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .94),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: WpccColors.line)),
        child: Row(children: [
          IconButton(
              onPressed: expanded ? () => focusNode.requestFocus() : open,
              icon: Icon(PhosphorIcons.magnifyingGlass(), size: 18),
              padding: EdgeInsets.zero),
          if (expanded)
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                onChanged: widget.onSearch,
                onTapOutside: (_) {
                  focusNode.unfocus();
                  if (controller.text.isEmpty) setState(() => expanded = false);
                },
                style: Theme.of(context).textTheme.bodySmall,
                decoration: InputDecoration.collapsed(hintText: widget.hint),
              ),
            ),
          if (expanded && controller.text.isNotEmpty)
            IconButton(
              onPressed: () {
                controller.clear();
                widget.onSearch('');
                setState(() {});
              },
              icon: Icon(PhosphorIcons.x(), size: 14),
              padding: EdgeInsets.zero,
              tooltip: 'Clear search',
              constraints: const BoxConstraints.tightFor(width: 48, height: 48),
            ),
        ]),
      ),
      const SizedBox(width: 8),
      PopupMenuButton<String>(
        tooltip: 'Filter',
        initialValue: widget.selectedFilter,
        onSelected: widget.onFilter,
        color: Colors.white.withValues(alpha: .96),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        itemBuilder: (context) => widget.filterOptions
            .map((option) => PopupMenuItem(
                  value: option,
                  child: Container(
                    width: 148,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                    decoration: BoxDecoration(
                        color: widget.selectedFilter == option
                            ? WpccColors.ink
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12)),
                    child: Text(option,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: widget.selectedFilter == option
                                ? Colors.white
                                : WpccColors.inkSoft)),
                  ),
                ))
            .toList(),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
              color: widget.selectedFilter == widget.filterOptions.first
                  ? Colors.white
                  : WpccColors.ink,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                  color: widget.selectedFilter == widget.filterOptions.first
                      ? WpccColors.line
                      : WpccColors.ink)),
          child: Icon(PhosphorIcons.funnelSimple(),
              size: 18,
              color: widget.selectedFilter == widget.filterOptions.first
                  ? WpccColors.ink
                  : Colors.white),
        ),
      ),
    ]);
  }
}
