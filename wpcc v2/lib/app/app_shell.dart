import 'dart:ui';

import 'package:flutter/material.dart';
import '../core/theme/app_motion.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../core/theme/member_theme.dart';
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
    final solid = MediaQuery.highContrastOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    final tablet = MediaQuery.sizeOf(context).width >= 600;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: AnimatedBuilder(
        animation: MediaPlayerController.instance,
        builder: (context, _) {
          final state = MediaPlayerController.instance.value;
          return SafeArea(
              bottom: false,
              child: Column(children: [
                if (state.episode != null)
                  _PersistentMediaPlayer(
                    state: state,
                    onToggle: MediaPlayerController.instance.togglePlayback,
                    onClose: MediaPlayerController.instance.close,
                  ),
                Expanded(
                    child: Semantics(
                  container: true,
                  explicitChildNodes: true,
                  child: child,
                )),
              ]));
        },
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(18, 0, 18,
            (tablet ? 24 : 22) + MediaQuery.paddingOf(context).bottom),
        child: Align(
          heightFactor: 1,
          child: SizedBox(
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
                      child: Row(
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
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
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
                color: widget.selected
                    ? MemberVisuals.selected(context)
                    : Colors.transparent,
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
                    child: Icon(widget.icon,
                        size: 24,
                        color: widget.selected
                            ? Theme.of(context).colorScheme.onSurface
                            : MemberVisuals.subtle(context)),
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
    final solid = MediaQuery.highContrastOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    final gutter = MediaQuery.sizeOf(context).width < 600 ? 20.0 : 32.0;
    return ClipRect(
        child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: solid ? 0 : 24, sigmaY: solid ? 0 : 24),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: gutter, vertical: 7),
        decoration: BoxDecoration(
          color: solid
              ? Color.alphaBlend(
                  MemberVisuals.sheet(context), MemberVisuals.page(context))
              : MemberVisuals.sheet(context),
          border: Border(
              bottom: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant)),
        ),
        child: Column(children: [
          Row(children: [
            MemberArtwork(
                imageUrl: episode.artworkUrl,
                size: 38,
                radius: 8,
                icon: PhosphorIconsRegular.microphoneStage),
            const SizedBox(width: 9),
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
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'WPCC Messages',
                          style: TextStyle(
                              fontSize: 11,
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
                state.isPlaying ? PhosphorIcons.pause() : PhosphorIcons.play(),
                size: 20,
              ),
            ),
            IconButton(
              tooltip: 'Close player',
              onPressed: onClose,
              icon: Icon(PhosphorIcons.x(), size: 20),
            ),
          ]),
          Semantics(
              label: 'Playback position',
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 4)),
                child: Slider(
                  value: state.durationMs <= 0
                      ? 0
                      : (state.positionMs / state.durationMs).clamp(0, 1),
                  semanticFormatterCallback: (value) =>
                      '${(value * state.durationMs / 60000).floor()} minutes',
                  onChanged: state.durationMs <= 0
                      ? null
                      : (value) => MediaPlayerController.instance
                          .seek((value * state.durationMs).round()),
                ),
              )),
        ]),
      ),
    ));
  }
}
