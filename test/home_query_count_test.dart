import 'package:flutter_test/flutter_test.dart';
import 'package:attendamce/features/home/home_feed_models.dart';

void main() {
  test('cached home feed defaults a missing query count to zero', () {
    final data = HomeFeedData.fromCacheMap(const <String, dynamic>{
      'displayName': 'Angus',
      'fullName': 'Igbani Angus',
      'avatarInitials': 'IA',
    });

    expect(data.queryCount, 0);
    expect(data.toCacheMap()['queryCount'], 0);
  });
}
