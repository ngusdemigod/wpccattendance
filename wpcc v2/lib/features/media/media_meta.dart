import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/widgets/member_components.dart';
import 'media_feed.dart';

IconData mediaTypeIcon(MediaType type) => switch (type) {
      MediaType.audio => PhosphorIconsRegular.headphones,
      MediaType.video => PhosphorIconsRegular.videoCamera,
      MediaType.livestream => PhosphorIconsRegular.broadcast,
    };

/// Badge plus the plain-text details (platform, date, duration) that sit under
/// a row title. Wraps instead of truncating so large text sizes still fit.
class MediaMetaLine extends StatelessWidget {
  const MediaMetaLine({super.key, required this.type, required this.details});
  final MediaType type;
  final List<String> details;

  @override
  Widget build(BuildContext context) => Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            MediaTypeBadge(label: type.label, icon: mediaTypeIcon(type)),
            for (final detail in details.where((d) => d.isNotEmpty))
              Text(detail, style: Theme.of(context).textTheme.bodySmall),
          ]);
}

/// Screen-reader text for a feed item, read once for the whole tile.
String mediaSemanticLabel(MediaFeedItem item) {
  final kind = item.isLiveNow ? 'Live now' : item.type.label;
  final details = mediaDetails(item).where((d) => d.isNotEmpty).join(', ');
  return details.isEmpty ? '$kind, ${item.title}' : '$kind, ${item.title}, $details';
}
