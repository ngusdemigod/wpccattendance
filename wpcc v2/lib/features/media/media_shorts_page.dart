import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/theme/app_motion.dart';
import 'media_feed.dart';
import 'media_links.dart';
import 'media_meta.dart';
import 'media_motion.dart';
import 'media_player_controller.dart';
import 'media_share.dart';
import 'media_shelves.dart';
import 'video_embed.dart';
import 'video_embed_controller.dart';

const _stage = Color(0xFF0E0E10);

/// Opens the Shorts viewer above everything else (navigation bar included),
/// starting at [index] in [items].
Future<void> openShortsViewer(BuildContext context,
    {required List<MediaFeedItem> items, required int index}) {
  final navigator = Navigator.of(context, rootNavigator: true);
  final themes = InheritedTheme.capture(from: context, to: navigator.context);
  return navigator.push<void>(PageRouteBuilder<void>(
      opaque: true,
      transitionDuration: AppMotion.duration(context, AppMotion.page),
      reverseTransitionDuration: AppMotion.duration(context, AppMotion.exit),
      pageBuilder: (_, __, ___) =>
          themes.wrap(MediaShortsPage(items: items, initialIndex: index)),
      transitionsBuilder: (_, animation, __, child) => AppRouteMotion(
          animation: animation, beginScale: .98, child: child)));
}

/// Full-screen vertical viewer for short and portrait videos, like Shorts or
/// TikTok. Swipe up or down (or use the arrows or keyboard) to move between
/// videos; tap the video to pause a YouTube short. Only the video on screen is
/// mounted as a player, so only one plays at a time.
class MediaShortsPage extends StatefulWidget {
  const MediaShortsPage(
      {super.key, required this.items, required this.initialIndex});
  final List<MediaFeedItem> items;
  final int initialIndex;

  @override
  State<MediaShortsPage> createState() => _MediaShortsPageState();
}

class _MediaShortsPageState extends State<MediaShortsPage> {
  late final PageController pages;
  final controller = VideoEmbedController();
  late int index = widget.initialIndex;
  bool paused = false;

  @override
  void initState() {
    super.initState();
    MediaPlayerController.instance.pause();
    pages = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    pages.dispose();
    super.dispose();
  }

  void _go(int target) {
    if (target < 0 || target >= widget.items.length) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      pages.jumpToPage(target);
    } else {
      pages.animateToPage(target,
          duration: AppMotion.sheet, curve: AppMotion.curve);
    }
  }

  void _toggle() {
    if (widget.items[index].provider != 'youtube') return;
    setState(() => paused = !paused);
    paused ? controller.pause() : controller.play();
  }

  @override
  Widget build(BuildContext context) => CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowDown): () => _go(index + 1),
        const SingleActivator(LogicalKeyboardKey.arrowUp): () => _go(index - 1),
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            Navigator.of(context).maybePop(),
      },
      child: Focus(
          autofocus: true,
          child: Scaffold(
              backgroundColor: _stage,
              body: Stack(children: [
                PageView.builder(
                    scrollDirection: Axis.vertical,
                    controller: pages,
                    itemCount: widget.items.length,
                    onPageChanged: (value) => setState(() {
                          index = value;
                          paused = false;
                        }),
                    itemBuilder: (context, i) => _ShortPage(
                        item: widget.items[i],
                        active: i == index,
                        paused: paused,
                        controller: controller,
                        onTap: _toggle)),
                SafeArea(
                    child: Align(
                        alignment: Alignment.topLeft,
                        child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: IconButton(
                                tooltip: 'Close shorts',
                                constraints: const BoxConstraints(
                                    minWidth: 48, minHeight: 48),
                                color: Colors.white,
                                icon: const Icon(PhosphorIconsRegular.x),
                                onPressed: () =>
                                    Navigator.of(context).maybePop())))),
                SafeArea(
                    child: Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _Step(
                                      icon: PhosphorIconsRegular.caretUp,
                                      label: 'Previous short',
                                      onTap: index > 0
                                          ? () => _go(index - 1)
                                          : null),
                                  const SizedBox(height: 8),
                                  _Step(
                                      icon: PhosphorIconsRegular.caretDown,
                                      label: 'Next short',
                                      onTap: index < widget.items.length - 1
                                          ? () => _go(index + 1)
                                          : null),
                                ])))),
              ]))));
}

