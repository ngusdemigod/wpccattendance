import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import '../core/theme/app_motion.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../core/theme/member_theme.dart';
import '../core/theme/member_material.dart';
import '../core/widgets/member_components.dart';
import '../features/media/media_player_controller.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});
  final Widget child;

  int indexFor(String location) {
    if (location.startsWith('/events')) return 1;
    if (location.startsWith('/media')) return 2;
    if (location.startsWith('/give')) return 3;
    if (location.startsWith('/profile')) return 4;
    return location == '/home' ? 0 : -1;
  }

  @override
  Widget build(BuildContext context) {
    final selected = indexFor(GoRouterState.of(context).uri.path);
    const destinations = ['/home', '/events', '/media', '/give', '/profile'];
    const labels = ['Home', 'Events', 'Media', 'Give', 'Profile'];
    const icons = [
      PhosphorIconsRegular.house,
      PhosphorIconsRegular.calendarBlank,
      PhosphorIconsRegular.disc,
      PhosphorIconsRegular.gift,
      PhosphorIconsRegular.user,
    ];
    const filled = [
      PhosphorIconsFill.house,
      PhosphorIconsFill.calendarBlank,
      PhosphorIconsFill.disc,
      PhosphorIconsFill.gift,
      PhosphorIconsFill.user,
    ];
    final solid = MemberMaterials.solid(context);
    final tablet = MediaQuery.sizeOf(context).width >= 600;

    final dock = Padding(
      padding: EdgeInsets.fromLTRB(
          18, 0, 18, (tablet ? 24 : 22) + MediaQuery.paddingOf(context).bottom),
      child: Align(
        heightFactor: 1,
        child: SizedBox(
          key: const ValueKey('floating-navigation'),
          width: 292,
          height: 60,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(34),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 28,
                    offset: Offset(0, 8))
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(34),
              child: BackdropFilter(
                filter: ImageFilter.blur(
                    sigmaX: solid ? 0 : 24, sigmaY: solid ? 0 : 24),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: solid
                        ? null
                        : LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withValues(alpha: .12),
                              Colors.white.withValues(alpha: .02)
                            ],
                          ),
                    color: solid
                        ? Color.alphaBlend(MemberVisuals.dock(context),
                            MemberVisuals.page(context))
                        : MemberVisuals.dock(context),
                    border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant),
                    borderRadius: BorderRadius.circular(34),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: Stack(children: [
                      _DockSelection(selected: selected),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            for (var n = 0; n < destinations.length; n++)
                              _DockButton(
                                label: labels[n],
                                selected: selected == n,
                                icon: selected == n ? filled[n] : icons[n],
                                onTap: () => context.go(destinations[n]),
                              ),
                          ]),
                    ]),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: AnimatedBuilder(
        animation: MediaPlayerController.instance,
        builder: (context, _) {
          final state = MediaPlayerController.instance.value;
          return SafeArea(
              bottom: false,
              child: Stack(children: [
                Positioned.fill(
                    child: Semantics(
                        container: true,
                        explicitChildNodes: true,
                        child: child)),
                Positioned(
                    left: 18,
                    right: 18,
                    bottom: (tablet ? 88 : 86) +
                        MediaQuery.paddingOf(context).bottom,
                    child: Center(
                        child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            reverseDuration: const Duration(milliseconds: 160),
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeInCubic,
                            transitionBuilder: (child, animation) =>
                                AnimatedBuilder(
                                  animation: animation,
                                  builder: (context, _) => IgnorePointer(
                                    ignoring: animation.status ==
                                        AnimationStatus.reverse,
                                    child: FadeTransition(
                                      opacity: animation,
                                      child: SlideTransition(
                                        position: Tween<Offset>(
                                          begin: MediaQuery.disableAnimationsOf(
                                                  context)
                                              ? Offset.zero
                                              : const Offset(0, .18),
                                          end: Offset.zero,
                                        ).animate(animation),
                                        child: child,
                                      ),
                                    ),
                                  ),
                                ),
                            child: state.episode == null
                                ? const SizedBox.shrink(
                                    key: ValueKey('no-player'))
                                : SizedBox(
                                    key: const ValueKey('floating-player'),
                                    width: 292,
                                    child: _PersistentMediaPlayer(
                                      state: state,
                                      onToggle: MediaPlayerController
                                          .instance.togglePlayback,
                                      onClose:
                                          MediaPlayerController.instance.close,
                                    ))))),
                Positioned(left: 0, right: 0, bottom: 0, child: dock),
              ]));
        },
      ),
    );
  }
}

