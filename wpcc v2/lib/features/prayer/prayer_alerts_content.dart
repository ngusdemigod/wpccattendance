import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/theme/app_motion.dart';
import '../../core/theme/member_theme.dart';
import '../../core/widgets/member_components.dart';
import '../../core/widgets/member_reveal.dart';
import '../../core/widgets/member_shimmer.dart';
import '../../core/widgets/member_sheet.dart';
import 'prayer_schedule.dart';

/// Native alarm-style presentation, independent of calendar and Web Push
/// services. Existing controller and repository callbacks own every operation.
///
/// Order: summary of what rings next, the quiet reminders banner, the
/// church-wide (global) card only when one exists, other church alerts, then
/// the member's own alerts. The "New alert" pill floats above the dock.
class PrayerAlertsContent extends StatefulWidget {
  const PrayerAlertsContent({
    super.key,
    required this.alerts,
    required this.onRefresh,
    required this.onTap,
    required this.onStart,
    required this.onCalendar,
    required this.onToggle,
    this.updating = const {},
    this.starting = const {},
    this.error,
    this.onEnablePush,
    this.enablingPush = false,
    this.onAdd,
    this.onBack,
    this.loading = false,
    this.now,
  });
  final List<Map<String, dynamic>> alerts;
  final Future<void> Function() onRefresh;
  final ValueChanged<Map<String, dynamic>> onTap, onStart, onCalendar;
  final void Function(Map<String, dynamic>, bool) onToggle;
  final Set<String> updating, starting;
  final String? error;
  final VoidCallback? onEnablePush, onAdd, onBack;
  final bool enablingPush, loading;

  /// Fixed clock for tests. Without it the device time is used and refreshed
  /// every 30 seconds.
  final DateTime? now;

  @override
  State<PrayerAlertsContent> createState() => _PrayerAlertsContentState();
}

class _PrayerAlertsContentState extends State<PrayerAlertsContent> {
  Timer? tick;
  late DateTime clock = widget.now ?? DateTime.now();
  bool bannerDismissed = false;

  @override
  void initState() {
    super.initState();
    if (widget.now == null) {
      tick = Timer.periodic(const Duration(seconds: 30), (_) {
        if (mounted) setState(() => clock = DateTime.now());
      });
    }
  }

  @override
  void dispose() {
    tick?.cancel();
    super.dispose();
  }

  List<Map<String, dynamic>> get alerts => widget.alerts;

  /// Space under the list so the last row clears the pill and the dock.
  static double dockClearance(BuildContext context) =>
      MediaQuery.paddingOf(context).bottom +
      (MediaQuery.sizeOf(context).width >= 600 ? 24 : 22) +
      60 +
      14;

