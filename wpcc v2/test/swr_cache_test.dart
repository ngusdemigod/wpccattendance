import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:wpcc_community/core/services/swr_cache.dart';

void main() {
  final cache = SwrCache.instance;

  setUp(cache.clear);

  test('late invalidated requests cannot replace newer cached data', () async {
    final old = Completer<int>();
    final first = cache.get('events:race', () => old.future);
    cache.invalidate('events:');
    expect(await cache.get('events:race', () async => 2), 2);
    old.complete(1);
    await first;
    expect(await cache.get('events:race', () async => 3), 2);
  });

  test('logout clear prevents pending requests from restoring cache', () async {
    final old = Completer<int>();
    final first = cache.get('private', () => old.future);
    cache.clear();
    old.complete(1);
    await first;
    expect(await cache.get('private', () async => 2), 2);
  });

  test('failed background refresh retains cached data without uncaught errors',
      () async {
    await cache.get('offline', () async => 1);
    await Future<void>.delayed(const Duration(milliseconds: 1));
    expect(
        await cache.get<int>('offline', () async => throw StateError('offline'),
            freshFor: Duration.zero),
        1);
    await Future<void>.delayed(const Duration(milliseconds: 1));
    expect(await cache.get('offline', () async => 2), 1);
  });

  test('cache has a bounded least-recently-used capacity', () async {
    for (var i = 0; i <= SwrCache.maximumEntries; i++) {
      await cache.get('item:$i', () async => i);
    }
    expect(await cache.get('item:0', () async => -1), -1);
    expect(await cache.get('item:200', () async => -1), 200);
  });

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
