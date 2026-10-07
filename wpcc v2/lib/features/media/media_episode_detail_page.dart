import 'package:flutter/material.dart';
import '../../core/widgets/member_photo_backdrop.dart';
import '../../core/widgets/member_skeleton.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/widgets/member_components.dart';
import 'media_page.dart';
import 'media_player_controller.dart';
import 'media_repository.dart';
import 'media_share.dart';

class MediaEpisodeDetailPage extends StatefulWidget {
  const MediaEpisodeDetailPage(
      {super.key,
      required this.episodeId,
      this.seed,
      this.loadAlbums,
      this.loadAlbumTracks});
  final String episodeId;
  final Map<String, dynamic>? seed;
  final EpisodeLoader? loadAlbums;
  final AlbumTracksLoader? loadAlbumTracks;
  @override
  State<MediaEpisodeDetailPage> createState() => _MediaEpisodeDetailPageState();
}

class _MediaEpisodeDetailPageState extends State<MediaEpisodeDetailPage> {
  late Future<Map<String, dynamic>?> episode;
  @override
  void initState() {
    super.initState();
    episode = _load();
    _autoPlay();
  }

  /// Opening a message from the list starts it playing, as the tap that opened
  /// it is the user's permission. A message that is already the current one
  /// is left as it is, and a page opened from a link (no tap) never autoplays.
  Future<void> _autoPlay() async {
    if (widget.seed == null) return;
    final row = await episode;
    if (row == null || !mounted) return;
    final player = MediaPlayerController.instance;
    if (player.value.episode?.id != row['id']?.toString()) player.play(row);
  }

  Future<Map<String, dynamic>?> _load() => widget.seed == null
      ? MediaRepository().episode(widget.episodeId)
      : Future.value(widget.seed);
  @override
  void didUpdateWidget(covariant MediaEpisodeDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.episodeId != widget.episodeId ||
        oldWidget.seed != widget.seed) {
      episode = _load();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: Colors.transparent,
      body: FutureBuilder<Map<String, dynamic>?>(
          future: episode,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const SafeArea(
                  child: SingleChildScrollView(
                      padding: EdgeInsets.all(24),
                      child: MemberSkeleton(hero: true)));
            }
            if (snapshot.hasError || snapshot.data == null) {
              return SafeArea(
                  child: Column(children: [
                _DetailHeader(provider: ''),
                Expanded(
                    child: Center(
                        child: MemberStatus(
                            message: 'Message unavailable',
                            icon: PhosphorIconsRegular.warningCircle,
                            onRetry: () => setState(() {
                                  episode = _load();
                                })))),
              ]));
            }
            return _EpisodeBody(
                key: ValueKey(widget.episodeId),
                episode: snapshot.data!,
                loadAlbums: widget.loadAlbums,
                loadTracks: widget.loadAlbumTracks);
          }));
}

typedef _Collection = ({
  Map<String, dynamic> album,
  List<Map<String, dynamic>> tracks
});

class _EpisodeBody extends StatefulWidget {
  const _EpisodeBody(
      {super.key, required this.episode, this.loadAlbums, this.loadTracks});
  final Map<String, dynamic> episode;
  final EpisodeLoader? loadAlbums;
  final AlbumTracksLoader? loadTracks;
  @override
  State<_EpisodeBody> createState() => _EpisodeBodyState();
}

class _EpisodeBodyState extends State<_EpisodeBody> {
  late Future<_Collection?> collection;
  @override
  void initState() {
    super.initState();
    collection = _findCollection();
  }

