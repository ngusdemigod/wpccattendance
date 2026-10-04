import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../home/home_feed_models.dart';

class AnnouncementCardWidget extends StatefulWidget {
  const AnnouncementCardWidget({
    super.key,
    required this.announcement,
    this.onTap,
    this.onShare,
    this.onGotIt,
  });

  final HomeAnnouncement announcement;
  final VoidCallback? onTap;
  final Future<void> Function()? onShare;
  final Future<void> Function()? onGotIt;

  @override
  State<AnnouncementCardWidget> createState() => _AnnouncementCardWidgetState();
}

class _AnnouncementCardWidgetState extends State<AnnouncementCardWidget> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFBF9),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: const Color(0x1A111827),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AnnouncementHeader(
            announcement: widget.announcement,
            onShare: widget.onShare,
          ),
          if (widget.announcement.cardType != AnnouncementCardType.text) ...[
            const SizedBox(height: 16),
            _AnnouncementMedia(
              announcement: widget.announcement,
            ),
          ],
          const SizedBox(height: 16),
          Text(
            widget.announcement.title,
            style: const TextStyle(
              fontFamily: 'Instrument Sans',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
              height: 1.25,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.announcement.body,
            style: const TextStyle(
              fontFamily: 'Instrument Sans',
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Color(0xFF4B5563),
              height: 1.55,
            ),
          ),
          if (widget.announcement.isPinned) ...[
            const SizedBox(height: 12),
            const _PinnedPill(),
          ],
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _GotItButton(
                busy: _busy,
                onTap: _handleGotIt,
              ),
              _AcknowledgementStack(
                users: widget.announcement.acknowledgementPreviewUsers,
                totalCount: widget.announcement.acknowledgementCount,
              ),
            ],
          ),
        ],
      ),
    );

    if (widget.onTap == null) {
      return card;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(30),
        child: card,
      ),
    );
  }

  Future<void> _handleGotIt() async {
    if (_busy || widget.onGotIt == null) {
      return;
    }
    setState(() => _busy = true);
    try {
      await widget.onGotIt!.call();
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }
}

class _AnnouncementHeader extends StatelessWidget {
  const _AnnouncementHeader({
    required this.announcement,
    this.onShare,
  });

  final HomeAnnouncement announcement;
  final Future<void> Function()? onShare;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SourceAvatar(announcement: announcement),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  announcement.sourceName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Instrument Sans',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  announcement.metadataText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Instrument Sans',
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF8A8F98),
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        InkWell(
          onTap: onShare == null ? null : () => onShare!.call(),
          borderRadius: BorderRadius.circular(999),
          child: Container(
            height: 30,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0x1A111827)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.ios_share_rounded,
                  size: 15,
                  color: Color(0xFF111113),
                ),
                SizedBox(width: 6),
                Text(
                  'Share',
                  style: TextStyle(
                    fontFamily: 'Instrument Sans',
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF111113),
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SourceAvatar extends StatelessWidget {
  const _SourceAvatar({
    required this.announcement,
  });

  final HomeAnnouncement announcement;

  @override
  Widget build(BuildContext context) {
    final (background, textColor) = switch (announcement.avatarKind) {
      AnnouncementSourceAvatarKind.admin =>
        (const Color(0xFFF1EADD), const Color(0xFF151515)),
      AnnouncementSourceAvatarKind.media =>
        (const Color(0xFFE4F0FB), const Color(0xFF1A4F82)),
      AnnouncementSourceAvatarKind.welfare =>
        (const Color(0xFFE3F5E9), const Color(0xFF1A6B35)),
      AnnouncementSourceAvatarKind.standard =>
        (const Color(0xFFF3E8E5), const Color(0xFF111827)),
    };

    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: background,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        announcement.sourceInitials,
        style: TextStyle(
          fontFamily: 'Instrument Sans',
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textColor,
          height: 1,
        ),
      ),
    );
  }
}

class _AnnouncementMedia extends StatelessWidget {
  const _AnnouncementMedia({
    required this.announcement,
  });

  final HomeAnnouncement announcement;

