import 'package:flutter_test/flutter_test.dart';
import 'package:wpcc_community/core/utils/wpcc_time.dart';

void main() {
  group('WpccTime', () {
    test('formats server UTC values in Africa/Lagos display time', () {
      expect(WpccTime.eventTime('2026-09-04T08:00:00Z', null), '9:00 AM');
    });

    test('localTimestamp encodes an explicitly selected schedule preference', () {
      expect(
        WpccTime.localTimestamp(DateTime(2026, 9, 6), const TimeValue(9, 30)),
        '2026-09-06T09:30:00',
      );
    });
  });
}
