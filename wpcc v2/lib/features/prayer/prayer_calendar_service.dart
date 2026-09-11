import 'package:web/web.dart' as web;

/// Web/PWA iCalendar export for prayer reminders.
///
/// The selected time/repeat rule is a user preference. It is not an
/// authoritative activity timestamp and is never used to measure a prayer
/// session or attendance. Those timestamps remain server-generated.
class PrayerCalendarService {
  const PrayerCalendarService();

  void downloadAlert(Map<String, dynamic> alert) {
    final title = (alert['title']?.toString().trim().isNotEmpty ?? false)
        ? alert['title'].toString().trim()
        : 'Prayer';
    final timezone = alert['timezone']?.toString().trim().isNotEmpty == true
        ? alert['timezone'].toString().trim()
        : 'Africa/Lagos';
    final localTime = alert['local_time']?.toString() ?? '06:00:00';
    final days = ((alert['days_of_week'] as List?) ?? const <dynamic>[])
        .map((value) => int.tryParse(value.toString()))
        .whereType<int>()
        .where((value) => value >= 1 && value <= 7)
        .toSet()
        .toList()
      ..sort();

    // This value is used only to make a local calendar file and its UID.
    // It is never uploaded as a prayer/session timestamp.
    final now = DateTime.now().toUtc();
    final startDate = _nextMatchingDate(now, days);
    final parts = localTime.split(':');
    final hh = (int.tryParse(parts.isNotEmpty ? parts[0] : '') ?? 6).clamp(0, 23);
    final mm = (int.tryParse(parts.length > 1 ? parts[1] : '') ?? 0).clamp(0, 59);
    final ss = (int.tryParse(parts.length > 2 ? parts[2] : '') ?? 0).clamp(0, 59);

    final dtStart = '${_date(startDate)}T${_two(hh)}${_two(mm)}${_two(ss)}';
    final uid = alert['id']?.toString() ?? 'wpcc-prayer-${now.microsecondsSinceEpoch}';
    final byDay = days.map(_icsDay).where((value) => value.isNotEmpty).join(',');
    final durationSeconds = int.tryParse(alert['duration_seconds']?.toString() ?? '');
    final end = durationSeconds == null
        ? null
        : DateTime(startDate.year, startDate.month, startDate.day, hh, mm, ss)
            .add(Duration(seconds: durationSeconds));

    final lines = <String>[
      'BEGIN:VCALENDAR',
      'VERSION:2.0',
      'PRODID:-//WPCC Community//Prayer Alerts//EN',
      'CALSCALE:GREGORIAN',
      'METHOD:PUBLISH',
      'BEGIN:VEVENT',
      'UID:${_escape(uid)}@wpcc-community',
      'DTSTAMP:${_utcStamp(now)}',
      'DTSTART;TZID=${_escape(timezone)}:$dtStart',
      if (end != null) 'DTEND;TZID=${_escape(timezone)}:${_localStamp(end)}',
      'SUMMARY:${_escape(title)}',
      'DESCRIPTION:${_escape(alert['description']?.toString() ?? 'WPCC prayer reminder')}',
      if (byDay.isNotEmpty) 'RRULE:FREQ=WEEKLY;BYDAY=$byDay',
      'BEGIN:VALARM',
      'TRIGGER:PT0S',
      'ACTION:DISPLAY',
      'DESCRIPTION:${_escape(title)}',
      'END:VALARM',
      'END:VEVENT',
      'END:VCALENDAR',
      '',
    ];

    final calendar = lines.join('\r\n');
    final anchor = web.HTMLAnchorElement()
      ..href = 'data:text/calendar;charset=utf-8,${Uri.encodeComponent(calendar)}'
      ..download = '${_safeFileName(title)}.ics';
    anchor.click();
  }

  DateTime _nextMatchingDate(DateTime utcNow, List<int> days) {
    final today = DateTime(utcNow.year, utcNow.month, utcNow.day);
    if (days.isEmpty) return today;
    for (var offset = 0; offset < 8; offset++) {
      final candidate = today.add(Duration(days: offset));
      if (days.contains(candidate.weekday)) return candidate;
    }
    return today;
  }

  String _icsDay(int day) => switch (day) {
        DateTime.monday => 'MO',
        DateTime.tuesday => 'TU',
        DateTime.wednesday => 'WE',
        DateTime.thursday => 'TH',
        DateTime.friday => 'FR',
        DateTime.saturday => 'SA',
        DateTime.sunday => 'SU',
        _ => '',
      };

  String _date(DateTime d) => '${d.year.toString().padLeft(4, '0')}${_two(d.month)}${_two(d.day)}';
  String _localStamp(DateTime d) => '${_date(d)}T${_two(d.hour)}${_two(d.minute)}${_two(d.second)}';
  String _utcStamp(DateTime d) {
    final value = d.toUtc();
    return '${_date(value)}T${_two(value.hour)}${_two(value.minute)}${_two(value.second)}Z';
  }

  String _two(int value) => value.toString().padLeft(2, '0');
  String _escape(String value) => value
      .replaceAll('\\', '\\\\')
      .replaceAll(';', '\\;')
      .replaceAll(',', '\\,')
      .replaceAll('\n', '\\n');

  String _safeFileName(String value) {
    final normalized = value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return normalized.isEmpty ? 'wpcc-prayer-alert' : normalized;
  }
}
