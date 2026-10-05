import 'package:flutter/material.dart';
import '../../core/theme/app_motion.dart';
import '../../core/widgets/member_skeleton.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/widgets/adaptive_layout.dart';
import '../../core/theme/member_theme.dart';
import '../../core/widgets/member_components.dart';
import 'media_player_controller.dart';
import 'media_repository.dart';

typedef EpisodeLoader = Future<List<Map<String, dynamic>>> Function();
typedef AlbumTracksLoader = Future<List<Map<String, dynamic>>> Function(
    String id);

class MediaPage extends StatefulWidget {
  const MediaPage(
      {super.key, this.loadEpisodes, this.loadAlbums, this.loadAlbumTracks});
  final EpisodeLoader? loadEpisodes, loadAlbums;
  final AlbumTracksLoader? loadAlbumTracks;
  @override
  State<MediaPage> createState() => _MediaPageState();
}

class _MediaPageState extends State<MediaPage> {
  late Future<List<Map<String, dynamic>>> episodes, albums;
  final trackFutures = <String, Future<List<Map<String, dynamic>>>>{};
  @override
  void initState() {
    super.initState();
    episodes = _episodes();
    albums = _albums();
  }

  Future<List<Map<String, dynamic>>> _episodes() =>
      (widget.loadEpisodes ?? MediaRepository().episodes)();
  Future<List<Map<String, dynamic>>> _albums() =>
      (widget.loadAlbums ?? MediaRepository().albums)();
  Future<List<Map<String, dynamic>>> _tracks(String id) =>
      trackFutures.putIfAbsent(id, () => _loadTracks(id));
  Future<List<Map<String, dynamic>>> _loadTracks(String id) =>
      (widget.loadAlbumTracks ?? MediaRepository().albumTracks)(id);
  Future<void> _refreshMessages() async {
    final next = _episodes(), nextAlbums = _albums();
    setState(() {
      episodes = next;
      albums = nextAlbums;
      trackFutures.clear();
    });
    try {
      await Future.wait([next, nextAlbums]);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
          bottom: false,
          child: RefreshIndicator(
              onRefresh: _refreshMessages,
              child: ListView(
                key: const PageStorageKey('media-messages'),
                primary: false,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: memberPagePadding(context,
                    phone: 20,
                    top: 20,
                    bottom: MediaQuery.paddingOf(context).bottom + 112),
                children: [
                  FutureBuilder<List<Map<String, dynamic>>>(
                      future: episodes,
                      builder: (context, snapshot) {
                        final rows = snapshot.data ?? const [];
                        final provider = rows.isEmpty
                            ? ''
                            : rows.first['provider_url']?.toString() ?? '';
                        return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _Utility(providerUrl: provider),
                              if (provider.isNotEmpty)
                                MediaProviderLink(url: provider),
                              _Bio(
                                  'The Word for everyday life. Teachings from Wisdom Power Christian Centre.'),
                              FutureBuilder<List<Map<String, dynamic>>>(
                                  future: albums,
                                  builder: (context, albumSnapshot) {
                                    if (albumSnapshot.connectionState !=
                                        ConnectionState.done) {
                                      return const _Loading();
                                    }
                                    if (albumSnapshot.hasError) {
                                      return MemberStatus(
                                          message: 'Albums are unavailable',
                                          icon: PhosphorIconsRegular.disc,
                                          onRetry: _refreshMessages);
                                    }
                                    final collections =
                                        albumSnapshot.data ?? const [];
                                    if (collections.isEmpty) {
                                      return const SizedBox.shrink();
                                    }
                                    return LayoutBuilder(
                                        builder: (context, box) =>
                                            AdaptiveSections(
                                                gap: box.maxWidth >= 900
                                                    ? 36
                                                    : 5,
                                                children: [
                                                  Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              top: 20),
                                                      child:
                                                          _FeaturedCollection(
                                                        album:
                                                            collections.first,
                                                        tracks: _tracks(
                                                            collections
                                                                .first['id']
                                                                .toString()),
                                                        onOpen: () =>
                                                            _openAlbum(
                                                                context,
                                                                collections
                                                                    .first),
                                                        onRetry: () =>
                                                            setState(() {
                                                          trackFutures.remove(
                                                              collections
                                                                  .first['id']
                                                                  .toString());
                                                        }),
                                                      )),
                                                  if (collections.length > 1)
                                                    _CollectionsRail(
                                                        albums: collections
                                                            .skip(1)
                                                            .toList(),
                                                        onOpen: (album) =>
                                                            _openAlbum(context,
                                                                album)),
                                                ]));
                                  }),
                              const SizedBox(height: 25),
                              if (snapshot.connectionState !=
                                  ConnectionState.done)
                                const _Loading()
                              else if (snapshot.hasError)
                                MemberStatus(
                                    message: 'Unable to load Spotify',
                                    icon: PhosphorIconsRegular.warningCircle,
                                    onRetry: _refreshMessages)
                              else if (rows.isEmpty)
                                MemberStatus(
                                    message: 'No episodes yet',
                                    icon: PhosphorIconsRegular.microphoneStage,
                                    onRetry: _refreshMessages)
                              else ...[
                                const MemberSectionHeader(
                                    title: 'Latest message'),
                                _EpisodeRow(episode: rows.first),
                                if (rows.length > 1) ...[
                                  const SizedBox(height: 32),
                                  const MemberSectionHeader(title: 'Messages'),
                                  for (final row in rows.skip(1))
                                    Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 8),
                                        child: _EpisodeRow(episode: row)),
                                ],
                              ],
                            ]);
                      })
                ],
              ))));
}

