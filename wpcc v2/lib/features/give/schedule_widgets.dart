import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/theme/app_motion.dart';
import '../../core/utils/wpcc_time.dart';

/// Read-only view of a recurring giving mandate row. Everything shown comes
/// from the row; nothing is inferred beyond formatting.
class GiveSchedule {
  const GiveSchedule(this.raw);
  final Map<String, dynamic> raw;

  String? get id => raw['id']?.toString();
  String get status => raw['status']?.toString() ?? '';
  bool get active => status == 'active';
  int get amountKobo => int.tryParse(raw['amount_kobo']?.toString() ?? '') ?? 0;

  String get amount => NumberFormat.currency(
          locale: 'en_NG',
          symbol: '₦',
          decimalDigits: amountKobo % 100 == 0 ? 0 : 2)
      .format(amountKobo / 100);

  String get statusLabel => status.isEmpty ? 'Unknown' : _capital(status);

  String get purpose {
    final type = raw['giving_type']?.toString() ?? '';
    return switch (type) {
      '' => 'Scheduled giving',
      'project' => 'Church project',
      _ => _capital(type.replaceAll('_', ' ')),
    };
  }

  /// Plain-language repeat description, for example "Every Thursday".
  String get repeats {
    final labels = <String>{
      for (final rule in (raw['rule_keys'] as List?) ?? const [])
        describeRule(rule.toString()),
    };
    return labels.isEmpty ? 'Schedule not available' : labels.join(' · ');
  }

  DateTime? _lagos(String key) {
    final value = WpccTime.parseServer(raw[key]);
    return value == null ? null : WpccTime.lagos(value);
  }

  DateTime? get nextCharge => _lagos('next_charge_at');
  DateTime? get lastCharge => _lagos('last_charge_at');
  DateTime? get startedAt => _lagos('consent_at');
  DateTime? get cancelledAt => _lagos('cancelled_at');

  static const _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  /// Handles every rule key the app writes: `weekday:N[:id]`, `event:date:id`,
  /// `monthly:D:id`, `yearly:M:D:id`, `recurring:id` and the named service
  /// days from the schedule form.
  static String describeRule(String key) {
    final parts = key.split(':');
    int? at(int i) => i < parts.length ? int.tryParse(parts[i]) : null;
    switch (parts.first) {
      case 'weekday':
        final day = at(1);
        return day != null && day >= 1 && day <= 7
            ? 'Every ${_days[day - 1]}'
            : 'Service day';
      case 'event':
        final date = parts.length > 1 ? DateTime.tryParse(parts[1]) : null;
        return date == null
            ? 'One event'
            : 'Once · ${DateFormat('d MMM').format(date)}';
      case 'monthly':
        final day = at(1);
        return day == null ? 'Monthly' : 'Monthly · day $day';
      case 'yearly':
        final month = at(1), day = at(2);
        return month != null && day != null && month >= 1 && month <= 12
            ? 'Yearly · ${DateFormat('d MMM').format(DateTime(2000, month, day))}'
            : 'Yearly';
      case 'recurring':
        return 'Recurring event';
      case 'sunday_service':
        return 'Sunday service';
      case 'wednesday':
        return 'Wednesday';
      case 'thursday':
        return 'Thursday';
      case 'special':
        return 'Special events';
    }
    return 'Service day';
  }

  static String formatDate(DateTime date) =>
      DateFormat('EEE, d MMM yyyy').format(date);
  static String formatDateTime(DateTime date) =>
      DateFormat('EEE, d MMM · h:mm a').format(date);

  static String _capital(String value) =>
      value.isEmpty ? value : '${value[0].toUpperCase()}${value.substring(1)}';

  /// The soonest upcoming charge among the active schedules.
  static DateTime? nextOf(Iterable<GiveSchedule> schedules) {
    DateTime? best;
    for (final schedule in schedules.where((s) => s.active)) {
      final next = schedule.nextCharge;
      if (next != null && (best == null || next.isBefore(best))) best = next;
    }
    return best;
  }
}

/// Number of active schedules and the next charge date.
class ScheduleSummary extends StatelessWidget {
  const ScheduleSummary({super.key, required this.schedules});
  final List<GiveSchedule> schedules;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = schedules.where((s) => s.active).length;
    final next = GiveSchedule.nextOf(schedules);
    final headline = active == 0
        ? 'No active schedules'
        : active == 1
            ? '1 active schedule'
            : '$active active schedules';
    final detail = active == 0
        ? 'Give automatically on the days you choose.'
        : next == null
            ? 'Next charge date not available'
            : 'Next charge · ${GiveSchedule.formatDateTime(next)}';
    return Semantics(
      container: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.colorScheme.outlineVariant)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Scheduled giving', style: theme.textTheme.bodySmall),
            const SizedBox(height: 6),
            Text(headline, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 6),
            Text(detail,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ]),
        ),
      ),
    );
  }
}

/// One schedule as a list row: purpose and repeat on the left, amount and
/// plain-text status on the right.
class ScheduleRow extends StatelessWidget {
  const ScheduleRow(
      {super.key,
      required this.schedule,
      required this.onTap,
      this.statusOverride,
      this.divider = true});
  final GiveSchedule schedule;
  final VoidCallback? onTap;

  /// Replaces the status text while an action on the row is in progress.
  final String? statusOverride;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final next = schedule.nextCharge;
    final secondary = [
      schedule.repeats,
      if (schedule.active && next != null)
        'Next ${DateFormat('d MMM').format(next)}',
    ].join(' · ');
    final status = statusOverride ?? schedule.statusLabel;
    return Semantics(
      button: onTap != null,
      child: AppPressMotion(
        child: InkWell(
          onTap: onTap,
          child: DecoratedBox(
            decoration: BoxDecoration(
                border: divider
                    ? Border(
                        bottom:
                            BorderSide(color: theme.colorScheme.outlineVariant))
                    : null),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 72),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(schedule.purpose,
                                  style: theme.textTheme.titleMedium),
                              const SizedBox(height: 3),
                              Text(secondary,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall),
                            ]),
                      ),
                      const SizedBox(width: 12),
                      ConstrainedBox(
                        constraints: BoxConstraints(
                            maxWidth: MediaQuery.sizeOf(context).width * .4),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(schedule.amount,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 3),
                              AnimatedSwitcher(
                                duration:
                                    AppMotion.duration(context, AppMotion.tab),
                                switchInCurve: AppMotion.curve,
                                switchOutCurve: AppMotion.curve.flipped,
                                child: Text(status,
                                    key: ValueKey(status),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                        color: schedule.active
                                            ? theme.colorScheme.onSurface
                                            : theme
                                                .colorScheme.onSurfaceVariant,
                                        fontWeight: schedule.active
                                            ? FontWeight.w600
                                            : FontWeight.w400)),
                              ),
                            ]),
                      ),
                      if (onTap != null) ...[
                        const SizedBox(width: 6),
                        Icon(PhosphorIconsRegular.caretRight,
                            size: 16,
                            color: theme.colorScheme.onSurfaceVariant),
                      ],
                    ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
