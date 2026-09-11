import 'package:intl/intl.dart';

class WpccTime {
  const WpccTime._();
  static const timezone = 'Africa/Lagos';

  static DateTime? parseServer(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  static DateTime lagos(DateTime value) => value.toUtc().add(const Duration(hours: 1));

  static String eventDate(dynamic value) {
    final d = parseServer(value);
    return d == null ? '' : DateFormat('EEEE, MMMM d, yyyy').format(lagos(d));
  }

  static String eventTime(dynamic start, dynamic end) {
    final s = parseServer(start);
    final e = parseServer(end);
    if (s == null) return '';
    final startText = DateFormat('h:mm a').format(lagos(s));
    if (e == null) return startText;
    return '$startText – ${DateFormat('h:mm a').format(lagos(e))}';
  }

  static String compact(dynamic value) {
    final d = parseServer(value);
    return d == null ? '' : DateFormat('EEE, d MMM · h:mm a').format(lagos(d));
  }

  static String transactionDate(dynamic value) {
    final d = parseServer(value);
    return d == null ? '' : DateFormat('MMM d, yyyy · h:mm a').format(lagos(d));
  }

  static String localTimestamp(DateTime date, TimeValue time) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    final h = time.hour.toString().padLeft(2, '0');
    final min = time.minute.toString().padLeft(2, '0');
    return '$y-$m-${d}T$h:$min:00';
  }
}

class TimeValue {
  const TimeValue(this.hour, this.minute);
  final int hour;
  final int minute;
}
