import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

typedef SwrLoader<T> = Future<T> Function();

class SwrCache {
  SwrCache._();

  static final instance = SwrCache._();

  final _entries = <String, _SwrEntry>{};
  final _inFlight = <String, Future<Object?>>{};
  SupabaseClient? _client;
  RealtimeChannel? _channel;
  StreamSubscription<AuthState>? _authSubscription;

  static const defaultFreshFor = Duration(minutes: 5);
  static const defaultMaxStale = Duration(hours: 1);
  static const maximumEntries = 200;

  void bind(SupabaseClient client) {
    if (identical(_client, client)) return;
    _authSubscription?.cancel();
    if (_channel != null && _client != null) {
      _client!.removeChannel(_channel!);
    }
    _client = client;
    clear();
    // A token refresh keeps the same member, and keys are already scoped by user
    // id, so it must not discard warm data (it happens about hourly and every
    // time the app returns from the background with an expired token).
    _authSubscription = client.auth.onAuthStateChange.listen((state) {
      if (state.event == AuthChangeEvent.tokenRefreshed ||
          state.event == AuthChangeEvent.initialSession) {
        return;
      }
      clear();
    });
    _channel = client
        .channel('wpcc-swr-invalidation')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          callback: (_) => invalidate(),
        )
        .subscribe();
  }

  Future<T> get<T>(
    String key,
    SwrLoader<T> loader, {
    Duration freshFor = defaultFreshFor,
    Duration maxStale = defaultMaxStale,
  }) async {
    final scopedKey = _scoped(key);
    final cached = _entries[scopedKey];
    if (cached != null) {
      _entries.remove(scopedKey);
      _entries[scopedKey] = cached;
    }
    final age =
        cached == null ? null : DateTime.now().difference(cached.savedAt);
    if (cached != null && age! < freshFor) return cached.value as T;
    if (cached != null && age! <= maxStale) {
      unawaited(_refresh(scopedKey, loader)
          .then<void>((_) {}, onError: (Object _, StackTrace __) {}));
      return cached.value as T;
    }
    return _refresh(scopedKey, loader);
  }

  Future<T> _refresh<T>(String key, SwrLoader<T> loader) {
    final existing = _inFlight[key];
    if (existing != null) return existing.then((value) => value as T);
    late final Future<Object?> request;
    request = Future<T>.sync(loader).then<Object?>((value) {
      // Invalidated or previous-session responses must never repopulate cache.
      if (identical(_inFlight[key], request)) {
        _entries.remove(key);
        _entries[key] = _SwrEntry(value, DateTime.now());
        while (_entries.length > maximumEntries) {
          _entries.remove(_entries.keys.first);
        }
      }
      return value;
    }).whenComplete(() {
      if (identical(_inFlight[key], request)) _inFlight.remove(key);
    });
    _inFlight[key] = request;
    return request.then((value) => value as T);
  }

  void invalidate([String? keyPrefix]) {
    if (keyPrefix == null) {
      clear();
      return;
    }
    final scopedPrefix = _scoped(keyPrefix);
    _entries.removeWhere((key, _) => key.startsWith(scopedPrefix));
    _inFlight.removeWhere((key, _) => key.startsWith(scopedPrefix));
  }

  void clear() {
    _entries.clear();
    _inFlight.clear();
  }

  String _scoped(String key) =>
      '${_client?.auth.currentUser?.id ?? 'anonymous'}:$key';
}

class _SwrEntry {
  const _SwrEntry(this.value, this.savedAt);
  final Object? value;
  final DateTime savedAt;
}
