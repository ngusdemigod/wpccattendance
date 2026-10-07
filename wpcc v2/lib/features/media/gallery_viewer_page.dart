import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'media_download_button.dart';
import 'media_feed.dart';
import 'media_gallery_tab.dart' show galleryPhotoLabel;
import 'media_links.dart';
import 'media_share.dart';

const _viewerBackground = Color(0xFF0E0E10);

/// Full-screen photo viewer: swipe between photos, pinch to zoom, and drag
/// down to dismiss. The drag tracks the finger 1:1 and settles from the
/// release velocity, so it can be grabbed again at any moment.
class GalleryViewerPage extends StatefulWidget {
  const GalleryViewerPage(
      {super.key, required this.photos, required this.initialIndex});
  final List<Map<String, dynamic>> photos;
  final int initialIndex;

  @override
  State<GalleryViewerPage> createState() => _GalleryViewerPageState();
}

class _GalleryViewerPageState extends State<GalleryViewerPage>
    with SingleTickerProviderStateMixin {
  late final PageController pages;
  late final AnimationController settle;
  late int index = widget.initialIndex;
  double dragY = 0;
  bool zoomed = false;

  static const _dismissDistance = 140.0;
  static const _dismissVelocity = 700.0;

  @override
  void initState() {
    super.initState();
    pages = PageController(initialPage: widget.initialIndex);
    settle = AnimationController.unbounded(vsync: this)
      ..addListener(() => setState(() => dragY = settle.value));
  }

  @override
  void dispose() {
    settle.dispose();
    pages.dispose();
    super.dispose();
  }

  void _dragStart(DragStartDetails _) => settle.stop();

  void _dragUpdate(DragUpdateDetails details) {
    if (zoomed) return;
    setState(() => dragY += details.delta.dy);
  }

  void _dragEnd(DragEndDetails details) {
    if (zoomed) return;
    final velocity = details.velocity.pixelsPerSecond.dy;
    // Project where the gesture is heading, then decide: a flick or a long
    // drag in the same direction dismisses, anything else springs back.
    final projected = dragY + velocity * 0.15;
    if (projected.abs() > _dismissDistance || velocity.abs() > _dismissVelocity) {
      Navigator.of(context).maybePop();
      return;
    }
    if (MediaQuery.disableAnimationsOf(context)) {
      setState(() => dragY = 0);
      return;
    }
    // Critically damped (no bounce): there is no momentum worth overshooting.
    settle.animateWith(SpringSimulation(
        SpringDescription.withDampingRatio(
            mass: 1, stiffness: 400, ratio: 1.0),
        dragY,
        0,
        velocity));
  }

  @override
  Widget build(BuildContext context) {
    final fade = (1 - (dragY.abs() / 400)).clamp(0.4, 1.0);
    final photo = widget.photos[index];
    return Scaffold(
      backgroundColor: _viewerBackground.withValues(alpha: fade),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragStart: _dragStart,
        onVerticalDragUpdate: _dragUpdate,
        onVerticalDragEnd: _dragEnd,
        child: Stack(children: [
          Transform.translate(
            offset: Offset(0, dragY),
            child: PageView.builder(
              controller: pages,
              physics: zoomed
                  ? const NeverScrollableScrollPhysics()
                  : const PageScrollPhysics(),
              itemCount: widget.photos.length,
              onPageChanged: (value) => setState(() {
                index = value;
                zoomed = false;
              }),
              itemBuilder: (context, i) => _ZoomablePhoto(
                  photo: widget.photos[i],
                  onZoomChanged: (value) {
                    if (i == index && value != zoomed) {
                      setState(() => zoomed = value);
                    }
                  }),
            ),
          ),
          if (!zoomed)
            Positioned.fill(
                child: SafeArea(
                    child: Column(children: [
              Padding(
                  padding: const EdgeInsets.all(4),
                  child: Row(children: [
                    IconButton(
                        tooltip: 'Close photo',
                        constraints:
                            const BoxConstraints(minWidth: 48, minHeight: 48),
                        color: Colors.white,
                        icon: const Icon(PhosphorIconsRegular.x),
                        onPressed: () => Navigator.of(context).maybePop()),
                    const Spacer(),
                    IconButton(
                        tooltip: 'Share photo',
                        constraints:
                            const BoxConstraints(minWidth: 48, minHeight: 48),
                        color: Colors.white,
                        icon: const Icon(PhosphorIconsRegular.export),
                        onPressed: () => shareMedia(context,
                            title: galleryPhotoLabel(photo),
                            text: 'Photo from WPCC Community',
                            url: mediaShareLink('p', photo['id'].toString()))),
                    // Keyed by photo so each photo starts from the icon.
                    MediaDownloadButton(
                        key: ValueKey('download-${photo['id']}'),
                        photo: photo),
                  ])),
              const Spacer(),
              _Details(photo: photo),
            ]))),
        ]),
      ),
    );
  }
}

class _ZoomablePhoto extends StatefulWidget {
  const _ZoomablePhoto({required this.photo, required this.onZoomChanged});
  final Map<String, dynamic> photo;
  final ValueChanged<bool> onZoomChanged;

  @override
  State<_ZoomablePhoto> createState() => _ZoomablePhotoState();
}

class _ZoomablePhotoState extends State<_ZoomablePhoto> {
  final transform = TransformationController();

  @override
  void initState() {
    super.initState();
    transform.addListener(
        () => widget.onZoomChanged(transform.value.getMaxScaleOnAxis() > 1.02));
  }

  @override
  void dispose() {
    transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final key = widget.photo['r2_key']?.toString() ?? '';
    return Hero(
      tag: 'gallery-photo-${widget.photo['id']}',
      child: InteractiveViewer(
        transformationController: transform,
        minScale: 1,
        maxScale: 4,
        child: Center(
            child: key.isEmpty
                ? const SizedBox.shrink()
                : Image.network(MediaCdn.thumb(key, width: 1600),
                    fit: BoxFit.contain,
                    semanticLabel: galleryPhotoLabel(widget.photo),
                    // If the large copy is missing, show the small one.
                    errorBuilder: (_, __, ___) => Image.network(
                        MediaCdn.thumb(key, width: 480),
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                            PhosphorIconsRegular.imageBroken,
                            color: Colors.white70,
                            size: 40)))),
      ),
    );
  }
}

class _Details extends StatelessWidget {
  const _Details({required this.photo});
  final Map<String, dynamic> photo;

  @override
  Widget build(BuildContext context) {
    final caption = photo['caption']?.toString().trim() ?? '';
    final date = DateTime.tryParse(photo['published_at']?.toString() ?? '');
    final permalink = photo['permalink']?.toString() ?? '';
    final style = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (caption.isNotEmpty)
              Text(caption,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: style.bodyLarge?.copyWith(color: Colors.white)),
            if (date != null) ...[
              if (caption.isNotEmpty) const SizedBox(height: 4),
              Text(DateFormat('d MMMM yyyy').format(date.toLocal()),
                  style: style.bodySmall?.copyWith(color: Colors.white70)),
            ],
            if (permalink.isNotEmpty) ...[
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                  style:
                      FilledButton.styleFrom(minimumSize: const Size(0, 48)),
                  onPressed: () => openMediaLink(permalink),
                  icon: const Icon(PhosphorIconsRegular.arrowSquareOut,
                      size: 18),
                  label: const Text('View on Facebook')),
            ],
          ]),
    );
  }
}
