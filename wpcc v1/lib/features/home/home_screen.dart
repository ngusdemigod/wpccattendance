import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart' as gf;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../auth/supabase_auth/auth_util.dart';
import '../../app/app_images.dart';
import '../../flutter_flow/custom_icons.dart';
import '../../flutter_flow/nav/nav.dart';
import '../../shared/widgets/gradient_avatar.dart';
import '../../shared/widgets/hamburger_menu_button.dart';
import '../../shared/widgets/app_motion.dart';
import '../events/screens/event_details_screen.dart';
import '../profile/profile_classes_screen.dart';
import '../profile/profile_query_screen.dart';
import '../search/screens/global_search_screen.dart';
import '../linked_flows/linked_flow_screens.dart';
import '../profile_completion/profile_completion_launcher.dart';
import '../profile_completion/profile_completion_service.dart';
import 'home_feed_controller.dart';
import 'home_feed_models.dart';

abstract final class GoogleFonts {
  static TextStyle urbanist({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
  }) =>
      TextStyle(
        fontFamily: 'Urbanist',
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );

  static TextStyle instrumentSans({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
  }) =>
      gf.GoogleFonts.instrumentSans(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );

  static TextStyle instrumentSerif({
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    Color? color,
    double? height,
    double? letterSpacing,
  }) =>
      gf.GoogleFonts.instrumentSerif(
        fontSize: fontSize,
        fontWeight: fontWeight,
        fontStyle: fontStyle,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.onEventsTap,
    this.onDepartmentsTap,
    this.onProfileTap,
  });

  final VoidCallback? onEventsTap;
  final VoidCallback? onDepartmentsTap;
  final VoidCallback? onProfileTap;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

/// New Home presentation. Data continues to come from [HomeFeedController].
class _RedesignedHomeView extends StatefulWidget {
  const _RedesignedHomeView(
      {required this.greeting,
      required this.data,
      required this.displayName,
      required this.avatarInitials,
      required this.onEventTap,
      required this.onDepartmentTap,
      required this.onProfileTap,
      required this.onClassesTap,
      required this.onQueryTap,
      required this.onSoulsTap,
      required this.onCounsellingTap,
      required this.onHeroTap});
  final String greeting, displayName, avatarInitials;
  final HomeFeedData data;
  final VoidCallback onEventTap,
      onDepartmentTap,
      onProfileTap,
      onClassesTap,
      onQueryTap,
      onSoulsTap,
      onCounsellingTap;
  final ValueChanged<HomeEventCard> onHeroTap;
  @override
  State<_RedesignedHomeView> createState() => _RedesignedHomeViewState();
}

class _RedesignedHomeViewState extends State<_RedesignedHomeView> {
  double _drag = 0;
  int _eventIndex = 0;
  static const _bg = Color(0xFFF6F7FA);
  static const _ink = Color(0xFF303239);
  static const _muted = Color(0xFF7E828A);
  Future<void> _external(String url) =>
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

  String get _firstName {
    final names = widget.displayName
        .trim()
        .split(RegExp(r'\s+'))
        .where((name) => name.isNotEmpty);
    return names.isEmpty ? 'Member' : names.first;
  }

