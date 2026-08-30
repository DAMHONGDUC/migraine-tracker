# Splash

The loading indicator, over the work a launch has to settle first, then the
dashboard.

- **It is the app's first route** (`initialLocation`), and it leaves for the
  dashboard when `SplashController.run` returns. No timer: it lasts exactly what
  the work lasts.
- **It carries the first-launch guard.** `FreshInstallGuard` used to run inside
  `AppBootstrap`, ahead of `runApp`, where the platform's launch screen stood in
  for it and a slow start could not be told from a hang. It runs here now, under
  something moving.
- **`AppBootstrap.ensureAnonymousSession` is called again after the guard, and
  must be.** A reinstall purge signs the old session out and leaves no caller at
  all; `getWeather` will not serve one it cannot name.
- **The splash is exempt from the router's `redirect`.** The guard it runs can
  WIPE the store those rules read — including `onboarding_completed` — so a
  redirect firing mid-purge would decide on values that are about to be gone. On
  the way out, the dashboard hits every rule as usual, which is what sends a
  purged install to onboarding.
- **`SplashController.run` never throws.** An app that cannot get past its own
  loading screen is worse than one that starts signed in.
- **`initialLocationProvider` exists for the tests.** `pumpApp` overrides it to
  the dashboard: the dots animation never ends, so a `pumpAndSettle` on the
  splash waits out its whole timeout instead of settling.
- **Nothing on it but the dots** (owner's call), at a raw pixel size — the first
  frame gains nothing from the design-size scale.
- **The native launch screen before it carries the app icon**
  (`LaunchImage.imageset`, `docs/setup/APP_ICON.md`), because `AppBootstrap.init`
  runs before any Dart and a bare colour field for that whole wait reads as a
  black screen. The icon goes away when this screen takes over; putting it here
  too is the one-line fix if that ever reads worse than the black did.
- **No ARB strings.** Nothing on the screen is a word.
