import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../theme/app_theme.dart';
import '../theme/member_theme.dart';
import '../theme/app_motion.dart';
import 'member_components.dart';

/// Reference sheets sit above the entire member shell, including its dock.
Future<T?> showMemberSheet<T>({
  required BuildContext context,
  required String title,
  required WidgetBuilder builder,
}) {
  final themes = InheritedTheme.capture(
      from: context, to: Navigator.of(context, rootNavigator: true).context);
  return Navigator.of(context, rootNavigator: true)
      .push<T>(_MemberSheetRoute<T>(
    barrierDismissible: true,
    barrierColor: Colors.transparent,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    transitionDuration: AppMotion.duration(context, AppMotion.sheet),
    transitionBuilder: (_, __, ___, child) => child,
    traversalEdgeBehavior: TraversalEdgeBehavior.closedLoop,
    pageBuilder: (context, animation, __) => themes.wrap(MemberSheet(
        title: title, animation: animation, child: Builder(builder: builder))),
  ));
}

class _MemberSheetRoute<T> extends RawDialogRoute<T> {
  _MemberSheetRoute(
      {required super.pageBuilder,
      required super.barrierDismissible,
      required super.barrierColor,
      required super.barrierLabel,
      required super.transitionDuration,
      required super.transitionBuilder,
      required super.traversalEdgeBehavior});
  @override
  Duration get reverseTransitionDuration =>
      transitionDuration == Duration.zero ? Duration.zero : AppMotion.sheetExit;
}

