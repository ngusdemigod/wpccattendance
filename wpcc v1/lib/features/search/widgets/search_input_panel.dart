import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../flutter_flow/custom_icons.dart';
import '../models/global_search_models.dart';
import '../../../shared/widgets/interactive_filter_pill.dart';

const _kPrimaryText = Color(0xFF111827);
const _kMuted = Color(0xFF8A8F98);
const _kCard = Color(0xFFFCFBF9);
const _kBorder = Color(0x1A111827);

/// Cream panel holding the pill search field and the results summary row.
class SearchInputPanel extends StatelessWidget {
  const SearchInputPanel({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onClear,
    required this.showSummary,
    required this.query,
    required this.totalMatches,
    required this.activeFilter,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final bool showSummary;
  final String query;
  final int totalMatches;
  final SearchFilter activeFilter;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0x14111827)),
            ),
            child: Row(
              children: [
                const Icon(FFIcons.kmagnifyingGlass,
                    size: 20, color: _kMuted),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    onChanged: onChanged,
                    textInputAction: TextInputAction.search,
                    style: GoogleFonts.instrumentSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _kPrimaryText,
                    ),
                    decoration: InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      hintText: 'Search people, events, notices...',
                      hintStyle: GoogleFonts.instrumentSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: _kMuted,
                      ),
                    ),
                  ),
                ),
                if (controller.text.isNotEmpty) ...[
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: onClear,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF3F4F6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        FFIcons.kx,
                        size: 16,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (showSummary)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 12, 4, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Results for “${query.trim()}”',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.instrumentSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            height: 1.25,
                            color: _kPrimaryText,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$totalMatches matches across the app',
                          style: GoogleFonts.instrumentSans(
                            fontSize: 11,
                            color: _kMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF111113),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      activeFilter == SearchFilter.all
                          ? 'All sections'
                          : activeFilter.label,
                      style: GoogleFonts.instrumentSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Horizontal scrolling filter chips with icons.
class SearchFilterChips extends StatelessWidget {
  const SearchFilterChips({
    super.key,
    required this.active,
    required this.onSelected,
  });

  final SearchFilter active;
  final ValueChanged<SearchFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Row(
        children: [
          for (final filter in SearchFilter.values) ...[
            if (filter != SearchFilter.values.first) const SizedBox(width: 8),
            _FilterChip(
              filter: filter,
              selected: filter == active,
              onTap: () => onSelected(filter),
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.filter,
    required this.selected,
    required this.onTap,
  });

  final SearchFilter filter;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InteractiveFilterPill(
      label: filter.label,
      icon: filter.icon,
      selected: selected,
      onTap: onTap,
    );
  }
}