  @override
  Widget build(BuildContext context) {
    final now = widget.now ?? clock;
    final width = MediaQuery.sizeOf(context).width;
    final text = Theme.of(context).textTheme;
    final personal =
        alerts.where((alert) => alert['scope'] == 'personal').toList();
    final church =
        alerts.where((alert) => alert['scope'] != 'personal').toList();
    final globals =
        church.where((alert) => alert['scope'] == 'global').toList();
    // The featured card exists only when a church-wide alert does.
    final featured = PrayerSchedule.featured(globals, now);
    final others = [
      for (final alert in church)
        if (!identical(alert, featured)) alert,
    ];
    final showEmpty = !widget.loading && widget.error == null && alerts.isEmpty;
    final showPill = !widget.loading &&
        widget.error == null &&
        alerts.isNotEmpty &&
        widget.onAdd != null;
    final pillClearance = dockClearance(context);
    var index = 0;

    final children = <Widget>[
      _Header(onBack: widget.onBack),
      if (widget.loading)
        const _Skeleton()
      else if (widget.error != null)
        MemberStatus(
            message: widget.error!,
            icon: PhosphorIconsRegular.warningCircle,
            onRetry: widget.onRefresh)
      else if (showEmpty)
        MemberReveal(child: _EmptyState(onAdd: widget.onAdd))
      else ...[
        MemberReveal(
            index: index++,
            child:
                _NextSummary(next: PrayerSchedule.next(alerts, now), now: now)),
        const SizedBox(height: 20),
        MemberSwap(
            child: widget.onEnablePush == null || bannerDismissed
                ? const SizedBox.shrink(key: ValueKey('no-banner'))
                : Padding(
                    key: const ValueKey('banner'),
                    padding: const EdgeInsets.only(bottom: 20),
                    child: _ReminderBanner(
                        busy: widget.enablingPush,
                        onEnable: widget.onEnablePush!,
                        onDismiss: () =>
                            setState(() => bannerDismissed = true)))),
        if (featured != null) ...[
          MemberReveal(
              index: index++,
              child: PrayerFeaturedCard(
                  key: ValueKey('featured-${featured['id']}'),
                  alert: featured,
                  busy: widget.starting.contains(featured['id']?.toString()),
                  onTap: () => widget.onTap(featured),
                  onStart: () => widget.onStart(featured),
                  onCalendar: () => widget.onCalendar(featured))),
          const SizedBox(height: 28),
        ],
        if (others.isNotEmpty) ...[
          const MemberSectionHeader(title: 'From your church'),
          for (final alert in others)
            _rowGap(MemberReveal(
                index: index++,
                child: PrayerAlertRow(
                    key: ValueKey('alert-${alert['id']}'),
                    alert: alert,
                    readOnly: true,
                    onChanged: null,
                    onTap: () => widget.onTap(alert),
                    onStart: widget.starting.contains(alert['id']?.toString())
                        ? null
                        : () => widget.onStart(alert),
                    onCalendar: () => widget.onCalendar(alert)))),
          const SizedBox(height: 20),
        ],
        const MemberSectionHeader(title: 'My alerts'),
        if (personal.isEmpty)
          Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                  'You have no alerts of your own yet. Tap New alert to add one.',
                  style: text.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant)))
        else
          for (final alert in personal)
            _rowGap(MemberReveal(
                index: index++,
                child: PrayerAlertRow(
                    key: ValueKey('alert-${alert['id']}'),
                    alert: alert,
                    readOnly: false,
                    onChanged: widget.updating.contains(alert['id']?.toString())
                        ? null
                        : (value) => widget.onToggle(alert, value),
                    onTap: () => widget.onTap(alert),
                    onStart: widget.starting.contains(alert['id']?.toString())
                        ? null
                        : () => widget.onStart(alert),
                    onCalendar: () => widget.onCalendar(alert)))),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 0, children: [
          TextButton.icon(
              onPressed: alerts.every(
                      (a) => widget.starting.contains(a['id']?.toString()))
                  ? null
                  : () => _choose(
                      context, 'Start prayer', widget.onStart, widget.starting),
              icon: const Icon(PhosphorIconsRegular.play, size: 18),
              label: const Text('Start prayer')),
          TextButton.icon(
              onPressed: () =>
                  _choose(context, 'Calendar', widget.onCalendar, const {}),
              icon: const Icon(PhosphorIconsRegular.calendarBlank, size: 18),
              label: const Text('Add to calendar')),
        ]),
      ],
    ];

    return Stack(children: [
      RefreshIndicator(
        onRefresh: widget.onRefresh,
        child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
                constraints:
                    BoxConstraints(maxWidth: width >= 900 ? 820 : 1180),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: memberPagePadding(context,
                      bottom: showPill ? pillClearance + 52 + 24 : 124),
                  children: [
                    Align(
                        alignment: Alignment.topLeft,
                        child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 680),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: children))),
                  ],
                ))),
      ),
      Positioned(
          left: 0,
          right: 0,
          bottom: pillClearance,
          child: Center(
              child: MemberSwap(
                  animateSize: false,
                  alignment: Alignment.bottomCenter,
                  child: showPill
                      ? _NewAlertPill(
                          key: const ValueKey('new-alert'),
                          onPressed: widget.onAdd!)
                      : const SizedBox.shrink(key: ValueKey('no-pill'))))),
    ]);
  }

  Widget _rowGap(Widget child) =>
      Padding(padding: const EdgeInsets.only(bottom: 10), child: child);

  Future<void> _choose(BuildContext context, String title,
      ValueChanged<Map<String, dynamic>> action, Set<String> busy) async {
    if (alerts.length == 1) {
      if (!busy.contains(alerts.first['id']?.toString())) action(alerts.first);
      return;
    }
    final selected = await showMemberSheet<Map<String, dynamic>>(
      context: context,
      title: title,
      builder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final alert in alerts)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: MemberListRow(
                  title: alert['title']?.toString() ?? 'Prayer',
                  subtitle:
                      '${PrayerAlertRow.time(alert)} · ${PrayerAlertRow.schedule(alert)}',
                  leading: Icon(PhosphorIconsRegular.bellSimple,
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                  trailing: busy.contains(alert['id']?.toString())
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(PhosphorIconsRegular.caretRight, size: 16),
                  onTap: busy.contains(alert['id']?.toString())
                      ? null
                      : () => Navigator.pop(sheetContext, alert)),
            ),
        ],
      ),
    );
    if (selected != null && context.mounted) action(selected);
  }
}

