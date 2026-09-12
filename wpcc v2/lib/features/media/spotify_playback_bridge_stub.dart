import 'package:flutter/foundation.dart';

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
  SpotifyPlaybackBridge._() : super(const SpotifyPlaybackState());
  static final instance = SpotifyPlaybackBridge._();
  void loadAndPlay(String entity) {}
  void togglePlay() {}
  void pause() {}
  void seek(int positionMs) {}
}