  @override
  Widget build(BuildContext context) {
    switch (announcement.cardType) {
      case AnnouncementCardType.text:
        return const SizedBox.shrink();
      case AnnouncementCardType.image:
        return _MediaImage(
          imageUrl: announcement.images.first.url,
          height: 188,
          radius: 30,
        );
      case AnnouncementCardType.gallery:
        return SizedBox(
          height: 210,
          child: Row(
            children: [
              Expanded(
                child: _MediaImage(
                  imageUrl: announcement.images[0].url,
                  height: double.infinity,
                  radius: 30,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: _MediaImage(
                        imageUrl: announcement.images.length > 1
                            ? announcement.images[1].url
                            : announcement.images[0].url,
                        height: double.infinity,
                        radius: 26,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: Stack(
                        children: [
                          _MediaImage(
                            imageUrl: announcement.images.length > 2
                                ? announcement.images[2].url
                                : announcement.images[0].url,
                            height: double.infinity,
                            radius: 26,
                          ),
                          if (announcement.images.length > 3)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.38),
                                  borderRadius: BorderRadius.circular(26),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '+${announcement.images.length - 2}',
                                  style: const TextStyle(
                                    fontFamily: 'Instrument Sans',
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    height: 1,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
    }
  }
}

class _MediaImage extends StatelessWidget {
  const _MediaImage({
    required this.imageUrl,
    required this.height,
    required this.radius,
  });

  final String imageUrl;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          errorWidget: (context, url, error) => const _AnnouncementMediaFallback(),
        ),
      ),
    );
  }
}

class _AnnouncementMediaFallback extends StatelessWidget {
  const _AnnouncementMediaFallback();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF9E8CF), Color(0xFFF6D07C), Color(0xFFEDE6F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0.55, -0.7),
            radius: 0.7,
            colors: [
              Colors.white.withValues(alpha: 0.6),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }
}

class _PinnedPill extends StatelessWidget {
  const _PinnedPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF9DDF4),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.push_pin_outlined,
            size: 13,
            color: Color(0xFFC3139C),
          ),
          SizedBox(width: 6),
          Text(
            'Pinned',
            style: TextStyle(
              fontFamily: 'Instrument Sans',
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Color(0xFFC3139C),
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _GotItButton extends StatelessWidget {
  const _GotItButton({
    required this.busy,
    required this.onTap,
  });

  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: busy ? null : onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF111113),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (busy)
              const SizedBox(
                width: 13,
                height: 13,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            else
              const Icon(
                Icons.thumb_up_alt_rounded,
                size: 13,
                color: Colors.white,
              ),
            const SizedBox(width: 6),
            const Text(
              'Got it',
              style: TextStyle(
                fontFamily: 'Instrument Sans',
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Colors.white,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AcknowledgementStack extends StatelessWidget {
  const _AcknowledgementStack({
    required this.users,
    required this.totalCount,
  });

  final List<AnnouncementAcknowledgementUser> users;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    if (totalCount <= 0 || users.isEmpty) {
      return const SizedBox.shrink();
    }

    final visibleUsers = users.take(6).toList(growable: false);
    final overflowCount = totalCount - visibleUsers.length;
    final bubbleCount = visibleUsers.length + (overflowCount > 0 ? 1 : 0);

    return SizedBox(
      width: 28 + ((bubbleCount - 1) * 20.0),
      height: 28,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ...List.generate(visibleUsers.length, (index) {
            final user = visibleUsers[index];
            final (background, foreground) = _stackColors(index);
            return Positioned(
              left: index * 20,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: background,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFCFBF9), width: 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  user.initials,
                  style: TextStyle(
                    fontFamily: 'Instrument Sans',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: foreground,
                    height: 1,
                  ),
                ),
              ),
            );
          }),
          if (overflowCount > 0)
            Positioned(
              left: visibleUsers.length * 20,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFF111113),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFCFBF9), width: 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  '+$overflowCount',
                  style: const TextStyle(
                    fontFamily: 'Instrument Sans',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  (Color, Color) _stackColors(int index) {
    const palette = [
      (Color(0xFFF1EADD), Color(0xFF151515)),
      (Color(0xFFE4F0FB), Color(0xFF1A4F82)),
      (Color(0xFFE3F5E9), Color(0xFF1A6B35)),
      (Color(0xFFF3E8E5), Color(0xFF111827)),
      (Color(0xFFECEFF3), Color(0xFF374151)),
      (Color(0xFFF9DDF4), Color(0xFFC3139C)),
    ];
    return palette[index % palette.length];
  }
}