  Future<_Collection?> _findCollection() async {
    final hint = widget.episode['_collection'];
    final hintTracks = widget.episode['_collection_tracks'];
    if (hint is Map && hintTracks is List) {
      return (
        album: Map<String, dynamic>.from(hint),
        tracks: hintTracks
            .map((row) => Map<String, dynamic>.from(row as Map))
            .toList(),
      );
    }
    final albums = await (widget.loadAlbums ?? MediaRepository().albums)();
    for (final album in albums) {
      final tracks = await (widget.loadTracks ??
          MediaRepository().albumTracks)(album['id'].toString());
      if (tracks.any((row) =>
          (row['episode'] as Map?)?['id']?.toString() ==
          widget.episode['id']?.toString())) {
        return (album: album, tracks: tracks);
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<_Collection?>(
      future: collection,
      builder: (context, snapshot) {
        final episode = widget.episode;
        final colors = Theme.of(context).colorScheme;
        final provider = episode['provider_url']?.toString() ?? '';
        final description = episode['description']?.toString().trim() ?? '';
        final album = snapshot.data?.album;
        return MemberPhotoBackdrop(
            route: '/media',
            imageUrl: album?['featured_image']?.toString() ??
                episode['artwork_url']?.toString(),
            child: SafeArea(
                bottom: false,
                child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                        constraints: BoxConstraints(
                            maxWidth: MediaQuery.sizeOf(context).width >= 900
                                ? 820
                                : 1180),
                        child: ListView(
                            padding: memberPagePadding(context,
                                phone: 20,
                                top: 20,
                                bottom:
                                    MediaQuery.paddingOf(context).bottom + 112),
                            children: [
                              _DetailHeader(
                                  provider: provider,
                                  episodeId: episode['id']?.toString(),
                                  title: episode['title']?.toString(),
                                  artwork: episode['artwork_url']?.toString()),
                              Align(
                                  alignment: Alignment.centerLeft,
                                  child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                          maxWidth:
                                              MediaQuery.sizeOf(context).width >= 600
                                                  ? 680
                                                  : double.infinity),
                                      child: LayoutBuilder(
                                          builder: (context, box) => SizedBox(
                                              width: box.maxWidth,
                                              height: (box.maxWidth * .75)
                                                  .clamp(0.0, 430.0),
                                              child: ClipRRect(
                                                  key: const ValueKey(
                                                      'message-artwork'),
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                  child: _Artwork(
                                                      url: album?['featured_image']?.toString() ??
                                                          episode['artwork_url']?.toString() ??
                                                          '')))))),
                              const SizedBox(height: 22),
                              Text(
                                  album?['title']?.toString() ??
                                      'WPCC Messages',
                                  style: Theme.of(context).textTheme.bodySmall),
                              const SizedBox(height: 9),
                              MediaDisplayTitle(
                                  episode['title']?.toString() ?? 'Message'),
                              if (provider.isNotEmpty)
                                MediaProviderLink(
                                    url: provider,
                                    label: 'Open in Spotify',
                                    showChevron: false),
                              if (description.isNotEmpty)
                                Padding(
                                    padding: const EdgeInsets.only(top: 17),
                                    child: Text(description,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                                height: 1.5,
                                                color:
                                                    colors.onSurfaceVariant))),
                              const SizedBox(height: 22),
                              ValueListenableBuilder<MediaPlayerState>(
                                  valueListenable:
                                      MediaPlayerController.instance,
                                  builder: (context, state, _) {
                                    final active = state.episode?.id ==
                                            episode['id']?.toString() &&
                                        state.isPlaying;
                                    return Align(
                                      alignment: Alignment.centerLeft,
                                      child: IconButton.filled(
                                          tooltip: active
                                              ? 'Pause message'
                                              : 'Play message',
                                          style: IconButton.styleFrom(
                                              backgroundColor: colors.onSurface,
                                              foregroundColor:
                                                  colors.surfaceContainerLowest,
                                              fixedSize: const Size(56, 56),
                                              shape: const CircleBorder()),
                                          onPressed: () {
                                            if (state.episode?.id ==
                                                episode['id']?.toString()) {
                                              MediaPlayerController.instance
                                                  .togglePlayback();
                                            } else {
                                              MediaPlayerController.instance
                                                  .play(episode);
                                            }
                                          },
                                          icon: Icon(
                                              active
                                                  ? PhosphorIconsFill.pause
                                                  : PhosphorIconsFill.play,
                                              size: 24)),
                                    );
                                  }),
                              if (snapshot.connectionState !=
                                  ConnectionState.done)
                                const Padding(
                                    padding: EdgeInsets.all(28),
                                    child: Center(
                                        child: CircularProgressIndicator()))
                              else if (snapshot.hasError)
                                MemberStatus(
                                    message: 'Collection unavailable',
                                    onRetry: () => setState(() {
                                          collection = _findCollection();
                                        }))
                              else if (snapshot.data != null) ...[
                                const SizedBox(height: 22),
                                Semantics(
                                    header: true,
                                    child: Text('In this collection',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(
                                                fontSize: 15,
                                                height: 24 / 17))),
                                const SizedBox(height: 13),
                                MediaCollectionTracks(
                                    album: snapshot.data!.album,
                                    tracks: snapshot.data!.tracks),
                              ],
                            ])))));
      });
}

class _DetailHeader extends StatelessWidget {
  const _DetailHeader(
      {required this.provider, this.episodeId, this.title, this.artwork});
  final String provider;
  final String? episodeId, title, artwork;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(children: [
        MemberIconButton(
            icon: PhosphorIconsRegular.caretLeft,
            label: 'Back',
            onPressed: () =>
                context.canPop() ? context.pop() : context.go('/media')),
        const SizedBox(width: 10),
        Expanded(
            child:
                Text('Message', style: Theme.of(context).textTheme.titleSmall)),
        MemberIconButton(
            icon: PhosphorIconsRegular.export,
            label: 'Share message',
            onPressed: episodeId == null || episodeId!.isEmpty
                ? null
                : () => shareMedia(context,
                    title: title ?? 'WPCC message',
                    text: 'Listen on WPCC Community',
                    url: mediaShareLink('a', episodeId!,
                        title: title, image: artwork))),
      ]));
}

class _Artwork extends StatelessWidget {
  const _Artwork({required this.url});
  final String url;
  @override
  Widget build(BuildContext context) {
    final fallback = ColoredBox(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        child: Center(
            child: Icon(PhosphorIconsRegular.disc,
                size: 48,
                color: Theme.of(context).colorScheme.onSurfaceVariant)));
    return url.isEmpty
        ? fallback
        : Image.network(url,
            fit: BoxFit.cover, errorBuilder: (_, __, ___) => fallback);
  }
}