  @override
  Widget build(BuildContext context) {
    final events = widget.data.events;
    return ColoredBox(
        color: _bg,
        child: SafeArea(
            bottom: false,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                    child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 48, 10, 4),
                        child: SizedBox(
                            height: 52,
                            child: Row(children: [
                              Container(
                                  width: 36,
                                  height: 36,
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(11),
                                      border: Border.all(
                                          color: const Color(0x0D111111))),
                                  child: Image.asset(AppImages.wpccLogo)),
                              const SizedBox(width: 9),
                              Expanded(
                                  child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                    Text('${widget.greeting} $_firstName',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.instrumentSans(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: _ink)),
                                    const SizedBox(height: 2),
                                    Text('WPCC, His Glory Expression',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.instrumentSans(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            letterSpacing: .5,
                                            color: _muted))
                                  ])),
                              IconButton(
                                  onPressed: () => Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                          builder: (_) =>
                                              const GlobalSearchScreen())),
                                  icon: const Icon(FFIcons.kmagnifyingGlass,
                                      color: _ink, size: 22)),
                            ])))),
                SliverPadding(
                    padding: const EdgeInsets.fromLTRB(13, 0, 13, 118),
                    sliver: SliverList.list(children: [
                      _eventSection(events),
                      const SizedBox(height: 15),
                      _modules(),
                      const SizedBox(height: 15),
                      _announcements(),
                    ])),
              ],
            )));
  }

  Widget _eventSection(List<HomeEventCard> events) {
    if (events.isEmpty) {
      return Container(
        height: 116,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .82),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0x0D0F172A)),
        ),
        child: Text(
          'No upcoming events',
          style: GoogleFonts.instrumentSans(fontSize: 13, color: _muted),
        ),
      );
    }
    return Container(
      height: 285,
      padding: const EdgeInsets.fromLTRB(10, 16, 10, 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(left: 12, bottom: 12),
          child: Text('Swipe to browse ↔',
              style: GoogleFonts.instrumentSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: .5,
                  color: _muted)),
        ),
        SizedBox(height: 210, child: _eventDeck(events)),
      ]),
    );
  }

  Widget _eventDeck(List<HomeEventCard> events) {
    final frontIndex = _eventIndex % events.length;
    final front = events[frontIndex];
    final second = events[(frontIndex + 1) % events.length];
    final third = events[(frontIndex + 2) % events.length];
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        if (events.length > 2)
          Positioned(
            top: 14,
            left: 15,
            right: 15,
            bottom: -8,
            child: _eventCard(third, dimmed: true),
          ),
        if (events.length > 1)
          Positioned(
            top: 7,
            left: 8,
            right: 8,
            bottom: -3,
            child: _eventCard(second, dimmed: true),
          ),
        Positioned.fill(
          child: GestureDetector(
            onTap: () => widget.onHeroTap(front),
            onHorizontalDragUpdate: (details) =>
                setState(() => _drag += details.delta.dx),
            onHorizontalDragEnd: (_) => setState(() {
              if (_drag.abs() >= 76) {
                _eventIndex = (_eventIndex + 1) % events.length;
              }
              _drag = 0;
            }),
            child: AnimatedContainer(
              duration: _drag == 0
                  ? const Duration(milliseconds: 340)
                  : Duration.zero,
              curve: Curves.easeOutCubic,
              transform: Matrix4.identity()
                ..translateByDouble(_drag, -_drag.abs() * .025, 0, 1)
                ..rotateZ(_drag * .00052),
              child: _eventCard(front),
            ),
          ),
        ),
      ],
    );
  }

  Widget _eventCard(HomeEventCard event, {bool dimmed = false}) {
    return Opacity(
      opacity: dimmed ? .72 : 1,
      child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(fit: StackFit.expand, children: [
              if (event.imageUrl?.trim().isNotEmpty == true)
                CachedNetworkImage(
                    imageUrl: event.imageUrl!.trim(),
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => _eventFallback(event))
              else
                _eventFallback(event),
              const DecoratedBox(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                    Color(0x0014161A),
                    Color(0x1A14161A),
                    Color(0x6614161A)
                  ]))),
              Padding(
                  padding: const EdgeInsets.fromLTRB(18, 15, 14, 16),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Expanded(
                              child: Text(event.eyebrow.toUpperCase(),
                                  style: GoogleFonts.instrumentSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white70))),
                          Container(
                              width: 30,
                              height: 30,
                              decoration: const BoxDecoration(
                                  color: Colors.white, shape: BoxShape.circle),
                              child: const Icon(FFIcons.karrowUpRight,
                                  color: _ink, size: 15))
                        ]),
                        const Spacer(),
                        Text(event.title.toUpperCase(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.instrumentSans(
                                fontSize: 23,
                                height: .94,
                                fontWeight: FontWeight.w600,
                                color: Colors.white)),
                        const SizedBox(height: 12),
                        Text(
                            '${event.dateText}   ${event.timeText}${event.location?.trim().isNotEmpty == true ? '   ${event.location}' : ''}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.instrumentSans(
                                fontSize: 12,
                                letterSpacing: .3,
                                color: Colors.white70)),
                      ])),
            ]),
          ),
    );
  }

  Widget _eventFallback(HomeEventCard _) =>
      Image.asset('assets/images/images.jpg', fit: BoxFit.cover);

  Widget _modules() {
    final modules = [
      (FFIcons.kcalendarCheck, 'Events', widget.onEventTap),
      (FFIcons.kusersThree, 'Department', widget.onDepartmentTap),
      (FFIcons.kuserPlus, 'My souls', widget.onSoulsTap),
      (FFIcons.kgraduationCap, 'Classes', widget.onClassesTap),
      (FFIcons.kchatsCircle, 'Counselling', widget.onCounsellingTap),
      (FFIcons.kwarningCircle, 'Query', widget.onQueryTap),
      (
        FFIcons.kstar,
        'Leave review',
        () => _external(
            'https://www.google.com/search?q=wisdom+power+christian+centre')
      ),
      (
        FFIcons.kglobeHemisphereWest,
        'Website',
        () => _external('https://www.wisdompowercc.org')
      )
    ];
    return GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: modules.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  childAspectRatio: 1,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8),
              itemBuilder: (_, i) {
                final item = modules[i];
                return Material(
                    color: Colors.white.withValues(alpha: .58),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(19),
                        side: const BorderSide(color: Color(0x0D0F172A))),
                    child: InkWell(
                        onTap: item.$3,
                        borderRadius: BorderRadius.circular(19),
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(item.$1, size: 23, color: _ink),
                              const SizedBox(height: 7),
                              Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 5),
                                  child: Text(item.$2,
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      softWrap: true,
                                      overflow: TextOverflow.fade,
                                      style: GoogleFonts.instrumentSans(
                                          fontSize:
                                              item.$2.length > 10 ? 10 : 11,
                                          height: 1.15,
                                          fontWeight: FontWeight.w600,
                                          color: _ink)))
                            ])));
              });
  }

  Widget _announcements() {
    return Container(
        padding: const EdgeInsets.fromLTRB(11, 13, 11, 11),
        decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .30),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: const Color(0x110F172A))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(children: [
                Text('Announcements',
                    style: GoogleFonts.instrumentSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _ink)),
                const Spacer(),
                Text('View all  ›',
                    style: GoogleFonts.instrumentSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: .4,
                        color: _muted))
              ])),
          const SizedBox(height: 10),
          ...widget.data.announcements.map((a) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _announcementCard(a),
              )),
          if (widget.data.announcements.isEmpty)
            Text('No announcements yet',
                style: GoogleFonts.instrumentSans(fontSize: 13, color: _muted)),
        ]));
  }

  Widget _announcementCard(HomeAnnouncement announcement) {
    final image = announcement.images.isEmpty
        ? Image.asset(AppImages.wpccLogo, fit: BoxFit.cover)
        : CachedNetworkImage(
            imageUrl: announcement.images.first.url,
            fit: BoxFit.cover,
            errorWidget: (_, __, ___) =>
                Image.asset(AppImages.wpccLogo, fit: BoxFit.cover),
          );
    return Container(
      constraints: const BoxConstraints(minHeight: 124),
      padding: const EdgeInsets.fromLTRB(13, 11, 12, 11),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .68),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(width: 34, height: 34, child: image),
        ),
        const SizedBox(width: 10),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(announcement.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.instrumentSans(
                    fontSize: 13, fontWeight: FontWeight.w600, color: _ink)),
            Text(announcement.sourceName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.instrumentSans(fontSize: 12, color: _muted)),
            const SizedBox(height: 8),
            Text(announcement.body,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.instrumentSans(
                    fontSize: 12, height: 1.35, color: _muted)),
            const SizedBox(height: 7),
            Text(announcement.metadataText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.instrumentSans(
                    fontSize: 12, letterSpacing: .3, color: _muted)),
          ]),
        ),
        const SizedBox(width: 5),
        const Icon(FFIcons.kdotsThree, size: 18, color: _muted),
      ]),
    );
  }
}

