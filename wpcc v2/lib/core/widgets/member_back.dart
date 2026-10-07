import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../theme/app_motion.dart';
import 'member_glass.dart';

/// Where the sticky back button goes when the page cannot be popped (deep
/// link, refresh) and how it is placed for the page's header style.
class MemberBackRule {
  const MemberBackRule(this.fallback,
      {this.forceGo = false, this.appBar = false});

  /// Parent route used when there is nothing to pop.
  final String fallback;

  /// Always navigate to [fallback] (for example after a payment result, where
  /// popping would reveal the finished payment form).
  final bool forceGo;

  /// The page draws a 56px toolbar, so the button is centred in it instead of
  /// in the 20px-padded header row of ordinary member pages.
  final bool appBar;

  static MemberBackRule of(String path) {
    final parts = Uri.parse(path).pathSegments;
    String at(int i) => i < parts.length ? parts[i] : '';
    switch (at(0)) {
      case 'media':
        return const MemberBackRule('/media');
      case 'events':
        return const MemberBackRule('/events');
      case 'departments':
        if (parts.length == 1) return const MemberBackRule('/home');
        if (parts.length == 2) {
          return const MemberBackRule('/departments', appBar: true);
        }
        return MemberBackRule('/departments/${at(1)}', appBar: true);
      case 'give':
        return MemberBackRule('/give', forceGo: at(1) == 'result');
      case 'prayer-alerts':
        return parts.length == 1
            ? const MemberBackRule('/home')
            : const MemberBackRule('/prayer-alerts', appBar: true);
      case 'prayer-session':
        return const MemberBackRule('/prayer-alerts');
      case 'devotional':
        return parts.length == 1
            ? const MemberBackRule('/home')
            : const MemberBackRule('/devotional', appBar: true);
      case 'souls':
        return parts.length == 1
            ? const MemberBackRule('/home')
            : const MemberBackRule('/souls', appBar: true);
      default:
        return const MemberBackRule('/home');
    }
  }
}

class _BackController {
  VoidCallback? override;
}

class _MemberBackScope extends InheritedWidget {
  const _MemberBackScope({required this.controller, required super.child});
  final _BackController controller;
  @override
  bool updateShouldNotify(_MemberBackScope oldWidget) => false;
}

/// Static helpers for pages that sit under a [MemberBackHost].
abstract final class MemberBackScope {
  /// True when the route supplies the sticky top-left back button, so a page
  /// must not draw its own back control.
  static bool active(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_MemberBackScope>() != null;

  static double gutter(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 600 ? 20 : 32;
}

/// Lets a page replace what the sticky back button does for as long as it is
/// mounted (for example to clear an inner selection, or to pop with a result).
class MemberBackOverride extends StatefulWidget {
  const MemberBackOverride(
      {super.key, required this.onBack, required this.child});
  final VoidCallback? onBack;
  final Widget child;
  @override
  State<MemberBackOverride> createState() => _MemberBackOverrideState();
}

class _MemberBackOverrideState extends State<MemberBackOverride> {
  _BackController? controller;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    controller =
        context.getInheritedWidgetOfExactType<_MemberBackScope>()?.controller;
    controller?.override = widget.onBack;
  }

  @override
  void didUpdateWidget(MemberBackOverride oldWidget) {
    super.didUpdateWidget(oldWidget);
    controller?.override = widget.onBack;
  }

  @override
  void dispose() {
    controller?.override = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Pins one [MemberBackButton] to the top left of a member route, above the
/// scrolling content and inside the safe area. Added once by the router.
class MemberBackHost extends StatefulWidget {
  const MemberBackHost({super.key, required this.path, required this.child});
  final String path;
  final Widget child;
  @override
  State<MemberBackHost> createState() => _MemberBackHostState();
}

class _MemberBackHostState extends State<MemberBackHost> {
  final _controller = _BackController();

  void _back(BuildContext context, MemberBackRule rule) {
    final custom = _controller.override;
    if (custom != null) return custom();
    if (!rule.forceGo && context.canPop()) {
      context.pop();
    } else {
      context.go(rule.fallback);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rule = MemberBackRule.of(widget.path);
    return _MemberBackScope(
      controller: _controller,
      child: Stack(fit: StackFit.passthrough, children: [
        widget.child,
        Positioned(
          top: MediaQuery.paddingOf(context).top + (rule.appBar ? 4 : 20),
          left: MemberBackScope.gutter(context),
          child: Material(
            type: MaterialType.transparency,
            child: MemberBackButton(onPressed: () => _back(context, rule)),
          ),
        ),
      ]),
    );
  }
}

/// The one back control: a 40px glass circle inside a 48px target.
class MemberBackButton extends StatelessWidget {
  const MemberBackButton(
      {super.key, this.onPressed, this.label = 'Back', this.plain = false});
  final VoidCallback? onPressed;

  /// Tooltip and accessible name: `Back`, or `Back to <place>`.
  final String label;

  /// Omit the glass circle (for use over an already solid surface).
  final bool plain;

  @override
  Widget build(BuildContext context) => AppPressMotion(
      child: SizedBox.square(
          dimension: 48,
          child: Stack(alignment: Alignment.center, children: [
            if (!plain)
              const SizedBox(
                  width: 40,
                  height: 40,
                  child: MemberGlass(radius: 20, child: SizedBox.expand())),
            IconButton(
              tooltip: label,
              onPressed: onPressed,
              style: IconButton.styleFrom(
                backgroundColor: Colors.transparent,
                minimumSize: const Size(48, 48),
                shape: const CircleBorder(),
              ),
              icon: const Icon(PhosphorIconsRegular.caretLeft, size: 20),
            ),
          ])));
}

/// App bar for member pages that use one. Under a [MemberBackHost] it draws no
/// leading back control and leaves room on the left for the sticky button.
class MemberAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MemberAppBar(
      {super.key,
      this.title,
      this.actions,
      this.centerTitle,
      this.backgroundColor,
      this.onBack});
  final Widget? title;
  final List<Widget>? actions;
  final bool? centerTitle;
  final Color? backgroundColor;

  /// Used only when the page is shown without a [MemberBackHost].
  final VoidCallback? onBack;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final hosted = MemberBackScope.active(context);
    return AppBar(
      title: title,
      centerTitle: centerTitle,
      backgroundColor: backgroundColor,
      automaticallyImplyLeading: false,
      leadingWidth: hosted ? MemberBackScope.gutter(context) + 56 : null,
      leading: hosted
          ? const SizedBox.shrink()
          : MemberBackButton(
              onPressed: onBack ??
                  () => context.canPop() ? context.pop() : context.go('/home')),
      actions: actions,
    );
  }
}
