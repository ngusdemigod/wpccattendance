/// Play and pause for an embedded YouTube player. Only YouTube answers these
/// commands (the embed URL carries enablejsapi=1); the Facebook player ignores
/// them, so callers must not rely on the result.
class VideoEmbedController {
  void Function(String command)? _send;

  /// Set by the embed while it is mounted.
  // ignore: use_setters_to_change_properties
  void attach(void Function(String command)? send) => _send = send;

  void play() => _send?.call('playVideo');
  void pause() => _send?.call('pauseVideo');
}