class _HomeScreenState extends State<HomeScreen> {
  late final HomeFeedController _controller;
  bool _profilePromptHandled = false;

  @override
  void initState() {
    super.initState();
    _controller = HomeFeedController()..hydrate();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _maybePromptProfileCompletion(),
    );
  }

  Future<void> _maybePromptProfileCompletion() async {
    if (_profilePromptHandled || !mounted) return;
    var status = AppStateNotifier.instance.profileCompletionStatus;
    if (status == ProfileCompletionStatus.unknown) {
      status = await ProfileCompletionService()
          .fetchStatus()
          .onError((_, __) => ProfileCompletionStatus.complete);
    }
    if (!mounted || _profilePromptHandled) return;
    if (status == ProfileCompletionStatus.incomplete) {
      _profilePromptHandled = true;
      await openProfileCompletionFlow(context);
    }
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2);
    final value = parts.map((part) => part[0].toUpperCase()).join();
    return value.isEmpty ? 'WP' : value;
  }

  String _capitalizeWords(String value) {
    return value
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .map(
          (word) => word.length == 1
              ? word.toUpperCase()
              : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  void _open(Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final fallbackName = currentUserDisplayName.trim().isNotEmpty &&
                !currentUserDisplayName.contains('@')
            ? currentUserDisplayName.trim()
            : 'Member';
        final data = _controller.data ??
            HomeFeedData(
              displayName: fallbackName.split(RegExp(r'\s+')).first,
              fullName: fallbackName,
              avatarInitials: _initials(fallbackName),
              queryCount: 0,
              events: const [],
              announcements: const [],
              upcomingEvents: const [],
              connectPeople: const [],
            );
        final profileName = data.fullName.trim().isNotEmpty
            ? data.fullName
            : fallbackName;
        final capitalizedProfileName = _capitalizeWords(profileName);

        return _RedesignedHomeView(
          greeting: _greeting,
          data: data,
          displayName: capitalizedProfileName,
          avatarInitials: _initials(capitalizedProfileName),
          onEventTap: widget.onEventsTap ?? () {},
          onDepartmentTap: widget.onDepartmentsTap ?? () {},
          onProfileTap: widget.onProfileTap ?? () {},
          onClassesTap: () => _open(const ProfileClassesScreen()),
          onQueryTap: () => _open(const ProfileQueryScreen()),
          onSoulsTap: () => _open(const SoulsScreen()),
          onCounsellingTap: () => _open(const CounsellingScreen()),
          onHeroTap: (event) => context.pushNamedAuth(
                    EventDetailsScreen.routeName,
                    mounted,
                    pathParameters: {'eventId': event.id},
                  ),
        );
      },
    );
  }
}

