import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/widgets/member_components.dart';
import '../../core/widgets/member_skeleton.dart';
import 'media_feed.dart';
import 'media_links.dart';
import 'media_meta.dart';
import 'media_motion.dart';
import 'media_page.dart' show EpisodeLoader;
import 'media_player_controller.dart';
import 'media_repository.dart';
import 'media_share.dart';
import 'media_shelves.dart';
import 'video_embed.dart';

/// A video or livestream on its own page. It starts playing as soon as the
/// page opens, and the "Open in YouTube / Facebook" button eases in under the
/// player a moment later.
class MediaVideoPage extends StatefulWidget {
  const MediaVideoPage(
      {super.key, required this.videoId, this.seed, this.loadVideos});
  final String videoId;
  final Map<String, dynamic>? seed;
  final EpisodeLoader? loadVideos;

  @override
  State<MediaVideoPage> createState() => _MediaVideoPageState();
}

class _MediaVideoPageState extends State<MediaVideoPage> {
  late Future<MediaFeedItem?> item;

  @override
  void initState() {
    super.initState();
    // A video and the audio mini player must not talk over each other.
    MediaPlayerController.instance.pause();
    item = _find();
  }

  Future<MediaFeedItem?> _find() async {
    final seed = widget.seed;
    if (seed != null && seed['id']?.toString() == widget.videoId) {
      return MediaFeedItem.video(seed);
    }
    // Opened from a link or after a refresh: look it up in the catalog.
    final rows = await (widget.loadVideos ?? MediaRepository().videos)();
    for (final row in rows) {
      if (row['id']?.toString() == widget.videoId) {
        return MediaFeedItem.video(row);
      }
    }
    return null;
  }

  void _back() => context.canPop() ? context.pop() : context.go('/media');

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
          bottom: false,
          child: ListView(
              primary: false,
              padding: memberPagePadding(context,
                  phone: 20,
                  top: 20,
                  bottom: MediaQuery.paddingOf(context).bottom + 112),
              children: [
                Align(
                    alignment: Alignment.centerLeft,
                    child: MemberIconButton(
                        icon: PhosphorIconsRegular.caretLeft,
                        label: 'Back',
                        onPressed: _back)),
                const SizedBox(height: 8),
                FutureBuilder<MediaFeedItem?>(
                    future: item,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const Padding(
                            padding: EdgeInsets.all(8),
                            child: MemberSkeleton(rows: 3, hero: true));
                      }
                      final video = snapshot.data;
                      if (snapshot.hasError || video == null) {
                        return MemberStatus(
                            message: snapshot.hasError
                                ? 'Unable to load this video'
                                : 'This video is no longer available',
                            icon: PhosphorIconsRegular.videoCameraSlash,
                            onRetry: snapshot.hasError
                                ? () => setState(() {
                                  item = _find();
                                })
                                : _back);
                      }
                      return _Body(video: video);
                    }),
              ])));
}

class _Body extends StatelessWidget {
  const _Body({required this.video});
  final MediaFeedItem video;

  @override
  Widget build(BuildContext context) {
    final embed = videoEmbedUrl(video.row);
    final permalink = video.row['permalink_url']?.toString() ?? '';
    final provider = video.providerLabel;
    final canEmbed = VideoEmbed.supported && embed.isNotEmpty;
    final description = video.row['description']?.toString().trim() ?? '';
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // The poster sits behind the player so there is no empty frame
          // while the embed loads.
          AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(fit: StackFit.expand, children: [
                MediaThumb(
                    url: mediaThumbnailUrl(video, width: 960),
                    radius: 20,
                    icon: mediaTypeIcon(video.type)),
                if (canEmbed)
                  VideoEmbed(
                      embedUrl: embed, title: video.title, aspectRatio: 16 / 9)
                else
                  Center(
                      child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                              provider.isEmpty
                                  ? 'This video cannot play here.'
                                  : 'This video cannot play here. Open it in $provider.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium))),
              ])),
          const SizedBox(height: 16),
          Text(video.title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          MediaMetaLine(type: video.type, details: mediaDetails(video)),
          const SizedBox(height: 16),
          // Arrive after the player has had a moment to start.
          MediaReveal(
              delay: const Duration(milliseconds: buttonDelay),
              offset: const Offset(0, 16),
              child: Row(children: [
                if (permalink.isNotEmpty)
                  Flexible(
                      child: FilledButton.tonalIcon(
                          style: FilledButton.styleFrom(
                              minimumSize: const Size(0, 48)),
                          onPressed: () => openMediaLink(permalink),
                          icon: const Icon(PhosphorIconsRegular.arrowSquareOut,
                              size: 18),
                          label: Text(
                              provider.isEmpty
                                  ? 'Open original'
                                  : 'Open in $provider',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis))),
                const SizedBox(width: 8),
                MemberIconButton(
                    icon: PhosphorIconsRegular.export,
                    label: 'Share video',
                    onPressed: () => shareMedia(context,
                        title: video.title,
                        text: 'Watch on WPCC Community',
                        url: mediaShareLink('v', video.id))),
              ])),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 20),
            MediaReveal(
                delay: const Duration(milliseconds: buttonDelay + 60),
                child: Text(description,
                    maxLines: 8,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        height: 1.5, color: colors.onSurfaceVariant))),
          ],
        ]),
      ),
    );
  }

  static const buttonDelay = 240;
}
