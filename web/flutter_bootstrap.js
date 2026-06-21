{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.load({
  config: {
    fontFallbackBaseUrl: '/assets/'
  },
  onEntrypointLoaded: async function(engineInitializer) {
    const appRunner = await engineInitializer.initializeEngine();
    await appRunner.runApp();
  }
});