// Legacy presentation retained temporarily for generated-route compatibility.
// ignore: unused_element
class _HomeView extends StatelessWidget {
  const _HomeView({
    required this.greeting,
    required this.data,
    required this.displayName,
    required this.avatarInitials,
    required this.onEventTap,
    required this.onDepartmentTap,
    required this.onProfileTap,
    required this.onClassesTap,
    required this.onQueryTap,
    required this.onSoulsTap,
    required this.onCounsellingTap,
    required this.onHeroTap,
  });

  final String greeting;
  final HomeFeedData data;
  final String displayName;
  final String avatarInitials;
  final VoidCallback onEventTap;
  final VoidCallback onDepartmentTap;
  final VoidCallback onProfileTap;
  final VoidCallback onClassesTap;
  final VoidCallback onQueryTap;
  final VoidCallback onSoulsTap;
  final VoidCallback onCounsellingTap;
  final VoidCallback onHeroTap;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(17, 7, 17, 28),
              sliver: SliverList.list(
                children: [
                  EntranceMotion(
                    child: _Header(
                      greeting: greeting,
                      name: displayName,
                      initials: avatarInitials,
                      onProfileTap: onProfileTap,
                    ),
                  ),
                  const SizedBox(height: 20),
                  EntranceMotion(
                    delay: const Duration(milliseconds: 45),
                    child: data.heroEvent != null
                        ? _ServiceHero(
                            event: data.heroEvent!,
                            onTap: onHeroTap,
                          )
                        : const _NoOngoingEventCard(),
                  ),
                  const SizedBox(height: 25),
                  const EntranceMotion(
                    delay: Duration(milliseconds: 90),
                    child: _ToolsHeading(),
                  ),
                  const SizedBox(height: 14),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 13,
                    childAspectRatio: 1.22,
                    children: [
                      EntranceMotion(
                        delay: const Duration(milliseconds: 120),
                        child: _ToolCard(
                          icon: FFIcons.kcalendarCheck,
                          title: 'Events',
                          help: 'Schedules, attendance and\nclock-in',
                          iconColor: const Color(0xFF7C5609),
                          iconBackground: const Color(0xFFF4E2AF),
                          onTap: onEventTap,
                        ),
                      ),
                      EntranceMotion(
                        delay: const Duration(milliseconds: 150),
                        child: _ToolCard(
                          icon: FFIcons.kusersThree,
                          title: 'Department',
                          help: 'Team updates, duties and\nleaders',
                          iconColor: const Color(0xFFD600B8),
                          iconBackground: const Color(0xFFF9DDF4),
                          onTap: onDepartmentTap,
                        ),
                      ),
                      EntranceMotion(
                        delay: const Duration(milliseconds: 180),
                        child: _ToolCard(
                          icon: FFIcons.kuserPlus,
                          title: 'Souls',
                          help: 'New converts and follow-up\nrecords',
                          iconColor: const Color(0xFF1A6B35),
                          iconBackground: const Color(0xFFE3F5E9),
                          onTap: onSoulsTap,
                        ),
                      ),
                      EntranceMotion(
                        delay: const Duration(milliseconds: 210),
                        child: _ToolCard(
                          icon: FFIcons.kgraduationCap,
                          title: 'Classes',
                          help: 'Training modules and\ncertificates',
                          iconColor: const Color(0xFF1A4F82),
                          iconBackground: const Color(0xFFE4F0FB),
                          onTap: onClassesTap,
                        ),
                      ),
                      EntranceMotion(
                        delay: const Duration(milliseconds: 240),
                        child: _ToolCard(
                          icon: FFIcons.kchatsCircle,
                          title: 'Counselling',
                          help: 'Care sessions and worker\nsupport',
                          iconColor: const Color(0xFF5B4A86),
                          iconBackground: const Color(0xFFEDE8F8),
                          onTap: onCounsellingTap,
                        ),
                      ),
                      EntranceMotion(
                        delay: const Duration(milliseconds: 270),
                        child: _ToolCard(
                          icon: FFIcons.kquestion,
                          title: 'Query',
                          help: 'Reports requiring your\nresponse',
                          iconColor: const Color(0xFF5E6470),
                          iconBackground: const Color(0xFFECEEF1),
                          badge: data.queryCount.toString(),
                          onTap: onQueryTap,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.greeting,
    required this.name,
    required this.initials,
    required this.onProfileTap,
  });

  final String greeting;
  final String name;
  final String initials;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const HamburgerMenuButton(),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: GoogleFonts.instrumentSans(
                  fontSize: 14,
                  height: 1,
                  color: const Color(0xFF7B818B),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.instrumentSerif(
                  fontSize: 28,
                  height: .9,
                  color: const Color(0xFF111827),
                ),
              ),
            ],
          ),
        ),
        InkWell(
          customBorder: const CircleBorder(),
          onTap: onProfileTap,
          child: GradientAvatar(
            initials: initials,
            colors: const [Color(0xFFB88A5A), Color(0xFFB88A5A)],
            radius: 21,
          ),
        ),
      ],
    );
  }
}

