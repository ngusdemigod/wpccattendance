import 'package:flutter/material.dart';
import '../../core/widgets/member_skeleton.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/widgets/member_components.dart';
import 'media_page.dart';
import 'media_repository.dart';

class MediaAlbumDetailPage extends StatefulWidget {
  const MediaAlbumDetailPage({
    super.key,
    required this.albumId,
    this.seed,
    this.loadAlbums,
    this.loadAlbumTracks,
  });

  final String albumId;
  final Map<String, dynamic>? seed;
  final EpisodeLoader? loadAlbums;
  final AlbumTracksLoader? loadAlbumTracks;

  @override
  State<MediaAlbumDetailPage> createState() => _MediaAlbumDetailPageState();
}

class _MediaAlbumDetailPageState extends State<MediaAlbumDetailPage> {
  late Future<Map<String, dynamic>?> album;
  late Future<List<Map<String, dynamic>>> tracks;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant MediaAlbumDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.albumId != widget.albumId || oldWidget.seed != widget.seed) {
      _load();
    }
  }

  void _load() {
    album = _findAlbum();
    tracks = _loadTracks();
  }

  Future<Map<String, dynamic>?> _findAlbum() async {
    if (widget.seed?['id']?.toString() == widget.albumId) return widget.seed;
    final rows = await (widget.loadAlbums ?? MediaRepository().albums)();
    for (final row in rows) {
      if (row['id']?.toString() == widget.albumId) return row;
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> _loadTracks() =>
      (widget.loadAlbumTracks ?? MediaRepository().albumTracks)(widget.albumId);

  void _back() => context.canPop() ? context.pop() : context.go('/media');

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final gutter = width < 600 ? 20.0 : 32.0;
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: width >= 900 ? 820 : 900),
            child: FutureBuilder<Map<String, dynamic>?>(
              future: album,
              builder: (context, snapshot) =>
                  FutureBuilder<List<Map<String, dynamic>>>(
                future: tracks,
                builder: (context, trackSnapshot) {
                  final data = snapshot.data;
                  final rows =
                      trackSnapshot.data ?? const <Map<String, dynamic>>[];
                  final description =
                      data?['description']?.toString().trim() ?? '';
                  final title = data?['title']?.toString() ?? 'Album';
                  return ListView(
                    key: PageStorageKey('album-${widget.albumId}'),
                    padding: EdgeInsets.only(
                        bottom: MediaQuery.paddingOf(context).bottom + 112),
                    children: [
                      if (data != null)
                        _AlbumHero(
                          imageUrl: data['featured_image']?.toString() ?? '',
                          title: title,
                          height: width < 600 ? 300 : 380,
                          gutter: gutter,
                          onBack: _back,
                        )
                      else
                        Padding(
                          padding: EdgeInsets.fromLTRB(gutter, 20, gutter, 20),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: MemberIconButton(
                                icon: PhosphorIconsRegular.caretLeft,
                                label: 'Back',
                                onPressed: _back),
                          ),
                        ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: gutter),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (snapshot.connectionState !=
                                ConnectionState.done)
                              const Padding(
                                  padding: EdgeInsets.all(28),
                                  child: Center(child: MemberSkeleton()))
                            else if (snapshot.hasError || data == null)
                              MemberStatus(
                                  message: 'Album unavailable',
                                  icon: PhosphorIconsRegular.disc,
                                  onRetry: () => setState(_load))
                            else ...[
                              Semantics(
                                  header: true,
                                  child: MediaDisplayTitle(title)),
                              Text(
                                  trackSnapshot.connectionState ==
                                              ConnectionState.done &&
                                          !trackSnapshot.hasError
                                      ? '${rows.length} ${rows.length == 1 ? 'message' : 'messages'} \u00b7 WPCC'
                                      : 'WPCC Messages',
                                  style: Theme.of(context).textTheme.bodySmall),
                              if (description.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 17),
                                  child: Text(description,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                              height: 1.5,
                                              color: colors.onSurfaceVariant)),
                                ),
                              const SizedBox(height: 25),
                              const MemberSectionHeader(title: 'Messages'),
                              if (trackSnapshot.connectionState !=
                                  ConnectionState.done)
                                const Padding(
                                    padding: EdgeInsets.all(28),
                                    child: Center(child: MemberSkeleton()))
                              else if (trackSnapshot.hasError)
                                MemberStatus(
                                    message: 'Messages are unavailable',
                                    onRetry: () => setState(() {
                                          tracks = _loadTracks();
                                        }))
                              else if (rows.isEmpty)
                                const MemberStatus(
                                    message: 'No messages in this album')
                              else
                                MediaCollectionTracks(
                                    album: data, tracks: rows),
                            ],
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AlbumHero extends StatelessWidget {
  const _AlbumHero(
      {required this.imageUrl,
      required this.title,
      required this.height,
      required this.gutter,
      required this.onBack});
  final String imageUrl, title;
  final double height, gutter;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final fallback = ColoredBox(
        color: colors.surfaceContainerLow,
        child: Center(
            child: Icon(PhosphorIconsRegular.disc,
                size: 72, color: colors.onSurfaceVariant)));
    return SizedBox(
      height: height,
      child: Stack(fit: StackFit.expand, children: [
        ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback: (bounds) => const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black, Colors.black, Colors.transparent],
              stops: [0, .55, 1]).createShader(bounds),
          child: Semantics(
            image: true,
            label: '$title artwork',
            child: imageUrl.isEmpty
                ? fallback
                : Image.network(imageUrl,
                    fit: BoxFit.cover,
                    alignment: const Alignment(0, -.3),
                    excludeFromSemantics: true,
                    errorBuilder: (_, __, ___) => fallback),
          ),
        ),
        Positioned(
            top: 16,
            left: gutter,
            child: Material(
              color: const Color(0x66000000),
              shape: const CircleBorder(),
              child: IconButton(
                  tooltip: 'Back',
                  onPressed: onBack,
                  color: Colors.white,
                  style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
                  icon: const Icon(PhosphorIconsRegular.caretLeft, size: 20)),
            )),
      ]),
    );
  }
}
