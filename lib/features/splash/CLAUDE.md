# Splash

The loading indicator, over the work a launch has to settle first, then the
dashboard.

- **It is the app's first route** (`initialLocation`), and it leaves for the
  dashboard when `SplashController.run` returns — the startup work, or
  `SplashConstant.minimumVisible` (2s), whichever is longer.
- **The 2s floor is the owner's call: the dots must be seen.** The session work
  usually settles in a fraction of a second, so without it a launch flickers
  from the launch image to the dashboard and reads as a glitch rather than as a
  loading screen. `SplashController.run` starts the timer *before* the work and
  awaits it after, so the two overlap and a launch slower than 2s pays nothing
  for the floor. `FreshInstallGate` above the app has no floor — the device
  check it waits on is not a screen of its own.
- **The device check runs under the same dots, but ABOVE this route, not in
  it.** `FreshInstallGate` (`presentation/widgets/`) watches
  `freshInstallProvider` and holds `_BaroEaseAppView` back until it resolves.
  It cannot live on this route: the wipe drops the Firestore cache, and
  `clearPersistence` throws `failed-precondition` once anything has opened a
  stream — `_BaroEaseAppView`'s first frame starts the sync, records pressure
  and reads `app_config`, and this route only exists inside it.
- **Both draw `SplashDots`, so the hand-off has no seam.** The gate draws it
  above `MaterialApp`, where there is no theme, no `MediaQuery` and no
  `Material` — hence its own `Directionality`, the raw colour, and
  `SplashConstant.dotsSize` being a plain `40` rather than `40.r`
  (`ScreenUtilInit` is below the gate).
  - **The animation itself lives in `core/widgets/app_loading_dots.dart`**, not
    here: the head picker waits on its model under the same dots, and two
    copies of one wait are two things that can drift apart. `SplashDots` is
    what wraps it in the launch's own background and text direction.
- **`AppBootstrap.ensureAnonymousSession` is called here and nowhere else.**
  It has to come after the wipe — that signs the old session out — and
  `getWeather` will not serve a caller it cannot name.
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
