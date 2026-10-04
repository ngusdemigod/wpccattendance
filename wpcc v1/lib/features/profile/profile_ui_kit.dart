import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../flutter_flow/custom_icons.dart';
import '../../flutter_flow/nav/nav.dart';
import '../../shared/widgets/interactive_filter_pill.dart';
import '../../shared/widgets/wpcc_shimmer.dart';
import '../search/screens/global_search_screen.dart';
import 'profile_feature_service.dart';

const _kPrimaryText = Color(0xFF111827);
const _kSecondaryText = Color(0xFF4B5563);
const _kActiveBlack = Color(0xFF111113);
const _kPink = Color(0xFFD600B8);
const _kCream = Color(0xFFF1EADD);
const _kCard = Color(0xFFFCFBF9);
const _kBorder = Color(0x14111827);
const _kFilterBorder = Color(0x24111827);

TextStyle profileSerif({
  double size = 28,
  FontWeight weight = FontWeight.w400,
  Color color = _kPrimaryText,
  double height = 1.02,
  double letterSpacing = -0.84,
}) {
  return GoogleFonts.instrumentSerif(
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  );
}

TextStyle profileSans({
  double size = 13,
  FontWeight weight = FontWeight.w400,
  Color color = _kPrimaryText,
  double height = 1.35,
  double letterSpacing = 0,
}) {
  return GoogleFonts.instrumentSans(
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  );
}

class ProfileSubpageHeader extends StatelessWidget {
  const ProfileSubpageHeader({
    super.key,
    required this.title,
    required this.onBack,
    this.onSearch,
  });

  final String title;
  final VoidCallback onBack;
  final VoidCallback? onSearch;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Row(
        children: [
          _ProfileCircleIconButton(
            icon: Icons.chevron_left_rounded,
            semanticLabel: 'Go back',
            onTap: onBack,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title, style: profileSerif()),
          ),
          const SizedBox(width: 12),
          _ProfileCircleIconButton(
            icon: Icons.search_rounded,
            semanticLabel: 'Search',
            onTap: onSearch ??
                () => context.pushNamed(GlobalSearchScreen.routeName),
          ),
        ],
      ),
    );
  }
}

class ProfileRouteTabs extends StatelessWidget {
  const ProfileRouteTabs({
    super.key,
    required this.activeTab,
    required this.onSelected,
  });

  final ProfileRouteTab activeTab;
  final ValueChanged<ProfileRouteTab> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ProfileFilterPill(
                label: 'Overview',
                icon: FFIcons.klistChecks,
                selected: activeTab == ProfileRouteTab.overview,
                onTap: () => onSelected(ProfileRouteTab.overview),
              ),
              const SizedBox(width: 8),
              _ProfileFilterPill(
                label: 'Classes',
                icon: FFIcons.kbookOpen,
                selected: activeTab == ProfileRouteTab.classes,
                onTap: () => onSelected(ProfileRouteTab.classes),
              ),
              const SizedBox(width: 8),
              _ProfileFilterPill(
                label: 'Query',
                icon: FFIcons.kchatCircleText,
                selected: activeTab == ProfileRouteTab.query,
                onTap: () => onSelected(ProfileRouteTab.query),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class QueryFilterTabs extends StatelessWidget {
  const QueryFilterTabs({
    super.key,
    required this.activeFilter,
    required this.onSelected,
  });

  final ProfileQueryFilter activeFilter;
  final ValueChanged<ProfileQueryFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ProfileFilterPill(
                label: 'Overview',
                icon: FFIcons.klistChecks,
                selected: activeFilter == ProfileQueryFilter.overview,
                onTap: () => onSelected(ProfileQueryFilter.overview),
              ),
              const SizedBox(width: 8),
              _ProfileFilterPill(
                label: 'Resolved',
                icon: FFIcons.kcheckCircle,
                selected: activeFilter == ProfileQueryFilter.resolved,
                onTap: () => onSelected(ProfileQueryFilter.resolved),
              ),
              const SizedBox(width: 8),
              _ProfileFilterPill(
                label: 'Needs attention',
                icon: FFIcons.kwarningCircle,
                selected: activeFilter == ProfileQueryFilter.needsAttention,
                onTap: () => onSelected(ProfileQueryFilter.needsAttention),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileSurfaceCard extends StatelessWidget {
  const ProfileSurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 30,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: _kBorder),
      ),
      child: child,
    );
  }
}