class _DockSelection extends StatefulWidget {
  const _DockSelection({required this.selected});
  final int selected;

  @override
  State<_DockSelection> createState() => _DockSelectionState();
}

class _DockSelectionState extends State<_DockSelection>
    with SingleTickerProviderStateMixin {
  late final AnimationController position = AnimationController.unbounded(
      vsync: this, value: widget.selected < 0 ? 0 : widget.selected.toDouble());
  bool reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion && widget.selected >= 0) {
      position.value = widget.selected.toDouble();
    }
  }

  @override
  void didUpdateWidget(covariant _DockSelection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected == oldWidget.selected) return;
    if (widget.selected < 0) {
      position.stop();
    } else if (reduceMotion || oldWidget.selected < 0) {
      position.value = widget.selected.toDouble();
    } else {
      // Retain presentation position and velocity when a new tap redirects it.
      position.animateWith(SpringSimulation(
        const SpringDescription(mass: 1, stiffness: 500, damping: 45),
        position.value,
        widget.selected.toDouble(),
        position.velocity,
        tolerance: const Tolerance(distance: .001, velocity: .01),
      ));
    }
  }

  @override
  void dispose() {
    position.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: AnimatedBuilder(
          animation: position,
          builder: (context, _) => Align(
            alignment: Alignment(-1 + position.value.clamp(0, 4) * .5, 0),
            child: Opacity(
              opacity: widget.selected < 0 ? 0 : 1,
              child: Transform.scale(
                scaleX: reduceMotion
                    ? 1
                    : 1 + (position.velocity.abs() * .018).clamp(0, .22),
                scaleY: reduceMotion
                    ? 1
                    : 1 - (position.velocity.abs() * .006).clamp(0, .07),
                child: Container(
                  key: const ValueKey('dock-selection'),
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: MemberVisuals.selected(context)),
                ),
              ),
            ),
          ),
        ),
      );
}

class _DockButton extends StatefulWidget {
  const _DockButton(
      {required this.label,
      required this.selected,
      required this.icon,
      required this.onTap});
  final String label;
  final bool selected;
  final IconData icon;
  final VoidCallback onTap;
  @override
  State<_DockButton> createState() => _DockButtonState();
}

class _DockButtonState extends State<_DockButton> {
  bool pressed = false, focused = false;
  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: widget.selected,
        label: widget.label,
        onTap: widget.onTap,
        excludeSemantics: true,
        child: Tooltip(
            message: widget.label,
            child: AnimatedScale(
              duration: AppMotion.duration(
                  context, Duration(milliseconds: pressed ? 100 : 140)),
              curve: AppMotion.curve,
              scale:
                  pressed && !MediaQuery.disableAnimationsOf(context) ? .97 : 1,
              child: Material(
                color: Colors.transparent,
                shape: CircleBorder(
                    side: focused
                        ? BorderSide(
                            color: Theme.of(context).focusColor, width: 2)
                        : BorderSide.none),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  overlayColor:
                      const WidgetStatePropertyAll(Colors.transparent),
                  onHighlightChanged: (value) =>
                      setState(() => pressed = value),
                  onFocusChange: (value) => setState(() => focused = value),
                  onTap: widget.onTap,
                  child: SizedBox.square(
                    dimension: 50,
                    child: AnimatedScale(
                      duration: AppMotion.duration(
                          context, const Duration(milliseconds: 180)),
                      curve: AppMotion.curve,
                      scale: widget.selected ? 1.06 : 1,
                      child: AnimatedSwitcher(
                        duration: AppMotion.duration(
                            context, const Duration(milliseconds: 140)),
                        child: Icon(widget.icon,
                            key: ValueKey(widget.selected),
                            size: 24,
                            color: widget.selected
                                ? Theme.of(context).colorScheme.onSurface
                                : Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? const Color(0xFFE3E3E8)
                                    : const Color(0xFF34343B)),
                      ),
                    ),
                  ),
                ),
              ),
            )),
      );
}

