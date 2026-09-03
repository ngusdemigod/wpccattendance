import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../app/theme/design_tokens.dart';
import '../../data/mock_data.dart';
import 'fade_slide_switcher.dart';
import 'gradient_avatar.dart';

class PeopleSuggestionCard extends StatefulWidget {
  const PeopleSuggestionCard({
    super.key,
    required this.person,
  });

  final PersonSuggestion person;

  @override
  State<PeopleSuggestionCard> createState() => _PeopleSuggestionCardState();
}

class _PeopleSuggestionCardState extends State<PeopleSuggestionCard> {
  bool _actioned = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final text = context.appText;
    final isConnect = widget.person.actionType == PersonActionType.connect;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(tokens.radiusMd),
        border: Border.all(color: tokens.border),
      ),
      child: Row(
        children: [
          GradientAvatar(
            initials: widget.person.avatarInitials.isNotEmpty
                ? widget.person.avatarInitials
                : widget.person.name
                    .split(' ')
                    .where((s) => s.isNotEmpty)
                    .take(2)
                    .map((s) => s[0])
                    .join(),
            colors: widget.person.avatarColors,
            radius: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.person.name,
                  style: text.cardTitleStrong(
                    color: const Color(0xFF171312),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.person.mutuals > 0
                      ? '${widget.person.role} • ${widget.person.mutuals} mutuals'
                      : widget.person.role,
                  style: text.supportText(
                    color: const Color(0xFF8D7D70),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => setState(() => _actioned = !_actioned),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: _actioned
                    ? AppColors.primarySoft
                    : isConnect
                        ? const Color(0xFF171312)
                        : AppColors.primarySoft,
                borderRadius: BorderRadius.circular(999),
                border: _actioned
                    ? null
                    : isConnect
                        ? null
                        : Border.all(color: AppColors.primary),
              ),
              child: FadeSlideSwitcher(
                duration: const Duration(milliseconds: 180),
                reverseDuration: const Duration(milliseconds: 140),
                offset: const Offset(0, 0.06),
                child: Text(
                  _actioned
                      ? (isConnect ? 'Requested' : 'Following')
                      : (isConnect ? 'Connect' : 'Follow'),
                  key: ValueKey<bool>(_actioned),
                  style: text.pillLabel(
                    color: _actioned
                        ? AppColors.primary
                        : isConnect
                            ? Colors.white
                            : AppColors.primary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
