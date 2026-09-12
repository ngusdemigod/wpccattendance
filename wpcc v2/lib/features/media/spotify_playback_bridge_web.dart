import 'dart:async';
import 'dart:js_interop';

import 'package:flutter/foundation.dart';

@JS('wpccSpotifyLoadAndPlay')
external void _loadAndPlay(JSString entity);
@JS('wpccSpotifyTogglePlay')
external void _togglePlay();
@JS('wpccSpotifyPause')
external void _pause();
@JS('wpccSpotifySeek')
external void _seek(JSNumber seconds);
@JS('wpccSpotifyIsReady')
external JSBoolean _isReady();
@JS('wpccSpotifyIsPaused')
external JSBoolean _isPaused();
@JS('wpccSpotifyPosition')
external JSNumber _position();
@JS('wpccSpotifyDuration')
external JSNumber _duration();

class SpotifyPlaybackState {
  const SpotifyPlaybackState({
    this.ready = false,
    this.isPaused = true,
    this.positionMs = 0,
    this.durationMs = 0,
  });
  final bool ready;
  final bool isPaused;
  final int positionMs;
  final int durationMs;
}

class SpotifyPlaybackBridge extends ValueNotifier<SpotifyPlaybackState> {
  SpotifyPlaybackBridge._() : super(const SpotifyPlaybackState()) {
    _timer = Timer.periodic(const Duration(milliseconds: 400), (_) => _sync());
  }
  static final instance = SpotifyPlaybackBridge._();
  late final Timer _timer;

  void _sync() {
    final next = SpotifyPlaybackState(
      ready: _isReady().toDart,
      isPaused: _isPaused().toDart,
      positionMs: _position().toDartInt,
      durationMs: _duration().toDartInt,
    );
    if (next.ready != value.ready ||
        next.isPaused != value.isPaused ||
        next.positionMs != value.positionMs ||
        next.durationMs != value.durationMs) {
      value = next;
    }
  }

  void loadAndPlay(String entity) {
    _loadAndPlay(entity.toJS);
    value = SpotifyPlaybackState(
      ready: value.ready,
      isPaused: false,
      positionMs: 0,
      durationMs: value.durationMs,
    );
  }

  void togglePlay() => _togglePlay();
  void pause() => _pause();
  void seek(int positionMs) => _seek((positionMs / 1000).toJS);

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }
}
