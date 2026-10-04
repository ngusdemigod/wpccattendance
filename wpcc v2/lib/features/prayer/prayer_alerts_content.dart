import 'package:flutter/material.dart';
import '../../core/theme/app_motion.dart';
import '../../core/widgets/member_skeleton.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/theme/member_theme.dart';
import '../../core/widgets/member_components.dart';

/// Native presentation kept independent of calendar and Web Push services.
class PrayerAlertsContent extends StatelessWidget {
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
  });
  final List<Map<String, dynamic>> alerts;
  final Future<void> Function() onRefresh;
  final ValueChanged<Map<String, dynamic>> onTap, onStart, onCalendar;
  final void Function(Map<String, dynamic>, bool) onToggle;
  final Set<String> updating, starting;
  final String? error;
  final VoidCallback? onEnablePush, onAdd, onBack;
  final bool enablingPush, loading;

  @override
  Widget build(BuildContext context) => RefreshIndicator(
        onRefresh: onRefresh,
        child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
                constraints: BoxConstraints(
                    maxWidth:
                        MediaQuery.sizeOf(context).width >= 900 ? 820 : 1180),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: memberPagePadding(context),
                  children: [
                    Align(
                      alignment: Alignment.topLeft,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 820),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            MemberPageHeader(
                                title: 'Prayer alerts',
                                onBack: onBack,
                                actions: [
                                  MemberIconButton(
                                      icon: PhosphorIconsRegular.plus,
                                      label: 'Add prayer alert',
                                      plain: true,
                                      onPressed: onAdd),
                                ]),
                            Text('Make room for prayer.',
                                style: MemberVisuals.display(context)),
                            const SizedBox(height: 17),
                            Text('A quiet moment, every day.',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant)),
                            const SizedBox(height: 25),
                            if (loading)
                              const Padding(
                                  padding: EdgeInsets.all(40),
                                  child: Center(child: MemberSkeleton()))
                            else if (error != null)
                              MemberStatus(
                                  message: error!,
                                  icon: PhosphorIconsRegular.warningCircle,
                                  onRetry: onRefresh)
                            else ...[
                              if (alerts.isEmpty)
                                const MemberStatus(
                                    message: 'No prayer alerts',
                                    icon: PhosphorIconsRegular.bellSimple)
                              else
                                _reminders(),
                              if (alerts.isNotEmpty) ...[
                                const SizedBox(height: 22),
                                SizedBox(
                                    width: double.infinity,
                                    child: FilledButton.icon(
                                        onPressed: alerts.every((a) => starting
                                                .contains(a['id']?.toString()))
                                            ? null
                                            : () => _choose(
                                                context,
                                                'Start prayer',
                                                onStart,
                                                starting),
                                        icon: const Icon(
                                            PhosphorIconsRegular.play,
                                            size: 22),
                                        label: const Text('Start prayer'))),
                                const SizedBox(height: 10),
                                SizedBox(
                                    width: double.infinity,
                                    child: TextButton.icon(
                                        onPressed: () => _choose(context,
                                            'Calendar', onCalendar, const {}),
                                        style: TextButton.styleFrom(
                                            backgroundColor: Theme.of(context)
                                                .colorScheme
                                                .surfaceContainerLow,
                                            textStyle: Theme.of(context)
                                                .textTheme
                                                .bodyMedium),
                                        icon: const Icon(
                                            PhosphorIconsRegular.calendarBlank,
                                            size: 22),
                                        label: const Text('Calendar'))),
                              ],
                            ],
                            if (onEnablePush != null) ...[
                              const SizedBox(height: 20),
                              TextButton.icon(
                                onPressed: enablingPush ? null : onEnablePush,
                                icon: enablingPush
                                    ? const SizedBox.square(
                                        dimension: 18,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2))
                                    : const Icon(
                                        PhosphorIconsRegular.bellRinging,
                                        size: 18),
                                label: const Text('Enable push reminders'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ))),
      );

  Future<void> _choose(BuildContext context, String title,
      ValueChanged<Map<String, dynamic>> action, Set<String> busy) async {
    if (alerts.length == 1) {
      if (!busy.contains(alerts.first['id']?.toString())) action(alerts.first);
      return;
    }
    final selected = await showModalBottomSheet<Map<String, dynamic>>(
      sheetAnimationStyle: AppMotion.sheetStyle(context),
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: .5,
        minChildSize: .3,
        maxChildSize: .9,
        builder: (context, controller) => ListView(
          controller: controller,
          padding: EdgeInsets.fromLTRB(
              20, 12, 20, MediaQuery.paddingOf(context).bottom + 20),
          children: [
            MemberPageHeader(title: title, actions: [
              MemberIconButton(
                  icon: PhosphorIconsRegular.x,
                  label: 'Close',
                  plain: true,
                  onPressed: () => Navigator.pop(sheetContext)),
            ]),
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
      ),
    );
    if (selected != null && context.mounted) action(selected);
  }

  Widget _reminders() {
    final rows = [
      ...alerts.where((alert) => alert['scope'] != 'personal'),
      ...alerts.where((alert) => alert['scope'] == 'personal'),
    ];
    return Column(children: [
      for (var index = 0; index < rows.length; index++)
        Padding(
            padding: EdgeInsets.only(bottom: index == rows.length - 1 ? 0 : 7),
            child: PrayerAlertRow(
              alert: rows[index],
              readOnly: rows[index]['scope'] != 'personal',
              onChanged: rows[index]['scope'] != 'personal' ||
                      updating.contains(rows[index]['id']?.toString())
                  ? null
                  : (value) => onToggle(rows[index], value),
              onTap: () => onTap(rows[index]),
              onStart: starting.contains(rows[index]['id']?.toString())
                  ? null
                  : () => onStart(rows[index]),
              onCalendar: () => onCalendar(rows[index]),
            )),
    ]);
  }
}

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
    final days = ((alert['days_of_week'] as List?) ?? const [])
        .whereType<int>()
        .toList();
    final scale = MediaQuery.textScalerOf(context).scale(15) / 15;
    final tile = Container(
      width: 50 * scale,
      constraints: BoxConstraints(minHeight: 50 * scale),
      decoration: BoxDecoration(
          color: colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12)),
      child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
                days.length == 7
                    ? 'DAILY'
                    : days.isNotEmpty
                        ? 'WEEKLY'
                        : 'PRAYER',
                style: text.bodySmall?.copyWith(fontSize: 11, height: 15 / 11)),
            Text(time(alert),
                style:
                    text.titleMedium?.copyWith(fontSize: 16, height: 21 / 16)),
          ]),
    );
    final controls = readOnly
        ? MemberIconButton(
            icon: PhosphorIconsRegular.play,
            label: 'Start ${alert['title'] ?? 'prayer'}',
            plain: true,
            onPressed: onStart)
        : Row(mainAxisSize: MainAxisSize.min, children: [
            PrayerReminderSwitch(
                label: 'Enable ${alert['title'] ?? 'prayer'} reminder',
                value: alert['is_active'] == true,
                onChanged: onChanged),
            const SizedBox(width: 12),
            MemberIconButton(
                icon: PhosphorIconsRegular.slidersHorizontal,
                label: 'Edit ${alert['title'] ?? 'prayer'}',
                plain: true,
                onPressed: onTap),
          ]);
    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: colors.outlineVariant)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: readOnly && onStart == null ? null : onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 76),
          padding: const EdgeInsets.all(11),
          child: LayoutBuilder(builder: (context, constraints) {
            final stacked = scale > 1.4 || constraints.maxWidth < 310;
            return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    tile,
                    const SizedBox(width: 12),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(alert['title']?.toString() ?? 'Prayer',
                              style: text.titleMedium),
                          const SizedBox(height: 4),
                          Text(schedule(alert), style: text.bodySmall),
                        ])),
                    if (!stacked) ...[
                      const SizedBox(width: 12),
                      controls,
                    ],
                  ]),
                  if (stacked)
                    Align(alignment: Alignment.centerRight, child: controls),
                ]);
          }),
        ),
      ),
    );
  }

  static String time(Map<String, dynamic> alert) {
    final parts = alert['local_time']?.toString().split(':');
    if (parts == null || parts.length < 2) return '--:--';
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null ||
        minute == null ||
        hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59) {
      return '--:--';
    }
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  static String schedule(Map<String, dynamic> alert) {
    final days = ((alert['days_of_week'] as List?) ?? const [])
        .whereType<int>()
        .toList();
    final duration = alert['duration_seconds'];
    return [
      _daysLabel(days),
      if (alert['audio_title']?.toString().trim().isNotEmpty == true)
        alert['audio_title'].toString(),
      duration is num ? '${duration.toInt() ~/ 60} min' : 'Count up',
    ].where((part) => part.isNotEmpty).join(' · ');
  }

  static String _daysLabel(List<int> days) {
    if (days.length == 7) return 'Every day';
    const labels = {
      1: 'Mon',
      2: 'Tue',
      3: 'Wed',
      4: 'Thu',
      5: 'Fri',
      6: 'Sat',
      7: 'Sun'
    };
    return days.map((d) => labels[d]).whereType<String>().join(', ');
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
