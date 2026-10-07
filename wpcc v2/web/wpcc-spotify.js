// Spotify playback bridge. The Flutter app drives a hidden Spotify embed
// through the window.wpccSpotify* functions below (see
// lib/features/media/spotify_playback_bridge_web.dart).
(() => {
  let controller = null;
  let controllerReady = false;
  let pendingEntity = null;
  let wantsPlayback = false;
  let playback = { isPaused: true, position: 0, duration: 0 };
  const playLoadedEntity = (entity) => {
    if (!controller) return;
    pendingEntity = null;
    controller.loadEntity(entity, false, 0);
    // The SDK queues this single command until the new embed is ready.
    controller.play();
  };

  window.wpccSpotifyLoadAndPlay = (entity) => {
    if (!entity) return;
    pendingEntity = entity;
    wantsPlayback = true;
    if (!controller) return;
    playLoadedEntity(entity);
  };
  window.wpccSpotifyTogglePlay = () => {
    wantsPlayback = controller ? playback.isPaused : !wantsPlayback;
    if (!controller) return;
    if (wantsPlayback) {
      if (pendingEntity) playLoadedEntity(pendingEntity);
      else controller.resume();
    } else controller.pause();
  };
  window.wpccSpotifyPause = () => {
    wantsPlayback = false;
    pendingEntity = null;
    if (controller) controller.pause();
  };
  window.wpccSpotifySeek = (seconds) => controller && controller.seek(Math.max(0, Math.floor(seconds)));
  window.wpccSpotifyIsReady = () => controller !== null && controllerReady;
  window.wpccSpotifyIsPaused = () => playback.isPaused;
  window.wpccSpotifyPosition = () => playback.position;
  window.wpccSpotifyDuration = () => playback.duration;

  window.onSpotifyIframeApiReady = (IFrameAPI) => {
    const element = document.getElementById('wpcc-spotify-player');
    IFrameAPI.createController(element, {
      width: 300,
      height: 80,
      uri: 'spotify:episode:7A2cF7XaQ72nQ4StEbtZKK'
    }, (embedController) => {
      controller = embedController;
      // A tap in the app must count as permission to autoplay inside the embed.
      const frame = element.querySelector && element.querySelector('iframe');
      if (frame) frame.allow = 'autoplay; encrypted-media; clipboard-write';
      controller.addListener('ready', () => {
        controllerReady = true;
      });
      controller.addListener('playback_update', (event) => {
        playback = event.data || playback;
        // Ignore the initial paused update while a requested episode loads.
        if (!playback.isPaused || playback.position > 0) {
          wantsPlayback = !playback.isPaused;
        }
      });
      if (pendingEntity && wantsPlayback) playLoadedEntity(pendingEntity);
    });
  };
})();