/// Large page title on the same row as the route's sticky Back button. Under
/// a MemberBackHost the Back control renders as an empty 48px square, so the
/// title clears it and nothing else sits in the top-left corner.
class _Header extends StatelessWidget {
  const _Header({this.onBack});
  final VoidCallback? onBack;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Row(children: [
          if (onBack != null) ...[
            MemberIconButton(
                icon: PhosphorIconsRegular.caretLeft,
                label: 'Back',
                onPressed: onBack),
            const SizedBox(width: 10),
          ],
          Expanded(
              child: Semantics(
                  header: true,
                  child: Text('Prayer alerts',
                      style: Theme.of(context).textTheme.headlineSmall))),
        ]),
      );
}

TextScaler _numeralScaler(BuildContext context, double size) {
  final scaler = MediaQuery.textScalerOf(context);
  return scaler.scale(size) / size > 1.3
      ? const TextScaler.linear(1.3)
      : scaler;
}

/// A clock time as large tabular numerals with a smaller am/pm. It follows
/// the device's 12 or 24 hour setting and shrinks to fit rather than wrap.
class PrayerTimeText extends StatelessWidget {
  const PrayerTimeText({
    super.key,
    required this.hour,
    required this.minute,
    this.size = 30,
    this.color,
    this.weight = FontWeight.w500,
  });
  final int hour, minute;
  final double size;
  final Color? color;
  final FontWeight weight;

  @override
  Widget build(BuildContext context) {
    final parts = PrayerSchedule.timeParts(hour, minute,
        use24: MediaQuery.alwaysUse24HourFormatOf(context));
    final style = Theme.of(context).textTheme.headlineMedium?.copyWith(
        fontSize: size,
        height: 1.1,
        fontWeight: weight,
        color: color,
        letterSpacing: 0,
        fontFeatures: const [FontFeature.tabularFigures()]);
    return FittedBox(
        fit: BoxFit.scaleDown,
        alignment: AlignmentDirectional.centerStart,
        child: Text.rich(
            TextSpan(text: parts.digits, style: style, children: [
              if (parts.suffix != null)
                TextSpan(
                    text: ' ${parts.suffix}',
                    style: style?.copyWith(
                        fontSize: math.max(12, size * .4),
                        fontWeight: FontWeight.w500)),
            ]),
            maxLines: 1,
            softWrap: false,
            textScaler: _numeralScaler(context, size)));
  }
}

