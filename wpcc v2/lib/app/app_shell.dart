import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/theme/app_theme.dart';
import '../features/media/media_player_controller.dart';
import '../features/media/spotify_episode_player.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});
  final Widget child;

  int indexFor(String location) {
    if (location.startsWith('/media')) return 1;
    if (location.startsWith('/events')) return 2;
    if (location.startsWith('/give')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final selected = indexFor(location);
    const destinations = ['/home', '/media', '/events', '/give', '/profile'];
    final icons = [
      PhosphorIcons.house(),
      PhosphorIcons.microphoneStage(),
      PhosphorIcons.calendarDots(),
      PhosphorIcons.handHeart(),
      PhosphorIcons.userCircle()
    ];
    final labels = ['Home', 'Media', 'Events', 'Give', 'Profile'];

    return Scaffold(
      extendBody: true,
      body: AnimatedBuilder(
        animation: MediaPlayerController.instance,
        builder: (context, _) {
          final state = MediaPlayerController.instance.value;
          return Column(children: [
            if (state.episode != null)
              _PersistentMediaPlayer(
                state: state,
                onToggle: MediaPlayerController.instance.toggleExpanded,
                onClose: MediaPlayerController.instance.close,
              ),
            Expanded(child: child),
          ]);
        },
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
            child: Container(
              height: 66,
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .78),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: .82)),
                  borderRadius: BorderRadius.circular(28)),
              child: Row(
                children: List.generate(
                    5,
                    (i) => Expanded(
                          child: Semantics(
                            button: true,
                            selected: selected == i,
                            label: labels[i],
                            excludeSemantics: true,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () => context.go(destinations[i]),
                              child: Align(
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  width: 62,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    gradient: selected == i
                                        ? const LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              WpccColors.primary,
                                              WpccColors.primaryDeep,
                                            ],
                                          )
                                        : null,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: selected == i
                                        ? const [
                                            BoxShadow(
                                              color: Color(0x38683793),
                                              blurRadius: 22,
                                              offset: Offset(0, 10),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(icons[i],
                                            size: 18,
                                            color: selected == i
                                                ? Colors.white
                                                : WpccColors.muted),
                                        const SizedBox(height: 3),
                                        Text(labels[i],
                                            maxLines: 1,
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelSmall
                                                ?.copyWith(
                                                    fontSize: 12,
                                                    color: selected == i
                                                        ? Colors.white
                                                        : WpccColors.muted)),
                                      ]),
                                ),
                              ),
                            ),
                          ),
                        )),
              ),
            ),
          ),
        ),
      ),
    );
  }
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
    return SafeArea(
      bottom: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: WpccColors.line),
          boxShadow: const [
            BoxShadow(
              color: Color(0x140F1220),
              blurRadius: 22,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(children: [
          Row(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: episode.artworkUrl.isEmpty
                  ? Container(
                      width: 50,
                      height: 50,
                      color: WpccColors.primarySoft,
                      child: Icon(
                        PhosphorIcons.microphoneStage(),
                        color: WpccColors.primaryDeep,
                      ),
                    )
                  : Image.network(
                      episode.artworkUrl,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 50,
                        height: 50,
                        color: WpccColors.primarySoft,
                      ),
                    ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: InkWell(
                onTap: onToggle,
                child: Column(
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
                    const SizedBox(height: 3),
                    const Text(
                      'WPCC Messages',
                      style: TextStyle(fontSize: 10, color: WpccColors.muted),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: const LinearProgressIndicator(
                        value: 0,
                        minHeight: 3,
                        backgroundColor: WpccColors.line,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              tooltip: state.expanded ? 'Minimize player' : 'Open player',
              onPressed: onToggle,
              icon: Icon(
                state.expanded ? PhosphorIcons.pause() : PhosphorIcons.play(),
                size: 19,
              ),
            ),
            IconButton(
              tooltip: 'Close player',
              onPressed: onClose,
              icon: Icon(PhosphorIcons.x(), size: 18),
            ),
          ]),
          if (state.expanded && episode.embedUrl.isNotEmpty) ...[
            const SizedBox(height: 8),
            SpotifyEpisodePlayer(
              key: ValueKey(episode.id),
              embedUrl: episode.embedUrl,
              providerUrl: episode.providerUrl,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: episode.providerUrl.isEmpty
                    ? null
                    : () => launchUrl(
                          Uri.parse(episode.providerUrl),
                          mode: LaunchMode.externalApplication,
                          webOnlyWindowName: '_blank',
                        ),
                icon: Icon(PhosphorIcons.spotifyLogo(), size: 16),
                label: const Text('Open in Spotify'),
              ),
            ),
          ],
        ]),
      ),
    );
  }
}
