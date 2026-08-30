# Splash

The app icon and a loading indicator, for `SplashConstant.minimumVisible`
(1200ms), then the dashboard.

- **It waits on nothing, and that is deliberate.** `AppBootstrap.init` finishes
  before `runApp`, so everything is ready by the first frame — the pause is for
  the icon to read, not for work. Never hang it on a future: hard rule 4 says
  nothing stands between a user mid-attack and the log button, and a splash that
  waits on the network is exactly that.
- **It goes to the dashboard, never to onboarding.** The router's `redirect`
  already owns that decision and sends a first launch on from there; a second
  copy of the rule here is one that can disagree with it.
- **The splash is exempt from `redirect`.** Without the exemption the
  onboarding rule would bounce a first launch off the splash before it ever
  drew.
- **`initialLocationProvider` exists for the tests.** `pumpApp` overrides it to
  the dashboard: the dots animation never ends, so a `pumpAndSettle` on the
  splash waits out its whole timeout instead of settling.
- **There are two launch screens, and only this one is Flutter.** The native one
  (`LaunchScreen.storyboard`, `launch_background.xml`) is a bare `#0C0C0E` field
  drawn by the platform before any Dart runs — same colour as this screen, so the
  icon appears rather than the background changing. `docs/setup/APP_ICON.md`
  covers it.
- **No ARB strings.** Nothing on the screen is a word.
