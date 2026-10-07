import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/theme/app_motion.dart';
import '../../core/theme/member_theme.dart';
import '../../core/widgets/member_components.dart';
import 'media_feed.dart';
import 'media_gallery_tab.dart';
import 'media_links.dart';
import 'media_motion.dart';
import 'media_player_controller.dart';
import 'media_share.dart';
import 'media_repository.dart';
import 'media_shelves.dart';
import 'media_skeletons.dart';
import 'media_shorts_page.dart';

typedef EpisodeLoader = Future<List<Map<String, dynamic>>> Function();
typedef AlbumTracksLoader = Future<List<Map<String, dynamic>>> Function(
    String id);

class MediaPage extends StatefulWidget {
  const MediaPage(
      {super.key,
      this.loadEpisodes,
      this.loadAlbums,
      this.loadVideos,
      this.loadGalleryPhotos,
      this.shelfSeed});
  final EpisodeLoader? loadEpisodes, loadAlbums, loadVideos;
  final GalleryLoader? loadGalleryPhotos;

  /// Fixes the shelf order, for tests. Left out, every load is different.
  final int? shelfSeed;
  @override
  State<MediaPage> createState() => _MediaPageState();
}

/// Everything the Media tab shows, loaded together. Each source can fail on
/// its own without hiding the others.
class _MediaData {
  _MediaData(
      {required this.episodes,
      required this.albums,
      required this.videos,
      required this.episodesFailed,
      required this.albumsFailed,
      required this.videosFailed,
      required Random random})
      : items = mergeMediaFeed(episodes, videos) {
    shelves = buildMediaShelves(items, random: random);
  }
  final List<Map<String, dynamic>> episodes, albums, videos;
  final bool episodesFailed, albumsFailed, videosFailed;
  final List<MediaFeedItem> items;
  late final List<MediaShelf> shelves;

  String get providerUrl =>
      episodes.isEmpty ? '' : episodes.first['provider_url']?.toString() ?? '';
}

class _MediaPageState extends State<MediaPage> {
  late final Random random = Random(widget.shelfSeed);
  late Future<_MediaData> data;
  int tab = 0, filter = 0;
  bool galleryVisited = false;

  /// True for a moment while the feed fades out before a filter change.
  bool fading = false;

  @override
  void initState() {
    super.initState();
    data = _load();
  }

  Future<List<Map<String, dynamic>>> _episodes() =>
      (widget.loadEpisodes ?? MediaRepository().episodes)();
  Future<List<Map<String, dynamic>>> _albums() =>
      (widget.loadAlbums ?? MediaRepository().albums)();
  Future<List<Map<String, dynamic>>> _videos() =>
      (widget.loadVideos ?? MediaRepository().videos)();

  Future<_MediaData> _load() async {
    Future<(List<Map<String, dynamic>>, bool)> settle(
            Future<List<Map<String, dynamic>>> source) =>
        source.then((rows) => (rows, false),
            onError: (Object _) => (const <Map<String, dynamic>>[], true));
    final results = await Future.wait(
        [settle(_episodes()), settle(_albums()), settle(_videos())]);
    return _MediaData(
        episodes: results[0].$1,
        albums: results[1].$1,
        videos: results[2].$1,
        episodesFailed: results[0].$2,
        albumsFailed: results[1].$2,
        videosFailed: results[2].$2,
        random: random);
  }

  Future<void> _refresh() async {
    final next = _load();
    setState(() {
      data = next;
    });
    await next;
  }

  void _setTab(int value) => setState(() {
        tab = value;
        if (value == 1) galleryVisited = true;
      });

