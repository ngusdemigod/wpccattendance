import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/theme/app_motion.dart';
import '../../core/widgets/member_components.dart';
import 'media_feed.dart';
import 'media_meta.dart';
import 'media_motion.dart';
import 'media_player_controller.dart';

/// Image that fills its parent, fades in when it has loaded and falls back to
/// a quiet tile with an icon when there is no image or it fails.
class MediaThumb extends StatelessWidget {
  const MediaThumb(
      {super.key, required this.url, required this.icon, this.radius = 12});
  final String url;
  final IconData icon;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final quiet = Center(
        child: Icon(icon, size: 28, color: colors.onSurfaceVariant));
    return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: ColoredBox(
            color: colors.surfaceContainerLow,
            child: SizedBox.expand(
                child: url.isEmpty
                    ? quiet
                    : LayoutBuilder(builder: (context, box) {
                        final pixels = MediaQuery.devicePixelRatioOf(context);
                        return Image.network(url,
                            fit: BoxFit.cover,
                            excludeFromSemantics: true,
                            cacheWidth: box.maxWidth.isFinite
                                ? (box.maxWidth * pixels).clamp(96, 1280).round()
                                : null,
                            errorBuilder: (_, __, ___) => quiet,
                            frameBuilder: (context, child, frame, sync) => sync
                                ? child
                                : AnimatedOpacity(
                                    duration: AppMotion.duration(
                                        context, AppMotion.page),
                                    curve: AppMotion.curve,
                                    opacity: frame == null ? 0 : 1,
                                    child: child));
                      }))));
  }
}

// ---------------------------------------------------------------------------
// Story circles: live now, latest livestream, albums
// ---------------------------------------------------------------------------

enum MediaStoryKind { live, latest, album }

class MediaStory {
  const MediaStory(
      {required this.id,
      required this.kind,
      required this.label,
      required this.semanticLabel,
      required this.imageUrl,
      required this.onTap});
  final String id, label, semanticLabel, imageUrl;
  final MediaStoryKind kind;
  final VoidCallback onTap;
}

/// Circles at the top of the page, like stories on a social app: the livestream
/// on air (with a LIVE badge) or else the latest livestream, then the albums.
class MediaStoryRail extends StatelessWidget {
  const MediaStoryRail({super.key, required this.stories});
  final List<MediaStory> stories;

  static const circle = 76.0;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(11) / 11;
    return SizedBox(
        height: circle + 14 + (2 * 14 * scale).ceilToDouble(),
        child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            padding: EdgeInsets.zero,
            itemCount: stories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) => MediaReveal(
                delay: Duration(milliseconds: 40 * math.min(index, 6)),
                child: _StoryCircle(story: stories[index]))));
  }
}

