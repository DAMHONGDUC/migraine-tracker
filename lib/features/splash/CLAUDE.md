# Splash

The loading indicator, over the work a launch has to settle first, then the
dashboard.

- **It is the app's first route** (`initialLocation`), and it leaves for the
  dashboard when `SplashController.run` returns. No timer: it lasts exactly what
  the work lasts.
- **It does NOT carry the device check.** `SdFreshInstall` runs in `main`,
  ahead of `runApp`: its wipe drops the Firestore cache, and `clearPersistence`
  throws `failed-precondition` once anything has opened a stream —
  `ForceUpdateWrapper` opens one on this route's own first frame. It was here
  while the wipe was only a sign-out; a cache step cannot be.
- **`AppBootstrap.ensureAnonymousSession` is called again here.** The bootstrap
  step already tried it after the wipe; this is the retry for a launch that had
  no network, and `getWeather` will not serve a caller it cannot name.
- **The splash is exempt from the router's `redirect`.** A wiped or first
  install has no `onboarding_completed`, so every rule below would send frame
  one to `/onboarding` and the work this screen exists to hold would never run.
  It leaves for the dashboard itself, where the rules apply as usual — that is
  what sends a wiped install to onboarding.
- **`SplashController.run` never throws.** An app that cannot get past its own
  loading screen is worse than one that starts signed out.
- **`initialLocationProvider` exists for the tests.** `pumpApp` overrides it to
  the dashboard: the dots animation never ends, so a `pumpAndSettle` on the
  splash waits out its whole timeout instead of settling.
- **Nothing on it but the dots** (owner's call), at a raw pixel size — the first
  frame gains nothing from the design-size scale.
- **The native launch screen before it carries the app icon**
  (`LaunchImage.imageset`, `docs/setup/APP_ICON.md`), because the bootstrap
  steps run before any Dart draws and a bare colour field for that whole wait
  reads as a black screen. The icon goes away when this screen takes over; putting it here
  too is the one-line fix if that ever reads worse than the black did.
- **No ARB strings.** Nothing on the screen is a word.