class _Utility extends StatelessWidget {
  const _Utility({required this.providerUrl});
  final String providerUrl;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(bottom: 26),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Expanded(
            child: Text('WPCC Messages',
                style: Theme.of(context).textTheme.titleSmall)),
        MemberIconButton(
            icon: providerUrl.isEmpty
                ? PhosphorIconsRegular.magnifyingGlass
                : PhosphorIconsRegular.export,
            label: providerUrl.isEmpty ? 'Search media' : 'Share messages',
            onPressed: providerUrl.isEmpty
                ? () => context.push('/search')
                : () async {
                    await Clipboard.setData(ClipboardData(text: providerUrl));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Message link copied')));
                    }
                  }),
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
                                            fontSize: 13, height: 18 / 13))),
                            if (showChevron) ...[
                              const SizedBox(width: 5),
                              const Icon(PhosphorIconsRegular.caretRight,
                                  size: 20),
                            ],
                          ])))))));
}

class _Bio extends StatelessWidget {
  const _Bio(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(top: 17),
      child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Text(text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.5,
                  color: Theme.of(context).colorScheme.onSurfaceVariant))));
}

class _FeaturedCollection extends StatelessWidget {
  const _FeaturedCollection(
      {required this.album,
      required this.tracks,
      required this.onOpen,
      required this.onRetry});
  final Map<String, dynamic> album;
  final Future<List<Map<String, dynamic>>> tracks;
  final VoidCallback onOpen, onRetry;
  @override
  Widget build(BuildContext context) => Material(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(26),
          side:
              BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
      child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(children: [
            InkWell(
                onTapDown: (_) => ComponentOrigin.capture(context),
                onTap: onOpen,
                borderRadius: BorderRadius.circular(15),
                child: Row(children: [
                  SizedBox.square(
                      dimension: 89,
                      child: _Cover(
                          url: album['featured_image']?.toString() ?? '',
                          radius: 15)),
                  const SizedBox(width: 14),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                gradient: const LinearGradient(colors: [
                                  Color(0xFF9E74F5),
                                  Color(0xFFD79A61)
                                ])),
                            child: Text('Featured collection',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                        fontSize: 11,
                                        color: const Color(0xFF211923)))),
                        const SizedBox(height: 9),
                        Text(album['title']?.toString() ?? 'Album',
                            style: Theme.of(context).textTheme.titleSmall),
                        const SizedBox(height: 5),
                        Text(
                            'Album${_albumCount(album) == null ? '' : ' · ${_albumCount(album)} messages'}',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(fontSize: 13, height: 19 / 13)),
                      ])),
                ])),
            const SizedBox(height: 13),
            FutureBuilder<List<Map<String, dynamic>>>(
                future: tracks,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const _Loading();
                  }
                  if (snapshot.hasError) {
                    return MemberStatus(
                        message: 'Messages are unavailable',
                        icon: PhosphorIconsRegular.warningCircle,
                        onRetry: onRetry);
                  }
                  final rows = snapshot.data ?? const [];
                  if (rows.isEmpty) {
                    return const MemberStatus(
                        message: 'No messages in this album');
                  }
                  return MediaCollectionTracks(
                      album: album, tracks: rows, maximum: 3);
                }),
          ])));
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
                                        fontSize: 13,
                                        height: 18 / 13,
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