class _ServiceHero extends StatelessWidget {
  const _ServiceHero({required this.event, required this.onTap});

  final HomeEventCard event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 213,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(36),
        border: Border.all(color: const Color(0x1A111827)),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF6DFA5), Color(0xFFF0C978)],
        ),
      ),
      child: Stack(
        children: [
          const Positioned(
            top: 56,
            left: -42,
            child: _DiagonalLine(width: 390),
          ),
          const Positioned(
            right: -48,
            bottom: 32,
            child: _DiagonalLine(width: 265),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(25, 25, 18, 19),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .78),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        FFIcons.kcircleFill,
                        size: 8,
                        color: Color(0xFF1A6B35),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        event.isOngoing ? 'Ongoing service' : 'Upcoming event',
                        style: GoogleFonts.instrumentSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF5A3A20),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  event.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.instrumentSerif(
                    fontSize: 35,
                    height: .96,
                    letterSpacing: -1.2,
                    color: const Color(0xFF352314),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _Meta(icon: FFIcons.kclock, text: event.timeText),
                    const SizedBox(width: 18),
                    Expanded(
                      child: _Meta(
                        icon: FFIcons.kmapPin,
                        text: event.location ?? '',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            right: 20,
            bottom: 19,
            child: FilledButton.icon(
              onPressed: onTap,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF111113),
                foregroundColor: Colors.white,
                minimumSize: const Size(117, 49),
                padding: const EdgeInsets.symmetric(horizontal: 18),
                shape: const StadiumBorder(),
              ),
              icon: const Icon(FFIcons.ksignIn, size: 17),
              label: Text(
                'Clock in',
                style: GoogleFonts.instrumentSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoOngoingEventCard extends StatelessWidget {
  const _NoOngoingEventCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 213,
      decoration: BoxDecoration(
        color: const Color(0xFFFCFBF9),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0x1C111827)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 55,
              height: 55,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFECEEF1),
              ),
              child: const Icon(
                FFIcons.kcalendarSlash,
                size: 27,
                color: Color(0xFF7B818B),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'No ongoing event',
              style: GoogleFonts.instrumentSans(
                fontSize: 12,
                color: const Color(0xFF7B818B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiagonalLine extends StatelessWidget {
  const _DiagonalLine({required this.width});
  final double width;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -.35,
      child: Container(
        width: width,
        height: 6,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .72),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: const Color(0xFF725536)),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.instrumentSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF63482D),
            ),
          ),
        ),
      ],
    );
  }
}