class _Step extends StatelessWidget {
  const _Step({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => AnimatedOpacity(
      duration: AppMotion.duration(context, AppMotion.control),
      curve: AppMotion.curve,
      opacity: onTap == null ? .35 : 1,
      child: DecoratedBox(
          decoration: const BoxDecoration(
              shape: BoxShape.circle, color: Color(0x73000000)),
          child: IconButton(
              tooltip: label,
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              color: Colors.white,
              icon: Icon(icon),
              onPressed: onTap)));
}

class _ShortPage extends StatelessWidget {
  const _ShortPage(
      {required this.item,
      required this.active,
      required this.paused,
      required this.controller,
      required this.onTap});
  final MediaFeedItem item;
  final bool active, paused;
  final VideoEmbedController controller;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final embed = videoEmbedUrl(item.row, bare: true);
    final canEmbed = active && VideoEmbed.supported && embed.isNotEmpty;
    final permalink = item.row['permalink_url']?.toString() ?? '';
    final provider = item.providerLabel;
    final text = Theme.of(context).textTheme;
    return Semantics(
      label: mediaSemanticLabel(item),
      child: Stack(fit: StackFit.expand, children: [
        Center(
            child: AspectRatio(
                aspectRatio: 9 / 16,
                child: Stack(fit: StackFit.expand, children: [
                  // Poster first: it is what shows until the player is ready,
                  // and what shows for every video that is not on screen.
                  MediaThumb(
                      url: mediaThumbnailUrl(item, width: 960),
                      radius: 0,
                      icon: PhosphorIconsRegular.videoCamera),
                  if (canEmbed)
                    VideoEmbed(
                        embedUrl: embed,
                        title: item.title,
                        aspectRatio: 9 / 16,
                        radius: 0,
                        interactive: false,
                        controller: controller),
                ]))),
        // Tap target over the video.
        Positioned.fill(
            child: GestureDetector(
                behavior: HitTestBehavior.translucent, onTap: onTap)),
        IgnorePointer(
            child: Center(
                child: AnimatedScale(
                    scale: paused && active ? 1 : .8,
                    duration: AppMotion.duration(context, AppMotion.control),
                    curve: AppMotion.curve,
                    child: AnimatedOpacity(
                        opacity: paused && active ? 1 : 0,
                        duration: AppMotion.duration(context, AppMotion.control),
                        curve: AppMotion.curve,
                        child: const DecoratedBox(
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0x8C000000)),
                            child: SizedBox.square(
                                dimension: 72,
                                child: Center(
                                    child: Icon(PhosphorIconsFill.play,
                                        size: 30, color: Colors.white)))))))),
        Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: DecoratedBox(
                decoration: const BoxDecoration(
                    gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x00000000), Color(0xB3000000)])),
                child: SafeArea(
                    top: false,
                    child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 56, 72, 16),
                        child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.title,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: text.titleMedium
                                      ?.copyWith(color: Colors.white)),
                              const SizedBox(height: 6),
                              Text(
                                  mediaDetails(item)
                                      .where((d) => d.isNotEmpty)
                                      .join(', '),
                                  style: text.bodySmall
                                      ?.copyWith(color: Colors.white70)),
                              if (permalink.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                // Eases in each time a short comes on screen.
                                if (active)
                                  MediaReveal(
                                      key: ValueKey('open-${item.id}'),
                                      delay: const Duration(milliseconds: 200),
                                      offset: const Offset(0, 16),
                                      child: Row(children: [
                                        Flexible(
                                            child: FilledButton.tonalIcon(
                                                style: FilledButton.styleFrom(
                                                    minimumSize:
                                                        const Size(0, 48)),
                                                onPressed: () =>
                                                    openMediaLink(permalink),
                                                icon: const Icon(
                                                    PhosphorIconsRegular
                                                        .arrowSquareOut,
                                                    size: 18),
                                                label: Text(
                                                    provider.isEmpty
                                                        ? 'Open original'
                                                        : 'Open in $provider',
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis))),
                                        const SizedBox(width: 4),
                                        IconButton(
                                            tooltip: 'Share short',
                                            constraints: const BoxConstraints(
                                                minWidth: 48, minHeight: 48),
                                            color: Colors.white,
                                            icon: const Icon(
                                                PhosphorIconsRegular.export),
                                            onPressed: () => shareMedia(context,
                                                title: item.title,
                                                text: 'Watch on WPCC Community',
                                                url: mediaShareLink(
                                                    'v', item.id))),
                                      ]))
                                else
                                  const SizedBox(height: 48),
                              ],
                            ]))))),
      ]),
    );
  }
}