class _CollectionsRail extends StatelessWidget {
  const _CollectionsRail({required this.albums, required this.onOpen});
  final List<Map<String, dynamic>> albums;
  final ValueChanged<Map<String, dynamic>> onOpen;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('More collections',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontSize: 27,
                height: 34 / 27,
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const SizedBox(height: 14),
        SizedBox(
            height: 172 +
                9 +
                (40 * (MediaQuery.textScalerOf(context).scale(14) / 14))
                    .ceilToDouble() +
                (18 * (MediaQuery.textScalerOf(context).scale(12) / 12))
                    .ceilToDouble(),
            child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: albums.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (itemContext, index) {
                  final album = albums[index];
                  return SizedBox(
                      width: 172,
                      child: InkWell(
                          onTapDown: (_) =>
                              ComponentOrigin.capture(itemContext),
                          onTap: () => onOpen(album),
                          borderRadius: BorderRadius.circular(20),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox.square(
                                    dimension: 172,
                                    child: _Cover(
                                        url: album['featured_image']
                                                ?.toString() ??
                                            '',
                                        radius: 20)),
                                const SizedBox(height: 9),
                                Text(album['title']?.toString() ?? 'Album',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(height: 20 / 14)),
                                if (_albumCount(album) != null)
                                  Text('${_albumCount(album)} messages',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(height: 18 / 12)),
                              ])));
                })),
      ]));
}

void _openAlbum(BuildContext context, Map<String, dynamic> album) {
  final id = album['id']?.toString() ?? '';
  if (id.isNotEmpty) {
    context.go('/media/albums/${Uri.encodeComponent(id)}', extra: album);
  }
}

class _EpisodeRow extends StatelessWidget {
  const _EpisodeRow({required this.episode});
  final Map<String, dynamic> episode;
  @override
  Widget build(BuildContext context) => MemberListRow(
      title: episode['title']?.toString() ?? 'Message',
      subtitle: _metadata(episode),
      leading: MemberArtwork(
          imageUrl: episode['artwork_url']?.toString() ?? '',
          size: 64,
          height: 66,
          icon: PhosphorIconsRegular.microphoneStage),
      trailing: ValueListenableBuilder<MediaPlayerState>(
          valueListenable: MediaPlayerController.instance,
          builder: (context, state, _) {
            final active = state.episode?.id == episode['id']?.toString() &&
                state.isPlaying;
            return IconButton(
                tooltip: active ? 'Pause message' : 'Play message',
                icon: Icon(
                    active
                        ? PhosphorIconsRegular.pause
                        : PhosphorIconsRegular.play,
                    size: 18),
                onPressed: () {
                  if (state.episode?.id == episode['id']?.toString()) {
                    MediaPlayerController.instance.togglePlayback();
                  } else {
                    MediaPlayerController.instance.play(episode);
                  }
                });
          }),
      onTap: () => context.push('/media/${episode['id']}', extra: episode));
}

class _Cover extends StatelessWidget {
  const _Cover({required this.url, required this.radius});
  final String url;
  final double radius;
  @override
  Widget build(BuildContext context) {
    final fallback = ColoredBox(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        child: Center(
            child: Icon(PhosphorIconsRegular.disc,
                size: 32,
                color: Theme.of(context).colorScheme.onSurfaceVariant)));
    return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: url.isEmpty
            ? fallback
            : Image.network(url,
                fit: BoxFit.cover, errorBuilder: (_, __, ___) => fallback));
  }
}

class _Loading extends StatelessWidget {
  const _Loading();
  @override
  Widget build(BuildContext context) =>
      const Padding(padding: EdgeInsets.all(28), child: MemberSkeleton());
}

int? _albumCount(Map<String, dynamic> album) {
  final rows = album['media_album_tracks'];
  return rows is List && rows.isNotEmpty
      ? int.tryParse((rows.first as Map)['count']?.toString() ?? '')
      : null;
}

String _metadata(Map<String, dynamic> episode) {
  final date =
      DateTime.tryParse(episode['source_published_at']?.toString() ?? '');
  final ms = int.tryParse(episode['duration_ms']?.toString() ?? '') ?? 0;
  final min = Duration(milliseconds: ms).inMinutes;
  return [
    if (date != null) DateFormat('d MMM yyyy').format(date.toLocal()),
    if (ms > 0) min >= 60 ? '${min ~/ 60}h ${min % 60}m' : '$min min'
  ].join(' · ');
}

Future<void> _openProvider(String url) async {
  final uri = Uri.tryParse(url);
  if (uri != null && uri.scheme == 'https') {
    await launchUrl(uri,
        mode: LaunchMode.externalApplication, webOnlyWindowName: '_blank');
  }
}