class ProfileStatusBadge extends StatelessWidget {
  const ProfileStatusBadge({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: profileSans(
          size: 11,
          weight: FontWeight.w400,
          color: textColor,
        ),
      ),
    );
  }
}

class ProfileEmptyCard extends StatelessWidget {
  const ProfileEmptyCard({
    super.key,
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return ProfileSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: profileSans(size: 14, weight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(
            message,
            style: profileSans(size: 12, color: _kSecondaryText, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class ProfileRetryCard extends StatelessWidget {
  const ProfileRetryCard({
    super.key,
    required this.title,
    required this.message,
    required this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ProfileSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: profileSans(size: 14, weight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(message, style: profileSans(size: 12, color: _kSecondaryText)),
          const SizedBox(height: 16),
          ProfilePillButton(
            label: 'Retry',
            onPressed: onRetry,
            backgroundColor: _kActiveBlack,
            foregroundColor: Colors.white,
          ),
        ],
      ),
    );
  }
}

class ProfilePillButton extends StatelessWidget {
  const ProfilePillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.backgroundColor = _kPink,
    this.foregroundColor = Colors.white,
    this.outlined = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color foregroundColor;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null;
    return SizedBox(
      height: 40,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          backgroundColor: isDisabled
              ? _kCream
              : outlined
                  ? Colors.white
                  : backgroundColor,
          foregroundColor: isDisabled ? _kSecondaryText : foregroundColor,
          side: BorderSide(
            color: outlined ? _kBorder : Colors.transparent,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        child: Text(
          label,
          style: profileSans(size: 12, weight: FontWeight.w600),
        ),
      ),
    );
  }
}

class ProfileLoadingList extends StatelessWidget {
  const ProfileLoadingList({
    super.key,
    this.itemCount = 3,
    this.includeStats = false,
  });

  final int itemCount;
  final bool includeStats;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
      children: [
        if (includeStats)
          Row(
            children: List.generate(3, (index) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: index == 2 ? 0 : 10),
                  child: const WpccShimmerCard(
                    height: 58,
                    radius: 30,
                    child: SizedBox.expand(),
                  ),
                ),
              );
            }),
          ),
        if (includeStats) const SizedBox(height: 16),
        ...List.generate(
          itemCount,
          (_) => const Padding(
            padding: EdgeInsets.only(bottom: 14),
            child: WpccShimmerCard(
              height: 168,
              radius: 30,
              child: SizedBox.expand(),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileCircleIconButton extends StatelessWidget {
  const _ProfileCircleIconButton({
    required this.icon,
    required this.semanticLabel,
    required this.onTap,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _kCard,
      shape: const CircleBorder(
        side: BorderSide(color: _kBorder),
      ),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Semantics(
          button: true,
          label: semanticLabel,
          child: SizedBox(
            width: 36,
            height: 36,
            child: Icon(icon, size: 20, color: _kPrimaryText),
          ),
        ),
      ),
    );
  }
}

class _ProfileFilterPill extends StatelessWidget {
  const _ProfileFilterPill({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InteractiveFilterPill(
      label: label,
      icon: icon,
      selected: selected,
      onTap: onTap,
      height: 34,
      horizontalPadding: 14,
      iconSize: 15,
      selectedBackgroundColor: _kActiveBlack,
      selectedBorderColor: _kActiveBlack,
      unselectedBorderColor: _kFilterBorder,
      fontWeight: FontWeight.w500,
    );
  }
}
