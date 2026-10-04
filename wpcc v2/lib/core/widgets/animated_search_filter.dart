import 'package:flutter/material.dart';
import '../theme/app_motion.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

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
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : AppMotion.control,
        curve: AppMotion.curve,
        width: expanded ? 218 : 50,
        height: 50,
        decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: .94),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant)),
        child: Row(children: [
          IconButton(
              onPressed: expanded ? () => focusNode.requestFocus() : open,
              tooltip: 'Search',
              icon: Icon(PhosphorIcons.magnifyingGlass(), size: 18),
              padding: EdgeInsets.zero,
              constraints:
                  const BoxConstraints.tightFor(width: 48, height: 48)),
          if (expanded)
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                onChanged: (value) {
                  widget.onSearch(value);
                  setState(() {});
                },
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
        color: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        itemBuilder: (context) => widget.filterOptions
            .map((option) => PopupMenuItem(
                  value: option,
                  child: Container(
                    width: 148,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                    decoration: BoxDecoration(
                        color: widget.selectedFilter == option
                            ? Theme.of(context).colorScheme.onSurface
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12)),
                    child: Text(option,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: widget.selectedFilter == option
                                ? Theme.of(context).colorScheme.surface
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant)),
                  ),
                ))
            .toList(),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
              color: widget.selectedFilter == widget.filterOptions.first
                  ? Theme.of(context).colorScheme.surface
                  : Theme.of(context).colorScheme.onSurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: widget.selectedFilter == widget.filterOptions.first
                      ? Theme.of(context).colorScheme.outlineVariant
                      : Theme.of(context).colorScheme.onSurface)),
          child: Icon(PhosphorIcons.funnelSimple(),
              size: 18,
              color: widget.selectedFilter == widget.filterOptions.first
                  ? Theme.of(context).colorScheme.onSurface
                  : Theme.of(context).colorScheme.surface),
        ),
      ),
    ]);
  }
}