class _NextSummary extends StatelessWidget {
  const _NextSummary({required this.next, required this.now});
  final PrayerNextAlert? next;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final upcoming = next;
    final time =
        upcoming == null ? null : PrayerSchedule.parseTime(upcoming.alert);
    if (upcoming == null || time == null) {
      return Semantics(
          container: true,
          label: 'No active alerts',
          child: ExcludeSemantics(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('Next alert',
                    style: text.labelMedium
                        ?.copyWith(color: colors.onSurfaceVariant)),
                const SizedBox(height: 6),
                Text('No active alerts', style: text.headlineSmall),
                const SizedBox(height: 4),
                Text('Switch an alert on to see when it rings next.',
                    style: text.bodyMedium
                        ?.copyWith(color: colors.onSurfaceVariant)),
              ])));
    }
    final use24 = MediaQuery.alwaysUse24HourFormatOf(context);
    final countdown = PrayerSchedule.countdown(upcoming);
    final title = upcoming.alert['title']?.toString() ?? 'Prayer';
    return Semantics(
        container: true,
        label:
            'Next alert, ${PrayerSchedule.timeText(time.hour, time.minute, use24: use24)}, $countdown, $title',
        child: ExcludeSemantics(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Next alert',
              style:
                  text.labelMedium?.copyWith(color: colors.onSurfaceVariant)),
          const SizedBox(height: 4),
          PrayerTimeText(hour: time.hour, minute: time.minute, size: 56),
          const SizedBox(height: 6),
          Text(countdown, style: text.titleLarge),
          const SizedBox(height: 2),
          Text(title,
              style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant)),
        ])));
  }
}

class _ReminderBanner extends StatelessWidget {
  const _ReminderBanner(
      {required this.busy, required this.onEnable, required this.onDismiss});
  final bool busy;
  final VoidCallback onEnable, onDismiss;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final scale = MediaQuery.textScalerOf(context).scale(12) / 12;
    final copy =
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Turn on reminders', style: text.titleMedium),
      const SizedBox(height: 2),
      Text('Get a notification when it is time to pray.',
          style: text.bodySmall),
    ]);
    final enable = TextButton(
        onPressed: busy ? null : onEnable,
        child: busy
            ? const SizedBox.square(
                dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
            : const Text('Turn on'));
    final dismiss = IconButton(
        tooltip: 'Dismiss reminders banner',
        onPressed: onDismiss,
        icon: const Icon(PhosphorIconsRegular.x, size: 18));
    return DecoratedBox(
        decoration: BoxDecoration(
            color: colors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(20)),
        child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
            child: LayoutBuilder(builder: (context, box) {
              final stacked = scale > 1.3 || box.maxWidth < 330;
              final icon = Icon(PhosphorIconsRegular.bellRinging,
                  size: 22, color: colors.onSurfaceVariant);
              if (stacked) {
                return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        icon,
                        const SizedBox(width: 12),
                        Expanded(child: copy),
                        dismiss,
                      ]),
                      Align(alignment: Alignment.centerLeft, child: enable),
                    ]);
              }
              return Row(children: [
                icon,
                const SizedBox(width: 12),
                Expanded(child: copy),
                enable,
                dismiss,
              ]);
            })));
  }
}

class _NewAlertPill extends StatelessWidget {
  const _NewAlertPill({super.key, required this.onPressed});
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => AppPressMotion(
      child: DecoratedBox(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 24,
                    offset: Offset(0, 8))
              ]),
          child: FilledButton.icon(
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                  minimumSize: const Size(48, 52),
                  padding: const EdgeInsets.symmetric(horizontal: 22)),
              icon: const Icon(PhosphorIconsBold.plus, size: 18),
              label: const Text('New alert'))));
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({this.onAdd});
  final VoidCallback? onAdd;
  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(children: [
          DecoratedBox(
              decoration: BoxDecoration(
                  color: colors.surfaceContainerLow, shape: BoxShape.circle),
              child: SizedBox.square(
                  dimension: 72,
                  child: Icon(PhosphorIconsRegular.alarm,
                      size: 32, color: colors.onSurfaceVariant))),
          const SizedBox(height: 20),
          Text('No alerts yet',
              textAlign: TextAlign.center, style: text.headlineSmall),
          const SizedBox(height: 6),
          Text('Choose a time to pray and it will show up here.',
              textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant)),
          const SizedBox(height: 24),
          FilledButton.icon(
              onPressed: onAdd,
              style: FilledButton.styleFrom(minimumSize: const Size(48, 52)),
              icon: const Icon(PhosphorIconsBold.plus, size: 18),
              label: const Text('Add your first alert')),
        ]));
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();
  @override
  Widget build(BuildContext context) => const MemberShimmer(
      label: 'Loading prayer alerts',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        MemberBone(width: 80, height: 12),
        SizedBox(height: 12),
        MemberBone(width: 190, height: 52, radius: 12),
        SizedBox(height: 12),
        MemberBone(width: 130, height: 16),
        SizedBox(height: 28),
        MemberBone(height: 104, radius: 20),
        SizedBox(height: 10),
        MemberBone(height: 104, radius: 20),
        SizedBox(height: 10),
        MemberBone(height: 104, radius: 20),
      ]));
}

