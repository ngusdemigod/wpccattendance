import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../theme/member_theme.dart';
import '../theme/app_motion.dart';
import 'member_glass.dart';

EdgeInsets memberPagePadding(BuildContext context,
    {double phone = 20, double top = 20, double bottom = 124}) {
  final clearance = MediaQuery.paddingOf(context).bottom + 16;
  return EdgeInsets.fromLTRB(
      MediaQuery.sizeOf(context).width < 600 ? phone : 32,
      top,
      MediaQuery.sizeOf(context).width < 600 ? phone : 32,
      bottom > clearance ? bottom : clearance);
}

class MemberPageHeader extends StatelessWidget {
  const MemberPageHeader(
      {super.key,
      required this.title,
      this.actions = const [],
      this.subtitle,
      this.leading,
      this.onBack});
  final String title;
  final List<Widget> actions;
  final String? subtitle;
  final Widget? leading;
  final VoidCallback? onBack;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            if (leading != null || onBack != null) ...[
              leading ??
                  MemberIconButton(
                      icon: PhosphorIconsRegular.caretLeft,
                      label: 'Back',
                      onPressed: onBack),
              const SizedBox(width: 10),
            ],
            Expanded(
                child: Text(title,
                    style: Theme.of(context).textTheme.headlineSmall)),
            if (actions.isNotEmpty) const SizedBox(width: 8),
            ...actions,
          ]),
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
          ],
        ]),
      );
}

class MemberSectionHeader extends StatelessWidget {
  const MemberSectionHeader({super.key, required this.title, this.action});
  final String title;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(bottom: action == null ? 14 : 2),
        child: Row(children: [
          Expanded(
              child:
                  Text(title, style: Theme.of(context).textTheme.titleLarge)),
          if (action != null) ...[const SizedBox(width: 8), action!],
        ]),
      );
}

class MemberIconButton extends StatelessWidget {
  const MemberIconButton(
      {super.key,
      required this.icon,
      required this.label,
      required this.onPressed,
      this.autofocus = false,
      this.plain = false,
      this.surface = true,
      this.iconSize = 20});
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool plain, surface, autofocus;
  final double iconSize;
  @override
  Widget build(BuildContext context) => AppPressMotion(
      child: SizedBox.square(
          dimension: 48,
          child: Stack(alignment: Alignment.center, children: [
            if (!plain && surface)
              SizedBox(
                  width: 40,
                  height: 40,
                  child:
                      const MemberGlass(radius: 20, child: SizedBox.expand())),
            IconButton(
              autofocus: autofocus,
              tooltip: label,
              onPressed: onPressed,
              style: IconButton.styleFrom(
                backgroundColor: Colors.transparent,
                minimumSize: const Size(48, 48),
                shape: const CircleBorder(),
              ),
              icon: Icon(icon, size: iconSize),
            )
          ])));
}

class MemberArtwork extends StatelessWidget {
  const MemberArtwork(
      {super.key,
      required this.imageUrl,
      this.size = 64,
      this.height,
      this.icon,
      this.radius = 12});
  final String? imageUrl;
  final double size;
  final double? height;
  final double radius;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: SizedBox(
            width: size,
            height: height ?? size,
            child: _Image(
              url: imageUrl,
              icon: icon ?? PhosphorIconsRegular.image,
            )),
      );
}

class _Image extends StatelessWidget {
  const _Image({required this.url, required this.icon});
  final String? url;
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    final fallback = ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Center(
          child: Icon(icon,
              size: 28, color: Theme.of(context).colorScheme.onSurfaceVariant)),
    );
    return url == null || url!.trim().isEmpty
        ? fallback
        : Image.network(
            url!,
            fit: BoxFit.cover,
            excludeFromSemantics: true,
            errorBuilder: (_, __, ___) => fallback,
            loadingBuilder: (_, child, progress) =>
                progress == null ? child : fallback,
          );
  }
}

class MemberPosterCard extends StatelessWidget {
  static const textScrim = Color(0xB3000000);
  const MemberPosterCard(
      {super.key,
      required this.title,
      required this.metadata,
      required this.imageUrl,
      required this.onTap,
      this.heroTag,
      this.width = 202,
      this.height = 253});
  final String title, metadata;
  final String? imageUrl, heroTag;
  final VoidCallback? onTap;
  final double width, height;
  @override
  Widget build(BuildContext context) {
    final extra = (MediaQuery.textScalerOf(context).scale(17) - 17) * 3.6;
    Widget art =
        _Image(url: imageUrl, icon: PhosphorIconsRegular.calendarBlank);
    if (heroTag != null) art = Hero(tag: heroTag!, child: art);
    return SizedBox(
        width: width,
        height: height + extra,
        child: Material(
          clipBehavior: Clip.antiAlias,
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          child: Semantics(
            button: true,
            enabled: onTap != null,
            onTap: onTap,
            label: '$title, $metadata',
            excludeSemantics: true,
            child: InkWell(
              onTap: onTap,
              child: Stack(fit: StackFit.expand, children: [
                art,
                const DecoratedBox(
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Color(0x10000000),
                    Color(0xAD000000)
                  ],
                  stops: [0.27, 0.44, 1],
                ))),
                Positioned(
                    left: 12,
                    right: 12,
                    bottom: 12,
                    child: Stack(clipBehavior: Clip.none, children: [
                      const Positioned.fill(
                          top: -40,
                          left: -12,
                          right: -12,
                          bottom: -12,
                          child: DecoratedBox(
                              decoration: BoxDecoration(
                                  gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              textScrim,
                              Color(0xCC000000)
                            ],
                            stops: [0, .35, 1],
                          )))),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(title,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 17,
                                    height: 23 / 17,
                                  )),
                          if (metadata.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(metadata,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: const Color(0xFFE5E5E5))),
                          ],
                        ],
                      ),
                    ])),
              ]),
            ),
          ),
        ));
  }
}

