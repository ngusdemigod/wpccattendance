import 'package:flutter/material.dart';

import '../../core/widgets/member_shimmer.dart';
import 'media_shelves.dart' show MediaStoryRail;

/// Loading placeholders for each section of the Media tab. They have the same
/// shape and size as the finished sections, so nothing jumps when the real
/// content arrives, and each shimmers on its own.

/// Circles with a short caption under each, same height as [MediaStoryRail].
class MediaStoriesSkeleton extends StatelessWidget {
  const MediaStoriesSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(11) / 11;
    return MemberShimmer(
        label: 'Loading albums',
        child: SizedBox(
            height: MediaStoryRail.circle + 14 + (2 * 14 * scale).ceilToDouble(),
            child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                itemCount: 5,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, __) => const SizedBox(
                    width: 84,
                    child: Column(children: [
                      MemberBone(height: MediaStoryRail.circle, circle: true),
                      SizedBox(height: 10),
                      MemberBone(width: 58, height: 10),
                    ])))));
  }
}

/// A heading bar, then a short list, a wide video, a row of small squares and
/// a row of portrait cards: the same kinds of shelf the finished feed uses.
class MediaFeedSkeleton extends StatelessWidget {
  const MediaFeedSkeleton({super.key});

  @override
  Widget build(BuildContext context) => MemberShimmer(
      label: 'Loading media',
      child: LayoutBuilder(builder: (context, box) {
        final tile = (box.maxWidth - 20) / 3;
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const MemberBone(width: 84, height: 18),
          const SizedBox(height: 18),
          for (var i = 0; i < 3; i++) ...[
            const _RowBone(),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 20),
          AspectRatio(
              aspectRatio: 16 / 9,
              child: LayoutBuilder(
                  builder: (context, wide) =>
                      MemberBone(height: wide.maxHeight, radius: 20))),
          const SizedBox(height: 12),
          const MemberBone(width: 220, height: 14),
          const SizedBox(height: 8),
          const MemberBone(width: 140, height: 10),
          const SizedBox(height: 28),
          Row(children: [
            for (var i = 0; i < 3; i++) ...[
              if (i > 0) const SizedBox(width: 10),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    MemberBone(width: tile, height: tile, radius: 12),
                    const SizedBox(height: 8),
                    MemberBone(width: tile * .9, height: 10),
                    const SizedBox(height: 6),
                    MemberBone(width: tile * .6, height: 10),
                  ])),
            ],
          ]),
          const SizedBox(height: 28),
          const MemberBone(width: 70, height: 18),
          const SizedBox(height: 14),
          SizedBox(
              height: 132 * 16 / 9,
              child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  itemCount: 4,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (_, __) =>
                      const MemberBone(width: 132, height: 132 * 16 / 9, radius: 12))),
        ]);
      }));
}

class _RowBone extends StatelessWidget {
  const _RowBone();
  @override
  Widget build(BuildContext context) => const Row(children: [
        MemberBone(width: 64, height: 66, radius: 12),
        SizedBox(width: 12),
        Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          MemberBone(height: 14),
          SizedBox(height: 10),
          MemberBone(width: 160, height: 10),
        ])),
      ]);
}

/// Masonry placeholders for the Gallery tab: two or more columns of tiles with
/// varied heights, like the finished grid.
class GallerySkeleton extends StatelessWidget {
  const GallerySkeleton({super.key, required this.columns});
  final int columns;

  static const _ratios = [1.0, 0.75, 1.3, 0.9, 1.15, 0.8, 1.0, 1.4, 0.85];

  @override
  Widget build(BuildContext context) => MemberShimmer(
      label: 'Loading photos',
      child: LayoutBuilder(builder: (context, box) {
        const gap = 8.0;
        final width = (box.maxWidth - gap * (columns - 1)) / columns;
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          for (var c = 0; c < columns; c++) ...[
            if (c > 0) const SizedBox(width: gap),
            SizedBox(
                width: width,
                child: Column(children: [
                  for (var r = 0; r < 3; r++) ...[
                    if (r > 0) const SizedBox(height: gap),
                    MemberBone(
                        width: width,
                        height: width / _ratios[(c * 3 + r) % _ratios.length],
                        radius: 12),
                  ],
                ])),
          ],
        ]);
      }));
}