class _PersistentMediaPlayer extends StatelessWidget {
  const _PersistentMediaPlayer({
    required this.state,
    required this.onToggle,
    required this.onClose,
  });
  final MediaPlayerState state;
  final VoidCallback onToggle;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final episode = state.episode!;
    final solid = MemberMaterials.solid(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter:
              ImageFilter.blur(sigmaX: solid ? 0 : 24, sigmaY: solid ? 0 : 24),
          child: Container(
            padding: const EdgeInsets.fromLTRB(6, 6, 6, 3),
            decoration: BoxDecoration(
              color: solid
                  ? (dark ? const Color(0xFF173C30) : const Color(0xFFD8F0E3))
                  : (dark ? const Color(0xFF18573E) : const Color(0xFFBCEDD4))
                      .withValues(alpha: dark ? .46 : .60),
              gradient: solid
                  ? null
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                          (dark
                                  ? const Color(0xFF438C69)
                                  : const Color(0xFFD4F5E3))
                              .withValues(alpha: .60),
                          (dark
                                  ? const Color(0xFF18573E)
                                  : const Color(0xFFADE3C8))
                              .withValues(alpha: .38)
                        ]),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Row(children: [
                Tooltip(
                    message: 'Seek playback',
                    child: InkWell(
                        onTap: () => showModalBottomSheet<void>(
                            context: context,
                            showDragHandle: true,
                            sheetAnimationStyle: AppMotion.sheetStyle(context),
                            builder: (context) => SafeArea(
                                child: Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: ValueListenableBuilder<
                                            MediaPlayerState>(
                                        valueListenable:
                                            MediaPlayerController.instance,
                                        builder: (context, current, _) =>
                                            Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                      current.episode?.title ??
                                                          'Playback',
                                                      maxLines: 2),
                                                  Slider(
                                                      value: current
                                                                  .durationMs <=
                                                              0
                                                          ? 0
                                                          : (current.positionMs /
                                                                  current
                                                                      .durationMs)
                                                              .clamp(0, 1),
                                                      semanticFormatterCallback:
                                                          (v) =>
                                                              '${(v * current.durationMs / 60000).floor()} minutes',
                                                      onChanged: current
                                                                  .durationMs <=
                                                              0
                                                          ? null
                                                          : (v) => MediaPlayerController
                                                              .instance
                                                              .seek((v *
                                                                      current
                                                                          .durationMs)
                                                                  .round())),
                                                ]))))),
                        child: SizedBox(
                            width: 48,
                            height: 48,
                            child: Center(
                                child: MemberArtwork(
                                    imageUrl: episode.artworkUrl,
                                    size: 34,
                                    radius: 8,
                                    icon: PhosphorIconsRegular
                                        .microphoneStage))))),
                const SizedBox(width: 6),
                Expanded(
                  child: InkWell(
                    onTap: () => context.push('/media/${episode.id}',
                        extra: episode.toRow()),
                    child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 48),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              episode.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'WPCC Messages',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 10,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant),
                            ),
                          ],
                        )),
                  ),
                ),
                IconButton(
                  tooltip: state.isPlaying ? 'Pause' : 'Play',
                  onPressed: onToggle,
                  icon: Icon(
                    state.isPlaying
                        ? PhosphorIcons.pause()
                        : PhosphorIcons.play(),
                    size: 20,
                  ),
                ),
                IconButton(
                  tooltip: 'Close player',
                  onPressed: onClose,
                  icon: Icon(PhosphorIcons.x(), size: 20),
                ),
              ]),
              LinearProgressIndicator(
                  minHeight: 2,
                  semanticsLabel: 'Playback progress',
                  value: state.durationMs <= 0
                      ? 0
                      : (state.positionMs / state.durationMs).clamp(0, 1)),
            ]),
          ),
        ));
  }
}
