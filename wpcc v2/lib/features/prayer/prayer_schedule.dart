/// Pure schedule helpers for prayer alerts. Nothing here reads a clock or a
/// repository: callers pass the alert rows and the current time, so every
/// result is derived from real alert data and can be tested with fixed times.
library;

/// The next time an alert will ring, measured from a given moment.
class PrayerNextAlert {
  const PrayerNextAlert({
    required this.alert,
    required this.minutesUntil,
    required this.dayOffset,
    required this.weekday,
  });

  final Map<String, dynamic> alert;

  /// Whole minutes from now (never negative; 0 means it rings this minute).
  final int minutesUntil;

  /// Calendar days from today in the alert's own time zone (0 = today).
  final int dayOffset;

  /// Day it rings, 1 = Monday .. 7 = Sunday.
  final int weekday;
}

abstract final class PrayerSchedule {
  /// Time zones the app can convert without a time zone database. The alert
  /// editor saves every personal alert as Africa/Lagos (UTC+1, no daylight
  /// saving). Any other zone is compared against the device clock as is.
  static const _fixedOffsetHours = {'Africa/Lagos': 1};

  static const _shortDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _longDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  /// Strictly parsed `HH:mm[:ss]`; null when missing or out of range.
  static ({int hour, int minute})? parseTime(Map<String, dynamic> alert) {
    final parts = alert['local_time']?.toString().split(':');
    if (parts == null || parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null ||
        minute == null ||
        hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59) {
      return null;
    }
    return (hour: hour, minute: minute);
  }

  /// Repeat days, 1 = Monday .. 7 = Sunday, sorted and unique. A row without
  /// the field repeats every day, matching the repository's own default.
  static List<int> days(Map<String, dynamic> alert) {
    final raw = alert['days_of_week'];
    if (raw is! List) return const [1, 2, 3, 4, 5, 6, 7];
    final days = raw.whereType<int>().where((d) => d >= 1 && d <= 7).toSet();
    return days.toList()..sort();
  }

  static bool isActive(Map<String, dynamic> alert) =>
      alert['is_active'] == true;

  /// The next occurrence of one alert, ignoring whether it is switched on.
  static PrayerNextAlert? nextOf(Map<String, dynamic> alert, DateTime now) {
    final time = parseTime(alert);
    final days = PrayerSchedule.days(alert);
    if (time == null || days.isEmpty) return null;
    final offset = _fixedOffsetHours[alert['timezone']?.toString()];
    final wall =
        offset == null ? now : now.toUtc().add(Duration(hours: offset));
    final nowMinute = wall.hour * 60 + wall.minute;
    final alertMinute = time.hour * 60 + time.minute;
    for (var offsetDays = 0; offsetDays <= 7; offsetDays++) {
      final weekday = (wall.weekday - 1 + offsetDays) % 7 + 1;
      if (!days.contains(weekday)) continue;
      final minutes = offsetDays * 1440 + alertMinute - nowMinute;
      if (minutes < 0) continue;
      return PrayerNextAlert(
        alert: alert,
        minutesUntil: minutes,
        dayOffset: offsetDays,
        weekday: weekday,
      );
    }
    return null;
  }

  /// The soonest next occurrence among alerts that are switched on.
  static PrayerNextAlert? next(
      Iterable<Map<String, dynamic>> alerts, DateTime now) {
    PrayerNextAlert? best;
    for (final alert in alerts) {
      if (!isActive(alert)) continue;
      final candidate = nextOf(alert, now);
      if (candidate != null &&
          (best == null || candidate.minutesUntil < best.minutesUntil)) {
        best = candidate;
      }
    }
    return best;
  }

  /// The alert to feature: the soonest active one, otherwise the first.
  static Map<String, dynamic>? featured(
      List<Map<String, dynamic>> alerts, DateTime now) {
    if (alerts.isEmpty) return null;
    return next(alerts, now)?.alert ?? alerts.first;
  }

  /// `Now`, `In 25 min`, `In 2 h 15 min`, `Tomorrow` or a weekday name.
  static String countdown(PrayerNextAlert next) {
    final m = next.minutesUntil;
    if (m < 1) return 'Now';
    if (m < 60) return 'In $m min';
    if (m < 1440) {
      final h = m ~/ 60;
      final rest = m % 60;
      return rest == 0 ? 'In $h h' : 'In $h h $rest min';
    }
    if (next.dayOffset == 1) return 'Tomorrow';
    return _longDays[next.weekday - 1];
  }

  /// Compact day text: Every day, Weekdays, Weekends, Mon to Wed, Mon, Wed.
  /// With [long] the day names are spelled out for screen readers.
  static String daysLabel(List<int> days, {bool long = false}) {
    final sorted = days.toSet().toList()..sort();
    if (sorted.isEmpty) return '';
    final names = long ? _longDays : _shortDays;
    String name(int d) => names[d - 1];
    if (sorted.length == 7) return 'Every day';
    if (_same(sorted, const [1, 2, 3, 4, 5])) {
      return long ? 'Monday to Friday' : 'Weekdays';
    }
    if (_same(sorted, const [6, 7])) {
      return long ? 'Saturday and Sunday' : 'Weekends';
    }
    final run = sorted.last - sorted.first + 1 == sorted.length;
    if (run && sorted.length >= 3) {
      return '${name(sorted.first)} to ${name(sorted.last)}';
    }
    if (long && sorted.length > 1) {
      final head = sorted.sublist(0, sorted.length - 1).map(name).join(', ');
      return '$head and ${name(sorted.last)}';
    }
    return sorted.map(name).join(', ');
  }

  static bool _same(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Display parts of a clock time: `6:00` + `am`, or `06:00` with no suffix
  /// on a 24-hour device.
  static ({String digits, String? suffix}) timeParts(int hour, int minute,
      {required bool use24}) {
    final mm = minute.toString().padLeft(2, '0');
    if (use24) {
      return (digits: '${hour.toString().padLeft(2, '0')}:$mm', suffix: null);
    }
    final h12 = hour % 12 == 0 ? 12 : hour % 12;
    return (digits: '$h12:$mm', suffix: hour < 12 ? 'am' : 'pm');
  }

  /// The spoken or written form of [timeParts]: `6:00 am` or `06:00`.
  static String timeText(int hour, int minute, {required bool use24}) {
    final parts = timeParts(hour, minute, use24: use24);
    return parts.suffix == null
        ? parts.digits
        : '${parts.digits} ${parts.suffix}';
  }
}