class MemberListRow extends StatelessWidget {
  const MemberListRow(
      {super.key,
      required this.title,
      this.subtitle,
      this.leading,
      this.trailing,
      this.onTap,
      this.subtitleWidget,
      this.selected,
      this.plain = false});
  final String title;
  final String? subtitle;
  final Widget? leading, trailing;
  final Widget? subtitleWidget;
  final bool plain;
  final bool? selected;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Semantics(
      selected: selected,
      child: Material(
        color:
            plain ? Colors.transparent : Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(plain ? 0 : 20),
          side: plain
              ? BorderSide.none
              : BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: plain ? 64 : 76),
              child: Padding(
                  padding: plain
                      ? const EdgeInsets.symmetric(vertical: 12)
                      : const EdgeInsets.all(11),
                  child: Row(children: [
                    if (leading != null) ...[
                      leading!,
                      const SizedBox(width: 12)
                    ],
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                          Text(title,
                              style: Theme.of(context).textTheme.titleMedium),
                          if (subtitleWidget != null ||
                              subtitle != null && subtitle!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            subtitleWidget ??
                                Text(subtitle!,
                                    style:
                                        Theme.of(context).textTheme.bodySmall),
                          ],
                        ])),
                    if (trailing != null) ...[
                      const SizedBox(width: 8),
                      trailing!
                    ] else if (onTap != null) ...[
                      const SizedBox(width: 8),
                      Icon(PhosphorIconsRegular.caretRight,
                          size: 16,
                          color: Theme.of(context).colorScheme.onSurfaceVariant)
                    ],
                  ])),
            )),
      ));
}

class MemberSearchBar extends StatelessWidget {
  const MemberSearchBar(
      {super.key,
      this.hint = 'Search events, departments, and more',
      this.onTap,
      this.controller,
      this.onChanged,
      this.onFilter,
      this.onSubmitted,
      this.onClear,
      this.autofocus = false});
  final String hint;
  final VoidCallback? onTap, onFilter, onClear;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  @override
  Widget build(BuildContext context) => ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: MediaQuery.highContrastOf(context) ||
                    MediaQuery.accessibleNavigationOf(context)
                ? 0
                : 12,
            sigmaY: MediaQuery.highContrastOf(context) ||
                    MediaQuery.accessibleNavigationOf(context)
                ? 0
                : 12,
          ),
          child: Material(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(26),
            child: InkWell(
              borderRadius: BorderRadius.circular(26),
              onTap: controller == null ? onTap : null,
              child: SizedBox(
                  height: 48,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(children: [
                      Icon(PhosphorIconsRegular.magnifyingGlass,
                          size: 21, color: MemberVisuals.subtle(context)),
                      const SizedBox(width: 9),
                      Expanded(
                          child: controller == null
                              ? Text(hint,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant))
                              : TextField(
                                  controller: controller,
                                  onChanged: onChanged,
                                  onTap: onTap,
                                  autofocus: autofocus,
                                  onSubmitted: onSubmitted,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  decoration: InputDecoration(
                                      hintText: hint,
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      filled: false,
                                      contentPadding: EdgeInsets.zero))),
                      if (onClear != null)
                        MemberIconButton(
                            icon: PhosphorIconsRegular.x,
                            iconSize: 21,
                            label: 'Clear search',
                            onPressed: onClear,
                            plain: true),
                      if (onFilter != null)
                        MemberIconButton(
                            icon: PhosphorIconsRegular.slidersHorizontal,
                            iconSize: 21,
                            label: 'Search filters',
                            onPressed: onFilter,
                            plain: true),
                    ]),
                  )),
            ),
          )));
}

class MemberFilterChip extends StatelessWidget {
  const MemberFilterChip(
      {super.key,
      required this.label,
      required this.icon,
      required this.selected,
      required this.onPressed,
      this.featured = false});
  final String label;
  final IconData icon;
  final bool selected, featured;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: selected,
        child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(24),
              child: SizedBox(
                  height: 48,
                  child: Center(
                      child: AnimatedContainer(
                    duration: AppMotion.duration(context, AppMotion.tab),
                    curve: AppMotion.curve,
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 13),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        gradient: selected && featured
                            ? MemberVisuals.highlight
                            : null,
                        color: selected && featured
                            ? null
                            : selected
                                ? Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerLow
                                : Theme.of(context).colorScheme.surface),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(icon,
                          size: 16,
                          color: selected && featured
                              ? const Color(0xFF211923)
                              : selected
                                  ? Theme.of(context).colorScheme.onSurface
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant),
                      const SizedBox(width: 6),
                      Text(label,
                          style: Theme.of(context)
                              .textTheme
                              .labelMedium
                              ?.copyWith(
                                  fontWeight: selected && featured
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: selected && featured
                                      ? const Color(0xFF211923)
                                      : selected
                                          ? Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                          : Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant)),
                    ]),
                  ))),
            )),
      );
}

class MemberStatus extends StatelessWidget {
  const MemberStatus(
      {super.key, required this.message, this.icon, this.onRetry});
  final String message;
  final IconData? icon;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[
            Icon(icon, color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
          ],
          Text(message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium),
          if (onRetry != null) ...[
            const SizedBox(height: 8),
            TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(PhosphorIconsRegular.arrowClockwise, size: 18),
                label: const Text('Retry')),
          ],
        ]),
      );
}
