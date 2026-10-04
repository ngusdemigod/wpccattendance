{{flutter_js}}
{{flutter_build_config}}

window.wpccInstalledLaunch.then(() => {
window.dispatchEvent(new Event('wpcc-startup'));
return _flutter.loader.load({
  onEntrypointLoaded: async (engineInitializer) => {
    try {
      const appRunner = await engineInitializer.initializeEngine();
      await appRunner.runApp();
    } catch (_) {
      window.wpccShowStartupError?.();
    }
  },
}); }).catch(() => window.wpccShowStartupError?.());


