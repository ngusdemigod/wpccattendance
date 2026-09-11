import 'package:flutter_test/flutter_test.dart';
import 'package:wpcc_community/features/search/search_page.dart';

void main() {
  test('only the latest search request remains current', () {
    final requests = SearchRequestCoordinator();

    final older = requests.begin();
    final latest = requests.begin();

    expect(requests.isCurrent(older), isFalse);
    expect(requests.isCurrent(latest), isTrue);
  });

  test('starting a new request invalidates the previous completion', () {
    final requests = SearchRequestCoordinator();
    final first = requests.begin();

    expect(requests.isCurrent(first), isTrue);

    requests.begin();

    expect(requests.isCurrent(first), isFalse);
  });
}