  /// The feed leaves quickly, then the new filter's content eases in.
  Future<void> _setFilter(int value) async {
    if (value == filter) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      setState(() => filter = value);
      return;
    }
    setState(() => fading = true);
    await Future<void>.delayed(AppMotion.exit ~/ 2);
    if (!mounted) return;
    setState(() {
      filter = value;
      fading = false;
    });
  }

  void _open(MediaFeedItem item, List<MediaFeedItem> all) {
    if (item.isAudio) {
      context.push('/media/${item.row['id']}', extra: item.row);
    } else if (item.isVertical) {
      final shorts = [
        for (final entry in all)
          if (entry.isVertical && !entry.isLiveNow) entry
      ];
      final start = shorts.indexWhere((entry) => entry.id == item.id);
      openShortsViewer(context, items: shorts, index: max(0, start));
    } else {
      context.push('/media/video/${Uri.encodeComponent(item.id)}',
          extra: item.row);
    }
  }

  /// Title, then the Media | Gallery switch in the same filter-chip style the
  /// Events page uses.
  Widget _header(String providerUrl) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _Utility(onShare: _share),
        SizedBox(
            height: 48,
            child: ListView(scrollDirection: Axis.horizontal, children: [
              for (final entry in [
                ('Media', PhosphorIconsRegular.playCircle),
                ('Gallery', PhosphorIconsRegular.images),
              ].indexed) ...[
                if (entry.$1 > 0) const SizedBox(width: 7),
                MemberFilterChip(
                    label: entry.$2.$1,
                    icon: entry.$2.$2,
                    selected: tab == entry.$1,
                    onPressed: () => _setTab(entry.$1)),
              ],
            ])),
      ]);

  Future<void> _share() => shareMedia(context,
      title: 'WPCC Community',
      text: 'Messages, videos and photos from Wisdom Power Christian Centre',
      path: '');

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
          bottom: false,
          // Both tabs stay mounted so each keeps its scroll position; the
          // gallery is only built the first time it is opened. Switching
          // cross-fades with the app's standard timing.
          child: Stack(children: [
            _TabLayer(visible: tab == 0, child: _mediaTab(context)),
            if (galleryVisited)
              _TabLayer(
                  visible: tab == 1,
                  child: FutureBuilder<_MediaData>(
                      future: data,
                      builder: (context, snapshot) => MediaGalleryTab(
                          loadPhotos: widget.loadGalleryPhotos,
                          header: _header(snapshot.data?.providerUrl ?? '')))),
          ])));

  Widget _mediaTab(BuildContext context) => RefreshIndicator(
      onRefresh: _refresh,
      child: FutureBuilder<_MediaData>(
          future: data,
          builder: (context, snapshot) {
            final loaded = snapshot.data;
            return ListView(
              key: const PageStorageKey('media-messages'),
              primary: false,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: memberPagePadding(context,
                  phone: 20,
                  top: 20,
                  bottom: MediaQuery.paddingOf(context).bottom + 112),
              children: [
                _header(loaded?.providerUrl ?? ''),
                const SizedBox(height: 20),
                if (loaded == null)
                  const MediaStoriesSkeleton()
                else
                  ..._stories(loaded),
                const SizedBox(height: 14),
                MediaFilterChips(
                    labels: const ['All', 'Audio'],
                    index: filter,
                    onChanged: _setFilter),
                const SizedBox(height: 18),
                if (loaded == null)
                  const MediaFeedSkeleton()
                else
                  ..._feed(loaded),
              ],
            );
          }));

  List<Widget> _stories(_MediaData loaded) {
    final live = liveNowItem(loaded.items);
    // The latest livestream only has a place when nothing is on air.
    final latest = live == null ? latestLivestreamItem(loaded.items) : null;
    final stories = <MediaStory>[
      if (live != null)
        MediaStory(
            id: live.id,
            kind: MediaStoryKind.live,
            label: 'Live now',
            semanticLabel: 'Live now, ${live.title}',
            imageUrl: mediaThumbnailUrl(live, width: 320),
            onTap: () => _open(live, loaded.items)),
      if (latest != null)
        MediaStory(
            id: latest.id,
            kind: MediaStoryKind.latest,
            label: 'Latest livestream',
            semanticLabel: 'Latest livestream, ${latest.title}',
            imageUrl: mediaThumbnailUrl(latest, width: 320),
            onTap: () => _open(latest, loaded.items)),
      for (final album in loaded.albums)
        MediaStory(
            id: album['id']?.toString() ?? '',
            kind: MediaStoryKind.album,
            label: album['title']?.toString() ?? 'Album',
            semanticLabel: 'Album, ${album['title'] ?? 'Album'}',
            imageUrl: album['featured_image']?.toString() ?? '',
            onTap: () => _openAlbum(context, album)),
    ];
    return stories.isEmpty ? const [] : [MediaStoryRail(stories: stories)];
  }

  /// Makes a feed row leave fast and enter smoothly when the filter changes.
  Widget _fade(Widget child) => AnimatedOpacity(
      duration: AppMotion.duration(
          context, fading ? AppMotion.exit ~/ 2 : AppMotion.control),
      curve: fading ? AppMotion.curve.flipped : AppMotion.curve,
      opacity: fading ? 0 : 1,
      child: child);

  List<Widget> _feed(_MediaData loaded) {
    final items = loaded.items;
    if (items.isEmpty) {
      if (loaded.episodesFailed && loaded.videosFailed) {
        return [
          MemberStatus(
              message: 'Unable to load media',
              icon: PhosphorIconsRegular.warningCircle,
              onRetry: _refresh)
        ];
      }
      if (loaded.episodesFailed) {
        return [
          MemberStatus(
              message: 'Unable to load Spotify',
              icon: PhosphorIconsRegular.warningCircle,
              onRetry: _refresh)
        ];
      }
      return [
        MemberStatus(
            message: 'No media yet',
            icon: PhosphorIconsRegular.microphoneStage,
            onRetry: _refresh)
      ];
    }
    final audioItems = [for (final item in items) if (item.isAudio) item];
    final rows = <Widget>[];
    if (filter == 1) {
      rows.add(_fade(const MemberSectionHeader(title: 'Audio')));
      if (audioItems.isEmpty) {
        rows.add(const MemberStatus(
            message: 'No audio yet', icon: PhosphorIconsRegular.headphones));
      }
      for (var i = 0; i < audioItems.length; i++) {
        rows.add(_fade(Padding(
            key: ValueKey('audio-$i'),
            padding: const EdgeInsets.only(bottom: 8),
            child: MediaListRow(
                item: audioItems[i],
                onOpen: () => _open(audioItems[i], items)))));
      }
    } else {
      rows.add(_fade(const MemberSectionHeader(title: 'Videos')));
      for (var i = 0; i < loaded.shelves.length; i++) {
        final shelf = loaded.shelves[i];
        // The first screenful eases in with a stagger; later shelves are
        // already in place by the time they are scrolled to.
        rows.add(_fade(MediaReveal(
            key: ValueKey('shelf-$i'),
            enabled: i < 4,
            delay: Duration(milliseconds: 50 * i),
            child: Padding(
                padding: const EdgeInsets.only(bottom: 28),
                child: MediaShelfView(
                    shelf: shelf, onOpen: (item) => _open(item, items))))));
      }
    }
    return [
      ...rows,
      if (loaded.episodesFailed)
        MemberStatus(
            message: 'Spotify messages are unavailable',
            icon: PhosphorIconsRegular.warningCircle,
            onRetry: _refresh),
      if (loaded.videosFailed)
        MemberStatus(
            message: 'Videos are unavailable',
            icon: PhosphorIconsRegular.warningCircle,
            onRetry: _refresh),
      if (loaded.albumsFailed)
        MemberStatus(
            message: 'Albums are unavailable',
            icon: PhosphorIconsRegular.disc,
            onRetry: _refresh),
      if (loaded.providerUrl.isNotEmpty)
        MediaProviderLink(url: loaded.providerUrl),
    ];
  }
}