class _StoryCircle extends StatelessWidget {
  const _StoryCircle({required this.story});
  final MediaStory story;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final live = story.kind == MediaStoryKind.live;
    final ring = switch (story.kind) {
      MediaStoryKind.live => colors.primary,
      MediaStoryKind.latest => colors.outlineVariant,
      MediaStoryKind.album => null,
    };
    return Semantics(
      button: true,
      label: story.semanticLabel,
      excludeSemantics: true,
      onTap: story.onTap,
      child: AppPressMotion(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: story.onTap,
            child: SizedBox(
              width: 84,
              child: Column(children: [
                Stack(clipBehavior: Clip.none, children: [
                  Container(
                      width: MediaStoryRail.circle,
                      height: MediaStoryRail.circle,
                      padding: EdgeInsets.all(ring == null ? 0 : 3),
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: ring == null
                              ? null
                              : Border.all(color: ring, width: 2)),
                      child: MediaThumb(
                          url: story.imageUrl,
                          radius: 100,
                          icon: story.kind == MediaStoryKind.album
                              ? PhosphorIconsRegular.disc
                              : PhosphorIconsRegular.broadcast)),
                  if (live)
                    Positioned(
                        left: 0,
                        right: 0,
                        bottom: -6,
                        child: Center(
                            child: DecoratedBox(
                                decoration: BoxDecoration(
                                    color: colors.error,
                                    borderRadius: BorderRadius.circular(8)),
                                child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 7, vertical: 2),
                                    child: Text('LIVE',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(
                                                color: colors.onError,
                                                fontWeight: FontWeight.w700)))))),
                ]),
                SizedBox(height: live ? 14 : 8),
                Text(story.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        height: 14 / 11, color: colors.onSurface)),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Filter chips
// ---------------------------------------------------------------------------

/// Filter pills under the story circles (All, Audio), in the same style as
/// the filters on the Events page.
class MediaFilterChips extends StatelessWidget {
  const MediaFilterChips(
      {super.key,
      required this.labels,
      required this.index,
      required this.onChanged});
  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  static const _icons = [
    PhosphorIconsRegular.squaresFour,
    PhosphorIconsRegular.headphones,
  ];

  @override
  Widget build(BuildContext context) => SizedBox(
      height: 48,
      child: ListView(scrollDirection: Axis.horizontal, children: [
        for (var i = 0; i < labels.length; i++)
          Padding(
              padding: const EdgeInsets.only(right: 7),
              child: MemberFilterChip(
                  label: labels[i],
                  icon: _icons[i % _icons.length],
                  selected: i == index,
                  onPressed: () => onChanged(i))),
      ]));
}

// ---------------------------------------------------------------------------
// Shelves
// ---------------------------------------------------------------------------

/// Renders one shelf of the feed in the layout its kind asks for.
class MediaShelfView extends StatelessWidget {
  const MediaShelfView({super.key, required this.shelf, required this.onOpen});
  final MediaShelf shelf;
  final ValueChanged<MediaFeedItem> onOpen;

  @override
  Widget build(BuildContext context) => switch (shelf.kind) {
        MediaShelfKind.list => MediaListShelf(items: shelf.items, onOpen: onOpen),
        MediaShelfKind.shorts =>
          MediaShortsShelf(items: shelf.items, onOpen: onOpen),
        MediaShelfKind.wide =>
          MediaWideCard(item: shelf.items.first, onOpen: onOpen),
        MediaShelfKind.grid => MediaSquareGrid(items: shelf.items, onOpen: onOpen),
      };
}

/// Play or pause button for an audio message; reflects the shared player.
class MediaPlayButton extends StatelessWidget {
  const MediaPlayButton({super.key, required this.episode});
  final Map<String, dynamic> episode;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<MediaPlayerState>(
      valueListenable: MediaPlayerController.instance,
      builder: (context, state, _) {
        final id = episode['id']?.toString();
        final active = state.episode?.id == id && state.isPlaying;
        return IconButton(
            tooltip: active ? 'Pause message' : 'Play message',
            icon: Icon(
                active ? PhosphorIconsRegular.pause : PhosphorIconsRegular.play,
                size: 18),
            onPressed: () {
              if (state.episode?.id == id) {
                MediaPlayerController.instance.togglePlayback();
              } else {
                MediaPlayerController.instance.play(episode);
              }
            });
      });
}

/// A few rows, Spotify style: artwork on the left, title and badge beside it.
class MediaListShelf extends StatelessWidget {
  const MediaListShelf({super.key, required this.items, required this.onOpen});
  final List<MediaFeedItem> items;
  final ValueChanged<MediaFeedItem> onOpen;

  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          MediaListRow(item: items[i], onOpen: () => onOpen(items[i])),
        ],
      ]);
}

class MediaListRow extends StatelessWidget {
  const MediaListRow({super.key, required this.item, required this.onOpen});
  final MediaFeedItem item;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => AppPressMotion(
      child: MemberListRow(
          title: item.title,
          subtitleWidget:
              MediaMetaLine(type: item.type, details: mediaDetails(item)),
          leading: MemberArtwork(
              imageUrl: mediaThumbnailUrl(item, width: 320),
              size: 64,
              height: 66,
              icon: mediaTypeIcon(item.type)),
          trailing: item.isAudio
              ? MediaPlayButton(episode: item.row)
              : const SizedBox.square(
                  dimension: 48,
                  child: Center(child: Icon(PhosphorIconsRegular.play, size: 18))),
          onTap: onOpen));
}