class _ToolsHeading extends StatelessWidget {
  const _ToolsHeading();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Workers module',
                style: GoogleFonts.instrumentSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Prioritised for your service responsibilities',
                style: GoogleFonts.instrumentSans(
                  fontSize: 12,
                  color: const Color(0xFF7B818B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ToolCard extends StatelessWidget {
  const _ToolCard({
    required this.icon,
    required this.title,
    required this.help,
    required this.iconColor,
    required this.iconBackground,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final String title;
  final String help;
  final Color iconColor;
  final Color iconBackground;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFCFBF9),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
        side: BorderSide(color: const Color(0xFF111827).withValues(alpha: .11)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: onTap,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(17, 17, 13, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 55,
                    height: 55,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: iconBackground,
                    ),
                    child: Icon(icon, size: 27, color: iconColor),
                  ),
                  const Spacer(),
                  Text(
                    title,
                    style: GoogleFonts.instrumentSans(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: EdgeInsets.only(right: badge == null ? 0 : 38),
                    child: Text(
                      help,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.instrumentSans(
                        fontSize: 12,
                        height: 1.28,
                        color: const Color(0xFF7B818B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Positioned(
              top: 18,
              right: 18,
              child: Icon(
                FFIcons.karrowUpRight,
                size: 19,
                color: Color(0xFF9AA0A9),
              ),
            ),
            if (badge != null)
              Positioned(
                right: 16,
                bottom: 16,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 27),
                  height: 27,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 7),
                  decoration: const BoxDecoration(
                    color: Color(0xFF111113),
                    borderRadius: BorderRadius.all(Radius.circular(999)),
                  ),
                  child: Text(
                    badge!,
                    style: GoogleFonts.instrumentSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