/// One of the two top-level tabs. Stays mounted when hidden (so it keeps its
/// scroll position) and fades with the app's standard timing. Once the fade
/// out has finished it goes off stage, so it is not painted and is invisible
/// to touch and screen readers.
class _TabLayer extends StatefulWidget {
  const _TabLayer({required this.visible, required this.child});
  final bool visible;
  final Widget child;

  @override
  State<_TabLayer> createState() => _TabLayerState();
}

class _TabLayerState extends State<_TabLayer> {
  late bool settledHidden = !widget.visible;

  @override
  void didUpdateWidget(_TabLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible) {
      settledHidden = false;
    } else if (MediaQuery.disableAnimationsOf(context)) {
      settledHidden = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final visible = widget.visible;
    return Positioned.fill(
        child: Offstage(
            offstage: !visible && settledHidden,
            child: IgnorePointer(
                ignoring: !visible,
                child: ExcludeSemantics(
                    excluding: !visible,
                    child: TickerMode(
                        enabled: visible || !settledHidden,
                        child: AnimatedOpacity(
                            duration: AppMotion.duration(context,
                                visible ? AppMotion.control : AppMotion.exit),
                            curve: visible
                                ? AppMotion.curve
                                : AppMotion.curve.flipped,
                            opacity: visible ? 1 : 0,
                            onEnd: () {
                              if (!widget.visible && !settledHidden) {
                                setState(() => settledHidden = true);
                              }
                            },
                            child: widget.child))))));
  }
}

class _Utility extends StatelessWidget {
  const _Utility({required this.onShare});
  final VoidCallback onShare;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Expanded(
            child: Text('Media', style: Theme.of(context).textTheme.titleLarge)),
        MemberIconButton(
            icon: PhosphorIconsRegular.export,
            label: 'Share',
            onPressed: onShare),
      ]));
}

class MediaDisplayTitle extends StatelessWidget {
  const MediaDisplayTitle(this.title, {super.key});
  final String title;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Text(title, style: MemberVisuals.display(context)));
}