Future<void> showMemberAppearanceSheet(BuildContext context) => showMemberSheet<
        void>(
    context: context,
    title: 'Appearance',
    builder: (context) => Column(mainAxisSize: MainAxisSize.min, children: [
          for (final mode in [
            ThemeMode.dark,
            ThemeMode.light,
            ThemeMode.system
          ])
            Padding(
                padding:
                    EdgeInsets.only(bottom: mode == ThemeMode.system ? 0 : 7),
                child: MemberListRow(
                  selected: ThemePreference.instance.value == mode,
                  title: switch (mode) {
                    ThemeMode.system => 'System',
                    ThemeMode.light => 'Light',
                    ThemeMode.dark => 'Dark',
                  },
                  leading: Icon(
                      switch (mode) {
                        ThemeMode.system =>
                          PhosphorIconsRegular.slidersHorizontal,
                        ThemeMode.light => PhosphorIconsRegular.sun,
                        ThemeMode.dark => PhosphorIconsRegular.moon,
                      },
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                  trailing: ThemePreference.instance.value == mode
                      ? Icon(PhosphorIconsRegular.check,
                          size: 16,
                          color: Theme.of(context).colorScheme.onSurfaceVariant)
                      : const SizedBox.shrink(),
                  onTap: () {
                    ThemePreference.instance.select(mode);
                    Navigator.of(context).pop();
                  },
                )),
        ]));

class MemberSheet extends StatefulWidget {
  const MemberSheet(
      {super.key,
      required this.title,
      required this.child,
      this.animation = const AlwaysStoppedAnimation(1)});
  final String title;
  final Widget child;
  final Animation<double> animation;

  @override
  State<MemberSheet> createState() => _MemberSheetState();
}

class _MemberSheetState extends State<MemberSheet>
    with SingleTickerProviderStateMixin {
  double _offset = 0;
  double _settleStart = 0;
  late final AnimationController _settle;
  @override
  void initState() {
    super.initState();
    _settle = AnimationController(vsync: this, duration: AppMotion.control)
      ..addListener(() => setState(() {
            _offset =
                _settleStart * (1 - AppMotion.curve.transform(_settle.value));
          }));
  }

  void _returnToRest() {
    if (MediaQuery.disableAnimationsOf(context)) {
      setState(() => _offset = 0);
      return;
    }
    _settleStart = _offset;
    _settle.forward(from: 0);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _settle.stop();
      _offset = 0;
    }
  }

  @override
  void dispose() {
    _settle.dispose();
    super.dispose();
  }

  bool _closing = false;
  void _dismiss() {
    if (_closing || ModalRoute.of(context)?.isCurrent != true) return;
    _closing = true;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final tablet = media.size.width >= 600;
    final solid = media.highContrast || media.accessibleNavigation;
    final colors = Theme.of(context).colorScheme;
    return Stack(children: [
      Positioned.fill(
        child: IgnorePointer(
          child: AppRouteMotion(
              animation: widget.animation,
              child: BackdropFilter(
                filter: ImageFilter.blur(
                    sigmaX: solid ? 0 : 4, sigmaY: solid ? 0 : 4),
                child: const ColoredBox(color: Color(0x77000000)),
              )),
        ),
      ),
      SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(8, 8, 8, 8 + media.viewInsets.bottom),
          child: LayoutBuilder(builder: (context, bounds) {
            return Align(
              alignment: tablet ? Alignment.center : Alignment.bottomCenter,
              child: AppRouteMotion(
                  animation: widget.animation,
                  curve: AppMotion.drawer,
                  offset: const Offset(0, 24),
                  child: Transform.translate(
                    offset: Offset(0, _offset),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: 560,
                        maxHeight:
                            math.min(media.size.height * .85, bounds.maxHeight),
                      ),
                      child: Container(
                        key: const ValueKey('member-sheet-surface'),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: const [
                            BoxShadow(
                                color: Color(0x55000000),
                                offset: Offset(0, 12),
                                blurRadius: 50),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(32),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(
                                sigmaX: solid ? 0 : 28, sigmaY: solid ? 0 : 28),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: solid
                                    ? MemberVisuals.sheet(context)
                                        .withValues(alpha: 1)
                                    : MemberVisuals.sheet(context),
                                borderRadius: BorderRadius.circular(32),
                                border: Border.all(
                                    color: media.highContrast
                                        ? colors.onSurfaceVariant
                                        : colors.outlineVariant),
                              ),
                              child: Material(
                                type: MaterialType.transparency,
                                child: Semantics(
                                  scopesRoute: true,
                                  explicitChildNodes: true,
                                  child: _FlexibleSheetContent(
                                    title: widget.title,
                                    onDismiss: _dismiss,
                                    onDragUpdate: (details) {
                                      _settle.stop();
                                      setState(() => _offset = math.max(
                                          0, _offset + details.delta.dy));
                                    },
                                    onDragEnd: (details) {
                                      if (_offset > 100 ||
                                          _offset > 20 &&
                                              details.velocity.pixelsPerSecond
                                                      .dy >
                                                  600) {
                                        _dismiss();
                                      } else {
                                        _returnToRest();
                                      }
                                    },
                                    onDragCancel: _returnToRest,
                                    bottomPadding: tablet ? 28 : 24,
                                    child: widget.child,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  )),
            );
          }),
        ),
      ),
    ]);
  }
}

class _FlexibleSheetContent extends StatelessWidget {
  const _FlexibleSheetContent({
    required this.title,
    required this.child,
    required this.onDismiss,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.onDragCancel,
    required this.bottomPadding,
  });
  final String title;
  final Widget child;
  final VoidCallback onDismiss, onDragCancel;
  final GestureDragUpdateCallback onDragUpdate;
  final GestureDragEndCallback onDragEnd;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(children: [
            Column(children: [
              SizedBox(
                height: 24,
                child: Center(
                    child: Container(
                  width: 32,
                  height: 3,
                  decoration: BoxDecoration(
                      color: MemberVisuals.subtle(context),
                      borderRadius: BorderRadius.circular(3)),
                )),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 21),
                child: Row(children: [
                  Expanded(
                      child: Semantics(
                    namesRoute: true,
                    header: true,
                    child: Text(title,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontSize: 26, height: 33 / 26)),
                  )),
                  const SizedBox(width: 12),
                  MemberIconButton(
                      icon: PhosphorIconsRegular.x,
                      label: 'Close',
                      autofocus: true,
                      onPressed: onDismiss,
                      plain: true),
                ]),
              ),
            ]),
            // Extend the grip's gesture target without changing its 24px artwork.
            Positioned(
              top: 0,
              left: 21,
              right: 81,
              height: 48,
              child: Semantics(
                button: true,
                label: 'Dismiss $title',
                onTap: onDismiss,
                child: GestureDetector(
                  key: const ValueKey('member-sheet-grip'),
                  behavior: HitTestBehavior.opaque,
                  excludeFromSemantics: true,
                  onVerticalDragUpdate: onDragUpdate,
                  onVerticalDragEnd: onDragEnd,
                  onVerticalDragCancel: onDragCancel,
                ),
              ),
            ),
          ]),
          const SizedBox(height: 10),
          Flexible(
              child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(21, 0, 21, bottomPadding + 1),
            child: child,
          )),
        ],
      );
}
