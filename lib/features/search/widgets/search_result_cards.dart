import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../controllers/global_search_controller.dart';
import '../models/global_search_models.dart';

const _kPrimaryText = Color(0xFF111827);
const _kSecondaryText = Color(0xFF4B5563);
const _kMuted = Color(0xFF8A8F98);
const _kCard = Color(0xFFFCFBF9);
const _kBorder = Color(0x1A111827);
const _kCream = Color(0xFFF1EADD);
const _kMatch = Color(0xFFC3139C);

/// Builds spans highlighting every case-insensitive occurrence of [query].
List<InlineSpan> highlightQuery(String text, String query, TextStyle base) {
  final term = query.trim();
  if (term.isEmpty) return [TextSpan(text: text, style: base)];
  final matchStyle = base.copyWith(color: _kMatch, fontWeight: FontWeight.w600);
  final lowerText = text.toLowerCase();
  final lowerTerm = term.toLowerCase();
  final spans = <InlineSpan>[];
  var start = 0;
  while (true) {
    final index = lowerText.indexOf(lowerTerm, start);
    if (index < 0) {
      if (start < text.length) {
        spans.add(TextSpan(text: text.substring(start), style: base));
      }
      break;
    }
    if (index > start) {
      spans.add(TextSpan(text: text.substring(start, index), style: base));
    }
    spans.add(TextSpan(
      text: text.substring(index, index + term.length),
      style: matchStyle,
    ));
    start = index + term.length;
  }
  return spans;
}

/// [soft circular icon] Section name           View all N >
class SearchSectionHeader extends StatelessWidget {
  const SearchSectionHeader({
    super.key,
    required this.icon,
    required this.title,
    this.trailingLabel,
    this.onTrailingTap,
  });

  final IconData icon;
  final String title;
  final String? trailingLabel;
  final VoidCallback? onTrailingTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: _kCream,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 14, color: const Color(0xFF111113)),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.instrumentSans(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _kPrimaryText,
              ),
            ),
          ),
          if (trailingLabel != null)
            GestureDetector(
              onTap: onTrailingTap,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    trailingLabel!,
                    style: GoogleFonts.instrumentSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _kPrimaryText,
                    ),
                  ),
                  if (onTrailingTap != null)
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: _kPrimaryText,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Standard cream result card: [leading] [kicker/title/body] [chevron].
class SearchResultCard extends StatelessWidget {
  const SearchResultCard({
    super.key,
    required this.result,
    required this.query,
    required this.onTap,
  });

  final GlobalSearchResult result;
  final String query;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 82),
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: _kBorder),
        ),
        child: Row(
          children: [
            SearchResultLeading(result: result),
            const SizedBox(width: 12),
            Expanded(child: _ResultCopy(result: result, query: query)),
            const SizedBox(width: 12),
            const Icon(Icons.chevron_right_rounded, size: 20, color: _kMuted),
          ],
        ),
      ),
    );
  }
}

/// Featured top result card with live-state badges.
class TopResultCard extends StatelessWidget {
  const TopResultCard({
    super.key,
    required this.result,
    required this.query,
    required this.onTap,
  });

  final GlobalSearchResult result;
  final String query;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final badges = <Widget>[
      if (result.isPinned)
        const _Badge(
          label: 'Pinned',
          background: Color(0xFFF9DDF4),
          foreground: Color(0xFFC3139C),
        ),
      if (result.isUpcomingEvent)
        const _Badge(
          label: 'Upcoming',
          background: Color(0xFFE3F5E9),
          foreground: Color(0xFF1A6B35),
        ),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 124),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _kCard,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: _kBorder),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SearchResultLeading(result: result),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ResultCopy(result: result, query: query),
                    if (badges.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(spacing: 8, runSpacing: 8, children: badges),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.chevron_right_rounded, size: 20, color: _kMuted),
            ],
          ),
        ),
      ),
    );
  }
}

/// 2-column grid of quick action shortcut cards.
class QuickActionsGrid extends StatelessWidget {
  const QuickActionsGrid({
    super.key,
    required this.actions,
    required this.onActionTap,
  });

