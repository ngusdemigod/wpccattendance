import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/theme/app_motion.dart';
import '../../core/widgets/member_components.dart';
import 'gallery_viewer_page.dart';
import 'media_download_button.dart';
import 'media_feed.dart';
import 'media_repository.dart';
import 'media_skeletons.dart';

typedef GalleryLoader = Future<List<Map<String, dynamic>>> Function(
    {Map<String, dynamic>? after});

int galleryColumns(double width) => width >= 900
    ? 4
    : width >= 600
        ? 3
        : 2;

/// Facebook page photos in a masonry grid with keyset pagination. Owns its own
/// scroll view so the grid stays virtualized; [header] (title and tab switch)
/// scrolls with it.
class MediaGalleryTab extends StatefulWidget {
  const MediaGalleryTab({super.key, required this.header, this.loadPhotos});
  final Widget header;
  final GalleryLoader? loadPhotos;

  @override
  State<MediaGalleryTab> createState() => _MediaGalleryTabState();
}

class _MediaGalleryTabState extends State<MediaGalleryTab> {
  final photos = <Map<String, dynamic>>[];
  bool loading = true, loadingMore = false, reachedEnd = false;
  bool loadFailed = false, moreFailed = false;
  int generation = 0;

  @override
  void initState() {
    super.initState();
    _loadFirst();
  }

  Future<List<Map<String, dynamic>>> _fetch({Map<String, dynamic>? after}) =>
      widget.loadPhotos != null
          ? widget.loadPhotos!(after: after)
          : MediaRepository().galleryPhotos(after: after);

  Future<void> _loadFirst() async {
    final mine = ++generation;
    setState(() {
      loading = photos.isEmpty;
      loadFailed = false;
      moreFailed = false;
    });
    try {
      final rows = await _fetch();
      if (!mounted || mine != generation) return;
      setState(() {
        photos
          ..clear()
          ..addAll(rows);
        loading = false;
        reachedEnd = rows.length < MediaRepository.galleryPageSize;
      });
    } catch (_) {
      if (!mounted || mine != generation) return;
      setState(() {
        loading = false;
        loadFailed = photos.isEmpty;
      });
    }
  }

  Future<void> _loadMore() async {
    if (loading || loadingMore || reachedEnd || photos.isEmpty) return;
    final mine = generation;
    setState(() {
      loadingMore = true;
      moreFailed = false;
    });
    try {
      final rows = await _fetch(after: photos.last);
      if (!mounted || mine != generation) return;
      setState(() {
        photos.addAll(rows);
        loadingMore = false;
        reachedEnd = rows.length < MediaRepository.galleryPageSize;
      });
    } catch (_) {
      if (!mounted || mine != generation) return;
      setState(() {
        loadingMore = false;
        moreFailed = true;
      });
    }
  }

  bool _onScroll(ScrollNotification notification) {
    if (notification.metrics.axis == Axis.vertical &&
        notification.metrics.extentAfter < 800) {
      _loadMore();
    }
    return false;
  }

  void _open(int index) => Navigator.of(context).push(PageRouteBuilder<void>(
      opaque: false,
      barrierColor: Colors.transparent,
      transitionDuration: AppMotion.duration(context, AppMotion.page),
      reverseTransitionDuration: AppMotion.duration(context, AppMotion.exit),
      pageBuilder: (_, __, ___) =>
          GalleryViewerPage(photos: List.of(photos), initialIndex: index),
      transitionsBuilder: (_, animation, __, child) =>
          FadeTransition(opacity: animation, child: child)));

