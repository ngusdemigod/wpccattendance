import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:wpcc_community/core/services/swr_cache.dart';
import 'package:wpcc_community/features/media/media_repository.dart';

http.Response page(List<Map<String, dynamic>> items, {int status = 200}) =>
    http.Response(jsonEncode({'items': items, 'next': null}), status,
        headers: {'content-type': 'application/json; charset=utf-8'});

void main() {
  setUp(() => SwrCache.instance.clear());

  test('reads the gallery from the public API without needing Supabase',
      () async {
    late Uri requested;
    late Map<String, String> sentHeaders;
    final repository = MediaRepository(
        null,
        MockClient((request) async {
          requested = request.url;
          sentHeaders = request.headers;
          return page([
            {
              'id': '1001',
              'caption': 'Sunday',
              'permalink': 'https://www.facebook.com/photo/1',
              'published_at': '2026-09-01T10:00:00.000Z',
              'width': 1200,
              'height': 800,
              'r2_key': 'media-sync/fb/photo-1001',
            }
          ]);
        }),
        'https://media-api.example.test/');
    final rows = await repository.galleryPhotos();
    expect(requested.toString(),
        'https://media-api.example.test/v1/gallery?limit=40');
    expect(sentHeaders['Accept'], 'application/json');
    expect(sentHeaders.containsKey('Authorization'), isFalse,
        reason: 'the media API is public: no login is sent');
    expect(rows.single['r2_key'], 'media-sync/fb/photo-1001');
    expect(rows.single['width'], 1200);
  });

  test('pages with a keyset cursor built from the last photo and caches page one',
      () async {
    final requests = <Uri>[];
    final repository = MediaRepository(
        null,
        MockClient((request) async {
          requests.add(request.url);
          return page([]);
        }),
        'https://media-api.example.test');
    await repository.galleryPhotos();
    await repository.galleryPhotos();
    expect(requests, hasLength(1), reason: 'the first page is cached');
    await repository.galleryPhotos(after: {
      'id': '1002',
      'published_at': '2026-09-01T09:00:00.000Z',
    });
    expect(requests.last.queryParameters, {
      'limit': '40',
      'before': '2026-09-01T09:00:00.000Z|1002',
    });
  });

  test('reads videos and clamps the page size to what the API allows',
      () async {
    final requests = <Uri>[];
    final repository = MediaRepository(
        null,
        MockClient((request) async {
          requests.add(request.url);
          return page([
            {
              'id': 'youtube:abc',
              'provider': 'youtube',
              'kind': 'live',
              'title': 'Sunday service',
              'published_at': '2026-09-20T10:00:00.000Z',
            }
          ]);
        }),
        'https://media-api.example.test');
    final rows = await repository.videos(limit: 500);
    expect(requests.single.path, '/v1/videos');
    expect(requests.single.queryParameters['limit'], '50');
    expect(rows.single['kind'], 'live');
  });

  test('reports a service failure instead of returning empty data', () async {
    for (final status in [403, 429, 503]) {
      SwrCache.instance.clear();
      final repository = MediaRepository(
          null,
          MockClient((_) async => page([], status: status)),
          'https://media-api.example.test');
      await expectLater(
          repository.videos(),
          throwsA(isA<Exception>().having(
              (e) => e.toString(), 'message', contains('($status)'))),
          reason: 'status $status');
    }
  });

  test('rejects malformed responses', () async {
    final repository = MediaRepository(
        null,
        MockClient((_) async => http.Response('{"oops": true}', 200)),
        'https://media-api.example.test');
    await expectLater(repository.galleryPhotos(), throwsA(isA<Exception>()));
  });
}