/// The church-wide alert: one prominent card with a clear primary action.
class PrayerFeaturedCard extends StatelessWidget {
  const PrayerFeaturedCard({
    super.key,
    required this.alert,
    required this.busy,
    required this.onTap,
    required this.onStart,
    required this.onCalendar,
  });
  final Map<String, dynamic> alert;
  final bool busy;
  final VoidCallback onTap, onStart, onCalendar;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final time = PrayerSchedule.parseTime(alert);
    final title = alert['title']?.toString() ?? 'Prayer';
    final active = PrayerSchedule.isActive(alert);
    final use24 = MediaQuery.alwaysUse24HourFormatOf(context);
    final meta = PrayerAlertRow.schedule(alert, includeAudio: false);
    final spoken = [
      'Church prayer alert',
      if (time != null)
        PrayerSchedule.timeText(time.hour, time.minute, use24: use24),
      title,
      PrayerSchedule.daysLabel(PrayerSchedule.days(alert), long: true),
      active ? 'on' : 'off',
    ].where((part) => part.isNotEmpty).join(', ');
    return DecoratedBox(
        decoration: BoxDecoration(
            color: colors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colors.outlineVariant)),
        child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 8, 20),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                    child: Text('Whole church',
                        style: text.labelMedium
                            ?.copyWith(color: colors.onSurfaceVariant))),
                MemberIconButton(
                    icon: PhosphorIconsRegular.calendarBlank,
                    label: 'Add $title to calendar',
                    plain: true,
                    onPressed: onCalendar),
              ]),
              Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Semantics(
                      container: true,
                      label: spoken,
                      onTap: onTap,
                      child: ExcludeSemantics(
                          child: SizedBox(
                              width: double.infinity,
                              child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: onTap,
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (time != null)
                                          PrayerTimeText(
                                              hour: time.hour,
                                              minute: time.minute,
                                              size: 44,
                                              color: active
                                                  ? null
                                                  : colors.onSurfaceVariant),
                                        const SizedBox(height: 6),
                                        Text(title, style: text.titleLarge),
                                        const SizedBox(height: 2),
                                        Text(
                                            [meta, if (!active) 'Off']
                                                .where((p) => p.isNotEmpty)
                                                .join(' · '),
                                            style: text.bodySmall),
                                      ])))))),
              const SizedBox(height: 18),
              Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                          onPressed: busy ? null : onStart,
                          style: FilledButton.styleFrom(
                              minimumSize: const Size(48, 52)),
                          icon: busy
                              ? SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: colors.onPrimary))
                              : const Icon(PhosphorIconsFill.play, size: 18),
                          label: Text(busy ? 'Starting' : 'Pray now')))),
            ])));
  }
}

