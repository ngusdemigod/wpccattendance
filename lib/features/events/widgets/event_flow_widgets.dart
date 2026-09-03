import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../components/leaflet_map_widget.dart';
import '../data/location_verification_service.dart';
import '../models/event_flow_models.dart';

class EventAvatar extends StatelessWidget {
  const EventAvatar({
    super.key,
    required this.initials,
    this.imageUrl,
    this.size = 48,
    this.radius = 18,
    this.backgroundColor,
    this.gradient,
    this.textColor = Colors.white,
  });

  final String initials;
  final String? imageUrl;
  final double size;
  final double radius;
  final Color? backgroundColor;
  final Gradient? gradient;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final normalized = imageUrl?.trim();
    if (normalized != null && normalized.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: CachedNetworkImage(
          imageUrl: normalized,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorWidget: (context, url, error) => _fallback(),
        ),
      );
    }
    return _fallback();
  }

  Widget _fallback() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(radius),
        gradient: backgroundColor == null
            ? (gradient ??
                const LinearGradient(
                  colors: [Color(0xFFDDBA96), Color(0xFF9B6543)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ))
            : null,
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          fontFamily: 'Instrument Sans',
          fontSize: size * 0.32,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}

class EventHero extends StatelessWidget {
  const EventHero({
    super.key,
    required this.imageUrl,
    required this.onBack,
    this.onImageTap,
  });

  final String? imageUrl;
  final VoidCallback onBack;
  final VoidCallback? onImageTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 294,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Material(
            color: const Color(0xFFF3E7C7),
            child: InkWell(
              onTap: onImageTap,
              child: imageUrl == null
                  ? const SizedBox.shrink()
                  : CachedNetworkImage(
                      imageUrl: imageUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) =>
                          const SizedBox.shrink(),
                    ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _RoundIconButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: onBack,
                    ),
                    const Spacer(),
                    const _RoundIconButton(icon: Icons.ios_share_rounded),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class EventMiniCard extends StatelessWidget {
  const EventMiniCard({
    super.key,
    required this.event,
    required this.statusLabel,
    this.actionLabel,
    this.onActionTap,
  });

  final EventFlowEvent event;
  final String statusLabel;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    final statusPillColor = statusLabel.toLowerCase() == 'open'
        ? const Color(0xFFE3F5E9)
        : const Color(0xFFF3F4F6);
    final statusTextColor = statusLabel.toLowerCase() == 'open'
        ? const Color(0xFF1A6B35)
        : const Color(0xFF4B5563);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFBF9),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color.fromRGBO(17, 24, 39, 0.10)),
      ),
      child: Row(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                colors: [Color(0xFFFFF0C7), Color(0xFFECC86A)],
              ),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.church_rounded,
              size: 28,
              color: Color(0xFF352314),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Instrument Sans',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _formatDate(event.startsAt),
                  style: const TextStyle(
                    fontFamily: 'Instrument Sans',
                    fontSize: 11,
                    color: Color(0xFF4B5563),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTimeRange(event.startsAt, event.endsAt),
                  style: const TextStyle(
                    fontFamily: 'Instrument Sans',
                    fontSize: 11,
                    color: Color(0xFF4B5563),
                  ),
                ),
              ],
            ),
          ),
          if (actionLabel != null)
            TextButton(
              onPressed: onActionTap,
              style: TextButton.styleFrom(
                minimumSize: const Size(0, 32),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                backgroundColor: const Color(0xFFF3F4F6),
              ),
              child: Text(
                actionLabel!,
                style: const TextStyle(
                  fontFamily: 'Instrument Sans',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: statusPillColor,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                statusLabel,
                style: TextStyle(
                  fontFamily: 'Instrument Sans',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: statusTextColor,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class EventDetailListCard extends StatelessWidget {
  const EventDetailListCard({
    super.key,
    required this.rows,
  });

  final List<MapEntry<String, String>> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFCFBF9),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color.fromRGBO(17, 24, 39, 0.10)),
      ),
      child: Column(
        children: List.generate(rows.length, (index) {
          final row = rows[index];
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              border: index == rows.length - 1
                  ? null
                  : const Border(
                      bottom: BorderSide(
                        color: Color.fromRGBO(17, 24, 39, 0.07),
                      ),
                    ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    row.key,
                    style: const TextStyle(
                      fontFamily: 'Instrument Sans',
                      fontSize: 11,
                      color: Color(0xFF8A8F98),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    row.value,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontFamily: 'Instrument Sans',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class EventMapCard extends StatelessWidget {
  const EventMapCard({
    super.key,
    required this.event,
    this.userLatitude,
    this.userLongitude,
    this.height = 260,
  });

  final EventFlowEvent event;
  final double? userLatitude;
  final double? userLongitude;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (!event.hasCoordinates) {
      return Container(
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFFFCFBF9),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: const Color.fromRGBO(17, 24, 39, 0.10)),
        ),
        alignment: Alignment.center,
        child: const Text(
          'Location unavailable',
          style: TextStyle(
            fontFamily: 'Instrument Sans',
            fontSize: 13,
            color: Color(0xFF8A8F98),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: LeafletMapWidget(
        height: height,
        title: event.title,
        location: event.locationName,
        latitude: event.latitude!,
        longitude: event.longitude!,
        radiusMeters: LocationVerificationService.boundaryMeters,
        userLatitude: userLatitude,
        userLongitude: userLongitude,
      ),
    );
  }
}

class EventCtaButton extends StatelessWidget {
  const EventCtaButton({
    super.key,
    required this.label,
    required this.onTap,
    this.enabled = true,
    this.dark = false,
  });

  final String label;
  final VoidCallback? onTap;
  final bool enabled;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final background = dark ? const Color(0xFF111113) : const Color(0xFFD600B8);
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: enabled ? onTap : null,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: background,
          foregroundColor: Colors.white,
          disabledBackgroundColor: background.withValues(alpha: 0.35),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Instrument Sans',
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        child: Text(label),
      ),
    );
  }
}

class EventFlowScaffold extends StatelessWidget {
  const EventFlowScaffold({
    super.key,
    required this.body,
    this.bottom,
  });

  final Widget body;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: body,
      bottomNavigationBar: bottom == null
          ? null
          : SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
                child: bottom,
              ),
            ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    this.onTap,
  });

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: const Color(0xFFFDFBF8).withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color.fromRGBO(17, 24, 39, 0.10)),
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          color: const Color(0xFF111827),
          size: 18,
        ),
      ),
    );
  }
}

String formatEventDate(DateTime dateTime) => _formatDate(dateTime);

String formatEventTimeRange(DateTime start, DateTime? end) =>
    _formatTimeRange(start, end);

String _formatDate(DateTime dateTime) {
  const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${weekdays[dateTime.weekday - 1]} ${dateTime.day}${_ordinal(dateTime.day)} ${months[dateTime.month - 1]}';
}

String _formatTimeRange(DateTime start, DateTime? end) {
  String formatTime(DateTime value) {
    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    final suffix = value.hour >= 12 ? 'pm' : 'am';
    return '$hour:$minute$suffix';
  }

  final startText = formatTime(start);
  final endText = end == null ? 'Unavailable' : formatTime(end);
  return '$startText - $endText';
}

String _ordinal(int day) {
  if (day >= 11 && day <= 13) {
    return 'th';
  }
  switch (day % 10) {
    case 1:
      return 'st';
    case 2:
      return 'nd';
    case 3:
      return 'rd';
    default:
      return 'th';
  }
}
