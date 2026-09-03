import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../flutter_flow/custom_icons.dart';
import '../../../flutter_flow/flutter_flow_expanded_image_view.dart';
import '../../../flutter_flow/nav/nav.dart';
import '../../../shared/widgets/wpcc_shimmer.dart';
import '../controllers/event_details_controller.dart';
import '../models/event_flow_models.dart';
import '../widgets/event_flow_widgets.dart';
import 'clock_in_screen.dart';

class EventDetailsScreen extends StatefulWidget {
  const EventDetailsScreen({
    super.key,
    required this.eventId,
  });

  static const String routeName = 'LiveEventDetails';
  static const String routePath = '/events/:eventId';

  final String eventId;

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

enum _EventDetailsTab {
  overview,
  attendance,
}

class _CtaConfig {
  const _CtaConfig({
    required this.label,
    required this.enabled,
  });

  final String label;
  final bool enabled;
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  late final EventDetailsController _controller;
  _EventDetailsTab _selectedTab = _EventDetailsTab.overview;

  @override
  void initState() {
    super.initState();
    _controller = EventDetailsController(eventId: widget.eventId)..load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openMap(EventFlowEvent event) async {
    final uri = event.hasCoordinates
        ? Uri.parse(
            'https://www.google.com/maps/search/?api=1&query=${event.latitude},${event.longitude}',
          )
        : Uri.parse(
            'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(event.locationName)}',
          );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _openImage(String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FlutterFlowExpandedImageView(
          useHeroAnimation: false,
          image: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.contain,
            errorWidget: (context, url, error) => const ColoredBox(
              color: Colors.black,
              child: SizedBox.expand(),
            ),
          ),
        ),
      ),
    );
  }

  _CtaConfig? _ctaConfig(EventDetailsData details) {
    final attendance = details.currentAttendance;
    if (attendance?.isCheckedIn == true) {
      if (!details.event.hasEnded || !details.event.hasCoordinates) {
        return null;
      }
      return const _CtaConfig(label: 'Check out', enabled: true);
    }
    if (!details.event.hasCoordinates) {
      return const _CtaConfig(label: 'Location unavailable', enabled: false);
    }
    if (!details.event.isOpenForCheckIn) {
      return const _CtaConfig(label: 'Check-in closed', enabled: false);
    }
    return const _CtaConfig(label: 'Clock in', enabled: true);
  }

  void _handlePrimary(EventDetailsData details) {
    final cta = _ctaConfig(details);
    if (cta == null || !cta.enabled) {
      return;
    }
    context.pushNamedAuth(
      ClockInScreen.routeName,
      mounted,
      pathParameters: {'eventId': details.event.id},
    );
  }

  List<EventAttendanceWorker> _activeWorkers(EventDetailsData details) {
    final branchId = details.currentUserBranchId?.trim();
    final workers = details.attendanceWorkers.where((worker) {
      if (!worker.isActiveInService) {
        return false;
      }
      if (branchId == null || branchId.isEmpty) {
        return true;
      }
      return worker.branchId == branchId;
    }).toList()
      ..sort((a, b) {
        final aTime = a.checkedInAt;
        final bTime = b.checkedInAt;
        if (aTime == null && bTime == null) {
          return a.fullName.compareTo(b.fullName);
        }
        if (aTime == null) {
          return 1;
        }
        if (bTime == null) {
          return -1;
        }
        return aTime.compareTo(bTime);
      });
    return workers;
  }

  void _openAttendanceList() {
    if (_selectedTab == _EventDetailsTab.attendance) {
      return;
    }
    setState(() => _selectedTab = _EventDetailsTab.attendance);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        if (_controller.isLoading && _controller.data == null) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: SafeArea(
              child: WpccScreenShimmer(includeBottomNavSpace: false),
            ),
          );
        }

        final details = _controller.data;
        if (details == null) {
          return EventFlowScaffold(
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFCFBF9),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: const Color.fromRGBO(17, 24, 39, 0.10),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _controller.errorMessage ?? 'Unable to load event.',
                            style: const TextStyle(
                              fontFamily: 'Instrument Sans',
                              fontSize: 14,
                              color: Color(0xFF111827),
                            ),
                          ),
                          const SizedBox(height: 16),
                          EventCtaButton(
                            label: 'Retry',
                            onTap: _controller.load,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final cta = _ctaConfig(details);
        final activeWorkers = _activeWorkers(details);

        return EventFlowScaffold(
          bottom: cta == null
              ? null
              : EventCtaButton(
                  label: cta.label,
                  enabled: cta.enabled,
                  onTap: () => _handlePrimary(details),
                ),
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: EventHero(
                  imageUrl: details.event.heroImageUrl,
                  onBack: () => Navigator.of(context).maybePop(),
                  onImageTap: details.event.heroImageUrl == null
                      ? null
                      : () => _openImage(details.event.heroImageUrl!),
                ),
              ),
              SliverToBoxAdapter(
                child: Transform.translate(
                  offset: const Offset(0, -10),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(34),
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 112),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _DetailsTabSelector(
                          selectedTab: _selectedTab,
                          onChanged: (tab) => setState(() => _selectedTab = tab),
                        ),
                        const SizedBox(height: 16),
                        if (_selectedTab == _EventDetailsTab.overview)
                          _OverviewTab(
                            details: details,
                            onOpenMap: () => _openMap(details.event),
                            onOpenAttendanceList: _openAttendanceList,
                          )
                        else
                          _AttendanceTab(
                            workers: activeWorkers,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DetailsTabSelector extends StatelessWidget {
  const _DetailsTabSelector({
    required this.selectedTab,
    required this.onChanged,
  });

  final _EventDetailsTab selectedTab;
  final ValueChanged<_EventDetailsTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _DetailsTabButton(
            label: 'Overview',
            icon: FFIcons.klistChecks,
            selected: selectedTab == _EventDetailsTab.overview,
            onTap: () => onChanged(_EventDetailsTab.overview),
          ),
          const SizedBox(width: 10),
          _DetailsTabButton(
            label: 'Attendance',
            icon: FFIcons.kusersThree,
            selected: selectedTab == _EventDetailsTab.attendance,
            onTap: () => onChanged(_EventDetailsTab.attendance),
          ),
        ],
      ),
    );
  }
}