  @override
  Widget build(BuildContext context) {
    final padding = memberPagePadding(context,
        phone: 20,
        top: 20,
        bottom: MediaQuery.paddingOf(context).bottom + 112);
    final columns = galleryColumns(MediaQuery.sizeOf(context).width);
    return RefreshIndicator(
      onRefresh: _loadFirst,
      child: NotificationListener<ScrollNotification>(
        onNotification: _onScroll,
        child: CustomScrollView(
          key: const PageStorageKey('media-gallery'),
          primary: false,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
                padding: EdgeInsets.fromLTRB(padding.left, padding.top,
                    padding.right, 20),
                sliver: SliverToBoxAdapter(child: widget.header)),
            if (loading)
              _padded(padding,
                  SliverToBoxAdapter(child: GallerySkeleton(columns: columns)))
            else if (loadFailed)
              _padded(
                  padding,
                  SliverToBoxAdapter(
                      child: MemberStatus(
                          message: 'Photos are unavailable',
                          icon: PhosphorIconsRegular.warningCircle,
                          onRetry: _loadFirst)))
            else if (photos.isEmpty)
              _padded(
                  padding,
                  SliverToBoxAdapter(
                      child: MemberStatus(
                          message: 'No photos yet',
                          icon: PhosphorIconsRegular.images,
                          onRetry: _loadFirst)))
            else ...[
              _padded(
                  padding,
                  SliverMasonryGrid.count(
                      crossAxisCount: columns,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childCount: photos.length,
                      itemBuilder: (context, index) => GalleryTile(
                          photo: photos[index], onTap: () => _open(index)))),
              _padded(
                  padding,
                  SliverToBoxAdapter(
                      child: moreFailed
                          ? MemberStatus(
                              message: 'More photos are unavailable',
                              onRetry: _loadMore)
                          : loadingMore
                              ? Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  child: GallerySkeleton(columns: columns))
                              : const SizedBox.shrink())),
            ],
            SliverToBoxAdapter(child: SizedBox(height: padding.bottom)),
          ],
        ),
      ),
    );
  }

  SliverPadding _padded(EdgeInsets padding, Widget sliver) => SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: padding.left), sliver: sliver);
}

/// A single masonry tile. Space is reserved from the stored width and height
/// so the grid never shifts as images load. The tile has no overlay text: the
/// caption lives in the viewer.
class GalleryTile extends StatelessWidget {
  const GalleryTile({super.key, required this.photo, required this.onTap});
  final Map<String, dynamic> photo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final width = (photo['width'] as num?)?.toDouble() ?? 0;
    final height = (photo['height'] as num?)?.toDouble() ?? 0;
    final ratio = width > 0 && height > 0 ? width / height : 1.0;
    final key = photo['r2_key']?.toString() ?? '';
    final placeholder = ColoredBox(
        color: colors.surfaceContainerLow,
        child: Center(
            child: Icon(PhosphorIconsRegular.image,
                color: colors.onSurfaceVariant)));
    return AspectRatio(
      aspectRatio: ratio.clamp(0.5, 2.0),
      child: LayoutBuilder(builder: (context, box) {
        final decodeWidth =
            (box.maxWidth * MediaQuery.devicePixelRatioOf(context))
                .clamp(120, 480)
                .round();
        return Stack(fit: StackFit.expand, children: [
          Semantics(
            button: true,
            image: true,
            label: galleryPhotoLabel(photo),
            excludeSemantics: true,
            onTap: onTap,
            child: Hero(
              tag: 'gallery-photo-${photo['id']}',
              child: Material(
                color: Colors.transparent,
                clipBehavior: Clip.antiAlias,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: onTap,
                  child: key.isEmpty
                      ? placeholder
                      : Image.network(MediaCdn.thumb(key, width: 480),
                          fit: BoxFit.cover,
                          excludeFromSemantics: true,
                          cacheWidth: decodeWidth,
                          errorBuilder: (_, __, ___) => placeholder,
                          frameBuilder: (context, child, frame, sync) => sync
                              ? child
                              : AnimatedOpacity(
                                  duration: AppMotion.duration(
                                      context, AppMotion.page),
                                  curve: AppMotion.curve,
                                  opacity: frame == null ? 0 : 1,
                                  child: child)),
                ),
              ),
            ),
          ),
          // Outside the Hero, so it does not fly with the photo.
          if (key.isNotEmpty)
            Positioned(
                top: 2,
                right: 2,
                child: MediaDownloadButton(photo: photo)),
        ]);
      }),
    );
  }
}

/// Screen-reader text for a photo: its caption, or the date it was posted.
String galleryPhotoLabel(Map<String, dynamic> photo) {
  final caption = photo['caption']?.toString().trim() ?? '';
  if (caption.isNotEmpty) return caption;
  final date = DateTime.tryParse(photo['published_at']?.toString() ?? '');
  return date == null
      ? 'Photo'
      : 'Photo from ${DateFormat('d MMMM yyyy').format(date.toLocal())}';
}
