import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/theme/app_theme.dart';
import 'media_player_controller.dart';
import 'media_repository.dart';

typedef EpisodeLoader = Future<List<Map<String, dynamic>>> Function();

class MediaPage extends StatefulWidget {
  const MediaPage({super.key, this.loadEpisodes});
  final EpisodeLoader? loadEpisodes;
  @override
  State<MediaPage> createState() => _MediaPageState();
}

class _MediaPageState extends State<MediaPage> {
  late Future<List<Map<String, dynamic>>> episodes;
  String filter = 'All';
  @override
  void initState() {
    super.initState();
    episodes = _load();
  }

  Future<List<Map<String, dynamic>>> _load() =>
      (widget.loadEpisodes ?? MediaRepository().episodes)();
  Future<void> _refresh() async {
    final next = _load();
    setState(() => episodes = next);
    await next;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
            bottom: false,
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: episodes,
                builder: (context, snapshot) {
                  final rows = snapshot.data ?? const <Map<String, dynamic>>[];
                  return ListView(
                      padding: const EdgeInsets.fromLTRB(19, 18, 19, 112),
                      children: [
                        Row(children: [
                          const Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text('Media',
                                    style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: -1)),
                                SizedBox(height: 3),
                                Text('Messages to strengthen your week',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: WpccColors.inkSoft)),
                              ])),
                          _CircleButton(
                              icon: PhosphorIcons.magnifyingGlass(),
                              label: 'Search media',
                              onTap: () {}),
                        ]),
                        const SizedBox(height: 20),
                        SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                                children: [
                              'All',
                              'New releases',
                              'Messages',
                              'Devotionals'
                            ]
                                    .map((item) => Padding(
                                        padding:
                                            const EdgeInsets.only(right: 8),
                                        child: ChoiceChip(
                                            label: Text(item),
                                            selected: filter == item,
                                            onSelected: (_) =>
                                                setState(() => filter = item),
                                            showCheckmark: false,
                                            selectedColor: WpccColors.ink,
                                            backgroundColor: Colors.white,
                                            labelStyle: TextStyle(
                                                fontSize: 12,
                                                color: filter == item
                                                    ? Colors.white
                                                    : WpccColors.inkSoft),
                                            side: const BorderSide(
                                                color: WpccColors.line),
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        20)))))
                                    .toList())),
                        const SizedBox(height: 26),
                        if (snapshot.connectionState != ConnectionState.done)
                          const SizedBox(
                              height: 300,
                              child: Center(child: CircularProgressIndicator()))
                        else if (snapshot.hasError)
                          const _MediaStatus(
                              icon: Icons.error_outline,
                              title: 'Unable to load Spotify',
                              message:
                                  'Pull down to retry loading the latest podcast episodes.')
                        else if (rows.isEmpty)
                          const _MediaStatus(
                              icon: Icons.mic_none_rounded,
                              title: 'No episodes yet',
                              message:
                                  'New Spotify episodes will appear here automatically.')
                        else ...[
                          const _SectionTitle(
                              title: 'Featured message', trailing: 'Latest'),
                          const SizedBox(height: 12),
                          _FeaturedEpisode(episode: rows.first),
                          const SizedBox(height: 28),
                          _SectionTitle(
                              title: 'Latest messages',
                              trailing: '${rows.length} episodes'),
                          const SizedBox(height: 10),
                          ...rows
                              .skip(1)
                              .map((episode) => _EpisodeTile(episode: episode)),
                        ],
                      ]);
                },
              ),
            )),
      );
}