/// One alarm row. Personal alerts carry the switch and open the editor;
/// church alerts (read only) carry Start and Calendar and begin a session.
class PrayerAlertRow extends StatelessWidget {
  const PrayerAlertRow(
      {super.key,
      required this.alert,
      required this.readOnly,
      required this.onChanged,
      required this.onTap,
      this.onStart,
      this.onCalendar});
  final Map<String, dynamic> alert;
  final bool readOnly;
  final ValueChanged<bool>? onChanged;
  final VoidCallback onTap;
  final VoidCallback? onStart, onCalendar;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final time = PrayerSchedule.parseTime(alert);
    final days = PrayerSchedule.days(alert);
    final title = alert['title']?.toString() ?? 'Prayer';
    final active = alert['is_active'] == true;
    final use24 = MediaQuery.alwaysUse24HourFormatOf(context);
    final spoken = [
      'Prayer alert',
      if (time != null)
        PrayerSchedule.timeText(time.hour, time.minute, use24: use24),
      title,
      PrayerSchedule.daysLabel(days, long: true),
      if (readOnly) 'from your church',
      active ? 'on' : 'off',
    ].where((part) => part.isNotEmpty).join(', ');
    final controls = readOnly
        ? Row(mainAxisSize: MainAxisSize.min, children: [
            MemberIconButton(
                icon: PhosphorIconsRegular.play,
                label: 'Start $title',
                plain: true,
                onPressed: onStart),
            MemberIconButton(
                icon: PhosphorIconsRegular.calendarBlank,
                label: 'Add $title to calendar',
                plain: true,
                onPressed: onCalendar),
          ])
        : PrayerReminderSwitch(
            label: 'Enable $title reminder',
            value: active,
            onChanged: onChanged);
    return MemberPress(
      child: Material(
        color: colors.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: colors.outlineVariant)),
        clipBehavior: Clip.antiAlias,
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Expanded(
              child: Semantics(
                  container: true,
                  button: true,
                  label: spoken,
                  onTap: onTap,
                  child: ExcludeSemantics(
                      child: InkWell(
                          onTap: onTap,
                          child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
                              child: TweenAnimationBuilder<double>(
                                  tween: Tween(end: active ? 1 : 0),
                                  duration: AppMotion.duration(
                                      context, AppMotion.control),
                                  curve: AppMotion.curve,
                                  builder: (context, t, _) {
                                    final ink = colors.onSurface;
                                    final quiet = colors.onSurfaceVariant;
                                    return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          if (time != null)
                                            PrayerTimeText(
                                                hour: time.hour,
                                                minute: time.minute,
                                                color: ink.withValues(
                                                    alpha: .55 + .45 * t))
                                          else
                                            Text('--:--',
                                                style: text.headlineMedium),
                                          const SizedBox(height: 2),
                                          Text(title,
                                              style: text.titleMedium?.copyWith(
                                                  color: Color.lerp(
                                                      quiet, ink, t))),
                                          const SizedBox(height: 6),
                                          PrayerDayStrip(
                                              days: days,
                                              color: Color.lerp(quiet, ink, t)!,
                                              quiet: quiet),
                                        ]);
                                  })))))),
          Padding(
              padding: EdgeInsetsDirectional.only(end: readOnly ? 4 : 10),
              child: controls),
        ]),
      ),
    );
  }

  /// Plain `HH:mm`, or `--:--` when the alert has no valid time.
  static String time(Map<String, dynamic> alert) {
    final parsed = PrayerSchedule.parseTime(alert);
    if (parsed == null) return '--:--';
    return '${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
  }

  static String schedule(Map<String, dynamic> alert,
      {bool includeAudio = true}) {
    final days = PrayerSchedule.days(alert);
    final duration = alert['duration_seconds'];
    return [
      PrayerSchedule.daysLabel(days),
      if (includeAudio &&
          alert['audio_title']?.toString().trim().isNotEmpty == true)
        alert['audio_title'].toString(),
      duration is num ? '${duration.toInt() ~/ 60} min' : 'Count up',
    ].where((part) => part.isNotEmpty).join(' · ');
  }
}