  final List<SearchQuickAction> actions;
  final ValueChanged<SearchQuickAction> onActionTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < actions.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            Expanded(child: _QuickActionCard(
              action: actions[i],
              onTap: () => onActionTap(actions[i]),
            )),
          ],
          if (actions.length == 1) const Expanded(child: SizedBox()),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({required this.action, required this.onTap});

  final SearchQuickAction action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isPeople = action.targetFilter == SearchFilter.people;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 82),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: _kBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  isPeople
                      ? Icons.groups_outlined
                      : Icons.edit_calendar_outlined,
                  size: 22,
                  color: const Color(0xFF111113),
                ),
                _Badge(
                  label: action.badgeLabel,
                  background:
                      isPeople ? const Color(0xFFE4F0FB) : _kCream,
                  foreground: isPeople
                      ? const Color(0xFF1A4F82)
                      : const Color(0xFF151515),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              action.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.instrumentSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.25,
                color: _kPrimaryText,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              action.subtitle,
              style: GoogleFonts.instrumentSans(fontSize: 11, color: _kMuted),
            ),
          ],
        ),
      ),
    );
  }
}

/// Leading visual: live avatar/thumbnail, flat-color initials for people,
/// or a soft cream icon tile.
class SearchResultLeading extends StatelessWidget {
  const SearchResultLeading({super.key, required this.result});

  final GlobalSearchResult result;

  static const _peoplePalette = [
    (Color(0xFFF3E8E5), Color(0xFF111827)),
    (Color(0xFFE3F5E9), Color(0xFF1A6B35)),
    (Color(0xFFE4F0FB), Color(0xFF1A4F82)),
    (Color(0xFFF1EADD), Color(0xFF151515)),
  ];

  @override
  Widget build(BuildContext context) {
    final isPerson = result.section == SearchFilter.people;
    final imageUrl = result.imageUrl;
    if (imageUrl != null && imageUrl.startsWith('http')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(isPerson ? 999 : 20),
        child: Image.network(
          imageUrl,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stack) => _fallback(),
        ),
      );
    }
    return _fallback();
  }

  Widget _fallback() {
    if (result.section == SearchFilter.people) {
      final colors =
          _peoplePalette[result.title.hashCode.abs() % _peoplePalette.length];
      return Container(
        width: 50,
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: colors.$1, shape: BoxShape.circle),
        child: Text(
          _initials(result.title),
          style: GoogleFonts.instrumentSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: colors.$2,
          ),
        ),
      );
    }
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: _kCream,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Icon(_sectionIcon, size: 23, color: const Color(0xFF111113)),
    );
  }

  IconData get _sectionIcon {
    switch (result.section) {
      case SearchFilter.events:
        return Icons.event_rounded;
      case SearchFilter.announcements:
        return Icons.campaign_outlined;
      case SearchFilter.departments:
        return Icons.church_outlined;
      default:
        return Icons.search_rounded;
    }
  }

  static String _initials(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}

class _ResultCopy extends StatelessWidget {
  const _ResultCopy({required this.result, required this.query});

  final GlobalSearchResult result;
  final String query;

  String get _kicker {
    switch (result.section) {
      case SearchFilter.people:
        return _joinKicker('Member profile', result.subtitle);
      case SearchFilter.events:
        final start = result.eventStartAt;
        return _joinKicker(
          'Event',
          start == null ? null : DateFormat('EEE h:mm a').format(start.toLocal()),
        );
      case SearchFilter.announcements:
        final created = result.createdAt;
        return _joinKicker(
          result.subtitle ?? 'Announcement',
          created == null
              ? null
              : DateFormat('MMM d, h:mm a').format(created.toLocal()),
        );
      case SearchFilter.departments:
        return _joinKicker('Department', result.subtitle);
      case SearchFilter.all:
        return '';
    }
  }

  static String _joinKicker(String first, String? second) {
    if (second == null || second.isEmpty) return first;
    return '$first · $second';
  }

  @override
  Widget build(BuildContext context) {
    final body = result.body;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _kicker,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.instrumentSans(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: _kMuted,
          ),
        ),
        const SizedBox(height: 5),
        Text.rich(
          TextSpan(
            children: highlightQuery(
              result.title,
              query,
              GoogleFonts.instrumentSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.25,
                color: _kPrimaryText,
              ),
            ),
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (body != null) ...[
          const SizedBox(height: 4),
          Text.rich(
            TextSpan(
              children: highlightQuery(
                body,
                query,
                GoogleFonts.instrumentSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  height: 1.4,
                  color: _kSecondaryText,
                ),
              ),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.instrumentSans(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: foreground,
        ),
      ),
    );
  }
}