class MediaProviderLink extends StatelessWidget {
  const MediaProviderLink(
      {super.key,
      required this.url,
      this.label = 'Spotify',
      this.showChevron = true});
  final String url, label;
  final bool showChevron;
  @override
  Widget build(BuildContext context) => ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: Align(
          alignment: Alignment.centerLeft,
          child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(22),
              child: InkWell(
                  borderRadius: BorderRadius.circular(22),
                  onTap: () => _openProvider(url),
                  child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 11, vertical: showChevron ? 7 : 7.5),
                          decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(22)),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(PhosphorIconsRegular.spotifyLogo,
                                size: 19, color: const Color(0xFF27D675)),
                            const SizedBox(width: 5),
                            Flexible(
                                child: Text(label,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                            fontSize: 12, height: 18 / 13))),
                            if (showChevron) ...[
                              const SizedBox(width: 5),
                              const Icon(PhosphorIconsRegular.caretRight,
                                  size: 20),
                            ],
                          ])))))));
}

class MediaCollectionTracks extends StatelessWidget {
  const MediaCollectionTracks(
      {super.key,
      required this.album,
      required this.tracks,
      this.maximum,
      this.onOpenMessage});
  final Map<String, dynamic> album;
  final List<Map<String, dynamic>> tracks;
  final int? maximum;
  final ValueChanged<Map<String, dynamic>>? onOpenMessage;
  @override
  Widget build(BuildContext context) {
    final shown = maximum == null ? tracks : tracks.take(maximum!).toList();
    return Column(children: [
      for (var index = 0; index < shown.length; index++) ...[
        if (index > 0) const SizedBox(height: 6),
        _Track(
            row: shown[index],
            album: album,
            tracks: tracks,
            onOpenMessage: onOpenMessage),
      ],
    ]);
  }
}

class _Track extends StatelessWidget {
  const _Track(
      {required this.row,
      required this.album,
      required this.tracks,
      this.onOpenMessage});
  final Map<String, dynamic> row, album;
  final List<Map<String, dynamic>> tracks;
  final ValueChanged<Map<String, dynamic>>? onOpenMessage;
  @override
  Widget build(BuildContext context) {
    final episode = Map<String, dynamic>.from((row['episode'] as Map?) ?? {});
    return ValueListenableBuilder<MediaPlayerState>(
        valueListenable: MediaPlayerController.instance,
        builder: (context, state, _) {
          final active =
              state.episode?.id == episode['id']?.toString() && state.isPlaying;
          return Material(
              color: state.episode?.id == episode['id']?.toString()
                  ? Theme.of(context).colorScheme.surfaceContainerLow
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: episode.isEmpty
                      ? null
                      : () {
                          final selected = {
                            ...episode,
                            '_collection': album,
                            '_collection_tracks': tracks
                          };
                          if (onOpenMessage != null) {
                            onOpenMessage!(selected);
                          } else {
                            context.push('/media/${episode['id']}',
                                extra: selected);
                          }
                        },
                  child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 66),
                      child: Padding(
                          padding: const EdgeInsets.only(left: 11),
                          child: Row(children: [
                            MemberArtwork(
                                imageUrl: (episode['artwork_url'] ??
                                        album['featured_image'])
                                    ?.toString(),
                                size: 44,
                                radius: 8,
                                icon: PhosphorIconsRegular.microphoneStage),
                            const SizedBox(width: 10),
                            Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [Text(
                                    episode['title']?.toString() ??
                                        'Message unavailable',
                                    maxLines: MediaQuery.textScalerOf(context)
                                                .scale(13) >
                                            16
                                        ? null
                                        : 1,
                                    overflow: MediaQuery.textScalerOf(context)
                                                .scale(13) >
                                            16
                                        ? null
                                        : TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium?.copyWith(
                                        fontFamily: 'DM Sans',
                                        fontSize: 12,
                                        height: 18 / 12,
                                        fontWeight: FontWeight.w500)),
                                  if (row['track_number'] != null) ...[
                                    const SizedBox(height: 4),
                                    Text('Message ${row['track_number']}', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11)),
                                  ],
                                ])),
                            IconButton(
                                tooltip:
                                    active ? 'Pause message' : 'Play message',
                                icon: Icon(
                                    active
                                        ? PhosphorIconsRegular.pause
                                        : PhosphorIconsRegular.play,
                                    size: 20),
                                onPressed: episode.isEmpty
                                    ? null
                                    : () {
                                        if (state.episode?.id ==
                                            episode['id']?.toString()) {
                                          MediaPlayerController.instance
                                              .togglePlayback();
                                        } else {
                                          MediaPlayerController.instance
                                              .play(episode);
                                        }
                                      }),
                          ])))));
        });
  }
}

void _openAlbum(BuildContext context, Map<String, dynamic> album) {
  final id = album['id']?.toString() ?? '';
  if (id.isNotEmpty) {
    context.go('/media/albums/${Uri.encodeComponent(id)}', extra: album);
  }
}

Future<void> _openProvider(String url) => openMediaLink(url);