/// M T W T F S S as plain text. Days the alert repeats on are bold and in the
/// stronger colour; the others stay regular and quiet. The row's own semantic
/// label carries the spoken days, so the strip is hidden from screen readers.
class PrayerDayStrip extends StatelessWidget {
  const PrayerDayStrip(
      {super.key,
      required this.days,
      required this.color,
      required this.quiet});
  final List<int> days;
  final Color color, quiet;
  static const letters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelMedium;
    return ExcludeSemantics(
        child: Wrap(spacing: 0, runSpacing: 2, children: [
      for (var i = 0; i < 7; i++)
        ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 20),
            child: Text(letters[i],
                textAlign: TextAlign.center,
                style: style?.copyWith(
                    fontWeight: days.contains(i + 1)
                        ? FontWeight.w700
                        : FontWeight.w400,
                    color: days.contains(i + 1) ? color : quiet))),
    ]));
  }
}

class PrayerReminderSwitch extends StatefulWidget {
  const PrayerReminderSwitch(
      {super.key,
      required this.label,
      required this.value,
      required this.onChanged});
  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  State<PrayerReminderSwitch> createState() => _PrayerReminderSwitchState();
}

class _PrayerReminderSwitchState extends State<PrayerReminderSwitch>
    with SingleTickerProviderStateMixin {
  late final position = AnimationController(
      vsync: this,
      value: widget.value ? 1 : 0,
      duration: const Duration(milliseconds: 150));
  bool focused = false, dragCanceled = false;

  void _settle() {
    final target = widget.value ? 1.0 : 0.0;
    if (MediaQuery.disableAnimationsOf(context)) {
      position.value = target;
    } else {
      position.animateTo(target, curve: Curves.easeOutCubic);
    }
  }

  @override
  void didUpdateWidget(PrayerReminderSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value || widget.onChanged == null) _settle();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context) && position.isAnimating) {
      position.value = widget.value ? 1 : 0;
    }
  }

  @override
  void dispose() {
    position.dispose();
    super.dispose();
  }

  void _change(bool value) {
    if (value != widget.value) widget.onChanged?.call(value);
    _settle();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onChanged != null;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Semantics(
      container: true,
      label: widget.label,
      toggled: widget.value,
      enabled: enabled,
      focusable: enabled,
      focused: focused,
      onTap: enabled ? () => _change(!widget.value) : null,
      excludeSemantics: true,
      child: Tooltip(
        message: widget.label,
        excludeFromSemantics: true,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onFocusChange: (value) => setState(() => focused = value),
            onTap: enabled ? () => _change(!widget.value) : null,
            child: Listener(
              onPointerCancel: (_) {
                dragCanceled = true;
                _settle();
              },
              child: GestureDetector(
                onHorizontalDragStart: enabled
                    ? (_) {
                        dragCanceled = false;
                        position.stop();
                      }
                    : null,
                onHorizontalDragUpdate: enabled
                    ? (details) => position.value = (position.value +
                            details.delta.dx * (rtl ? -1 : 1) / 18)
                        .clamp(0.0, 1.0)
                    : null,
                onHorizontalDragEnd: enabled
                    ? (details) {
                        if (!dragCanceled) {
                          _change(position.value +
                                  (details.primaryVelocity ?? 0) *
                                      (rtl ? -1 : 1) *
                                      .00015 >=
                              .5);
                        }
                      }
                    : null,
                onHorizontalDragCancel: enabled ? _settle : null,
                child: SizedBox(
                  width: 51,
                  height: 56,
                  child: Center(
                    child: AnimatedBuilder(
                      animation: position,
                      builder: (context, _) => Container(
                        width: 44,
                        height: 26,
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Color.lerp(MemberVisuals.subtle(context),
                              const Color(0xFF29996C), position.value),
                          boxShadow: focused
                              ? [
                                  BoxShadow(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                      spreadRadius: 2)
                                ]
                              : null,
                        ),
                        child: Align(
                          alignment:
                              AlignmentDirectional(position.value * 2 - 1, 0),
                          child: const SizedBox.square(
                            dimension: 20,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                  color: Colors.white, shape: BoxShape.circle),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