/// A horizontal scroll of portrait cards, like Shorts or TikTok.
class MediaShortsShelf extends StatelessWidget {
  const MediaShortsShelf({super.key, required this.items, required this.onOpen});
  final List<MediaFeedItem> items;
  final ValueChanged<MediaFeedItem> onOpen;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final width = box.maxWidth >= 600 ? 160.0 : 132.0;
        final scale = MediaQuery.textScalerOf(context).scale(12) / 12;
        final height = width * 16 / 9 + 8 + (2 * 16 * scale).ceilToDouble();
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const MemberSectionHeader(title: 'Shorts'),
          SizedBox(
              height: height,
              child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  padding: EdgeInsets.zero,
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, i) => _ShortCard(
                      item: items[i],
                      width: width,
                      onTap: () => onOpen(items[i])))),
        ]);
      });
}

class _ShortCard extends StatelessWidget {
  const _ShortCard(
      {required this.item, required this.width, required this.onTap});
  final MediaFeedItem item;
  final double width;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
      width: width,
      child: Semantics(
        button: true,
        label: mediaSemanticLabel(item),
        excludeSemantics: true,
        onTap: onTap,
        child: AppPressMotion(
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox(
                  width: width,
                  height: width * 16 / 9,
                  child: MediaThumb(
                      url: mediaThumbnailUrl(item, width: 480),
                      icon: PhosphorIconsRegular.videoCamera)),
              const SizedBox(height: 8),
              Text(item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(height: 16 / 12, fontWeight: FontWeight.w500)),
            ]),
          ),
        ),
      ));
}

/// One large 16:9 video. Tapping opens it on its own page.
class MediaWideCard extends StatelessWidget {
  const MediaWideCard({super.key, required this.item, required this.onOpen});
  final MediaFeedItem item;
  final ValueChanged<MediaFeedItem> onOpen;

  @override
  Widget build(BuildContext context) => Semantics(
      button: true,
      label: mediaSemanticLabel(item),
      excludeSemantics: true,
      onTap: () => onOpen(item),
      child: AppPressMotion(
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => onOpen(item),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(fit: StackFit.expand, children: [
                  MediaThumb(
                      url: mediaThumbnailUrl(item, width: 960),
                      radius: 20,
                      icon: mediaTypeIcon(item.type)),
                  const Center(child: _PlayGlyph()),
                ])),
            const SizedBox(height: 10),
            Text(item.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            MediaMetaLine(type: item.type, details: mediaDetails(item)),
          ]),
        ),
      ));
}

class _PlayGlyph extends StatelessWidget {
  const _PlayGlyph();
  @override
  Widget build(BuildContext context) => const DecoratedBox(
      decoration: BoxDecoration(shape: BoxShape.circle, color: Color(0x8C000000)),
      child: SizedBox.square(
          dimension: 52,
          child: Center(
              child: Icon(PhosphorIconsFill.play, size: 22, color: Colors.white))));
}

/// Small square tiles, three across (six on a wide screen).
class MediaSquareGrid extends StatelessWidget {
  const MediaSquareGrid({super.key, required this.items, required this.onOpen});
  final List<MediaFeedItem> items;
  final ValueChanged<MediaFeedItem> onOpen;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final columns = box.maxWidth >= 600 ? 6 : 3;
        const gap = 10.0;
        final tile = (box.maxWidth - gap * (columns - 1)) / columns;
        final scale = MediaQuery.textScalerOf(context).scale(12) / 12;
        // square + gap + two title lines + gap + badge
        final extent = tile +
            8 +
            (2 * 16 * scale).ceilToDouble() +
            6 +
            (26 * scale).ceilToDouble();
        return GridView.builder(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: gap,
                mainAxisSpacing: 14,
                mainAxisExtent: extent),
            itemBuilder: (context, i) =>
                _SquareTile(item: items[i], size: tile, onTap: () => onOpen(items[i])));
      });
}

class _SquareTile extends StatelessWidget {
  const _SquareTile(
      {required this.item, required this.size, required this.onTap});
  final MediaFeedItem item;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
      button: true,
      label: mediaSemanticLabel(item),
      excludeSemantics: true,
      onTap: onTap,
      child: AppPressMotion(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox.square(
                dimension: size,
                child: MediaThumb(
                    url: mediaThumbnailUrl(item, width: 320),
                    icon: mediaTypeIcon(item.type))),
            const SizedBox(height: 8),
            Text(item.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(height: 16 / 12, fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            MediaTypeBadge(label: item.type.label, icon: mediaTypeIcon(item.type)),
          ]),
        ),
      ));
}
