import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:wpcc_community/core/services/swr_cache.dart';

void main() {
  final cache = SwrCache.instance;

  setUp(cache.clear);

  test('reuses fresh data without issuing another request', () async {
    var requests = 0;
    Future<int> load() async => ++requests;

    expect(await cache.get('fresh', load), 1);
    expect(await cache.get('fresh', load), 1);
    expect(requests, 1);
  });

  test('invalidation makes the next read fetch new data', () async {
    var requests = 0;
    Future<int> load() async => ++requests;

    expect(await cache.get('events:list', load), 1);
    cache.invalidate('events:');
    expect(await cache.get('events:list', load), 2);
  });

  test('returns stale data while one background refresh runs', () async {
    var requests = 0;
    final refresh = Completer<int>();
    Future<int> load() {
      requests += 1;
      return requests == 1 ? Future.value(1) : refresh.future;
    }

    expect(await cache.get('swr', load), 1);
    await Future<void>.delayed(Duration.zero);
    expect(
      await cache.get(
        'swr',
        load,
        freshFor: Duration.zero,
        maxStale: const Duration(minutes: 1),
      ),
      1,
    );
    expect(
      await cache.get(
        'swr',
        load,
        freshFor: Duration.zero,
        maxStale: const Duration(minutes: 1),
      ),
      1,
    );
    expect(requests, 2);

    refresh.complete(2);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(await cache.get('swr', load), 2);
  });
}