class _DetailsTabButton extends StatelessWidget {
  const _DetailsTabButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 31,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF111113) : const Color(0xFFFDFBF8),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0x24111827)),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: selected ? Colors.white : const Color(0xFF444B57),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Instrument Sans',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : const Color(0xFF444B57),
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({
    required this.details,
    required this.onOpenMap,
    required this.onOpenAttendanceList,
  });

  final EventDetailsData details;
  final VoidCallback onOpenMap;
  final VoidCallback onOpenAttendanceList;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          details.event.title,
          style: const TextStyle(
            fontFamily: 'Instrument Sans',
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2A2018),
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          details.event.description,
          style: const TextStyle(
            fontFamily: 'Instrument Sans',
            fontSize: 13,
            height: 1.4,
            color: Color(0xFF8A8F98),
          ),
        ),
        const SizedBox(height: 20),
        _InfoRow(
          icon: Icons.calendar_today_outlined,
          value: formatEventDate(details.event.startsAt),
        ),
        const SizedBox(height: 12),
        _InfoRow(
          icon: Icons.access_time_rounded,
          value:
              '${formatEventTimeRange(details.event.startsAt, details.event.endsAt)} (GMT+1)',
        ),
        const SizedBox(height: 12),
        _InfoRow(
          icon: Icons.place_outlined,
          value: details.event.locationName,
          actionLabel: 'Find',
          onActionTap: onOpenMap,
        ),
        const SizedBox(height: 18),
        _AttendanceCard(
          details: details,
          onOpenAttendanceList: onOpenAttendanceList,
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(
                color: Color.fromRGBO(17, 24, 39, 0.10),
              ),
              bottom: BorderSide(
                color: Color.fromRGBO(17, 24, 39, 0.10),
              ),
            ),
          ),
          child: Row(
            children: [
              EventAvatar(
                initials: details.host.initials,
                imageUrl: details.host.avatarUrl,
                radius: 999,
                backgroundColor: const Color(0xFFC89357),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            details.host.name,
                            style: const TextStyle(
                              fontFamily: 'Instrument Sans',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2A2018),
                            ),
                          ),
                        ),
                        if (details.host.isVerified) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 17,
                            height: 17,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF9DDF4),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              size: 11,
                              color: Color(0xFFC3139C),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      details.host.role,
                      style: const TextStyle(
                        fontFamily: 'Instrument Sans',
                        fontSize: 11,
                        color: Color(0xFF8A8F98),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const Text(
          'Directions to the event',
          style: TextStyle(
            fontFamily: 'Instrument Sans',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 10),
        EventMapCard(event: details.event),
      ],
    );
  }
}

class _AttendanceTab extends StatelessWidget {
  const _AttendanceTab({
    required this.workers,
  });

  final List<EventAttendanceWorker> workers;