class _FeaturedEpisode extends StatelessWidget {
  const _FeaturedEpisode({required this.episode});
  final Map<String, dynamic> episode;
  @override
  Widget build(BuildContext context) {
    final artwork = episode['artwork_url']?.toString() ?? '';
    final description = episode['description']?.toString() ?? '';
    return InkWell(
      onTap: () => context.push('/media/${episode['id']}', extra: episode),
      borderRadius: BorderRadius.circular(28),
      child: Container(
          height: 205,
          decoration: BoxDecoration(
              color: WpccColors.primarySoft,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: WpccColors.lavender)),
          child: ClipRRect(
              borderRadius: BorderRadius.circular(27),
              child: Stack(children: [
                Positioned(
                    right: -16,
                    bottom: -12,
                    top: 16,
                    width: 178,
                    child: artwork.isEmpty
                        ? const _ArtworkPlaceholder(size: 178)
                        : Image.network(artwork,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const _ArtworkPlaceholder(size: 178))),
                Positioned.fill(
                    child: DecoratedBox(
                        decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [
                  WpccColors.primarySoft,
                  WpccColors.primarySoft.withValues(alpha: .96),
                  WpccColors.primarySoft.withValues(alpha: 0)
                ], stops: const [
                  0,
                  .48,
                  .78
                ])))),
                Padding(
                    padding: const EdgeInsets.all(20),
                    child: SizedBox(
                        width: 220,
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('NEW MESSAGE',
                                  style: TextStyle(
                                      fontSize: 9,
                                      letterSpacing: 1.1,
                                      fontWeight: FontWeight.w600,
                                      color: WpccColors.primaryDeep)),
                              const SizedBox(height: 10),
                              Text(
                                  episode['title']?.toString() ??
                                      'Podcast episode',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 20,
                                      height: 1.08,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              Text(description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      height: 1.35,
                                      color: WpccColors.inkSoft)),
                              const Spacer(),
                              FilledButton.icon(
                                  onPressed: () => MediaPlayerController
                                      .instance
                                      .play(episode),
                                  style: FilledButton.styleFrom(
                                      backgroundColor: WpccColors.ink,
                                      foregroundColor: Colors.white,
                                      minimumSize: const Size(112, 44)),
                                  icon: Icon(PhosphorIcons.play(), size: 16),
                                  label: const Text('Listen')),
                            ]))),
              ]))),
    );
  }
}

class _EpisodeTile extends StatelessWidget {
  const _EpisodeTile({required this.episode});
  final Map<String, dynamic> episode;
  @override
  Widget build(BuildContext context) {
    final artwork = episode['artwork_url']?.toString() ?? '';
    final published =
        DateTime.tryParse(episode['source_published_at']?.toString() ?? '');
    final durationMs =
        int.tryParse(episode['duration_ms']?.toString() ?? '') ?? 0;
    return InkWell(
        onTap: () => context.push('/media/${episode['id']}', extra: episode),
        borderRadius: BorderRadius.circular(22),
        child: Container(
            margin: const EdgeInsets.only(bottom: 9),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: WpccColors.line)),
            child: Row(children: [
              ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: artwork.isEmpty
                      ? const _ArtworkPlaceholder(size: 68)
                      : Image.network(artwork,
                          width: 68,
                          height: 68,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const _ArtworkPlaceholder(size: 68))),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(episode['title']?.toString() ?? 'Podcast episode',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 14,
                            height: 1.2,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 7),
                    Text(
                        [
                          if (published != null)
                            DateFormat('d MMM yyyy')
                                .format(published.toLocal()),
                          if (durationMs > 0) _duration(durationMs)
                        ].join(' · '),
                        style: const TextStyle(
                            fontSize: 10, color: WpccColors.muted)),
                  ])),
              const SizedBox(width: 8),
              InkWell(
                  onTap: () => MediaPlayerController.instance.play(episode),
                  customBorder: const CircleBorder(),
                  child: Container(
                      width: 42,
                      height: 42,
                      decoration: const BoxDecoration(
                          color: WpccColors.ink, shape: BoxShape.circle),
                      child: Icon(PhosphorIcons.play(),
                          size: 17, color: Colors.white))),
            ])));
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.trailing});
  final String title, trailing;
  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(
            child: Text(title,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w500))),
        Text(trailing,
            style: const TextStyle(fontSize: 11, color: WpccColors.muted))
      ]);
}

class _CircleButton extends StatelessWidget {
  const _CircleButton(
      {required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Semantics(
      button: true,
      label: label,
      child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: WpccColors.line)),
              child: Icon(icon, size: 20))));
}

class _ArtworkPlaceholder extends StatelessWidget {
  const _ArtworkPlaceholder({required this.size});
  final double size;
  @override
  Widget build(BuildContext context) => Container(
      width: size,
      height: size,
      color: WpccColors.lavender,
      alignment: Alignment.center,
      child: Icon(PhosphorIcons.microphoneStage(),
          size: size * .3, color: WpccColors.primaryDeep));
}

class _MediaStatus extends StatelessWidget {
  const _MediaStatus(
      {required this.icon, required this.title, required this.message});
  final IconData icon;
  final String title, message;
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: WpccColors.line)),
      child: Column(children: [
        Icon(icon, size: 34, color: WpccColors.primaryDeep),
        const SizedBox(height: 14),
        Text(title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text(message,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 12, height: 1.5, color: WpccColors.muted))
      ]));
}

String _duration(int milliseconds) {
  final mins = Duration(milliseconds: milliseconds).inMinutes;
  return mins >= 60 ? '${mins ~/ 60}h ${mins % 60}m' : '$mins min';
}