  @override
  Widget build(BuildContext context) {
    if (workers.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFFCFBF9),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: const Color.fromRGBO(17, 24, 39, 0.10)),
        ),
        child: const Text(
          'No workers are currently in service for this branch.',
          style: TextStyle(
            fontFamily: 'Instrument Sans',
            fontSize: 13,
            color: Color(0xFF6B7280),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFBF9),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0x14111827)),
      ),
      child: Column(
        children: List.generate(workers.length, (index) {
          final worker = workers[index];
          return Column(
            children: [
              if (index > 0)
                const Divider(height: 1, color: Color(0x0F111827)),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: _AttendanceWorkerCard(
                  rank: index + 1,
                  worker: worker,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _AttendanceWorkerCard extends StatelessWidget {
  const _AttendanceWorkerCard({
    required this.rank,
    required this.worker,
  });

  final int rank;
  final EventAttendanceWorker worker;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: rank <= 3 ? const Color(0xFFF1EADD) : Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0x14111827)),
          ),
          child: Text(
            '$rank',
            style: const TextStyle(
              fontFamily: 'Instrument Sans',
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: Color(0xFF111827),
            ),
          ),
        ),
        const SizedBox(width: 12),
        EventAvatar(
          initials: worker.initials,
          imageUrl: worker.avatarUrl,
          size: 34,
          radius: 999,
          backgroundColor: const Color(0xFFEADFCF),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                rank == 1 ? '${worker.fullName} 🔥' : worker.fullName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Instrument Sans',
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _attendanceCountLabel(worker),
                style: const TextStyle(
                  fontFamily: 'Instrument Sans',
                  fontSize: 11,
                  color: Color(0xFF8A8F98),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _formatClockIn(worker.checkedInAt),
              style: const TextStyle(
                fontFamily: 'Instrument Sans',
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Time',
              style: TextStyle(
                fontFamily: 'Instrument Sans',
                fontSize: 9,
                fontWeight: FontWeight.w400,
                color: Color(0xFF8A8F98),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _attendanceCountLabel(EventAttendanceWorker worker) {
    if (worker.checkedInAt == null) {
      return 'Attendance recorded';
    }
    return '1 event attended';
  }

  String _formatClockIn(DateTime? value) {
    if (value == null) {
      return '--:--';
    }
    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    final suffix = value.hour >= 12 ? 'pm' : 'am';
    return '$hour:$minute$suffix';
  }
}

class _AttendeePreviewChips extends StatelessWidget {
  const _AttendeePreviewChips({
    required this.attendees,
    required this.attendeeCount,
  });

  final List<EventAttendeePreview> attendees;
  final int attendeeCount;

  @override
  Widget build(BuildContext context) {
    final preview = attendees.take(4).toList(growable: false);
    final remaining = attendeeCount - preview.length;
    const colors = [
      Color(0xFFC89357),
      Color(0xFF20883F),
      Color(0xFF6B3BB5),
      Color(0xFF284A83),
    ];

    return SizedBox(
      height: 30,
      width: 96,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ...List.generate(preview.length, (index) {
            final attendee = preview[index];
            return Positioned(
              left: index * 20,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.2),
                ),
                child: EventAvatar(
                  initials: attendee.initials,
                  imageUrl: attendee.avatarUrl,
                  size: 30,
                  radius: 999,
                  backgroundColor: colors[index % colors.length],
                ),
              ),
            );
          }),
          if (remaining > 0)
            Positioned(
              left: preview.length * 20,
              child: Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                  color: Color(0xFF111113),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '+$remaining',
                  style: const TextStyle(
                    fontFamily: 'Instrument Sans',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AttendanceCard extends StatelessWidget {
  const _AttendanceCard({
    required this.details,
    required this.onOpenAttendanceList,
  });

  final EventDetailsData details;
  final VoidCallback onOpenAttendanceList;

  @override
  Widget build(BuildContext context) {
    final checkedIn = details.currentAttendance?.checkedInAt;
    final checkedOut = details.currentAttendance?.checkedOutAt;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFBF9),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color.fromRGBO(17, 24, 39, 0.10)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatColumn(
              label: 'Check-in Time',
              value: checkedIn == null
                  ? 'Nil'
                  : formatEventTimeRange(checkedIn, checkedIn).split(' - ').first,
            ),
          ),
          const VerticalDivider(
            width: 1,
            thickness: 1,
            color: Color.fromRGBO(17, 24, 39, 0.10),
          ),
          Expanded(
            flex: 2,
            child: InkWell(
              onTap: onOpenAttendanceList,
              borderRadius: BorderRadius.circular(18),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: _AttendeePreviewChips(
                    attendees: details.attendeePreview,
                    attendeeCount: details.attendeeCount,
                  ),
                ),
              ),
            ),
          ),
          const VerticalDivider(
            width: 1,
            thickness: 1,
            color: Color.fromRGBO(17, 24, 39, 0.10),
          ),
          Expanded(
            child: _StatColumn(
              label: 'Check-out Time',
              value: checkedOut == null
                  ? 'Nil'
                  : formatEventTimeRange(checkedOut, checkedOut).split(' - ').first,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Instrument Sans',
            fontSize: 10,
            color: Color(0xFF8A8F98),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Instrument Sans',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2A2018),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.value,
    this.actionLabel,
    this.onActionTap,
  });

  final IconData icon;
  final String value;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF2E2B27)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontFamily: 'Instrument Sans',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF2A2018),
            ),
          ),
        ),
        if (actionLabel != null)
          TextButton.icon(
            onPressed: onActionTap,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF8A8F98),
              minimumSize: Size.zero,
              padding: EdgeInsets.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: const Icon(Icons.place_outlined, size: 18),
            label: Text(
              actionLabel!,
              style: const TextStyle(
                fontFamily: 'Instrument Sans',
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }
}
